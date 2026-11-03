#!/usr/bin/env python3
"""在两个头文件里做最小的结构性插入（不改动原有注释）。"""
import sys

LRU_H = "/root/bustub/src/include/buffer/lru_k_replacer.h"
BPM_H = "/root/bustub/src/include/buffer/buffer_pool_manager_instance.h"

# ---------- 1. lru_k_replacer.h ----------
src = open(LRU_H, encoding="utf-8").read()

node_class = '''/**
 * 每个帧的访问历史与可驱逐标记。
 */
class LRUKNode {
 public:
  /** 最近 k 次访问的时间戳，最旧的在前，最新的在后。 */
  std::list<size_t> history_;
  /** 是否可被淘汰。新建时为 false，等到 pin_count 归零才置 true。 */
  bool is_evictable_{false};
};

'''

anchor = "class LRUKReplacer {"
if "class LRUKNode {" not in src:
    if src.count(anchor) != 1:
        sys.exit("lru_k_replacer.h: 找不到唯一的 class LRUKReplacer 锚点")
    src = src.replace(anchor, node_class + anchor)

old_member = "  [[maybe_unused]] size_t current_timestamp_{0};"
new_member = ("  /** 帧 -> 访问历史 */\n"
              "  std::unordered_map<frame_id_t, LRUKNode> node_store_;\n"
              "  size_t current_timestamp_{0};")
if "node_store_" not in src:
    if src.count(old_member) != 1:
        sys.exit("lru_k_replacer.h: 找不到唯一的 current_timestamp_ 成员")
    src = src.replace(old_member, new_member)

open(LRU_H, "w", encoding="utf-8").write(src)
print("  lru_k_replacer.h 已更新")

# ---------- 2. buffer_pool_manager_instance.h ----------
src = open(BPM_H, encoding="utf-8").read()

anchor = "  // TODO(student): You may add additional private members and helper functions"
helper = ("  /**\n"
          "   * @brief 取一个可用帧：优先空闲链表，其次驱逐一个可淘汰帧。\n"
          "   *        调用者必须已持有 latch_。\n"
          "   * @return false 表示缓冲池已满且所有帧都被 pin 住\n"
          "   */\n"
          "  auto AcquireFrame(frame_id_t *frame_id) -> bool;\n\n")

if "AcquireFrame" not in src:
    if src.count(anchor) != 1:
        sys.exit("buffer_pool_manager_instance.h: 锚点不唯一或不存在")
    src = src.replace(anchor, helper + anchor)

open(BPM_H, "w", encoding="utf-8").write(src)
print("  buffer_pool_manager_instance.h 已更新")
