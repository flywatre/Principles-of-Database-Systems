//===----------------------------------------------------------------------===//
//
//                         BusTub
//
// extendible_hash_table.cpp
//
// Identification: src/container/hash/extendible_hash_table.cpp
//
// Copyright (c) 2022, Carnegie Mellon University Database Group
//
//===----------------------------------------------------------------------===//

#include <cassert>
#include <cstdlib>
#include <functional>
#include <list>
#include <utility>

#include "container/hash/extendible_hash_table.h"
#include "storage/page/page.h"

namespace bustub {

template <typename K, typename V>
ExtendibleHashTable<K, V>::ExtendibleHashTable(size_t bucket_size) : bucket_size_(bucket_size) {
  // 目录初始只有一个桶，全局深度为 0。
  // 不建这个桶的话 dir_ 是空的，GetLocalDepth(0) 会立刻越界。
  dir_.push_back(std::make_shared<Bucket>(bucket_size_, 0));
}

template <typename K, typename V>
auto ExtendibleHashTable<K, V>::IndexOf(const K &key) -> size_t {
  int mask = (1 << global_depth_) - 1;
  return std::hash<K>()(key) & mask;
}

template <typename K, typename V>
auto ExtendibleHashTable<K, V>::GetGlobalDepth() const -> int {
  std::scoped_lock<std::mutex> lock(latch_);
  return GetGlobalDepthInternal();
}

template <typename K, typename V>
auto ExtendibleHashTable<K, V>::GetGlobalDepthInternal() const -> int {
  return global_depth_;
}

template <typename K, typename V>
auto ExtendibleHashTable<K, V>::GetLocalDepth(int dir_index) const -> int {
  std::scoped_lock<std::mutex> lock(latch_);
  return GetLocalDepthInternal(dir_index);
}

template <typename K, typename V>
auto ExtendibleHashTable<K, V>::GetLocalDepthInternal(int dir_index) const -> int {
  return dir_[dir_index]->GetDepth();
}

template <typename K, typename V>
auto ExtendibleHashTable<K, V>::GetNumBuckets() const -> int {
  std::scoped_lock<std::mutex> lock(latch_);
  return GetNumBucketsInternal();
}

template <typename K, typename V>
auto ExtendibleHashTable<K, V>::GetNumBucketsInternal() const -> int {
  return num_buckets_;
}

template <typename K, typename V>
auto ExtendibleHashTable<K, V>::Find(const K &key, V &value) -> bool {
  std::scoped_lock<std::mutex> lock(latch_);
  return dir_[IndexOf(key)]->Find(key, value);
}

template <typename K, typename V>
auto ExtendibleHashTable<K, V>::Remove(const K &key) -> bool {
  std::scoped_lock<std::mutex> lock(latch_);
  return dir_[IndexOf(key)]->Remove(key);
}

/**
 * 插入。桶满时先拆分再重试，直到能插进去。
 */
template <typename K, typename V>
void ExtendibleHashTable<K, V>::Insert(const K &key, const V &value) {
  std::scoped_lock<std::mutex> lock(latch_);

  while (true) {
    const size_t index = IndexOf(key);
    auto bucket = dir_[index];

    // 键已存在 —— 覆盖，不需要拆分
    V discarded;
    if (bucket->Find(key, discarded)) {
      bucket->Insert(key, value);
      return;
    }

    // 桶没满 —— 直接插
    if (!bucket->IsFull()) {
      bucket->Insert(key, value);
      return;
    }

    // 桶满了，需要拆分
    if (bucket->GetDepth() == global_depth_) {
      // 只有一个指针指向它，目录必须翻倍
      const size_t old_size = dir_.size();
      dir_.resize(old_size * 2);
      for (size_t i = 0; i < old_size; i++) {
        dir_[i + old_size] = dir_[i];
      }
      global_depth_++;
    }

    const int old_depth = bucket->GetDepth();
    bucket->IncrementDepth();
    auto new_bucket = std::make_shared<Bucket>(bucket_size_, bucket->GetDepth());

    // 让原本指向旧桶的指针里，高位为 1 的那一半改指向新桶
    const size_t split_bit = static_cast<size_t>(1) << old_depth;
    for (size_t i = 0; i < dir_.size(); i++) {
      if (dir_[i] == bucket && (i & split_bit) != 0) {
        dir_[i] = new_bucket;
      }
    }

    num_buckets_++;
    RedistributeBucket(bucket);

    // 重新回到循环开头：可能还要再拆
  }
}

template <typename K, typename V>
auto ExtendibleHashTable<K, V>::RedistributeBucket(std::shared_ptr<Bucket> bucket) -> void {
  auto items = std::move(bucket->GetItems());
  bucket->GetItems().clear();
  for (auto &kv : items) {
    dir_[IndexOf(kv.first)]->Insert(kv.first, kv.second);
  }
}

//===--------------------------------------------------------------------===//
// Bucket
//===--------------------------------------------------------------------===//
template <typename K, typename V>
ExtendibleHashTable<K, V>::Bucket::Bucket(size_t array_size, int depth) : size_(array_size), depth_(depth) {}

template <typename K, typename V>
auto ExtendibleHashTable<K, V>::Bucket::Find(const K &key, V &value) -> bool {
  for (auto &kv : list_) {
    if (kv.first == key) {
      value = kv.second;
      return true;
    }
  }
  return false;
}

template <typename K, typename V>
auto ExtendibleHashTable<K, V>::Bucket::Remove(const K &key) -> bool {
  for (auto it = list_.begin(); it != list_.end(); ++it) {
    if (it->first == key) {
      list_.erase(it);
      return true;
    }
  }
  return false;
}

template <typename K, typename V>
auto ExtendibleHashTable<K, V>::Bucket::Insert(const K &key, const V &value) -> bool {
  for (auto &kv : list_) {
    if (kv.first == key) {
      kv.second = value;  // 覆盖
      return true;
    }
  }
  if (IsFull()) {
    return false;
  }
  list_.emplace_back(key, value);
  return true;
}

template class ExtendibleHashTable<page_id_t, Page *>;
template class ExtendibleHashTable<Page *, std::list<Page *>::iterator>;
template class ExtendibleHashTable<int, int>;
// test purpose
template class ExtendibleHashTable<int, std::string>;
template class ExtendibleHashTable<int, std::list<int>::iterator>;

}  // namespace bustub
