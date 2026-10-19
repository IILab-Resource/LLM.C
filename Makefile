# ============================================================================
#  从零造一个大模型 · 14 天 C 语言实战营
#  ============================================================================
#  这是课程的统一构建入口。
#
#  【Day 1 会讲这个文件】
#    编译器（gcc）负责把 .c 变成能跑的机器码，
#    Make 负责"替你反复去请编译器"，并且只在需要时才请。
#    这两个是不同层面的东西，Day 1 下午会花一小时讲清楚。
#
#  【常用法】
#    make                 列出所有可用目标（= make help）
#    make day01_compile   编译并运行 Day 1
#    make all             一次性编译全部 14 天（只编译，不运行）
#    make run             跑完整版推理程序 (Day 14)
#    make story           ★ 最终成果：生成一个英文小故事
#    make perf            ★ 编译优化等级性能对比矩阵 (Day 14)
#    make threads         ★ OpenMP 线程数加速比实测 (Day 14)
#    make check           环境与数据自检
#    make clean           清理所有可执行文件
#
#  【Make 的三个核心概念】
#    1. 目标(target)：想得到的东西，这里都是"编译出某个可执行文件"
#    2. 依赖(prerequisite)：做这个目标需要先有什么，这里都是 .c 源文件
#    3. 规则(recipe)：怎么从依赖做出目标，这里都是一行 gcc 命令
#
#       规则的三行结构，缩进必须是【一个 Tab】，不是空格：
#           目标: 依赖
#           	命令
#           ^^^^^ 这一行开头必须是 Tab
#
#    ★ Make 最像人的地方：它比较文件的修改时间。
#      如果 days/day06_neuron.c 比 bin/day06_neuron 新 → 重新编译
#      如果 .c 没变过 → 什么都不做，直接跳过
#      所以 `make all` 跑第二次时是瞬间完成的。
# ============================================================================

# ------------------------------------------------------------
#  一、变量：把"经常重复的东西"抽出来，改一处就全生效
# ------------------------------------------------------------
#  用法：$(变量名) 引用，赋值时不要加 $
CC      = gcc
CFLAGS  = -O2 -std=c11 -Wall -Wextra -Wno-unused-parameter
LDFLAGS = -lm
BIN     = bin

# OpenMP 多线程版用的编译选项（Day 12/14 讲）
OMPFLAGS = -O3 -std=c11 -fopenmp -march=native

# 课程自带的模型与分词器（Day 14 讲 mmap 和 BPE 时要用）
MODEL = data/stories15M.bin
TOK   = data/tokenizer.bin

# 14 天的目标名清单。注意顺序 = 学习顺序
DAYS = day01_compile day02_batch day03_function day04_pointer \
       day05_load_file day06_neuron day07_layer_matrix day08_load_weights \
       day09_tokenizer day10_layer_parts day11_attention day12_forward \
       day13_sampler day14_inference

# 14 个 stamp 目标（"只编译"的标记文件）。定义必须放在 build 之前 ——
# Make 在**解析阶段**就展开依赖列表，变量在引用之后才赋值就来不及了。
STAMPS = $(addprefix $(BIN)/.build_,$(DAYS))

# ★ 一个容易踩的坑：DAYS 里的目标不只是"编译"，它们还会**运行程序**
#   （见第四节 $(BIN)/% 那条规则的最后一行 @./$@）
#   所以"只编译不运行"的批量目标必须依赖 $(BIN)/ 下的可执行文件，
#   而不是依赖 $(DAYS)。这个区别在第七节的 build / runday 里有对照演示。
DAYS_BIN = $(addprefix $(BIN)/,$(DAYS))

# ------------------------------------------------------------
#  二、帮助：任何项目都应该有的第一个目标
# ------------------------------------------------------------
.PHONY: help
help:
	@echo ""
	@echo "  从零造一个大模型 · 14 天 C 语言实战营"
	@echo "  ========================================================"
	@echo ""
	@echo "  【学习入口】"
	@echo "    make dayNN_xxx        编译并运行某一天的代码"
	@echo "    make all              编译全部 14 天（不运行，已编译的会跳过）"
	@echo "    make build            同上（all 的别名）"
	@echo "    make runday           编译全部并逐个运行"
	@echo "    make all2             教学对照：一条 recipe 的错误写法"
	@echo "    make clean            清理 bin/"
	@echo ""
	@echo "  【Day 1 · 编译器与构建】"
	@echo "    make demo_preprocess  演示 gcc 四步流水线的第 1 步（预处理）"
	@echo "    make demo_assemble    演示第 3 步（汇编，看 .o 文件）"
	@echo "    make demo_touch       演示 Make 的时间戳判断（改了就重编，没改就跳过）"
	@echo "    make why              演示 Make 的依赖关系（为什么不会重复编译）"
	@echo ""
	@echo "  【Day 14 · 完整程序】"
	@echo "    make run              跑完整版推理程序"
	@echo "    make story            ★ 生成一个英文小故事（最终成果）"
	@echo "    make chat             进入多轮对话模式"
	@echo ""
	@echo "  【Day 14 · 性能优化】"
	@echo "    make perf             编译优化等级性能矩阵 (-O0/-O1/-O2/-O3/-Ofast)"
	@echo "    make omp              只编译 OpenMP 版（不自动运行）"
	@echo "    make threads          ★ 线程数加速比实测（先检查是否真启用了 OpenMP）"
	@echo "    make runomp           单线程 vs 4 线程对比"
	@echo ""
	@echo "  【自检】"
	@echo "    make check            编译器 / CPU / 内存 / 数据文件 / 冒烟测试"
	@echo ""
	@echo "  数据文件："
	@echo "    $(MODEL)    神经网络权重"
	@echo "    $(TOK)      BPE 分词器（32000 词表）"
	@echo ""

# ------------------------------------------------------------
#  三、逐日代码：make dayNN_xxx
# ------------------------------------------------------------
#  下面两行是本文件最值得学的写法：
#
#      .PHONY: $(DAYS)
#      $(DAYS): %: $(BIN)/%
#
#  第 1 行：告诉 make 这些目标是"假目标"。因为 bin/ 里真的有个叫
#          day01_compile 的文件，make 会以为目标已经存在、什么都不用做。
#          .PHONY 强制它每次都重新执行规则。
#  第 2 行：静态模式规则。把 day01_compile 这个名字里的"day01_compile"
#          套进 $(BIN)/%，得到 bin/day01_compile。
#
#  为什么绕这一圈？因为 Make 的规则是"一个模式"配"一堆文件名"，
#  这是 GNU Make 特有的写法。理解它需要先看懂下面那行 $(BIN)/%: days/%.c。
# ------------------------------------------------------------
.PHONY: $(DAYS)
$(DAYS): %: $(BIN)/%

# 模式规则（pattern rule）：把 days/ 下的任意 .c 编成 bin/ 下同名可执行文件
#   $<  = 第一个依赖（这里就是 days/xxx.c）
#   $@  = 目标名（这里就是 bin/xxx）
$(BIN)/%: days/%.c | $(BIN)
	$(CC) $(CFLAGS) -o $@ $< $(LDFLAGS)
	@echo ""
	@echo ">>> 已编译 $@ ，开始运行 <<<"
	@./$@

# 顺序依赖：先确保 bin/ 目录存在，再谈编译
$(BIN):
	@mkdir -p $(BIN)

# ------------------------------------------------------------
#  四、Day 1 专用：把编译器流水线做成可观察的目标
# ------------------------------------------------------------
#  Day 1 上午在黑板上推演这四步，现在让 make 一步步带你走一遍：
#
#      make demo_pipeline   完整跑一遍四步，每步都看产物
#
.PHONY: demo_pipeline
demo_pipeline:
	@echo ""
	@echo "============================================================"
	@echo " gcc 四步流水线 —— 每一步都留下一个文件"
	@echo "============================================================"
	@mkdir -p $(BIN)
	@echo ""
	@echo "【第 1 步 · 预处理】.c + 头文件  ->  .i   （gcc -E）"
	@$(CC) -E days/day01_compile.c -o $(BIN)/demo.i
	@wc -l days/day01_compile.c | awk '{print "    源文件   " $$1 " 行"}'
	@wc -l $(BIN)/demo.i          | awk '{print "    预处理后 " $$1 " 行  <- stdio.h 全被文本粘贴进来了"}'
	@echo ""
	@echo "【第 2 步 · 编译】.i  ->  .s   （gcc -S）C 代码翻译成汇编"
	@$(CC) -S days/day01_compile.c -o $(BIN)/demo.s
	@head -12 $(BIN)/demo.s | sed 's/^/    /'
	@echo ""
	@echo "【第 3 步 · 汇编】.s  ->  .o   （gcc -c）汇编翻译成机器码"
	@$(CC) -c days/day01_compile.c -o $(BIN)/demo.o
	@file $(BIN)/demo.o | sed 's/^/    /'
	@ls -l $(BIN)/demo.o | awk '{print "    大小 " $$5 " 字节"}'
	@echo ""
	@echo "【第 4 步 · 链接】.o + libc + libm  ->  可执行文件（gcc 不带 -c）"
	@$(CC) $(CFLAGS) -o $(BIN)/demo days/day01_compile.c $(LDFLAGS)
	@file $(BIN)/demo | sed 's/^/    /'
	@echo ""
	@echo "★ 观察 .o 和可执行文件的大小差：那部分就是链接进来的标准库。"

.PHONY: demo_preprocess
demo_preprocess:
	@mkdir -p $(BIN)
	@echo "=== 预处理：把 stdio.h 文本粘贴到你的代码里 ==="
	@$(CC) -E days/day01_compile.c -o $(BIN)/demo.i
	@echo "  源文件   $(shell wc -l < days/day01_compile.c) 行"
	@echo "  预处理后 $(shell wc -l < $(BIN)/demo.i) 行"
	@echo ""
	@echo "--- 看看开头 30 行（全是 stdio.h 的内容）---"
	@head -30 $(BIN)/demo.i | sed 's/^/  /'

.PHONY: demo_assemble
demo_assemble:
	@mkdir -p $(BIN)
	@echo "=== 汇编：C 代码变成 x86 汇编 ==="
	@$(CC) -S days/day01_compile.c -o $(BIN)/demo.s
	@file $(BIN)/demo.s | sed 's/^/  /'
	@echo ""
	@echo "--- 找 main 函数对应的汇编 ---"
	@grep -n -A18 "^main:" $(BIN)/demo.s | head -20 | sed 's/^/  /'

# 演示 Make 的时间戳判断：这是 Make 最像人的地方
.PHONY: demo_touch
demo_touch:
	@mkdir -p $(BIN)
	@echo "============================================================"
	@echo " Make 的时间戳判断：改了才重编，没改就跳过"
	@echo "============================================================"
	@echo ""
	@echo "--- 第 1 次 make（首次编译，一定会执行）---"
	@$(MAKE) --no-print-directory $(BIN)/day06_neuron
	@echo ""
	@echo "--- 第 2 次 make（源文件没变，make 直接跳过）---"
	@$(MAKE) --no-print-directory $(BIN)/day06_neuron
	@echo ""
	@echo "--- 现在把 .c 的修改时间推到最新，再 make ---"
	@touch days/day06_neuron.c
	@$(MAKE) --no-print-directory $(BIN)/day06_neuron
	@echo ""
	@echo "★ 看清楚：只有第 1 次和第 3 次真的编译了。"
	@echo "  这就是为什么 'make all' 第二次跑是瞬间完成的。"

# 演示依赖关系：为什么不会重复编译
# 注意下面用了 printf '%s\n' 而不是 echo "..."：
#     echo "$@" 里的 $@ 会被 shell 当成"位置参数"而展开成空，
#     再加上双引号被吃掉就变成了语法错误。
#     printf 的格式串用单引号，$ 和 @ 都原样保留。
.PHONY: why
why:
	@printf '%s\n' '============================================================'
	@printf '%s\n' ' Make 依赖关系：它是怎么知道谁该重编的？'
	@printf '%s\n' '============================================================'
	@printf '%s\n' ''
	@printf '%s\n' '看这条规则：'
	@printf '%s\n' ''
	@printf '%s\n' '    bin/%: days/%.c | bin'
	@printf '%s\n' '     $$@        $$<          $$|'
	@printf '%s\n' '      |          |            |'
	@printf '%s\n' '      |          |            +-- 顺序依赖：先 mkdir -p bin'
	@printf '%s\n' '      |          +--------------- 依赖：先有 days/xxx.c'
	@printf '%s\n' '      +-------------------------- 目标：要生成 bin/xxx'
	@printf '%s\n' ''
	@printf '%s\n' '三个自动变量（在规则里才展开）：'
	@printf '%s\n' '    $$@  = 目标名    $$<  = 第一个依赖    $$^  = 所有依赖'
	@printf '%s\n' '  ↑ 上面的 $$@ 是想让你看的字面量；'
	@printf '%s\n' '    真正执行规则时，make 会把它换成 bin/day06_neuron。'
	@printf '%s\n' '    这就是转义：想让 make 不展开某个美元符号，就把它写两遍。'
	@printf '%s\n' ''
	@printf '%s\n' '--- make 实际会执行的命令（--dry-run 只打印不执行）---'
	@$(MAKE) --no-print-directory --dry-run --always-make $(BIN)/day06_neuron 2>&1 | grep -E 'gcc|mkdir' | sed 's/^/  /'
	@printf '%s\n' ''
	@printf '%s\n' '--- 文件时间戳（make 就是比这两个）---'
	@stat -c '  源文件   %y' days/day06_neuron.c 2>/dev/null || echo "  源文件   （读取失败）"
	@stat -c '  可执行   %y' $(BIN)/day06_neuron 2>/dev/null || echo "  可执行   （还没编译过，make 会执行规则）"

# ------------------------------------------------------------
#  五、Day 14：完整推理程序
# ------------------------------------------------------------
.PHONY: run
run: $(BIN)/day14_inference_build
	@./$(BIN)/day14_inference $(MODEL) -z $(TOK) -i "Once upon a time" -n 120

$(BIN)/day14_inference_build: days/day14_inference.c | $(BIN)
	$(CC) $(CFLAGS) -o $(BIN)/day14_inference days/day14_inference.c $(LDFLAGS)
	@echo ""

.PHONY: story
story: | $(BIN)
	@$(MAKE) --no-print-directory $(BIN)/day14_inference_build
	@echo "============================================================"
	@echo " 最终成果：用纯 C 代码跑通一个 15M 参数大模型"
	@echo "============================================================"
	@./$(BIN)/day14_inference $(MODEL) -z $(TOK) \
		-i "Once upon a time, there was a little girl named Lily who" -n 150
	@echo ""
	@echo "============================================================"
	@echo " 换个开头，看模型如何续写另一个故事"
	@echo "============================================================"
	@./$(BIN)/day14_inference $(MODEL) -z $(TOK) \
		-i "The little dog ran into the forest and" -n 150

.PHONY: chat
chat: $(BIN)/day14_inference_build
	@./$(BIN)/day14_inference $(MODEL) -z $(TOK) -m chat -n 60

.PHONY: selftest
selftest: $(BIN)/day14_inference_build
	@./$(BIN)/day14_inference $(MODEL) -z $(TOK) -T
	@./$(BIN)/day14_inference $(MODEL) -z $(TOK) -w

# ------------------------------------------------------------
#  六、Day 14：性能优化（这里 make 的价值最大）
# ------------------------------------------------------------
#  Day 7 我们手敲命令编了 4 个变体做性能对比，手敲一次就错一次。
#  现在把它交给 make：
#
#    make perf     →  自动编出 5 个优化等级，依次跑一遍，打印速度表
#
#  写法讲解（这就是 make 的"循环"）：
#      for lv in O0 O1 O2 O3 Ofast; do ... done
#      $$(lv)     →  转义后的 $(lv)，在 shell 里就是变量 lv
#      $$^        →  在 make 里等于 $(^)，但这里在 for 循环里要转义成 $$ 给 shell
#
.PHONY: perf
perf: | $(BIN)
	@echo "============================================================"
	@echo " 编译优化等级性能矩阵（同一份源码，5 种编译选项）"
	@echo "============================================================"
	@echo " CPU 核心数：$$(nproc)"
	@echo ""
	@printf "  %-10s %-12s %-14s %s\n" "等级" "编译耗时" "生成速度(tok/s)" "说明"
	@printf "  %-10s %-12s %-14s %s\n" "----------" "------------" "--------------" "----------"
	@for lv in O0 O1 O2 O3 Ofast; do \
		case $$lv in \
			Ofast) note="-Ofast：放开所有保守假设，最快" ;; \
			O0)    note="-O0：不优化，看编译器什么都不干" ;; \
			*)     note="-$$lv：标准优化等级" ;; \
		esac; \
		printf "  %-10s " "$$lv"; \
		t0=$$(date +%s%N); \
		$(CC) -$$lv -std=c11 -o $(BIN)/perf_$$lv days/day14_inference.c $(LDFLAGS) 2>/dev/null; \
		t1=$$(date +%s%N); \
		cms=$$(( (t1 - t0) / 1000000 )); \
		tps=$$(./$(BIN)/perf_$$lv $(MODEL) -z $(TOK) -i "Once upon a time" -n 60 2>&1 >/dev/null | grep -oE "[0-9]+\.[0-9]+" | tail -1); \
		printf "%-12s %-14s %s\n" "$${cms}ms" "$$tps" "$$note"; \
	done
	@echo ""
	@echo "★ 看两列的关系：优化等级越高，编译越慢，生成越快。"
	@echo "  这是典型的'用编译时间换运行时间'的权衡。"
	@rm -f $(BIN)/perf_*

.PHONY: threads
threads: bench_threads
	@echo ""
	@echo "  上面那张表就是本机实测结果。★ 峰值位置会随系统负载浮动，"
	@echo "  绝对值也会变 —— 所以每次都要重新跑，别用别人的结论。"

# 用 tools/bench_threads.sh 跑（它会先检查二进制是否真的启用了 OpenMP）
.PHONY: bench_threads
bench_threads: $(BIN)/day14_inference_omp_build
	@bash tools/bench_threads.sh $(BIN)/day14_inference_omp

# 只编译 OpenMP 版不跑（想自己控制线程数时用）
.PHONY: omp
omp: $(BIN)/day14_inference_omp_build
	@echo ""
	@echo "已编译 OpenMP 版：$(BIN)/day14_inference_omp"
	@echo ""
	@echo "用它跑（注意必须显式给线程数，OMP_NUM_THREADS 默认是 1）："
	@echo "    OMP_NUM_THREADS=4 ./$(BIN)/day14_inference_omp $(MODEL) -z $(TOK) -i \"Once upon a time\" -n 100"
	@echo ""
	@echo "或者用这两个现成目标："
	@echo "    make bench_threads    扫描 1~nproc 找甜点线程数"
	@echo "    make threads          同上（bench_threads 的别名）"
	@echo ""
	@echo "★ 注意：make build 编出来的是**串行版**（CFLAGS 里没有 -fopenmp），"
	@echo "  对它设 OMP_NUM_THREADS 完全没用。测加速比必须用 omp 版。"

# 旧的固定表格版（保留：没有 libgomp 检查，但输出稳定可比）
.PHONY: threads_fixed
threads_fixed: | $(BIN)
	@echo "============================================================"
	@echo " OpenMP 线程数加速比实测"
	@echo "============================================================"
	@echo " CPU 核心数：$$(nproc)   物理/逻辑核心差异会导致加速比不满"
	@echo ""
	@printf "  %-10s %-14s %s\n" "线程数" "速度(tok/s)" "相对单线程"
	@printf "  %-10s %-14s %s\n" "----------" "--------------" "------------"
	@base=""; \
	for t in 1 2 4 8; do \
		tps=$$(OMP_NUM_THREADS=$$t ./$(BIN)/day14_inference_omp $(MODEL) -z $(TOK) -i "Once upon a time" -n 60 2>&1 >/dev/null | grep -oE "[0-9]+\.[0-9]+" | tail -1); \
		if [ -z "$$base" ]; then base=$$tps; fi; \
		spd=$$(awk -v a="$$tps" -v b="$$base" 'BEGIN{printf "%.2fx", a/b}'); \
		printf "  %-10s %-14s %s\n" "$$t" "$$tps" "$$spd"; \
	done
	@echo ""
	@echo "★ 加速比为什么小于线程数？三个原因："
	@echo "    1. 内存带宽共享 —— 4 个核抢同一条总线"
	@echo "    2. 线程创建与同步开销 —— 每次 parallel for 都要 fork/join"
	@echo "    3. 工作量太小 —— 本模型只有 43 次 matmul，拆分的粒度有限"

$(BIN)/day14_inference_omp_build: days/day14_inference.c | $(BIN)
	$(CC) $(OMPFLAGS) -o $(BIN)/day14_inference_omp days/day14_inference.c $(LDFLAGS)

.PHONY: runomp
runomp: $(BIN)/day14_inference_omp_build
	@echo ">>> 单线程基准 <<<"
	@./$(BIN)/day14_inference $(MODEL) -z $(TOK) -i "Once upon a time" -n 120
	@echo ""
	@echo ">>> OpenMP 4 线程 <<<"
	@OMP_NUM_THREADS=4 ./$(BIN)/day14_inference_omp $(MODEL) -z $(TOK) -i "Once upon a time" -n 120

# ------------------------------------------------------------
#  七、一次性编译全部
# ------------------------------------------------------------
#  这里用的是 shell 的 for 循环，不是 make 的循环。
#  区别很重要：
#      make 的依赖解析在**执行任何命令之前**就完成了（解析阶段）
#      真正的命令是一条条**按顺序执行**的（执行阶段）
#  这个两阶段模型是 make 最重要也最容易被误解的设计。
#
#  ★ 顺带一个重要的推论（实测：本机 20 核）
#      顺带说明为什么 all2（一条 recipe 里写 for 循环）每次都要 3.5 秒：
#      make 只看到 all2 一个目标，它不知道 bin/ 里的文件已经是最新的
#      （因为 .c 没有作为依赖写进规则），所以每次都重跑整条循环。
#      同理 `make -j8 all2` 也不会加速：-j 只对**不同目标**有效。
#
#  正确写法是 `all: $(DAYS)` —— 那时 make 看到的是 14 个独立目标，
#  才会做时间戳判断、才吃 -j。并行加速的实测见下面 build 目标。
#  本课程刻意保留 for 循环版本，就是为了现场演示这个区别。
#
#  ★ 学员日常不需要敲 14 次 make。用 build 一次编完，
#    它把每个 day 声明成独立目标，所以 -j 能真正并行。
# ------------------------------------------------------------
#  （真正的 all: build 定义在下面第七节，避免同一目标写两遍 —— 
#    make 会警告"覆盖关于目标 all 的配方"）
# ------------------------------------------------------------
#  ------------------------------------------------------------
#  七、批量编译
#  ------------------------------------------------------------
#  这里有一个很容易踩的坑，本节就是用来看清它的。
#
#  ★ 坑：$(DAYS) 里的目标不只是"编译"，它们还会**运行程序**
#        （见第四节 $(BIN)/% 那条规则的最后一行 @./$@）
#        所以 `build: $(DAYS)` 会去运行全部 14 个程序 —— 这是错的。
#        编译和运行必须是两个目标。
#
#  下面是三种写法的对比，都保留下来做教学对照：
#      build  正确：14 个独立目标，时间戳生效，-j 能并行，**不运行**
#      all2   错误：一条 recipe 包 for 循环，没有时间戳，-j 无效，不运行
#      runday 正确：14 个独立目标，时间戳生效，**并逐个运行**
#
#  实测（本机 20 核）：
#      make all     第一次 4.7s，第二次 0.00s   ← 时间戳生效
#      make -j8 all                        → 真正并行
#      make all2    每次都 3.5s             ← 无时间戳，每次全编
#      make -j8 all2                       → 无加速（实测 3.45 vs 3.49）
#  ------------------------------------------------------------
.PHONY: all
all: build
	@echo "（all 是 build 的别名。想看差别，对比下面的 all2）"

# 学员日常用的批量编译：14 个独立目标，只编译不运行
# 依赖的是 stamp 清单（STAMPS），不是可执行文件清单 —— 理由见下面的注释
# ------------------------------------------------------------
.PHONY: build
build: $(STAMPS)
	@echo ""
	@echo "全部 14 天代码编译完成，位于 $(BIN)/"
	@echo ""
	@echo "★ build 里有 14 个独立目标，所以："
	@echo "  · 再跑一次 make build 会跳过没变的文件（实测 3.4s → 0.00s）"
	@echo "  · make -j8 build 能真正并行加速"
	@echo "  · ★ 它不会运行任何程序 —— 编译和运行是两个不同的事"
	@echo ""
	@echo "★ 对比下面的 all2：它只有一条 recipe，所以前两个能力都没有。"

# ★ 编译与运行必须是两个不同的名字（这是本节最关键的设计）
#
#   坑的根源：模式规则 $(BIN)/%: days/%.c 的最后一行是 @./$@，
#   也就是 `make dayNN` 会**编译并运行**。这是课程主流程，想要它保留。
#
#   但 `build` 只想编译、绝不运行。如果 build 依赖 $(DAYS_BIN)，
#   make 会匹配到 bin/dayNN，再回退到上面那条模式规则 → 把程序也跑了。
#
#   ✗ 错误解法一：给 14 个文件各写一条显式的"只编译"规则。
#     显式规则优先级高于模式规则，看起来能覆盖，但**它把 @./$@ 一起覆盖了**，
#     于是 `make day01_compile` 静默变成"只编译不运行" —— 课程主流程被破坏。
#     （这是本课程实际踩过的坑，详见 docs/Makefile完全指南.md §8.1.1）
#
#   ✓ 正确解法：**换一个名字**。让 stamp 目标负责"只编译"，
#     让 dayNN 目标负责"编译并运行"，两者互不覆盖。
#
#        bin/dayNN          真正的可执行文件，由模式规则生成（编译 + 运行）
#        bin/.build_dayNN   stamp 标记文件，touch 出来就代表"已编译"
#
#     build 依赖 stamp（14 个独立目标 → 时间戳和 -j 都生效）
#     dayNN  依赖可执行文件（模式规则 → 照旧编译并运行）
#     两条路径通过"编译了同一个东西"自然共享结果，不靠规则优先级。
# ---------------------------------------------------------------------------
# stamp 目标：只编译，然后用 touch 造一个标记文件
#
# ★ 这里必须用**静态模式规则**而不是普通模式规则，原因很关键：
#
#   普通模式规则  $(BIN)/.build_%: days/%.c
#     对目标 bin/.build_day01_compile，% 会匹配成 ".build_day01_compile"
#     于是去找 days/.build_day01_compile.c —— 不存在，规则永远不触发。
#
#   静态模式规则  $(STAMPS): $(BIN)/.build_%: days/%.c
#     左边把 14 个名字全部列出来，% 只在"模式"那一段出现，
#     所以 % 匹配到的是去掉 .build_ 前缀之后的 day01_compile，
#     正确找到 days/day01_compile.c。
#
#   两者的区别是 Make 里最容易混的一处：
#     模式规则     —— 左边只有一个 %，make 自己猜它对应哪个文件
#     静态模式规则 —— 左边把候选名全列出来，% 的取值被"点名"确定
$(STAMPS): $(BIN)/.build_%: days/%.c | $(BIN)
	$(CC) $(CFLAGS) -o $(BIN)/$* $< $(LDFLAGS)
	@touch $@


# 教学对照：错误的批量编译写法（一条 recipe 包住 14 次编译）
.PHONY: all2
all2: | $(BIN)
	@for d in $(DAYS); do \
		echo "编译 $$d ..."; \
		$(CC) $(CFLAGS) -o $(BIN)/$$d days/$$d.c $(LDFLAGS) || exit 1; \
	done
	@echo ""
	@echo "all2 完成。注意它**每次都重编全部 14 个文件** ——"
	@echo "因为 make 只看到 all2 一个目标，不知道 bin/ 里哪些已经是最新的。"
	@echo "而且 make -j8 all2 不会加速：-j 只对不同目标有效，这里只有一个目标。"

# 批量编译**并逐个运行**（14 个独立目标，时间戳同样生效）
.PHONY: runday
runday: $(DAYS)
	@echo ""
	@echo "14 天全部编译并运行完毕。"
	@echo ""

# ------------------------------------------------------------
#  八、环境自检
# ------------------------------------------------------------
.PHONY: check
check:
	@echo "=== 1. 编译器 ==="
	@$(CC) --version | head -1
	@echo ""
	@echo "=== 2. 构建工具 ==="
	@$(MAKE) --version | head -1
	@echo ""
	@echo "=== 3. CPU 核心数（Day 12/14 OpenMP 用） ==="
	@nproc
	@echo ""
	@echo "=== 4. 内存 ==="
	@free -h 2>/dev/null | head -2 || echo "  (无法读取)"
	@echo ""
	@echo "=== 5. 数据文件 ==="
	@ls -lh $(MODEL) $(TOK) 2>&1
	@echo ""
	@echo "=== 6. 模型文件头（Config 结构体 = 7 个 int = 28 字节） ==="
	@od -A d -t d4 -N 28 $(MODEL) 2>/dev/null | head -3
	@echo "  预期: dim=288 hidden_dim=768 n_layers=6 n_heads=6 n_kv_heads=6"
	@echo "        vocab_size=32000 seq_len=256"
	@echo ""
	@echo "=== 7. 冒烟测试：跑 Day 1 ==="
	@$(MAKE) --no-print-directory day01_compile

.PHONY: clean
clean:
	rm -rf $(BIN)
	@echo "已清理 bin/"