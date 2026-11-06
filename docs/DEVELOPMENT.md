# 开发历史与计数边界

以下为首次公开代码的10条实际提交，保留真实日期。每条均包含文件变化；不倒填、不重写、不建空提交。数量涵盖核心功能、修复、验证、集成、CI和文档，不代表主办方已认可全部为有效参赛提交。

```text
846364a | 2026-10-31T19:27:19+08:00 | Implement initial domain core, executable example and boundary tests
82fd04e | 2026-10-31T19:36:13+08:00 | Add planning, diagnosis and moving audio workflows; fix boundary semantics
7ff4bdd | 2026-10-31T19:42:25+08:00 | Document implemented 0.2.0 behavior and validated boundaries
22aaae2 | 2026-10-31T19:48:23+08:00 | Configure btlqql module namespace, repository metadata and package exclusions
9911c2f | 2026-10-31T19:49:12+08:00 | Add named before-after configuration comparison and proven slack
e873e89 | 2026-10-31T19:50:11+08:00 | Connect named configuration regression reports to the JSON CLI
bff6a39 | 2026-10-31T19:51:34+08:00 | Add executable regression fixtures and adversarial state-boundary tests
2ef3f4b | 2026-10-31T19:52:35+08:00 | Add self-contained independent verification runnable from a clean repository
4127b1f | 2026-10-31T19:53:18+08:00 | Run portable tests on four backends and independent file-workflow oracles in CI
b0008ff | 2026-10-31T19:55:26+08:00 | Document complete runnable workflows, ecosystem differences and Markdown applications for release
```

用户本轮明确确认：比赛要求为每个参赛仓库至少10次提交，没有另列起始或截止时间。本项目按仓库真实历史计数，不再将旧通知的9月1日或假设的11月1日另作本轮门槛。

## 2026-11-06：RTOS 实质更新

原仓库 0.3.0 基线 `e44889c` 有 12 条提交。本轮继续同一仓库，没有删除旧历史或拆分报名。下列基线 `1b6d0b7` 的总数为 18，已大于 10；后续文档/发布核验提交在公开历史中继续累计。

```text
65172f4 | 2026-11-06T23:29:46+08:00 | 有界调度、优先级继承、IPC 与语义测试
c22c764 | 2026-11-06T23:29:47+08:00 | Cortex-M3 复位、独立栈、时钟与切换执行端口
e6d92e6 | 2026-11-06T23:32:37+08:00 | QEMU 场景与栈/内存故障注入验证
cab0269 | 2026-11-06T23:33:00+08:00 | 固定已验证编译器/core ABI
b6ebd5a | 2026-11-06T23:39:32+08:00 | 运行说明、整改对应与生态职责核查
1b6d0b7 | 2026-11-06T23:42:34+08:00 | Markdown 申报书及实际执行证据
```

Git HTTPS 本轮连接失败，采用 GitHub Git Data API 传输相同本地 Git 对象；每个 tree/commit SHA 必须与本地完全相同后才更新引用。原作者、提交者和真实时间均保持，分支只快进，不强制覆盖远端历史。公共 Linux CI 对基线 `cab0269` 的四后端及全部裸机用例已通过。
