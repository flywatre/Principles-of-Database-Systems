//===----------------------------------------------------------------------===//
//
//                         BusTub
//
// buffer_pool_manager_instance.cpp
//
// Identification: src/buffer/buffer_pool_manager.cpp
//
// Copyright (c) 2015-2021, Carnegie Mellon University Database Group
//
//===----------------------------------------------------------------------===//

#include "buffer/buffer_pool_manager_instance.h"

#include "common/exception.h"
#include "common/macros.h"

namespace bustub {

BufferPoolManagerInstance::BufferPoolManagerInstance(size_t pool_size, DiskManager *disk_manager, size_t replacer_k,
                                                     LogManager *log_manager)
    : pool_size_(pool_size), disk_manager_(disk_manager), log_manager_(log_manager) {
  // we allocate a consecutive memory space for the buffer pool
  pages_ = new Page[pool_size_];
  page_table_ = new ExtendibleHashTable<page_id_t, frame_id_t>(bucket_size_);
  replacer_ = new LRUKReplacer(pool_size, replacer_k);

  // Initially, every page is in the free list.
  for (size_t i = 0; i < pool_size_; ++i) {
    free_list_.emplace_back(static_cast<int>(i));
  }
}

BufferPoolManagerInstance::~BufferPoolManagerInstance() {
  delete[] pages_;
  delete page_table_;
  delete replacer_;
}

/**
 * 取一个可用帧：优先空闲链表，其次驱逐一个可淘汰帧。调用者必须已持有 latch_。
 * @return false 表示缓冲池已满且没有任何帧可被驱逐
 */
auto BufferPoolManagerInstance::AcquireFrame(frame_id_t *frame_id) -> bool {
  // 1. 有空闲帧
  if (!free_list_.empty()) {
    *frame_id = free_list_.front();
    free_list_.pop_front();
    return true;
  }

  // 2. 没有空闲帧，让替换器挑一个牺牲者
  frame_id_t victim = -1;
  if (!replacer_->Evict(&victim)) {
    return false;  // 全是 pinned
  }

  // 3. 回收旧帧：脏页先写回，再从页表里摘掉
  Page &old = pages_[victim];
  if (old.page_id_ != INVALID_PAGE_ID) {
    if (old.is_dirty_) {
      disk_manager_->WritePage(old.page_id_, old.GetData());
    }
    page_table_->Remove(old.page_id_);
  }
  old.ResetMemory();
  old.page_id_ = INVALID_PAGE_ID;
  old.is_dirty_ = false;
  old.pin_count_ = 0;

  *frame_id = victim;
  return true;
}

auto BufferPoolManagerInstance::NewPgImp(page_id_t *page_id) -> Page * {
  std::scoped_lock<std::mutex> lock(latch_);

  frame_id_t frame_id = -1;
  if (!AcquireFrame(&frame_id)) {
    return nullptr;
  }

  const page_id_t new_page_id = AllocatePage();
  Page &page = pages_[frame_id];
  page.ResetMemory();
  page.page_id_ = new_page_id;
  page.pin_count_ = 1;
  page.is_dirty_ = false;

  page_table_->Insert(new_page_id, frame_id);
  replacer_->RecordAccess(frame_id);
  replacer_->SetEvictable(frame_id, false);

  *page_id = new_page_id;
  return &page;
}

auto BufferPoolManagerInstance::FetchPgImp(page_id_t page_id) -> Page * {
  std::scoped_lock<std::mutex> lock(latch_);

  // 命中：直接返回，pin_count 加一，并重置淘汰计时
  frame_id_t frame_id = -1;
  if (page_table_->Find(page_id, frame_id)) {
    Page &page = pages_[frame_id];
    page.pin_count_++;
    replacer_->RecordAccess(frame_id);
    replacer_->SetEvictable(frame_id, false);
    return &page;
  }

  // 未命中：取帧 → 读盘 → 登记
  if (!AcquireFrame(&frame_id)) {
    return nullptr;
  }

  Page &page = pages_[frame_id];
  page.ResetMemory();
  disk_manager_->ReadPage(page_id, page.GetData());
  page.page_id_ = page_id;
  page.pin_count_ = 1;
  page.is_dirty_ = false;

  page_table_->Insert(page_id, frame_id);
  replacer_->RecordAccess(frame_id);
  replacer_->SetEvictable(frame_id, false);

  return &page;
}

auto BufferPoolManagerInstance::UnpinPgImp(page_id_t page_id, bool is_dirty) -> bool {
  std::scoped_lock<std::mutex> lock(latch_);

  frame_id_t frame_id = -1;
  if (!page_table_->Find(page_id, frame_id)) {
    return false;
  }

  Page &page = pages_[frame_id];
  if (page.pin_count_ <= 0) {
    return false;
  }

  // 只有"传入了脏"才置脏；已经是脏的不会被改回干净
  if (is_dirty) {
    page.is_dirty_ = true;
  }

  page.pin_count_--;
  if (page.pin_count_ == 0) {
    replacer_->SetEvictable(frame_id, true);
  }

  return true;
}

auto BufferPoolManagerInstance::FlushPgImp(page_id_t page_id) -> bool {
  std::scoped_lock<std::mutex> lock(latch_);

  frame_id_t frame_id = -1;
  if (!page_table_->Find(page_id, frame_id)) {
    return false;  // 不在缓冲池里
  }

  Page &page = pages_[frame_id];
  disk_manager_->WritePage(page_id, page.GetData());
  page.is_dirty_ = false;
  return true;
}

void BufferPoolManagerInstance::FlushAllPgsImp() {
  std::scoped_lock<std::mutex> lock(latch_);

  for (size_t i = 0; i < pool_size_; i++) {
    Page &page = pages_[i];
    if (page.page_id_ != INVALID_PAGE_ID) {
      disk_manager_->WritePage(page.page_id_, page.GetData());
      page.is_dirty_ = false;
    }
  }
}

auto BufferPoolManagerInstance::DeletePgImp(page_id_t page_id) -> bool {
  std::scoped_lock<std::mutex> lock(latch_);

  frame_id_t frame_id = -1;
  if (!page_table_->Find(page_id, frame_id)) {
    return true;  // 本来就不在缓冲池，视为删除成功
  }

  Page &page = pages_[frame_id];
  if (page.pin_count_ > 0) {
    return false;  // 还有人在用，不能删
  }

  if (page.is_dirty_) {
    disk_manager_->WritePage(page_id, page.GetData());
  }

  page_table_->Remove(page_id);
  replacer_->Remove(frame_id);

  page.ResetMemory();
  page.page_id_ = INVALID_PAGE_ID;
  page.pin_count_ = 0;
  page.is_dirty_ = false;

  free_list_.push_back(frame_id);
  DeallocatePage(page_id);
  return true;
}

auto BufferPoolManagerInstance::AllocatePage() -> page_id_t { return next_page_id_++; }

}  // namespace bustub
