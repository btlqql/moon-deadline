# 验证记录

版本0.3.0；8项MoonBit测试，本地JS/Wasm/Wasm-GC各8项通过。

[代码基线四后端CI](https://github.com/btlqql/moon-deadline/actions/runs/41198960038)：`b0008ff116e3d482b2637613a88f87b2add2f697`。

公共CI的JS、Wasm、Wasm-GC、native四个job均实际成功；其中JS执行独立脚本及文件流程。

```sh
moon check --target all --deny-warn
moon test --target all --deny-warn
python scripts/verify.py
```

独立脚本只使用标准库、MoonBit和Node，不读取相邻工作区。模型、批量案例和测试条目数量分开记录。具体领域边界见README与申报书。
