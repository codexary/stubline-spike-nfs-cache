# Write policy run / 写策略运行记录

Command / 命令: `./scripts/observe.sh write` on Docker Desktop 29.9.2, macOS, 2026-10-31. Exit status: 0. Each policy uses a fresh NFS volume and mounts; the script removes them on exit. / 每种策略使用全新的 NFS 数据卷和挂载，脚本退出时将其删除。

```text
write policy: async
B initial: before
B while A keeps file open: ''
writer has written but remains open
writer closed
B after A closes: 'after!'

write policy: fsync
B initial: before
B while A keeps file open: ''
B after A fsync, before close: 'after!'
writer has written but remains open
writer called fsync
writer closed
B after A closes: 'after!'

write policy: sync
B initial: before
B while A keeps file open: 'after!'
writer has written but remains open
writer closed
B after A closes: 'after!'
```
