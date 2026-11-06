# 0.4.0 公开发布核验

日期：2026-11-06。仓库沿用 [btlqql/moon-deadline](https://github.com/btlqql/moon-deadline)。

- 本次发布代码基线：`ba1bf28f054192be4a3b76cfc40d2ba86a186ed7`，公开 main 与本地 Git 对象相同；该基线为 19 条真实提交，后续发布记录提交继续累计。
- [最终发布基线公共 CI](https://github.com/btlqql/moon-deadline/actions/runs/42245873910) 已完成且成功，包含四个宿主后端和 Cortex-M3/QEMU 正负例验证。
- [MoonCakes 0.4.0](https://mooncakes.io/docs/btlqql/moon_deadline@0.4.0) 已正式发布，注册表版本已核实，公开文档 HTTP 200。
- 独立目录从公开注册表安装精确版本 0.4.0，无本地路径依赖。两项公开 API 测试（消息唤醒/优先级选择、锁继承/超时撤销）在 JS、Wasm、Wasm-GC 各通过，合计 6 次执行。
- 下载包中的 `moon.mod` 与三份 RTOS 核心源码，经换行归一化后与本次 GitHub 发布基线逐字节相同。
- [完整版 MD 申报书](proposal.md) 和 [一页说明](proposal-summary.md) 已随公开仓库交付；只陈述已实现与验证的范围。

本记录是发布后的新增文档，不修改已发布包的算法实现。MoonCakes 提供语义核心；完整固件与硬件端口从 GitHub 获取。

实体板运行未完成，全部裸机验证来自 QEMU Cortex-M3。初审回执允许 2026-11-30 前修改报名信息；本次未操作飞书报名表或发送赛事消息，需以更新后的 MD 材料在原报名表重新提交。开源发布不代表报名复审通过。
