# MoonDeadline项目申报参考书

面向实时任务配置变更的响应时间与预算分析工具

版本：0.3.0 | 主要语言：MoonBit | 许可：Apache-2.0 | 日期：2026-10-31

GitHub账号：btlqql；项目仓库：https://github.com/btlqql/moon-deadline；公共模块：btlqql/moon_deadline@0.3.0。团队身份按本人报名信息填写。

## 一、项目名称与摘要

MoonDeadline以MoonBit实现单处理器固定优先级可抢占任务的响应时间分析、优先级分配和执行预算搜索。调用者输入任务名、执行预算、周期、相对截止期、释放抖动与阻塞上界，得到逐步干扰迭代、任务是否满足截止期，以及可复查的调度轨迹。

项目将分析核心连接为任务配置文件到结果的CLI流程。此次0.3.0新增Audsley最低优先级逐层分配与单任务最大可行整数执行预算搜索，并区分收敛的响应时间上界与已经超过截止期的迭代值，避免把分析失败值当作保证。

## 二、选题背景与实际使用场景

周期任务增加或修改后，CPU平均利用率不足100%并不能保证每项任务按时完成，尤其是截止期短于周期、优先级顺序不合适时。本项目直接检查任务级时间条件，而不是仅输出总体负载。

场景一是嵌入式配置回归：将控制、采样等周期任务的预算与deadline写入JSON，检查优先级调整后是否出现超时。场景二是预算规划：固定其他任务和优先级，求某一任务在全部任务仍通过RTA时的最大整数cost。场景三是调度策略验证：为错误优先级寻找可行顺序，用同步释放的执行轨迹与EDF需求反例说明不同判断。

这些流程已通过软件模型复现；输入cost是调用者提供的WCET预算，当前没有测量真实设备执行时间，也不声称实际RTOS部署或用户采用。

## 三、实现范围、参数与处理链

处理链：任务JSON读取 -> 名称与参数检查 -> 固定优先级响应时间迭代 -> 有限窗口轨迹和EDF需求检查 -> 可选优先级分配与预算搜索 -> JSON结果。业务计算在MoonBit中，Node宿主只读取文件并设置退出码。

任务按数组顺序从高到低排列，时间单位由调用者统一。支持1至64项任务，正执行量、正周期，0 < deadline <= period；周期、cost和阻塞上限为1,000,000。RTA最多迭代10,000步，耗尽明确报错。优先级分配与预算搜索限制最多16项任务；优先级分配只接受零抖动、零阻塞模型。

## 四、核心算法与工程处理

响应时间迭代从自身执行量加阻塞开始，按更高优先级任务的释放次数累计干扰，直到收敛或越过截止期。高优先级任务抖动参与干扰计数，被分析任务自身抖动计入相对于名义释放的界。阻塞上界必须有外部资源分析依据，工具不会从任务名字推测。

Audsley分配从最低优先级开始，逐个尝试候选任务：其余未分配任务全部视为更高优先级，只在候选通过时固定该层。无法选出候选返回None。测试同时核对原输入未被修改。

maximum_cost固定优先级及其他任务预算，利用可行性对目标cost的单调性二分搜索；仅当所有任务均通过RTA才接受。结果是模型中的可行预算上限，不是测量或证明实际代码WCET。

轨迹采用同步周期释放、固定优先级、零抖动和零阻塞，保留超时任务；遇到未完成作业与新释放重叠时停止并标明实际覆盖长度，不丢弃积压作业后继续声称仿真完整。EDF窗口枚举处理器需求，返回首个超载区间；窗口无反例不自动等于全时域可行。

新增compare接口与CLI的before输入，按稳定任务名匹配不同优先级顺序，输出前后是否通过、收敛上界与余量；失败迭代不参与余量计算。

## 五、与相关能力的区别及独立贡献

moonbitJobShop针对制造工序和设备排程，moonrecur/moon_cron针对日历触发，moon-netcalculus针对流体到达与服务曲线。本项目对象是CPU抢占任务、截止期与执行预算，不将已有日历、作业车间或网络演算能力描述为空白。

独立工作是受限模型中的响应时间、候选优先级分配、整体预算约束及轨迹的同一实现与可核对输出，不以CLI外壳或测试数量代替机制贡献。经典RTA参考Joseph与Pandya的Finding Response Times in a Real-Time System（1986，DOI:10.1093/comjnl/29.5.390）；算法依据公开定义独立编写，未移植第三方源码。

## 六、完整案例与输入输出

案例一：control的cost=2、period=10、deadline=2；sensor的cost=2、period=20、deadline=3。总利用率为30%，sensor响应迭代却到4而超时；EDF也在长度3的区间发现需求4。运行：moon run cmd/main --target js -- examples/missed-deadline.json。

案例二：slow为(2,10,10)，urgent为(1,4,2)，顺序为slow、urgent时urgent超时。运行examples/priority-plan.json，优先级分配返回urgent、slow，响应分别为1和3，全部通过；原顺序下单任务最大预算分别为1与空值，说明只修改urgent预算不能解决其前置干扰。

CLI同时返回response_upper_bound和exceeded_deadline_iterate；只有收敛且满足截止期时前者非空。Int64输出为十进制字符串保持整数精度。ok=true表示分析执行成功，超时结果仍需读取meets_deadline；非法模型或计算失败退出1。上述案例均为自制软件模型。

新增可复现文件：examples/config-regression.json。slow优先于urgent时urgent超时；改为urgent、slow后响应分别为1、3。配置比较把失败结果保留为空上界，urgent新余量为1。

## 七、正确性验证与独立参考

当前8项MoonBit测试，在Windows本地JS、Wasm、Wasm-GC分别通过，共24次本地测试执行；核心check --target all --deny-warn通过，JS CLI构建与示例实际执行。native没有实际运行，静态check不作为运行证明。

基础独立对照包含80组任务模型：Python按每个时间tick调度各优先级前缀，核对RTA的成功响应时间和是否超时；另以作业释放与截止期枚举核对EDF需求反例。复核新增32组模型，穷举全部任务优先级排列，核对分配是否存在，并对全部整数cost逐项穷举核对预算搜索。

模型使用固定随机种子，验证入口为上级verify.py与review_verify.py，原始结果保存在evidence/validation.json和review-validation.json。批量模型数与测试条目数分别记录，不合并宣传为独立用户案例。

仓库内scripts/verify.py独立验证：48组随机模型：独立逐tick调度、全部优先级排列、全部候选整数cost和按名变更对齐。无需父目录或原工作区。

## 八、公开接口、使用与当前边界

公共API包括Task、Response、fixed_priority、edf_window、simulate、assign_priorities和maximum_cost；pkg.generated.mbti列出完整签名。CLI以JSON文件为输入，可嵌入开发者配置检查脚本。

支持范围是单处理器、固定优先级、可抢占、受限截止期任务。多核、非抢占临界区、动态资源锁和RTOS运行日志导入不在当前实现中。EDF和轨迹只说明给定窗口；WCET与阻塞条件必须由使用者保证。零抖动零阻塞下的经典分析与带J/B条件下的充分界分别说明。

## 九、公开交付与复现入口

- GitHub仓库：[https://github.com/btlqql/moon-deadline](https://github.com/btlqql/moon-deadline)。
- MoonCakes模块：[btlqql/moon_deadline@0.3.0](https://mooncakes.io/docs/btlqql/moon_deadline@0.3.0)。
- 主要代码与测试、README、独立验证脚本、来源许可、JSON示例、生成API均在同一仓库。
- [公共CI](https://github.com/btlqql/moon-deadline/actions)包含四后端测试，实际完成状态与安装验证记录在发布核验报告，不预写未发生的运行结论。

GitHub开发历史、公共包发布与比赛报名是不同事项。本项目为AI辅助开发，参赛者负责理解模型、取舍和质量。未代填比赛报名，也没有主办方通过回执。
