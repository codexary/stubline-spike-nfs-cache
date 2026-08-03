English | [简体中文](README.zh-CN.md)

# NFS client cache spike

The server and clients use pinned Debian 12.12 images with `nfs-kernel-server` and `nfs-common`, which support both arm64 and amd64. The containers need `privileged: true` to start kernel NFS services and mount NFS filesystems. On Docker Desktop for macOS, the server and both clients share the Docker VM's Linux kernel: these two “machines” are separate kernel mounts on one host, not independent kernels. The previous server image mounted on Apple Silicon; the replacement image and revised probes have not yet been run in Docker.

Run `./mvnw -q verify`, then each script from the repository root. Every invocation creates a fresh volume and mounts, so B's cache starts in a known state, and a trap runs `docker compose down -v` even on failure.

```sh
./scripts/observe.sh cached
./scripts/observe.sh close-to-open
./scripts/observe.sh noac
./scripts/observe.sh write
./scripts/observe.sh v4
```

- `cached`: NFSv3 `vers=3,nolock,actimeo=10`. B keeps one file open while A closes a replacement. Expected shape: `initial open: before`, `same open, immediate: before`, `same open, after actimeo: after!`. A run on Docker Desktop for macOS with the earlier image printed these lines.
- `close-to-open`: the same NFSv3 mount, but B closes and reopens immediately after A's close, before the ten-second timeout. Expected `close then reopen: after!`.
- `noac`: NFSv3 with attribute caching disabled. Expected immediate `after!`; the script prints the actual before and after `GETATTR` counts from B's `/proc/self/mountstats`, exposing the extra metadata traffic. Counts vary.
- `write`: B uses `noac` to isolate writer policy. A holds the file open after a write; compare B's read before A closes or calls `fsync` under default async and `sync` mounts. Expected async may retain `before` until flush or close; `fsync` and `sync` force earlier visibility. Kernel timing may flush async writes sooner, so the printed values are observations, not a guarantee.
- `v4`: NFSv4.2 with `actimeo=10` repeats the open-reader probe. A run with the old image printed immediate `after!`:  a read delegation to B was recalled when A opened for writing. The script prints delegation lines from mountstats if that kernel exports them. If none appear, the fresh read is consistent with delegation recall but does not independently prove the grant.

The server exports both NFSv3 (`server:/data`) and NFSv4 (`server:/`). These kernel cache semantics differ from the whole-object PUT/GET interface used for Stubline tickets.

## License

This repository is licensed under the [MIT License](LICENSE).

## About this repository

This repository contains a focused Stubline experiment. The README documents its commands and observed results.

The code and documents in this repository were written with the help of AI tools; every recorded output comes from actually running them.
