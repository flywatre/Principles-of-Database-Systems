//===----------------------------------------------------------------------===//
//
//                         BusTub
//
// lru_k_replacer.cpp
//
// Identification: src/buffer/lru_k_replacer.cpp
//
// Copyright (c) 2015-2022, Carnegie Mellon University Database Group
//
//===----------------------------------------------------------------------===//

#include "buffer/lru_k_replacer.h"

#include <cstddef>
#include <limits>

#include "common/exception.h"

namespace bustub {

LRUKReplacer::LRUKReplacer(size_t num_frames, size_t k) : replacer_size_(num_frames), k_(k) {}

/**
 * 淘汰后退 k-距离最大的可驱逐帧。
 *
 * 三类候选的优先级：
 *   1. 访问次数 < k（后退 k-距离为 +inf）的帧，优先淘汰；
 *   2. 多个 +inf 之间，取"第一次访问时间最早"的（传统 LRU 语义）；
 *   3. 访问次数 >= k 的帧之间，取 (当前时间 - 第 k 次先前访问时间) 最大的。
 */
auto LRUKReplacer::Evict(frame_id_t *frame_id) -> bool {
  std::scoped_lock<std::mutex> lock(latch_);

  bool found = false;
  bool found_inf = false;
  size_t best_earliest = 0;   // +inf 候选中最早的时间戳
  size_t best_distance = 0;   // 有限候选中最大的后退 k-距离
  frame_id_t victim = -1;

  for (const auto &entry : node_store_) {
    const frame_id_t fid = entry.first;
    const auto &node = entry.second;
    if (!node.is_evictable_) {
      continue;
    }

    const bool is_inf = node.history_.size() < k_;
    const size_t earliest = node.history_.front();

    size_t distance = 0;
    if (!is_inf) {
      // 第 k 次先前访问 = 历史中的倒数第 k 个
      auto it = node.history_.rbegin();
      std::advance(it, static_cast<std::ptrdiff_t>(k_) - 1);
      distance = current_timestamp_ - *it;
    }

    bool better = false;
    if (!found) {
      better = true;
    } else if (is_inf != found_inf) {
      better = is_inf;  // +inf 优先于任何有限值
    } else if (is_inf) {
      better = earliest < best_earliest;  // 都是 +inf：最早访问的先淘汰
    } else {
      better = distance > best_distance;  // 都有限：距离最大的先淘汰
    }

    if (better) {
      found = true;
      found_inf = is_inf;
      victim = fid;
      best_earliest = earliest;
      best_distance = distance;
    }
  }

  if (!found) {
    return false;
  }

  node_store_.erase(victim);
  curr_size_--;
  *frame_id = victim;
  return true;
}

void LRUKReplacer::RecordAccess(frame_id_t frame_id) {
  std::scoped_lock<std::mutex> lock(latch_);

  if (static_cast<size_t>(frame_id) >= replacer_size_) {
    throw Exception("LRUKReplacer: invalid frame id in RecordAccess");
  }

  current_timestamp_++;

  auto &node = node_store_[frame_id];
  node.history_.push_back(current_timestamp_);
  // 只保留最近 k 次访问
  while (node.history_.size() > k_) {
    node.history_.pop_front();
  }
}

void LRUKReplacer::SetEvictable(frame_id_t frame_id, bool set_evictable) {
  std::scoped_lock<std::mutex> lock(latch_);

  if (static_cast<size_t>(frame_id) >= replacer_size_) {
    throw Exception("LRUKReplacer: invalid frame id in SetEvictable");
  }

  auto it = node_store_.find(frame_id);
  if (it == node_store_.end()) {
    return;  // 未登记过的帧：什么都不做
  }

  auto &node = it->second;
  if (node.is_evictable_ == set_evictable) {
    return;  // 状态没变，不能重复加减计数
  }

  node.is_evictable_ = set_evictable;
  if (set_evictable) {
    curr_size_++;
  } else {
    curr_size_--;
  }
}

void LRUKReplacer::Remove(frame_id_t frame_id) {
  std::scoped_lock<std::mutex> lock(latch_);

  auto it = node_store_.find(frame_id);
  if (it == node_store_.end()) {
    return;
  }

  if (!it->second.is_evictable_) {
    throw Exception("LRUKReplacer: removing a non-evictable frame");
  }

  node_store_.erase(it);
  curr_size_--;
}

auto LRUKReplacer::Size() -> size_t {
  std::scoped_lock<std::mutex> lock(latch_);
  return curr_size_;
}

}  // namespace bustub
