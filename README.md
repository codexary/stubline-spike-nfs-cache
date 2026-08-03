English | [简体中文](README.zh-CN.md)

# NFS client cache spike

The server uses a pinned Debian 12.12 image with `nfs-kernel-server` and `nfs-common`; the clients use pinned Ubuntu 24.04, and both images support arm64 and amd64. The containers need `privileged: true` to start kernel NFS services and mount NFS filesystems. On Docker Desktop for macOS, the server and both clients share the Docker VM's Linux kernel: these two “machines” are separate kernel mounts on one host, not independent kernels. The server enables NFSv3 and NFSv4; it does not request NFSv2, which current kernels no longer support.

Run `./mvnw -q verify`, then each script from the repository root. Every invocation creates a fresh volume and mounts, so B's cache starts in a known state. On exit and between the three `write` policies, the script unmounts both clients before `docker compose down -v`. The server's SIGTERM handler unexports the data and stops the kernel NFS threads, mount daemon, and port mapper. Run each command twice in a row and check that `docker compose ps -a` lists no containers after each run.

```sh
./scripts/observe.sh cached
./scripts/observe.sh close-to-open
./scripts/observe.sh noac
./scripts/observe.sh write
./scripts/observe.sh v4
```

- `cached` (expected until recorded on this image): NFSv3 `vers=3,nolock,actimeo=10`. B keeps one file open while A closes a replacement. The expected lines are `initial open: before`, `same open, immediate: before`, and `same open, after actimeo: after!`; the final `close then reopen:` line should report `after!`. A run with the earlier image printed the first three lines.
- `close-to-open` (run with NFSv2 disabled): the same NFSv3 mount, but B closes and reopens immediately after A's close. The output was `initial open: before`, `same open, immediate: before`, `close then reopen: after!`.
- `noac` (expected until recorded): NFSv3 with attribute caching disabled. Expected lines are `initial open: before`, `same open, immediate: after!`, and `close then reopen: after!`. The script also prints `NFSv3 GETATTR calls before=... after=... delta=...` from B's `/proc/self/mountstats`; the counts vary.
- `write` (expected until recorded): B uses `noac` to isolate writer policy. For each `write policy: async|fsync|sync`, expect `B initial: before`, then `B while A keeps file open:` and `B after A fsync/close: after!`. The middle read may show `before` for async and may show `after!` after the kernel flushes; `fsync` is called only after that middle read, so it cannot change the value already printed. A `sync` mount can make the middle read show `after!` sooner. The script prints `writer has written but remains open`, then `writer called fsync` for that policy, and `writer closed`.
- `v4` (expected until recorded on this image): NFSv4.2 with `actimeo=10` repeats the open-reader probe. Expected lines are `initial open: before`, `same open, immediate: after!`, and `close then reopen: after!`; the earlier image showed an immediate fresh read. The script prints delegation lines from mountstats if that kernel exports them. A fresh read alone does not prove a delegation was granted and recalled.

The server exports both NFSv3 (`server:/data`) and NFSv4 (`server:/`). These kernel cache semantics differ from the whole-object PUT/GET interface used for Stubline tickets.

## License

This repository is licensed under the [MIT License](LICENSE).

## About this repository

This repository contains a focused Stubline experiment. The README documents its commands and observed results.

The code and documents in this repository were written with the help of AI tools; every recorded output comes from actually running them.
