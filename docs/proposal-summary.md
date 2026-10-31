# MoonDeadline项目申报书

**实时任务配置回归、响应时间与预算分析**

账号：btlqql；版本：0.3.0；主要语言：MoonBit；许可：Apache-2.0。

## 解决的问题与使用场景

修改周期任务预算或优先级后，检查哪个任务变成超时、可用余量如何变化，以及是否存在可行优先级顺序。

## 已实现功能与技术路线

固定优先级RTA、带条件的抖动/阻塞界、EDF窗口需求、同步周期轨迹、Audsley分配、最大整数cost搜索、按任务名对齐的配置变更与已证明余量。

## 完整案例

slow优先于urgent时urgent超时；改为urgent、slow后响应分别为1、3。配置比较把失败结果保留为空上界，urgent新余量为1。 运行`moon run cmd/main --target js -- examples/config-regression.json`可复现。

## 独立贡献与验证

制造工序与设备排程；本项目处理CPU可抢占任务的响应时间与截止期。 当前8项MoonBit测试；48组随机模型：独立逐tick调度、全部优先级排列、全部候选整数cost和按名变更对齐。 相邻项目对照见docs/ECOSYSTEM.md，来源与许可见THIRD_PARTY.md。

## 当前边界

单处理器、可抢占、deadline<=period。输入WCET和阻塞上界须由调用者建立依据；窗口无反例不等于全时域可行。优先级分配只接受J=B=0、最多16项任务。没有多核、真实RTOS日志导入或WCET测量。

GitHub：https://github.com/btlqql/moon-deadline。模块：btlqql/moon_deadline@0.3.0。AI辅助开发；公开提交、CI和独立安装以实际核验记录为准，开源发布不代表比赛报名或验收通过。
