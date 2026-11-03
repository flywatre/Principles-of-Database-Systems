#!/usr/bin/env bash
cd /root/bustub || exit 1
echo "=================== page.h ==================="
tr -d '\r' < src/include/storage/page/page.h
echo
echo "=================== disk_manager.h（只看公开方法）==================="
tr -d '\r' < src/include/storage/disk/disk_manager.h | grep -nE '^\s*(auto|void|explicit|virtual|~)|public:|private:' | head -40
