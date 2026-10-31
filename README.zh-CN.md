[English](README.md) | 简体中文

# NFS 客户端缓存小项目

BuildKit 在镜像重新构建时复用 apt 软件包索引和下载缓存，减少下载量、构建时间及 CI 成本。

server 镜像基于 Debian 12.12 slim，安装 `nfs-kernel-server` 与 `nfs-common`；client 基于 Ubuntu 24.04。两个基础镜像都在 Dockerfile 里按摘要（digest）固定，重新构建时用的是同一组基础层；两者都支持 arm64 和 amd64。容器需要 `privileged: true` 才能启动内核 NFS 服务并挂载 NFS 文件系统。在 macOS Docker Desktop 上，server 和两个 client 共用 Docker VM 的 Linux 内核：两台“机器”是同一主机上的两个内核挂载，不是独立内核。server 启用 NFSv3 和 NFSv4，不请求当前内核已不支持的 NFSv2。

运行 `./mvnw -q verify`，再从仓库根目录运行各脚本。每次调用都新建 volume 和挂载，确保 B 的缓存从已知状态开始。退出时和 `write` 的三种策略之间，脚本先卸载两个 client，再运行 `docker compose down -v`。server 的 SIGTERM 处理函数取消导出数据，停止内核 NFS 线程、mount daemon 和 port mapper。每条命令连续运行两次，并在每次运行后检查 `docker compose ps -a` 没有剩余容器。

```sh
./scripts/observe.sh cached
./scripts/observe.sh close-to-open
./scripts/observe.sh noac
./scripts/observe.sh write
./scripts/observe.sh v4
```

- `cached`：实测 `initial open: before`、`same open, immediate: before`、`same open, after actimeo: after!`、`close then reopen: after!`。
- `close-to-open`：实测 `initial open: before`、`same open, immediate: before`、`close then reopen: after!`。
- `noac`：实测 `initial open: before`、`same open, immediate: after!`、`close then reopen: after!`，以及 `NFSv3 GETATTR calls before=2 after=15 delta=13`。计数随运行变化。
- `write`：记录中的运行显示，A 保持文件打开时，`async` 与 `fsync` 下 B 先读到空值；A 调用 `fsync` 后、关闭前，B 读到 `after!`；`sync` 下 A 保持文件打开时 B 已读到 `after!`。三种策略在关闭后 B 均读到 `after!`。见[写策略运行记录](docs/recorded-runs/write-policy.md)。
- `v4`：实测 `initial open: before`、`same open, immediate: after!`、`close then reopen: after!`。此内核的 client mountstats 没有 delegation 计数，因此脚本不再打印空标题。读到新数据本身不能证明 delegation 曾被授予或撤销。如需证据，可在文件保持打开时检查 server 的 `/proc/fs/nfsd/clients/*/states`。

server 同时导出 NFSv3 (`server:/data`) 和 NFSv4 (`server:/`)。这些内核缓存语义不同于 Stubline 票据使用的整对象 PUT/GET 接口。

## 许可证

本仓库采用 [MIT License](LICENSE)。

## 关于本仓库

本仓库包含一项针对 Stubline 的独立实验。README 说明运行命令与观察结果。

本仓库的代码与文档借助 AI 工具编写；记录的输出都来自实际运行。

## 结论

实验结果及其对后端决策的影响见[FINDINGS.zh-CN.md](FINDINGS.zh-CN.md)。
