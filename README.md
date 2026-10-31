# MoonDeadline

实时任务配置回归、响应时间与预算分析，主要业务机制由MoonBit实现，Apache-2.0。

修改周期任务预算或优先级后，检查哪个任务变成超时、可用余量如何变化，以及是否存在可行优先级顺序。

## 可运行任务

```sh
moon run cmd/main --target js -- examples/config-regression.json
moon run cmd/main --target js -- examples/priority-plan.json
```

slow优先于urgent时urgent超时；改为urgent、slow后响应分别为1、3。配置比较把失败结果保留为空上界，urgent新余量为1。

examples/config-regression.json中的before表示旧配置、tasks表示新配置。optimize=true可同时运行优先级分配和预算搜索。

CLI读取JSON文件，ok表示计算执行成功；领域可行性、超时或削波需读取各自字段。Node只读写文件、设置退出码和封装PCM；核心算法不转发给Python/C或外部服务。

## 可复用接口与安装

```sh
moon add btlqql/moon_deadline@0.3.0
```

在moon.pkg导入`"btlqql/moon_deadline" @core`；完整签名见[pkg.generated.mbti](pkg.generated.mbti)。

固定优先级RTA、带条件的抖动/阻塞界、EDF窗口需求、同步周期轨迹、Audsley分配、最大整数cost搜索、按任务名对齐的配置变更与已证明余量。

## 验证

```sh
moon check --target all --deny-warn
moon test --target js --deny-warn
moon test --target wasm --deny-warn
moon test --target wasm-gc --deny-warn
python scripts/verify.py
```

当前8项MoonBit测试。独立开发对照：48组随机模型：独立逐tick调度、全部优先级排列、全部候选整数cost和按名变更对齐。

脚本只需要Python标准库、Node与MoonBit；可用MOON_BIN指定moon路径。产物保存在本仓库_build/oracle，脚本不下载外部库，不访问相邻工作区。CI覆盖JS/Wasm/Wasm-GC/native，实际运行状态见[Actions](https://github.com/btlqql/moon-deadline/actions)。本地验证和公共CI结论分别记录，不用静态检查冒称native运行。

## 实现边界与来源

单处理器、可抢占、deadline<=period。输入WCET和阻塞上界须由调用者建立依据；窗口无反例不等于全时域可行。优先级分配只接受J=B=0、最多16项任务。没有多核、真实RTOS日志导入或WCET测量。

对照详见[ECOSYSTEM](docs/ECOSYSTEM.md)，归属见[THIRD_PARTY](THIRD_PARTY.md)。实例是软件模型或合成输入，不是生产部署证明。

## 申报与开发记录

[完整版Markdown申报书](docs/proposal.md) | [一页Markdown摘要](docs/proposal-summary.md) | [实际提交历史](https://github.com/btlqql/moon-deadline/commits/main/)

版本0.3.0。GitHub提交保留真实时间与每次文件变化；不以数量替代独立价值和实际质量。十一月规则尚未从公开页面完整确认，开源发布不等于比赛报名或验收通过。
