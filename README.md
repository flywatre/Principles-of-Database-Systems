# 数据库系统原理 · 实验一：缓冲池管理器

CMU 15-445 BusTub **Project 1** 的完整实现与文档。项目实现了一个可用的数据库缓冲池：可扩展哈希表负责页映射，LRU-K 算法负责页面置换，缓冲池管理器把两者与磁盘读写串联起来。

## 完成情况

| 测试套件 | 用例数 | 结果 |
|---|---:|---|
| `extendible_hash_table_test` | 12 | ✅ 全部通过 |
| `lru_k_replacer_test` | 4 | ✅ 全部通过 |
| `buffer_pool_manager_instance_test` | 13 | ✅ 全部通过 |
| **合计** | **29** | **29 / 29** |

| 质量门禁 | 结果 |
|---|---|
| `make format` | ✅ 通过 |
| `make check-lint` | ✅ 实现文件零告警 |
| `make check-clang-tidy-p1` | ✅ 通过 |
| AddressSanitizer（Debug 全程开启） | ✅ 无越界、无泄漏 |

## 目录结构

```
.
├── bustub/                  BusTub 源码（已实现 P1，可直接编译）
│   ├── src/buffer/          lru_k_replacer.cpp / buffer_pool_manager_instance.cpp
│   ├── src/container/hash/  extendible_hash_table.cpp
│   └── test/                三个测试套件
│
├── experiment 1/            实验资料与文档
│   ├── 实验一指导文档.md     怎么做（算法讲解 + 逐函数流程 + 调试手册）
│   ├── 实验一设计文档.md     为什么这么做（结构选择、并发策略、取舍）
│   ├── 实验一总结文档.md     复盘（测试结果、7 个踩坑、改进方向）
│   ├── Tutorial for Project1.pdf
│   ├── LRU-2 算法的例子.pdf
│   └── CLOCK 时钟置换算法及其与 LRU 的关系.pdf
│
├── 文档/                    环境搭建说明
├── 原始代码/                课程下发的初始骨架（含未实现版本，便于对比）
├── 工具/                    构建与测试辅助脚本
└── 运行实验.cmd             一键编译并运行全部测试（Windows）
```

## 实验内容

### 1. Extendible Hash Table

用目录 + 桶的两级结构实现 `page_id → frame_id` 映射，避免整体 rehash：

- 全局深度决定目录大小（`2^g` 个槽），局部深度决定桶的实际前缀长度
- 桶满时**先拆分再插入**，且用循环处理"拆一次仍放不下"的情况
- 桶局部深度等于全局深度时才翻倍目录，否则只重分配兄弟指针
- 单锁保护整表，内部调用使用不加锁的 `*Internal` 版本避免自我死锁

### 2. LRU-K Replacer

按**后退 k-距离**淘汰，分三层优先级：

| 优先级 | 候选 | 判据 |
|---|---|---|
| 1 | 访问次数 < k | 后退 k-距离视为 +∞ |
| 2 | 多个 +∞ | 第一次访问时间最早者 |
| 3 | 访问次数 ≥ k | 后退 k-距离最大者 |

状态为 `unordered_map<frame_id, LRUKNode>`，每个节点保存最近 k 次访问的时间戳与可驱逐标记。

### 3. Buffer Pool Manager

| 成员 | 职责 |
|---|---|
| `pages_` | 帧数组，每帧含页号、pin 计数、脏标记与 4 KB 数据 |
| `page_table_` | 可扩展哈希表，`page_id → frame_id` |
| `replacer_` | LRU-K 替换器 |
| `free_list_` | 空闲帧链表 |
| `latch_` | 全局锁，保护以上全部元数据 |

关键设计是提取了 `AcquireFrame()`：空闲链表优先 → 无空闲则驱逐 → 脏页先写回 → 从页表摘除 → 重置帧。`NewPgImp` 与 `FetchPgImp` 共用这条路径，保证行为一致。

## 构建与测试

环境要求：Linux 或 WSL2 下的 Ubuntu 20.04+，clang 15（或 gcc 11+），CMake 3.20+。

```bash
cd bustub
mkdir -p build && cd build
cmake -DCMAKE_BUILD_TYPE=Debug ..
make -j$(nproc)

# 运行 P1 的全部测试
make lru_k_replacer_test extendible_hash_table_test buffer_pool_manager_instance_test
./test/lru_k_replacer_test
./test/extendible_hash_table_test
./test/buffer_pool_manager_instance_test
```

只跑单个用例：

```bash
./test/extendible_hash_table_test --gtest_filter='*InsertSplit*'
```

Windows 下可以双击 `运行实验.cmd`（需要事先配好 WSL 环境，见 `文档/Bustub实验环境配置指南.md`）。

## 开发环境

| 项目 | 配置 |
|---|---|
| 系统 | Ubuntu 22.04.5 LTS（WSL2） |
| 编译器 | clang 15.0.7 |
| 构建 | CMake 3.22.1，Debug + AddressSanitizer |
| 规范 | Google C++ Style（clang-format / clang-tidy） |

> 仓库不包含 WSL 虚拟磁盘与安装镜像（数 GB，超出 GitHub 限制）。
> 环境重建步骤见 `文档/Bustub实验环境配置指南.md`。

## 说明

- `bustub/` 下的代码为本人实现，用于课程实验。
- `experiment 1/` 中的 PDF 为课程提供的学习资料，仅作个人存档。
- `原始代码/bustub_initial.zip` 为课程下发的初始骨架，保留用于对比与还原。

## 参考

- CMU 15-445/645 Database Systems, Fall 2022, Lecture 03–07
- [cmu-db/bustub](https://github.com/cmu-db/bustub)
- [AddressSanitizer 文档](https://clang.llvm.org/docs/AddressSanitizer.html)
