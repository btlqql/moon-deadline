# MoonDeadline RTOS

MoonBit 实现的有界抢占式 RTOS 核心与 Cortex-M3 裸机执行端口，Apache-2.0，版本 0.4.0。

任务调度、等待/唤醒、传递式优先级继承、信号量和消息队列由 MoonBit 实现；C/Thumb 汇编负责复位、异常入口、独立任务栈及硬件寄存器访问。MoonBit 任务编译为 ARM ELF，在 **QEMU `mps2-an385` Cortex-M3** 上从复位入口运行。没有实体开发板验证。

## 运行裸机示例

需要 Python 3、MoonBit `0.10.15+943464bfa` 及匹配 core、GNU Arm Embedded GCC、QEMU system-arm。工具加入 PATH；可通过 `ARM_GCC`、`QEMU_ARM` 指定完整程序路径，`MOON_HOME` 指向工具链目录。Windows 所有工具与构建输出均可放在 D 盘。

```sh
python scripts/rtos.py --scenario 1
python scripts/rtos.py --scenario 2
python scripts/rtos.py --scenario 3
python scripts/rtos.py --scenario 4
python scripts/rtos.py --scenario 5
python scripts/rtos.py --fault stack
python scripts/rtos.py --fault allocation
```

脚本直接调用 MoonBit 原生后端生成 C，再交叉编译 Cortex-M3 ELF。每次生成 ELF、链接映射、UART 日志和含 SHA256 的工具版本记录，位于 `_build/rtos/`。正例要求退出码 0 和 `RTOS_PASS`；两个故障用例要求非零退出及指定错误码。`--verbose` 显示完整导出的轨迹。

| 场景 | 已实现行为与检查 |
|---|---|
| 1 抢占与轮转 | 三个不主动让出的忙任务轮转；高优先级任务在 tick 5 唤醒抢占；检查 R4–R11、局部值和栈底哨兵 |
| 2 优先级反转 | 低任务继承高任务优先级越过中任务，在 tick 5 释放锁；解锁后恢复基础优先级 |
| 3 采集处理流水线 | SysTick 通知采集任务，采集→处理→消费三条 MoonBit 任务，经两队列逐项验证 20 条整数消息 |
| 4 超时竞争 | 同 tick 先超时再投递中断事件；检查令牌、满队列发送超时清理和消息保留 |
| 5 压力 | 150,010 ticks，150,012 次任务身份切换，寄存器/栈检查通过，启动后分配次数不变 |
| 故障注入 | 破坏栈底触发 `PANIC 72`；启动后分配触发 `PANIC 81`，均为预期拒绝 |

完整复现见 [端口说明](docs/RTOS.md)，原始结果见 [验证记录](docs/VALIDATION.md)；公共结果见 [Actions](https://github.com/btlqql/moon-deadline/actions)。QEMU 加速虚拟时间不表示实体硬件性能。

## 复用核心

```sh
moon add btlqql/moon_deadline@0.4.0
```

在 `moon.pkg` 导入 `"btlqql/moon_deadline/rtos" @rt`。接口见 [rtos/pkg.generated.mbti](rtos/pkg.generated.mbti)。

```moonbit
let k = @rt.Kernel::new()
ignore(k.create(1, 5))
ignore(k.semaphore(0, 0, 1))
ignore(k.take(1, 0, -1)) // 阻塞
ignore(k.give(0))        // 唤醒
let selected = k.pick()  // 1
```

MoonCakes 提供跨后端复用的核心语义；裸机固件、端口和构建脚本从 GitHub 获取。固件位于单独模块，避免硬件 FFI 混入宿主程序。JS/Wasm 上调用核心不会产生硬件任务切换。

## 工程范围

单核 Cortex-M3，无 FPU/MPU；16 任务槽、32 级优先级（数字越小越高）、8 信号量、8 非递归互斥锁、4 队列，每队列最多 16 个 32 位整数。SysTick 100 Hz；PendSV 保存 R4–R11，硬件保存其余异常帧；SVC 启动首个任务。内核调用关闭中断串行化。

所有内核资源启动时创建并固定生命周期，启动后禁止分配/释放对象；任务体只使用不分配的整数操作与端口调用。适配器不是通用 MoonBit 内存运行时。固定栈每任务 4 KiB，16 槽共 64 KiB，启动堆预留 64 KiB，验证 trace 另占 64 KiB。实测堆使用 1,488 字节不代表总 RAM。

无物理板、驱动库、通用动态任务创建、文件系统、网络、硬实时 WCET 证明或安全认证。栈哨兵在切换时检测，不能替代 MPU 隔离。适用于嵌入式教学、移植验证和有界 MoonBit 任务原型。

## 兼容保留的离线分析工具

根包保留 0.3.0 的 RTA、EDF 有限窗口、预算搜索和配置对比 API。独立假设见 [分析工具说明](docs/ANALYZER.md)，离线响应时间界不能当作内核实测 WCET。

```sh
moon run cmd/main --target js -- examples/config-regression.json
moon check --target all --deny-warn
moon test --target js --deny-warn
moon test --target wasm --deny-warn
moon test --target wasm-gc --deny-warn
moon test --target native --deny-warn
python scripts/verify.py
```

16 条 MoonBit 测试（8 条分析、8 条 RTOS），另有 48 组分析器独立参考模型；RTOS 测试包含 4,096 次 FIFO 混合操作、时钟回绕、锁继承链、退出清理和资源边界。

## 参赛材料

[Markdown 申报书](docs/proposal.md) · [一页项目说明](docs/proposal-summary.md) · [整改核对](docs/REVIEW.md) · [生态对照](docs/ECOSYSTEM.md) · [来源许可](THIRD_PARTY.md) · [真实提交历史](https://github.com/btlqql/moon-deadline/commits/main/)

保留原仓库及 0.3.0 历史，以同一项目实质更新申报；核心、端口和样例不拆成多个参赛作品。公开发布不等同于重新提交报名表或审核通过。
