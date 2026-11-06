# 生态对照与重复性核查

本轮核查：2026-11-06。公开可检索内容有范围限制，不能据此保证所有参赛作品均不重复。

| 一手来源 | 已有职责 | 本次交付的区别 |
|---|---|---|
| [MoonBit OS 提案 #3322](https://github.com/moonbitlang/core/issues/3322) | 提案面向 RISC-V/Wasm；指向一多 OS | 本项目明确以 Cortex-M3 异常、PSP 和固定资源任务为执行模型，不宣称首个 MoonBit OS |
| [liaoran123/yiduo 当前 README](https://github.com/liaoran123/yiduo/blob/main/README.md) | 当前说明以 Wasm/WASI、WIT 组件组合及运行时编排为中心；范围与早期提案不同 | 本项目没有组件加载/WASI 编排；直接 ARM ELF、SysTick/PendSV 抢占、锁继承与 ISR 消息；按其当前说明比较，不拿旧提案代替当前状态 |
| [ljs448/moonbitJobShop](https://github.com/ljs448/moonbitJobShop) | 工序/设备作业车间排程 | 对象是 CPU 任务与真实异常上下文，不是制造排程 |
| [niuniu513-ask/moon-netcalculus](https://github.com/niuniu513-ask/moon-netcalculus) | 到达/服务曲线与网络时延演算 | 本次有实际任务栈、锁和队列，不以另一类时延公式计作 RTOS |
| [FreeRTOS Kernel](https://github.com/FreeRTOS/FreeRTOS-Kernel) | 成熟多平台 C RTOS | 调度、继承、IPC 为本项目独立 MoonBit 实现，未包装 FreeRTOS；平台、功能和生产成熟度远小于 FreeRTOS |

GitHub 仓库搜索 `moonbit RTOS`、`MoonBit kernel Cortex` 本轮未返回结果，但另通过公开网页检索找到了上述 OS 提案，说明仅靠关键词“零命中”不足以声称唯一。

调度、优先级继承、环形队列、Cortex-M 异常切换均是成熟方法；创新价值在 MoonBit 核心与固定平台执行端口、无运行期分配约束、可检查的抢占和通信行为组合。该判断是基于已核查材料的职责比较，项目价值及重复性仍由评委审定。

同一仓库从 0.3.0 离线分析更新为 0.4.0 RTOS 核心和执行端口，保留原历史。核心、固件和样例作为同一作品提交，不拆分重复报名。
