[English](FINDINGS.md) | 简体中文

# 实验结论

## 观察

记录中的 NFSv3 `cached` 运行里，B 持续打开文件时一直读到 `before`，属性缓存到期后才看到新值；A 关闭后，B 重新打开可读到 `after!`。使用 `noac` 时 B 立即读到新值，但该次运行多了 13 次 `GETATTR`。写入实验中，A 保持文件打开时，`async` 或 `fsync` 策略下 B 可能读到空值；执行 `fsync` 或使用 `sync` 后，关闭前也能看见新内容。NFSv4 那次读到新值，但没有 delegation 计数。

## 对后端的影响

共享挂载使读者受缓存策略和文件开关时机影响。电子票按完整对象写入、读取，因此后端选择对象 PUT/GET。本地 NFSv4 结果不足以推断通用的 delegation 行为。参见[后端 ADR 0011：Store e-tickets as objects](https://github.com/codexary/stubline-backend/blob/main/docs/adr/0011-store-etickets-as-objects.md)。
