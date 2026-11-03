# BusTub（CMU 15-445）实验环境配置指南

> 依据：《数据库实验环境配置.pdf》+ 本次实机配置的全部踩坑记录。
> 配套文件：`setup_bustub.sh`（一键配置脚本）、`02-启用WSL2.cmd`（WSL2 离线安装器）。

---

## 现在的环境（已配置完成，可以直接做实验）

环境不是虚拟机，而是 **WSL2 里的 Ubuntu 22.04**。原因是原来那台 VMware 虚拟机是
**32 位 Ubuntu 16.04 + gcc 5.4**，属于硬性不兼容（见下面「零」），重装一套虚拟机又要一小时，
而 WSL2 只要几分钟。

| 项目 | 值 |
|---|---|
| 发行版 | Ubuntu 22.04.5 LTS（jammy） |
| 内核 | 6.18.54.1-microsoft-standard-WSL2 |
| 架构 | x86_64 |
| CPU / 内存 | 20 核 / 15.4 GB |
| 磁盘 | 约 955 GB 可用 |
| 编译器 | **clang 15.0.7**（Debug + AddressSanitizer） |
| CMake | 3.22.1 |
| 源码目录 | `/root/bustub`（课程定制的 BusTub **2023.1**，仅含 P1；本地 git 基线 `1490cc2`） |
| 构建目录 | `/root/bustub/build` |
| 发行版存放 | `D:\code\database system principle\_wsl\Ubuntu-22.04\ext4.vhdx` |
| APT 源 | 清华镜像 |

### 三个入口

| 双击 | 用途 |
|---|---|
| `2-打开代码编辑器.cmd` | VS Code 打开 `/root/bustub`，**写代码用这个** |
| `运行实验.cmd` | 一键编译 + 跑 P1 三个测试 |
| `启动实验环境.cmd` | 打开 Linux 终端 |

或者在任意终端里：

```powershell
wsl                 # 进默认发行版，当前用户是 root
wsl -d Ubuntu-22.04 --cd /root/bustub
```

### 整个文件夹的结构

所有东西都在 `D:\code\database system principle\` 里，没有散落在别处：

```
D:\code\database system principle\
├─ 2-打开代码编辑器.cmd / 运行实验.cmd / 启动实验环境.cmd
├─ README.md                                   ← 导航说明
├─ 文档\
│   ├─ Bustub实验环境配置指南.md                ← 本文档
│   └─ 数据库实验环境配置.pdf                   ← 课程原始要求
├─ 环境\
│   ├─ Ubuntu-22.04\ext4.vhdx                  ← 整个 Linux + 代码（4.8 GB）
│   ├─ 安装包\                                  ← WSL 安装镜像（重装用，可删）
│   └─ 安装脚本\                                ← 安装器与日志（存档）
├─ 原始代码\
│   └─ bustub_initial.zip                      ← 课程初始代码（只读备份）
└─ 工具\                                       ← 配置与诊断脚本（存档）
```

用 Windows 侧看源代码（只读浏览用）：
`\\wsl.localhost\Ubuntu-22.04\root\bustub`

> **别把代码复制到 D 盘再改**。跨文件系统（`/mnt/d/...`）编译会慢好几倍，
> 而且文件权限行为不一致。代码就放在虚拟磁盘里的 `/root/bustub`。

### 日常命令

```bash
bash /root/tools/run-p1.sh      # 一键：编译 + 跑 P1 三个测试
cd /root/bustub/build
make -j$(nproc) lru_k_replacer_test      # 只编一个测试
./test/lru_k_replacer_test               # 跑
./test/lru_k_replacer_test --gtest_filter='LRUKReplacerTest.SampleTest'
make format && make check-lint           # 格式检查
make check-clang-tidy-p1                 # 静态检查
```

> `make format` 会**直接改写你的源文件**，别在没提交的代码上随手跑。

### 三个已经踩过并修好的坑

1. **`YOU HAVE 7 DISABLED TESTS`** —— 测试函数名带 `DISABLED_` 前缀，属于正常现象。
   打开对应 `test/*.cpp` 去掉前缀再 `make` 即可，PDF 里也讲了这点。
2. **测试随机段错误、无任何输出** —— 内核把 `vm.mmap_rnd_bits` 调到 32，而 ASan 要求 ≤28。
   已通过 `/etc/sysctl.d/99-bustub-asan.conf` 固定为 28，重启 WSL 后仍生效。
3. **CMake 报 "couldn't find clang-format / clang-tidy"** —— 它找的是不带版本号的命令，
   已用 `update-alternatives` 把 `clang-format` / `clang-tidy` 指向 15。

### 提交作业前记得配 git 身份

```bash
git config --global user.name "你的名字"
git config --global user.email "你的邮箱"
```

> 下面「零」和「一」是环境判断标准，**二～九**是当时的备选方案（虚拟机路线）与通用排错，
> 现在用不到，留着以后换机器时参考。

---

## 零、先过这道硬门槛

```bash
getconf LONG_BIT        # 必须输出 64
uname -m                # 必须是 x86_64（或 aarch64）
lsb_release -s -i -r    # 必须是 Ubuntu 20.04 或更高
```

**三条满足不了就直接重装系统，不要试图在旧系统上打补丁**：

- **32 位（i686 / i386）绝对不行。** BusTub 用 C++17，需要 gcc ≥ 8 或 clang-14，而这两个工具链没有官方 i386 构建；Ubuntu 16.04 自带的 gcc 5.4 只到 C++14。
- **Ubuntu 18.04 也不行。** 自带 gcc 7.5、cmake 3.10，差一档。
- **Ubuntu 16.04 已 EOL**，`apt.llvm.org/xenial` 现在直接返回 404，换源也救不回来。

> 实测记录：Ubuntu 16.04.7 i686 + gcc 5.4 的虚拟机，脚本在"基础工具链"这步就会停在
> `[FAIL] gcc 版本过低（5.4.0），需要 >= 8`。这不是脚本的问题，是环境的天花板。

---

## 一、这台虚拟机够不够用

在虚拟机终端里执行：

```bash
lsb_release -a          # 系统版本
nproc                   # CPU 核数
free -h                 # 内存
df -h ~                 # 磁盘剩余
```

| 项目 | 最低 | 推荐 | 说明 |
|---|---|---|---|
| 位数 | **64 位** | 64 位 | 32 位无解，见上一节 |
| 系统 | Ubuntu 20.04 | **22.04 LTS** | 不要用中文 locale |
| CPU | 2 核 | 4 核 | 编译速度直接取决于核数 |
| 内存 | 2 GB | **4 GB 以上** | 2 GB 用 `make -j4` 会被 OOM Killer 杀掉 |
| 磁盘 | 15 GB | 25 GB 以上 | 源码 + build + 测试目标约 5–8 GB |

不够的话先在 **VMware → 虚拟机设置** 里加内存/CPU，再关机重启虚拟机，然后继续。

> 提示：装系统时如果把语言选成了中文，编译脚本容易出现乱码或路径解析问题。改回英文：
> ```bash
> sudo locale-gen en_US.UTF-8
> sudo update-locale LANG=en_US.UTF-8
> ```
> 重新登录后生效。

---

## 二、把脚本送进虚拟机（四选一）

**方式 A：拖拽 / 复制粘贴（最省事）**
装了 `open-vm-tools` 的话，直接把 Windows 上的 `setup_bustub.sh` 拖进虚拟机桌面。
没装就装一下：`sudo apt install -y open-vm-tools open-vm-tools-desktop`

**方式 B：终端粘贴建文件**
在虚拟机终端里输入下面这一行，回车，然后把脚本全文粘贴进去，最后按 `Ctrl+D`：

```bash
cat > ~/setup_bustub.sh <<'BUSTUB_EOF'
```

（`'BUSTUB_EOF'` 加了引号，保证 `$` 等符号不被提前展开。）

**方式 C：VMware 共享文件夹**
虚拟机设置 → 选项 → 共享文件夹 → 添加 `D:\code\database system principle`。
然后在虚拟机里访问 `/mnt/hgfs/共享名/setup_bustub.sh`。

**方式 D：主机起个临时 HTTP 服务，虚拟机下载**
需要我这边操作的话说一声，我会在主机上起一个只读的临时服务，你在虚拟机里 `wget` 即可。

---

## 三、执行

```bash
# 1) 如果文件是从 Windows 传过来的，先去掉可能存在的 CRLF（无害，可无脑执行）
sed -i 's/\r$//' ~/setup_bustub.sh

# 2) 跑起来（中途会要一次 sudo 密码）
bash ~/setup_bustub.sh
```

常用变体：

```bash
bash ~/setup_bustub.sh --repo ~/Documents/bustub    # 源码不在默认位置时手动指定
bash ~/setup_bustub.sh --jobs 2                     # 内存小，限制并行度
bash ~/setup_bustub.sh --clean                      # 换过编译器/从别处拷来的 build 目录
bash ~/setup_bustub.sh --with-tests                 # 顺带把全部单元测试也编译出来
bash ~/setup_bustub.sh --clang                      # 强制用 clang-14 编译
bash ~/setup_bustub.sh --no-mirror                  # 你在境外/有代理，不想自动换源
bash ~/setup_bustub.sh --help
```

### 脚本做了哪 7 件事

| 步骤 | 内容 | 失败时 |
|---|---|---|
| 0 | 探测系统版本、架构、内存、CPU、locale | 非 Ubuntu/Debian 直接退出 |
| 1 | 在 `~/Documents` 等处定位 bustub 源码，发现压缩包自动解压 | 提示用 `--repo` 指定 |
| 2 | `apt-get update`；失败则自动切清华/阿里/中科大镜像（原文件带时间戳备份） | 报网络问题 |
| 3 | 装 `build-essential`、`git`、`cmake`、`python-is-python3` 等 | 中止 |
| 4 | 确保 cmake ≥ 3.20（apt → Kitware 仓库 → pip 三级降级） | 中止并给手动方案 |
| 5 | 跑 `build_support/packages.sh`；补 clang-14（apt 装不上则 `llvm.sh 14`） | **只告警不中断** |
| 6 | `cmake -DCMAKE_BUILD_TYPE=Debug ..` + `make -jN`，编译日志存 `/tmp/bustub_build.log` | 打印最后 40 行并中止 |
| 7 | 可选构建测试 | 只告警 |

**设计取向**：clang-14 / clang-format-14 只影响 `make format`、`make check-lint` 这类格式检查，**不影响编译和跑测试**，所以它失败不会让整个流程中断。

---

## 四、验证是否装好了

```bash
cd ~/Documents/bustub/build        # 换成脚本最后打印的实际路径
echo '\q' | ./bin/bustub-shell     # 能进入 shell 再退出 = 基础环境 OK
```

再编一个最小测试验证 GTest 链路：

```bash
make lru_replacer_test -j$(nproc)
./test/lru_replacer_test
```

> **注意**：初始状态下测试函数名带 `DISABLED_` 前缀，直接跑会显示 `DISABLED` 而不执行。
> 打开对应的 `test/*.cpp`，把 `TEST(LRUKReplacerTest, DISABLED_SampleTest)` 改成
> `TEST(LRUKReplacerTest, SampleTest)` 再重新 `make` 即可。

---

## 五、报错对照表

| 报错 | 原因 | 处理 |
|---|---|---|
| `E: Package 'clang-14' has no installation candidate` | 20.04 / 24.04 的源里没有 clang-14 | 脚本已自动降级到 `llvm.sh`；手动：`wget https://apt.llvm.org/llvm.sh && chmod +x llvm.sh && sudo ./llvm.sh 14` |
| `command 'python' not found` | 只有 `python3` | `sudo apt install -y python-is-python3` |
| `/usr/bin/env: 'python3\r': No such file or directory` | 脚本是 CRLF 换行 | `sed -i 's/\r$//' 该文件`，或 vim 里 `:set ff=unix` 后 `:wq` |
| `CMake 3.20 or higher is required` | cmake 太旧（20.04 自带 3.16） | `bash setup_bustub.sh --clean` 会自动升级；或手动装 Kitware 版 |
| `fatal error: gtest/gtest.h: No such file or directory` | `third_party/` 缺失（下载的是不完整包） | `git submodule update --init --recursive`，或重新下载完整仓库 |
| `c++: fatal error: Killed signal terminated program cc1plus` | 内存不够，被 OOM Killer 杀了 | 降并行度 `--jobs 2`，或给虚拟机加内存（推荐 4 GB+） |
| `make: *** No rule to make target 'check-tests'` | 不同年份的 bustub 目标名不一样 | 先 `make help` 看可用目标，或改用 `ctest` |
| `Permission denied` 跑 `packages.sh` | 没有执行位 | `chmod +x build_support/packages.sh` |
| `apt-get update` 卡住/超时 | 默认源在国内慢 | 脚本会自动切镜像；也可手动 `--mirror tuna` |
| 编译产物找不到 | 目录层级记错 | 产物在 `build/bin/`、`build/test/` |

卡住了就把终端输出贴给我，特别是 `/tmp/bustub_build.log` 的最后 40 行。

---

## 六、日常开发流程速查

```bash
cd ~/Documents/bustub

# 改了 .cpp / .h —— 不用重跑 cmake，直接编
cd build && make -j$(nproc)

# 只编某个测试（快）
make -j$(nproc) lru_replacer_test && ./test/lru_replacer_test

# 全部测试
make -j$(nproc) check-tests

# 格式（会直接改你的文件）
make format
make check-lint
make check-clang-tidy-p1

# 提交某个 Lab
make submit-p1          # 按 Lab 号调整
```

**只有这三种情况需要重新 `cmake ..`**：改了 `CMakeLists.txt`、新增源文件、删除源文件。

**调试**：别堆 `printf`，用 `common/logger.h` 的 log 宏，或者
```bash
gdb --args ./bin/bustub-shell
```

**换 Debug 模式**（默认已开，gdb 调试需要）：
```bash
cmake -DCMAKE_BUILD_TYPE=Debug ..
make -j$(nproc)
```

**提交前的硬性要求**（PDF 里明确写了）：
- 遵循 Google C++ 风格，函数**必须用尾置返回类型**
- 不能有内存泄漏
- 格式不合规直接判 0 分

---

## 七、重装成 64 位 Ubuntu 22.04（保留 VMware 的方案）

**1. 下镜像（用清华镜像，几十 MB/s）**

打开 <https://mirrors.tuna.tsinghua.edu.cn/ubuntu-releases/22.04/>，下
`ubuntu-22.04.x-desktop-amd64.iso`（想要轻量就用同级目录 `server` 版）。
文件名里的 **`amd64` 就是 64 位**，别下成 `i386`。

**2. 在 VMware 里新建虚拟机**

- 新建 → 典型 → 稍后安装操作系统
- 客户机操作系统：**Linux → Ubuntu 64 位**（这一项选错就会变成 32 位机器）
- 磁盘：40 GB，存储为单个文件
- 自定义硬件：内存 **4 GB 起（能给 8 GB 更好）**、处理器 **4 核**、网络 NAT

**3. 安装系统**

安装向导里语言选 **English**（别选中文，后面构建脚本会给你添麻烦）。
用户名按你习惯取，密码记住。

**4. 装完先装 VMware 工具和基础包**

```bash
sudo apt update
sudo apt install -y open-vm-tools open-vm-tools-desktop
```

**5. 把 `setup_bustub.sh` 拖进虚拟机，执行**

```bash
sed -i 's/\r$//' ~/setup_bustub.sh
bash ~/setup_bustub.sh --repo ~/Documents/bustub
```

（`~/Documents/bustub` 换成你重新下载/拷贝的 bustub 路径。）

> 原来那台 16.04 虚拟机不用删，留着也行；但 **bustub 这份代码在新机器上要重新准备一份**，
> 不要直接拿 32 位机器上的 `build/` 目录过去——里面的 `CMakeCache.txt` 记录了旧的编译器路径和
> 32 位标志，会让新机器上的编译以奇怪的方式失败。脚本的 `--clean` 会自动处理这个。

---

## 八、更快的替代方案：WSL2

你主机是 Windows，其实**不用 VMware 也能做这个实验**，而且速度快一个数量级（没有图形界面开销，文件读写直接走本机磁盘）。PDF 里也把 WSL 列为官方支持方案之一。

```powershell
# 管理员身份打开 PowerShell，然后：
wsl --install -d Ubuntu-22.04
# 装完重启，按提示设置 Linux 用户名和密码
```

装好后在 PowerShell 里 `wsl -d Ubuntu-22.04` 就能进入。之后同样跑 `setup_bustub.sh`。

**几个要注意的点：**

- 代码必须放在 Linux 自己的文件系统里（`~/`），**不要放在 `/mnt/d/` 下**——跨文件系统编译会慢到离谱，而且 `chmod` 行为不对。
- 需要主板开启 CPU 虚拟化（VT-x / AMD-V），任务管理器 → 性能 → CPU 里能看到"虚拟化：已启用"。
- 用 `wsl --install` 需要管理员权限并重启一次。

**这条路的最大好处**：WSL 是我这边能直接调用到的（`wsl.exe -d Ubuntu-22.04 -- bash -lc "..."`），
所以我能**全自动**帮你装环境、编译、跑测试、看报错，你完全不用复制粘贴。

---

## 九、让我直接接管 VMware 里的虚拟机

**在虚拟机里：**
```bash
sudo apt install -y openssh-server
sudo systemctl enable --now ssh
ip a | grep 'inet '        # 记下 192.168.x.x 这个地址
```

**在 Windows（PowerShell）里验证：**
```powershell
ssh 你的用户名@192.168.x.x
```

能连上后把 IP、用户名、密码告诉我，我就能直接在上面操作了。
（VMware NAT 模式下，虚拟机 IP 一般是 `192.168.xxx.128` 之类；主机侧对应网卡是 `VMnet8`。）

---

## 十、怎么做实验（工作流）

### 第 0 步：装编辑器（一次性，约 5 分钟）

在终端里敲 `vim` 改 buffer pool manager 会非常痛苦。推荐：

1. Windows 上装 **VS Code**（如果还没有）
2. VS Code 扩展商店里装两个扩展：**WSL** 和 **clangd**
3. 进 WSL 终端，执行：

```bash
cd /root/bustub && code .
```

窗口会在 Windows 上打开，但**编辑的是 WSL 里的文件**，保存即生效，编译在 Linux 侧跑。
`clangd` 服务器已经装好（15.0.7），`build/compile_commands.json` 也已生成，
所以跳转定义、补全、显示错误都能直接用。

不想装 VS Code 的话，在终端里 `apt install vim` 或直接用 `nano`，只是效率低一些。

### 第 1 步：搞清楚这个 Lab 要你做什么

**权威顺序**：课程页面 / PDF > 代码里的 `TODO(P1)` 注释 > 测试文件。

```bash
grep -rn "TODO(P1)" /root/bustub/src   # 所有待实现的位置
cat /root/bustub/p1_test.sh            # 课程自带的 P1 一键脚本
```

你这份是课程定制的 **BusTub 2023.1**，**只有 P1**（P2–P4 没有 TODO），
要完成三个部件，全部位于 `src/` 下，头文件里留好了成员变量和 TODO 注释：

| 部件 | 实现文件 | 头文件 |
|---|---|---|
| LRU-K 替换器 | `src/buffer/lru_k_replacer.cpp` | `src/include/buffer/lru_k_replacer.h` |
| 缓冲池管理器 | `src/buffer/buffer_pool_manager_instance.cpp` | `src/include/buffer/buffer_pool_manager_instance.h` |
| 可扩展哈希表 | `src/container/hash/extendible_hash_table.cpp` | `src/include/container/hash/extendible_hash_table.h` |

对应三个测试，共 **29 个用例**：

| 测试 | 用例数 | 启动时状态 |
|---|---:|---|
| `test/buffer/lru_k_replacer_test.cpp` | 4 | 全部失败 |
| `test/container/hash/extendible_hash_table_test.cpp` | 12 | 首个用例 SEGV |
| `test/buffer/buffer_pool_manager_instance_test.cpp` | 13 | 全部失败 |

> 好消息：这三个测试**本来就是启用状态**（没有 `DISABLED_` 前缀），不用手动改。
> 带 `DISABLED_` 的是其他 Lab 的测试（catalog、lock_manager、b_tree 等），跟 P1 无关。

### 第 2 步：跑一遍基线

```bash
cd /root/bustub
bash p1_test.sh        # 课程自带的脚本：format + lint + clang-tidy + 编译 + 跑三个测试
```

或者手动跑单个（更快）：

```bash
cd /root/bustub/build
make -j$(nproc) lru_k_replacer_test
./test/lru_k_replacer_test
```

**初始状态就是 0 通过 / 29 失败**，这是骨架的正常表现，不是环境问题。

> `extendible_hash_table_test` 会直接段错误而不是正常报错——因为 `Insert()` 是空的，
> 测试拿到的 bucket 是空指针，解引用就崩。ASan 会打印出崩溃所在的文件和行号。


### 第 3 步：改代码 → 编译 → 跑测试

```bash
cd /root/bustub/build

make -j$(nproc) buffer_pool_manager_test   # 只编这一个测试，几秒到几十秒
./test/buffer_pool_manager_test            # 跑

./test/buffer_pool_manager_test --gtest_filter='*PagePinEasy*'   # 只跑某个用例
```

`make -j$(nproc)` 会把整个工程也顺带编译一遍，第一次之后都是增量的，很快。

**只有这三种情况需要重新 `cmake ..`**：改了 `CMakeLists.txt`、新增源文件、删除源文件。
其余情况直接 `make` 就行。

### 第 4 步：调试

**① 看 ASan 报告（最有效）**

Debug 构建自带 AddressSanitizer，内存越界、use-after-free 会直接打印出错的 `文件:行号` 和调用栈：

```
==12345==ERROR: AddressSanitizer: heap-use-after-free on address 0x...
READ of size 8 at 0x... thread T0
    #0 0x... in bustub::BufferPoolManager::FetchPage(...) src/buffer/buffer_pool_manager.cpp:87
```

看到 `#0` 那一行的文件和行号，就是你该看的地方。

**② gdb（已装好 12.1）**

```bash
gdb --args ./test/buffer_pool_manager_test --gtest_filter='*PagePinEasy*'
(gdb) run
(gdb) bt            # 崩溃后看调用栈
(gdb) frame 2       # 切到第 2 帧
(gdb) p *page       # 打印变量
```

**③ 打日志**：别用 `printf`，用 `common/logger.h` 里的宏（PDF 也强调了这点），
它带时间戳和文件行号，而且不会破坏 ASan 的输出格式。

**④ 段错误但没有任何输出**：先确认 `cat /proc/sys/vm/mmap_rnd_bits` 是 `28`。
是 `32` 的话就是 ASan 的兼容问题，不是你的代码错。

### 第 5 步：提交前

```bash
cd /root/bustub/build

make format                    # 自动排版（会直接改写源文件，先 commit 再跑更安全）
make check-lint                # cpplint 检查
make check-clang-tidy-p1       # 静态检查（p0~p4 对应各 Lab）
```

然后填 `docs/p1-design.md`（提交时会自动一起打包，`make submit-p1` 会读它），最后：

```bash
make submit-p1                 # 生成提交包
```

> 课程要求：Google C++ 风格、**函数必须用尾置返回类型**、零内存泄漏、格式不合规判 0 分。
> `make check-lint` 抓的是格式，`check-clang-tidy` 抓的是代码质量，两个都过一遍再提交。

### 第 6 步：一个好习惯

每完成一个小功能就提交一次，别攒到最后：

```bash
git add -A && git commit -m "P1: 实现 LRU-K 的 Evict 与 SetEvictable"
```

理由很实际：ASan 报错时，`git diff` 能让你看清"这次改了什么"，比翻记忆可靠得多；
真要改崩了，`git checkout .` 一键回到能编译的状态。

---

## 十一、常见疑问

**Q：`make check-tests` 一跑就是几十个失败，正常吗？**
正常。这份代码是干净骨架，P0~P4 全都没实现，`check-tests` 跑的是全仓库测试。
日常开发用单个测试目标（`make xxx_test`），只在最后整体自检时跑 `check-tests`。

**Q：能同时在 `/mnt/d/` 下写代码吗？**
不建议。跨文件系统 I/O 会让编译慢几倍，而且权限行为不一致。代码放 `/root/bustub`，
需要从 Windows 访问就用 `\\wsl$\Ubuntu-22.04\root\bustub`。

**Q：想重来一遍怎么办？**
```bash
cd /root/bustub && git checkout . && git clean -fd src test
```
只回滚代码，不删 `build/`，能省一次全量编译。

**Q：这套环境占多大？**
WSL 发行版 3.6 GB，`/root/bustub` 里 `build/` 占 899 MB。都放在 `D:\WSL\` 下。


