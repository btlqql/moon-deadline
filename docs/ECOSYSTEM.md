# 与已有项目的职责对照

核查日期2026-10-31。检索公开仓库、模块和最接近项目的一手README；未命中不构成生态唯一保证。

- [ljs448/moonbitJobShop](https://github.com/ljs448/moonbitJobShop)：制造工序与设备排程；本项目处理CPU可抢占任务的响应时间与截止期。
- [niuniu513-ask/moon-netcalculus](https://github.com/niuniu513-ask/moon-netcalculus)：流体到达/服务曲线与网络时延；不等同于CPU任务优先级与WCET。

单处理器、可抢占、deadline<=period。输入WCET和阻塞上界须由调用者建立依据；窗口无反例不等于全时域可行。优先级分配只接受J=B=0、最多16项任务。没有多核、真实RTOS日志导入或WCET测量。

本项目是AI辅助的独立MoonBit实现，算法来自成熟公开方法，不将CLI、基础I/O或第三方数据计为独立算法贡献。
