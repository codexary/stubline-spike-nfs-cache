[English](README.md) | 简体中文

# NFS 客户端缓存小项目

server 和 client 使用固定版本 Debian 12.12 镜像，安装 `nfs-kernel-server` 与 `nfs-common`，同时支持 arm64 和 amd64。容器需要 `privileged: true` 才能启动内核 NFS 服务并挂载 NFS 文件系统。在 macOS Docker Desktop 上，server 和两个 client 共用 Docker VM 的 Linux 内核：两台“机器”是同一主机上的两个内核挂载，不是独立内核。旧镜像已在 Apple Silicon 上成功挂载；替换后的镜像与新探针尚未经过 Docker 实测。

运行 `./mvnw -q verify`，再从仓库根目录运行各脚本。每次调用都新建 volume 和挂载，确保 B 的缓存从已知状态开始；trap 即使失败也运行 `docker compose down -v`。

```sh
./scripts/observe.sh cached
./scripts/observe.sh close-to-open
./scripts/observe.sh noac
./scripts/observe.sh write
./scripts/observe.sh v4
```

- `cached`：NFSv3 `vers=3,nolock,actimeo=10`。A 覆盖并关闭文件时 B 保持同一 open。预期 `initial open: before`、`same open, immediate: before`、`same open, after actimeo: after!`。Docker Desktop for macOS 上旧镜像的一次运行打印了此结果。
- `close-to-open`：相同 NFSv3 挂载，但 B 在 A 关闭后、十秒超时前立即关闭并重开。预期 `close then reopen: after!`。
- `noac`：关闭 NFSv3 属性缓存。预期立即读到 `after!`；脚本从 B 的 `/proc/self/mountstats` 打印 `GETATTR` 调用前后计数，展示额外元数据流量。实际计数不固定。
- `write`：B 使用 `noac`，隔离写方策略。A 写入后保持文件打开；比较默认 async 和 `sync` 挂载下，A 关闭或调用 `fsync` 前 B 的读取。预期 async 可保持 `before` 直到刷新或关闭；`fsync` 和 `sync` 会更早使数据可见。内核可能提前刷新 async 写入，因此输出是真实观察，不保证固定值。
- `v4`：NFSv4.2 `actimeo=10` 重复 open-reader 探针。旧镜像的一次运行打印出立即读到 `after!`：B 获得 read delegation，A 打开写入时触发 recall。若内核导出 delegation 行，脚本从 mountstats 打印；若没有，fresh read 与 recall 一致，但不能单独证明 grant。

server 同时导出 NFSv3 (`server:/data`) 和 NFSv4 (`server:/`)。这些内核缓存语义不同于 Stubline 票据使用的整对象 PUT/GET 接口。

## 许可证

本仓库采用 [MIT License](LICENSE)。

## 关于本仓库

本仓库包含一项针对 Stubline 的独立实验。README 说明运行命令与观察结果。

本仓库的代码与文档借助 AI 工具编写；记录的输出都来自实际运行。
