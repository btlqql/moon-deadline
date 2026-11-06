# 来源、许可与 AI 辅助说明

本项目源码采用 Apache-2.0。MoonBit 调度、等待、优先级继承、信号量、队列、测试，以及 C/Thumb 平台胶水均为本仓库 AI 辅助编写；参赛者负责理解、演示与维护。没有把其他参赛仓库代码或 FreeRTOS 调度实现移植后冒称原创。

| 依赖/参考 | 使用方式与归属 |
|---|---|
| [MoonBit 官方 core](https://github.com/moonbitlang/core) | 使用官方编译器、core 和工具链 ABI 头；core 许可证见上游，编译器按其发行条款使用。工具链头含 IDEA 的 Apache-2.0 版权说明；构建时引用，不改写版权 |
| [MoonBit FFI](https://docs.moonbitlang.com/en/latest/language/ffi.html) | 原生代码生成、导出及 C 接口定义参考 |
| [Arm Cortex-M3 文档](https://developer.arm.com/documentation/dui0552/latest/) | 异常帧、PSP、PRIMASK、SysTick/PendSV 等硬件机制参考；未复制 CMSIS/厂商驱动源码 |
| [QEMU](https://www.qemu.org/docs/master/system/arm/mps2.html) | 独立测试程序，不嵌入库；适用上游 QEMU GPL 等许可，项目 Apache 许可不覆盖 QEMU |
| [xPack GNU ARM GCC](https://github.com/xpack-dev-tools/arm-none-eabi-gcc-xpack) / [xPack QEMU](https://github.com/xpack-dev-tools/qemu-arm-xpack) | Windows 构建/测试工具，独立安装；下载校验记录保存在本地工具清单，不上传工具二进制 |
| GNU libgcc | 裸机交叉链接用于整数辅助操作，按 GCC Runtime Library Exception 等适用条款使用；不是本项目原创算法 |
| RTA / Audsley | 保留分析器依据经典公开算法独立编写；RTA 参考 Joseph/Pandya 1986，DOI:10.1093/comjnl/29.5.390 |

`ports/cortex-m3/runtime.c` 是本项目为常驻对象编写的受限 ABI 适配；不是复制并裁剪官方通用内存管理器，也不提供同等功能。生成 C 包含编译器/core 产物，不以生成代码行数计算原创贡献。仓库不保存访问凭据。
