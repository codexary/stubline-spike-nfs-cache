[English](README.md) | 简体中文

# NFS 客户端缓存小项目

这个实验接续 Stubline 后端 ADR 0011《将电子票存为对象》的存储决策，展示共享文件系统挂载需要应用考虑的因素：已打开的读取句柄、属性缓存、写入方关闭文件以及客户端写策略。请在**支持 NFS server 内核模块的 Linux Docker 主机**上运行。`erichough/nfs-server:2.2.1` 需要 `privileged: true`（或者至少 `CAP_SYS_ADMIN` 加内核支持），客户端挂载也需要特权。该旧镜像只有 amd64。macOS Docker Desktop 的容器运行在独立 Linux VM，可能缺少 NFS 内核模块，因此这里不声称该实验能在其上运行。

运行 `./mvnw -q verify` 验证 Java 项目；运行 `./scripts/observe.sh cached` 进行真实内核 NFS 实验。脚本启动一个 server 和两个 client，并以 `actimeo=10` 将同一 NFSv4 export 挂载到两端。A 先写入 `before`，B 打开文件，A 随后覆盖成 `after!`。B 通过未关闭的句柄立即再读，11 秒后再读，最后关闭并重新打开。输出标签固定；**读到的值是真实观察，不是脚本写死的预期**。典型缓存轨迹为 `before`、`before`、`after!`、`after!`；close-to-open 通常让最后一次读取看到 `after!`。客户端实现和时序也可能让立即读取就看到新值，因此应比较实际输出，不能假定必有旧读。

再运行 `./scripts/observe.sh noac` 和 `./scripts/observe.sh sync`，比较四处输出。`noac` 关闭属性缓存，通常缩短旧读窗口，但增加元数据查询和网络成本。`sync` 要求客户端同步发送写入，改变写入确认与延迟，不保证读取一定更新。`actimeo=10` 限定属性缓存时间，并非所有数据缓存现象的严格上界。属性缓存的 freshness interval 对应这一取舍：更长间隔节省查询但可能看到旧元数据；write policy 对应写入者何时等待远端持久化。

脚本只有挂载成功才会打印读取结果。若 `mount` 报 `Operation not permitted`、`nfsd` 无法启动或 export 不可用，就停止并记录失败，不能用 bind mount 代替。`docker compose down -v` 清除实验数据。

## 许可证

本仓库采用 [MIT License](LICENSE)。

## 关于本仓库

本仓库包含一项针对 Stubline 的独立实验。README 说明运行命令与观察结果。

本仓库的代码与文档借助 AI 工具编写；记录的输出都来自实际运行。
