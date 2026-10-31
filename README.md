English | [简体中文](README.zh-CN.md)

# NFS client cache spike

BuildKit caches apt package indexes and downloads across image rebuilds, reducing download traffic, build time, and CI cost.

The server image is built on Debian 12.12 slim with `nfs-kernel-server` and `nfs-common`; the clients are built on Ubuntu 24.04. Both base images are pinned by digest in the Dockerfiles, so a rebuild uses the same base layers, and both support arm64 and amd64. The containers need `privileged: true` to start kernel NFS services and mount NFS filesystems. On Docker Desktop for macOS, the server and both clients share the Docker VM's Linux kernel: these two “machines” are separate kernel mounts on one host, not independent kernels. The server enables NFSv3 and NFSv4; it does not request NFSv2, which current kernels no longer support.

Run `./mvnw -q verify`, then each script from the repository root. Every invocation creates a fresh volume and mounts, so B's cache starts in a known state. On exit and between the three `write` policies, the script unmounts both clients before `docker compose down -v`. The server's SIGTERM handler unexports the data and stops the kernel NFS threads, mount daemon, and port mapper. Run each command twice in a row and check that `docker compose ps -a` lists no containers after each run.

```sh
./scripts/observe.sh cached
./scripts/observe.sh close-to-open
./scripts/observe.sh noac
./scripts/observe.sh write
./scripts/observe.sh v4
```

- `cached`: recorded `initial open: before`, `same open, immediate: before`, `same open, after actimeo: after!`, `close then reopen: after!`.
- `close-to-open`: recorded `initial open: before`, `same open, immediate: before`, `close then reopen: after!`.
- `noac`: recorded `initial open: before`, `same open, immediate: after!`, `close then reopen: after!`, and `NFSv3 GETATTR calls before=2 after=15 delta=13`. The counters vary by run.
- `write`: the recorded run shows B reading an empty value while A keeps the file open with `async` and `fsync`. After A calls `fsync`, B reads `after!` before close; with `sync`, B reads `after!` while A still holds the file open. B reads `after!` after close for all three policies. See [the recorded write run](docs/recorded-runs/write-policy.md).
- `v4`: recorded `initial open: before`, `same open, immediate: after!`, `close then reopen: after!`. The kernel exposed no delegation counters in client mountstats, so the script no longer prints an empty delegation heading. Fresh data alone does not prove that a delegation was granted or recalled. Inspect `/proc/fs/nfsd/clients/*/states` on the server during a held-open file if delegation evidence is needed.

The server exports both NFSv3 (`server:/data`) and NFSv4 (`server:/`). These kernel cache semantics differ from the whole-object PUT/GET interface used for Stubline tickets.

## License

This repository is licensed under the [MIT License](LICENSE).

## About this repository

This repository contains a focused Stubline experiment. The README documents its commands and observed results.

The code and documents in this repository were written with the help of AI tools; every recorded output comes from actually running them.

## Findings

The experiment results and their effect on the backend decision are recorded in [FINDINGS.md](FINDINGS.md).
