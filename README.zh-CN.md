[English](README.md) | 简体中文

# NFS 客户端缓存小项目

server 使用固定版本 Debian 12.12 镜像，安装 `nfs-kernel-server` 与 `nfs-common`；client 使用固定版本 Ubuntu 24.04 镜像，两种镜像均支持 arm64 和 amd64。容器需要 `privileged: true` 才能启动内核 NFS 服务并挂载 NFS 文件系统。在 macOS Docker Desktop 上，server 和两个 client 共用 Docker VM 的 Linux 内核：两台“机器”是同一主机上的两个内核挂载，不是独立内核。server 启用 NFSv3 和 NFSv4，不请求当前内核已不支持的 NFSv2。

运行 `./mvnw -q verify`，再从仓库根目录运行各脚本。每次调用都新建 volume 和挂载，确保 B 的缓存从已知状态开始。退出时和 `write` 的三种策略之间，脚本先卸载两个 client，再运行 `docker compose down -v`。server 的 SIGTERM 处理函数取消导出数据，停止内核 NFS 线程、mount daemon 和 port mapper。每条命令连续运行两次，并在每次运行后检查 `docker compose ps -a` 没有剩余容器。

```sh
./scripts/observe.sh cached
./scripts/observe.sh close-to-open
./scripts/observe.sh noac
./scripts/observe.sh write
./scripts/observe.sh v4
```

- `cached`（新镜像上的输出待记录）：NFSv3 `vers=3,nolock,actimeo=10`。A 覆盖并关闭文件时 B 保持同一 open。预期输出 `initial open: before`、`same open, immediate: before`、`same open, after actimeo: after!`；最后的 `close then reopen:` 预期为 `after!`。前三行曾在旧镜像上观察到。
- `close-to-open`（关闭 NFSv2 后的一次运行）：相同 NFSv3 挂载，B 在 A 关闭后立即关闭并重开。实际输出为 `initial open: before`、`same open, immediate: before`、`close then reopen: after!`。
- `noac`（待记录）：关闭 NFSv3 属性缓存。预期输出 `initial open: before`、`same open, immediate: after!`、`close then reopen: after!`。脚本还从 B 的 `/proc/self/mountstats` 打印 `NFSv3 GETATTR calls before=... after=... delta=...`；实际计数不固定。
- `write`（待记录）：B 使用 `noac`，隔离写方策略。每个 `write policy: async|fsync|sync` 都预期先输出 `B initial: before`，再输出 `B while A keeps file open:` 和 `B after A fsync/close: after!`。中间一次读取在 async 策略下可能仍为 `before`，内核提前刷新时也可能为 `after!`；`fsync` 在这次读取之后才调用，无法改变已打印的结果。`sync` 挂载可能让中间一次读取更早看到 `after!`。脚本输出 `writer has written but remains open`，在对应策略下输出 `writer called fsync`，最后输出 `writer closed`。
- `v4`（新镜像上的输出待记录）：NFSv4.2 `actimeo=10` 重复 open-reader 探针。预期输出 `initial open: before`、`same open, immediate: after!`、`close then reopen: after!`；旧镜像曾观察到立即读取新值。若内核导出 delegation 行，脚本会从 mountstats 打印。仅凭读取到新值不能证明曾授予并撤回 delegation。

server 同时导出 NFSv3 (`server:/data`) 和 NFSv4 (`server:/`)。这些内核缓存语义不同于 Stubline 票据使用的整对象 PUT/GET 接口。

## 许可证

本仓库采用 [MIT License](LICENSE)。

## 关于本仓库

本仓库包含一项针对 Stubline 的独立实验。README 说明运行命令与观察结果。

本仓库的代码与文档借助 AI 工具编写；记录的输出都来自实际运行。
