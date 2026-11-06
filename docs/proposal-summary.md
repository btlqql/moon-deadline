# MoonDeadline RTOS 一页项目说明

**面向 Cortex-M3 的 MoonBit 有界抢占式实时内核｜0.4.0｜Apache-2.0｜GitHub：btlqql**

## 需求与交付

为 MoonBit 嵌入式任务原型提供实际执行、定时抢占、阻塞恢复和同步通信。针对旧作品仅做离线分析的初审意见，本轮增加可运行 RTOS 核心、Cortex-M3 端口和实际 MoonBit 任务体，在 QEMU MPS2 AN385 从 ARM ELF 复位入口运行。

## 已完成机制

MoonBit 实现优先级调度、同级轮转、任务延时/退出、有界信号量、传递式优先级继承互斥锁、有界 FIFO 消息及 ISR 通知。C/Thumb 负责启动、独立 PSP 栈、SVC/PendSV 上下文切换、SysTick 时钟和 UART。16 任务槽、32 级优先级、8 信号量/8 锁、4 队列×最多 16 个整数；运行期禁止分配。

## 场景与实际验证

五组目标架构运行：不主动让出的忙任务被抢占/轮转；三任务优先级反转恢复；中断唤醒的采集→处理→消费流水线；队列与信号量超时竞争；150,012 次任务身份切换压力。两个故障注入确认栈损坏和启动后分配被拒绝。各正例有 UART、退出码、工具版本和 ELF 哈希；16 条 MoonBit 测试覆盖四后端，公共 CI 独立运行裸机用例。

## 差异与边界

对照一多 OS 的 Wasm/WASI 组件运行时，本项目交付固定 Cortex-M3 异常执行与有界同步通信；不宣称首个 OS 或保证所有参赛作品无重复。原仓库保留旧历史与分析 API，按同一项目实质更新，真实提交总数已超过 10。

**没有实体开发板验证**；QEMU 虚拟时间不代表板上性能。没有通用动态堆、驱动/网络、MPU、WCET 证明或生产部署。适用于教学、原型与端口验证；完整限制、来源和证据列于仓库。

## 复现与链接

```sh
python scripts/rtos.py --scenario 3
python scripts/rtos.py --scenario 5
```

需要 README 指定的 MoonBit/core、ARM GCC、QEMU 与 Python。MoonCakes 安装：`moon add btlqql/moon_deadline@0.4.0`；导入 `btlqql/moon_deadline/rtos`。

- GitHub：[https://github.com/btlqql/moon-deadline](https://github.com/btlqql/moon-deadline)
- MoonCakes：[https://mooncakes.io/docs/btlqql/moon_deadline@0.4.0](https://mooncakes.io/docs/btlqql/moon_deadline@0.4.0)
- 完整申报书：[proposal.md](proposal.md)；运行证据：[VALIDATION.md](VALIDATION.md)

公开发布不代表报名表已更新或审核已通过。日期：2026-11-06。
