# MoonDeadline

实时系统任务的响应时间分析核心。首批实现，模块名november/moon_deadline是本地开发命名空间，尚未在注册表发布。

输入按优先级从高到低排列，每项指定name、cost、period、deadline、jitter、blocking；所有时间使用同一个调用者定义的整数单位。支持单处理器、固定优先级、可抢占、相对截止期不超过周期的模型。输入cost是调用者提供的WCET预算，工具不测量或证明WCET。

已实现fixed_priority、edf_window、simulate三类API。完整签名见pkg.generated.mbti。RTA记录每次干扰迭代；jitter相对于名义释放计入端到端界，blocking必须是外部分析给出的阻塞上界。J=B=0且模型假设成立时使用经典响应时间分析；带J/B为对应假设下的充分分析。

运行：

```powershell
moon run cmd/main --target js -- examples/missed-deadline.json
moon test --target js --deny-warn
```

示例CPU利用率仅30%，但sensor任务deadline=3、响应时间=4，输出meets_deadline=false；EDF在区间3也得到需求4的反例。示例是自制模型，不是设备实测。

CLI的bound和iterations为Int64的JSON十进制字符串，保持整数精度。当meets_deadline=true时bound是收敛的响应时间界；为false时它只是已经超过截止期的迭代值，不能解释为有限响应时间上界。进程退出0表示分析成功执行，超时结果仍需读取meets_deadline；输入/计算失败退出1。

simulate只接受零抖动零阻塞的同步周期释放；超时后保留反例，不默默丢弃积压作业继续声称有效仿真。EDF窗口无反例只能说明该有限窗口，不能证明全时域可调度。不支持多核、非抢占片段、动态资源锁或真实FreeRTOS trace导入。

任务数1..64；周期/执行量/阻塞上限1,000,000；仿真horizon<=100,000、EDF<=1,000,000。CLI同时调用两者时有效horizon<=100,000。RTA迭代上限10,000，耗尽明确报错。

独立逐tick模型、EDF作业枚举对照与三后端测试由上级目录verify.py执行；结果在../../evidence/validation.json。全目标check与native实际运行分开记录。

算法参考：[Joseph/Pandya 1986](https://doi.org/10.1093/comjnl/29.5.390)。未移植第三方算法代码。相邻项目moonbitJobShop、moonrecur、moon-netcalculus的功能对照见上级制作总方案。Apache-2.0，AI辅助实现。
