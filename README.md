English | [简体中文](README.zh-CN.md)

# NFS client cache spike

This experiment follows the ticket object's storage decision in Stubline backend ADR 0011, Store e-tickets as objects. It shows what a shared file-system mount asks the application to reason about: an open reader, cached attributes, a writer's close, and client write policy. Run it on a **Linux Docker host with NFS server kernel support**. The server image `erichough/nfs-server:2.2.1` requires `privileged: true` (or at least `CAP_SYS_ADMIN` plus kernel support); the clients require mount privileges. The image is amd64-only and old. Docker Desktop for macOS runs containers in a separate Linux VM whose NFS kernel modules may be unavailable, so this experiment is not claimed to run there.

Run `./mvnw -q verify` for the Java project and `./scripts/observe.sh cached` for the kernel-backed experiment. The script starts one server and two clients, mounts the same NFSv4 export on both with `actimeo=10`, has A write `before`, lets B open it, then has A overwrite it with `after!`. B reads immediately through its still-open handle, reads again after 11 seconds, then closes and reopens. The output labels are fixed; **the values are observations, not hard-coded expectations**. A typical cache trace is `before`, `before`, `after!`, `after!`; close-to-open normally makes the final read `after!`. NFS client implementations and server timing can make the immediate read fresh, so compare actual output rather than treating a stale read as guaranteed.

Run `./scripts/observe.sh noac` and `./scripts/observe.sh sync` and compare the four labelled values. `noac` disables attribute caching and usually shortens the stale interval at a metadata and network cost. `sync` asks the client to send writes synchronously; it changes write acknowledgement and latency, not the cache's read freshness guarantee. `actimeo=10` bounds attribute cache time, not every possible data-cache observation. The attribute-cache freshness interval corresponds to this tradeoff: a longer interval saves lookups but can show older metadata. Its write policy corresponds to choosing when a writer waits for remote persistence.

The scripts print real values only after a successful mount. If `mount` reports `Operation not permitted`, `nfsd` cannot start, or the export is unavailable, stop and record that failure; do not substitute a bind mount. `docker compose down -v` removes the experiment's data.

## License

This repository is licensed under the [MIT License](LICENSE).

## About this repository

This repository contains a focused Stubline experiment. The README documents its commands and observed results.

The code and documents in this repository were written with the help of AI tools; every recorded output comes from actually running them.
