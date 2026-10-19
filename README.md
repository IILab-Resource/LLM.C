# 从零造一个大模型 · 14 天 C 语言实战营

> **14 天，从"没写过代码"到"用 1281 行纯 C 跑通一个大模型"。**
> 不需要 PyTorch，不需要显卡，不需要任何第三方库——只需要一个 gcc。

---

## 先读这个

📖 **[项目总览.md](项目总览.md)** —— 开课前必读。它回答：
- 这个项目到底在做什么
- 最终交付物长什么样（8 个部分、42 个函数、实测速度）
- 涉及哪些技术与知识点（C 语言 / 系统 / 数学 / 神经网络，200+ 项清单）
- 59MB 的模型文件里到底装了什么（可手算核对）
- 一次生成的完整数据流图

📖 **[docs/大模型推理知识手册.md](docs/大模型推理知识手册.md)** —— 数学参考手册。
按**概念**组织（不按天），17 个主题，每个都是「是什么 → 为什么需要 → 公式 → 代码在哪一行」。
想查"为什么除以 √d"、"残差连接到底解决什么"、"43 次矩阵乘怎么算出来的"，翻这里。

📖 **[docs/多线程与OpenMP完全指南.md](docs/多线程与OpenMP完全指南.md)** —— 多线程专题。
14 个主题，讲清"为什么 4 个线程只能快 3 倍"、"线程数开多了为什么反而更慢"。
附本机实测的线程数-加速比曲线，`make threads` 可复现。

📖 **[docs/Windows环境配置完全指南.md](docs/Windows环境配置完全指南.md)** —— ★ 用 Windows 的学员必读。
四条路可选（WSL2 / MSYS2 / Visual Studio / 云主机），含 VS Code 和 CLion 配置、
逐条真实报错速查、以及"哪些天在 Windows 上需要改什么"的精确核查结果。

## 这是什么课

这是一门**面向编程零基础**的 14 天集训课程。课程的目标很明确：

> 从最基础的 C 语言语法出发，逐日递进，到第 14 天你手上有一个**完整的大模型推理程序**，
> 它能读懂一句英文，并一个字一个字续写出通顺的英文小故事，
> 而你能用自己的话解释整条流水线的每一个环节。

课程按**"从现象出发推导"**的方式组织：从"一个神经元吃什么吐什么"出发，
一路推到矩阵、注意力、采样，最后组装成一个完整程序。

## 课程特色

| | |
|---|---|
| **零门槛** | 只需 `gcc` 和 `make`，连 PyTorch 都不需要装 |
| **真项目** | 跑的是真实训练好的模型权重，不是玩具代码 |
| **逐日递进** | 14 天，每天一个能独立编译运行的完整程序 |
| **离线可用** | 模型权重 `stories15M.bin`（59MB）已随课程附带，无需联网 |
| **可观测** | 每一步都能打印：概率分布、注意力热力图、权重统计、算力账本 |
| **可改造** | 6 个教学开关（温度/top-p/top-k/残差/GQA/调试深度），第一天就能改出不同行为 |
| **性能意识** | Day 7 接触 cache 局部性，Day 12 起 OpenMP 并行化（实测 72 → 235 tok/s） |

## 快速开始（3 步）

```bash
# 1. 环境自检（检查编译器、CPU、数据文件，并冒烟测试 Day 1）
make check

# 2. 跑通最终成果：让大模型写故事
make story

# 3. 或者单独跑某一天的代码
make day01        # 从 Day 1 开始
make day08        # Day 8 开始需要用到 data/ 里的模型文件
```

预期输出（`make story` 会打印两段不同的续写）：

```
========================================================
 最终成果：用 900 行纯 C 代码跑通一个 15M 参数大模型
========================================================
Once upon a time, there was a little girl named Lily who loved
to play with her toys. Her favorite toy was a big teddy bear and
she would take it everywhere she went...
```

## 环境要求

| 项目 | 要求 | 验证 |
|---|---|---|
| 编译器 | GCC 8+（推荐 13/14） | `gcc --version` |
| 构建工具 | GNU Make | `make --version` |
| 内存 | 建议 ≥ 2GB 可用 | `free -h` |
| 磁盘 | 约 70MB（模型权重占大头） | `du -sh .` |
| 编辑器 | VS Code + C/C++ 插件 | — |

Valgrind（Day 4 用来抓内存泄漏）可选安装：
```bash
sudo apt install valgrind      # Ubuntu/Debian
sudo brew install valgrind     # macOS
```

## 目录结构

```
LLM.C/
├── README.md                       # 你正在看的这个文件
├── 课程计划.md                      # ★ 14 天详细教学计划（先看这个）
├── Makefile                        # 统一构建入口
│
├── days/                           # ★ 逐日递进代码（核心）
│   ├── day01_hello.c               #   Day 1  编译入门、分支
│   ├── day02_control.c             #   Day 2  循环、数组、矩阵
│   ├── day03_function.c            #   Day 3  函数、值传递、递归
│   ├── day04_pointer.c             #   Day 4  指针（最关键的一天）
│   ├── day05_string_file.c         #   Day 5  字符串、struct、文件 I/O
│   ├── day06_vector.c              #   Day 6  浮点数、向量、softmax
│   ├── day07_matmul.c              #   Day 7  矩阵布局、性能计时
│   ├── day08_load_model.c          #   Day 8  mmap 加载 60MB 权重
│   ├── day09_tokenizer.c           #   Day 9  BPE 分词器
│   ├── day10_blocks.c              #   Day 10 rmsnorm / SwiGLU / RoPE
│   ├── day11_attention.c           #   Day 11 注意力、GQA、KV Cache
│   ├── day12_forward.c             #   Day 12 完整 forward + OpenMP
│   ├── day13_sampler.c             #   Day 13 采样策略、RNG
│   └── day14_inference.c           #   Day 14 ★ 完整整合版
│
├── exercises/                      # 每日上机练习题
├── solutions/                      # 练习参考答案
├── tools/                          # 辅助工具
├── docs/                           # 每日讲义、术语表、常见错误
├── data/                           # 模型数据（已附带，离线可用）
│   ├── stories15M.bin              #   15M 参数模型，59MB
│   ├── tokenizer.bin               #   BPE 分词器，32000 词表
│   └── tokenizer.model             #   分词器原始模型（备份）
│
└── llama2.c-master/                # 别人的实现（教学参考资料，非本课叙事对象）
```

## 常用命令

```bash
make help                    # 列出所有目标
make check                   # 环境 + 数据自检
make day01                   # 编译并运行 Day 1
make all                     # 一次性编译全部 14 天代码到 bin/
make run                     # 跑完整版推理程序
make runomp                  # 对比单线程 vs OpenMP 多线程速度
make story                   # ★ 最终成果：生成小故事
make clean                   # 清理 bin/

# 直接用 gcc 编译（课程全程只用这一条命令）
gcc -O2 -std=c11 -Wall -o dayXX days/dayXX.c -lm
```

> `-lm` 必须放在**最后**：数学库 `libm`（`sqrtf/expf/powf/...`）在链接阶段才被找到。

## 最终版的使用方法

```bash
./bin/day14_llama2 data/stories15M.bin -z data/tokenizer.bin \
    -i "Once upon a time" -n 100
```

### 基础参数

| 参数 | 含义 | 默认值 |
|---|---|---|
| `<checkpoint>` | 模型文件路径（必需，第一个位置参数） | — |
| `-i <string>` | 输入提示词 | 空 |
| `-n <int>` | 生成步数（token 数），`0` = 用满 `seq_len` | 256 |
| `-t <float>` | temperature，越大越发散；`0` = 贪心（会复读） | 1.0 |
| `-p <float>` | top-p 核采样阈值 | 0.9 |
| `-s <int>` | 随机种子（固定它就能复现同一次输出） | 时间戳 |
| `-z <string>` | 自定义分词器路径 | `tokenizer.bin` |
| `-m <string>` | 模式：`generate` 或 `chat` | `generate` |
| `-y <string>` | chat 模式下的 system prompt | 无 |

### Day 14 额外新增的教学开关

| 参数 | 作用 | 课堂演示效果 |
|---|---|---|
| `-T` | 分词器自检 | 跑 5 组有已知答案的用例，应 5/5 全 ✓ |
| `-w` | 权重统计 | 打印 12 个张量的 shape / 元素数 / 字节数 / mean / std / min / max |
| `-d <0-3>` | 调试详细度 | 1=关键节点 2=每层 3=每层每头注意力热力图 |
| `-r <0\|1>` | 残差连接开关 | 关掉后输出变成复读机（6 层信息全被丢弃），证明残差不可或缺 |
| `-u <int>` | GQA 实验 | 覆盖 `n_kv_heads`，触发 `kv_mul > 1` 代码路径（输出乱码但不崩） |
| `-l <int>` | top-k 采样 | 与 top-p 对比，配合 `-t` 观察采样空间变化 |

**推荐参数**：`-t 1.0 -p 0.9`（默认值就是最优推荐）

**实验建议**（Day 13 会正式做）：
```bash
# 贪心解码：必然复读
./bin/day14_llama2 data/stories15M.bin -z data/tokenizer.bin -i "Lily is" -t 0.0

# 高温乱写
./bin/day14_llama2 data/stories15M.bin -z data/tokenizer.bin -i "Lily is" -t 1.5

# 复现：两次结果完全一致
./bin/day14_llama2 data/stories15M.bin -z data/tokenizer.bin -i "Lily is" -s 1337
./bin/day14_llama2 data/stories15M.bin -z data/tokenizer.bin -i "Lily is" -s 1337

# 看模型在想什么：每个候选词的概率分布
./bin/day14_llama2 data/stories15M.bin -z data/tokenizer.bin -i "Once upon a time" -n 5 -d 3

# 证明残差连接不可或缺
./bin/day14_llama2 data/stories15M.bin -z data/tokenizer.bin -i "Lily is" -n 30 -r 0
```

### 可复现性验证

同一颗随机种子跑两次，输出必须**逐字节相同**——这是采样器可复现性的验收标准：

```bash
$ gcc -O3 -fopenmp -o orig llama2.c-master/run.c -lm
$ gcc -O3 -fopenmp -o new  days/day14_inference.c   -lm

$ ./orig data/stories15M.bin -z data/tokenizer.bin -i "Once upon a time" -n 100 -t 1.0 -p 0.9 -s 42
$ ./new  data/stories15M.bin -z data/tokenizer.bin -i "Once upon a time" -n 100 -t 1.0 -p 0.9 -s 42
# 输出一致，md5 均为 351b8cb0f35f38552d030614c06cc02d
```

## 14 天路线图速览

```
Day  1  编译入门：gcc 四步流水线、数据类型、分支
Day  2  循环 + 数组：素数筛选、二维数组、手写矩阵乘法
Day  3  函数：分层、值传递 vs 指针传递、递归、栈
Day  4 ★ 指针：内存本质、动态数组、内存泄漏与野指针
Day  5  字符串 + struct + 文件 I/O：读取二进制模型头
Day  6  浮点数与向量：手写 softmax
Day  7  矩阵布局：手写 matmul + 性能实测
Day  8  mmap：用零拷贝打开 60MB 权重文件
Day  9  Tokenizer：BPE 分词，文本 ⇄ token
Day 10  Transformer 积木：rmsnorm / SwiGLU / RoPE
Day 11  注意力：单头 → 多头 → GQA → KV Cache
Day 12 ★ forward：组装完整前向传播 + OpenMP
Day 13  采样：temperature / top-p / xorshift 随机数
Day 14 ★ 组装：把前面所有零件串起来、性能优化、结业验收
```

详细到每个时段的安排见 **[课程计划.md](课程计划.md)**。
项目在做什么、涉及哪些知识点、模型文件里装了什么，见 **[项目总览.md](项目总览.md)**。

## 结业标准

- [ ] 能不看资料写出 `matmul` 与 `softmax`（含减最大值）
- [ ] 能**从零推导**出"为什么一层神经元必须是矩阵、为什么权重是 `out × in`"
- [ ] 能解释 59MB 的 `stories15M.bin` 里存了什么、每个张量的形状，并手算核对文件大小
- [ ] 能把任意文本编码成 token 序列并解码还原
- [ ] 能逐段讲完 `forward()`，并画出数据流图
- [ ] 能解释 temperature 与 top-p 的作用，并现场调参解释输出差异
- [ ] 能给这个程序加一个新功能且不崩溃

---

**许可**：课程代码基于 [llama2.c](https://github.com/karpathy/llama2.c) 重构，原工程 MIT License，见 `llama2.c-master/LICENSE`。
