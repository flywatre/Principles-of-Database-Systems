#!/usr/bin/env bash
cd /root/bustub || exit 1
for f in src/include/buffer/lru_k_replacer.h src/include/container/hash/extendible_hash_table.h; do
  echo "=================== $f ==================="
  tr -d '\r' < "$f"
  echo
done
