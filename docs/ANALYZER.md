# 保留的离线分析工具

根包和 JS CLI 保留固定优先级 RTA、EDF 有限窗口需求、同步周期轨迹、Audsley 优先级分配、整数 cost 搜索与按任务名配置对比。此次 RTOS 更新不改变其分析假设。

```sh
moon run cmd/main --target js -- examples/config-regression.json
moon run cmd/main --target js -- examples/priority-plan.json
python scripts/verify.py
```

`before` 为旧配置，`tasks` 为新配置，`optimize=true` 开启规划；`ok` 表示执行成功，任务结果另看 `meets_deadline`。收敛且满足截止期时 `response_upper_bound` 才有值，失败迭代不参与余量计算。Int64 在 JSON 中为十进制字符串。

单处理器、可抢占、0 < deadline <= period。WCET cost 与阻塞界由调用者提供；带抖动/阻塞的充分界不意味着测得内核开销。轨迹为同步释放、无抖动阻塞；EDF 有限窗口无反例不是全时域证明。优先级分配最多 16 任务、J=B=0。没有多核、WCET 测量或运行 trace 自动校准。

例 slow=(2,10,10)、urgent=(1,4,2)，slow 高优先级时 urgent 超时；改为 urgent 高优先级后响应为 1、3。独立 Python 标准库入口用 48 组固定种子模型、逐 tick 调度、穷举优先级与整数 cost 核对结果。
