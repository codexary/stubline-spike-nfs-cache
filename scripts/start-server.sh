#!/bin/sh
set -eu
mountpoint -q /proc/fs/nfsd || mount -t nfsd nfsd /proc/fs/nfsd
mountd_pid=
rpcbind_pid=
shutdown() {
  exportfs -ua || true
  rpc.nfsd 0 || true
  if [ -n "$mountd_pid" ]; then kill "$mountd_pid" 2>/dev/null || true; fi
  if [ -n "$rpcbind_pid" ]; then kill "$rpcbind_pid" 2>/dev/null || true; fi
  if [ -n "$mountd_pid" ]; then wait "$mountd_pid" 2>/dev/null || true; fi
  if [ -n "$rpcbind_pid" ]; then wait "$rpcbind_pid" 2>/dev/null || true; fi
}
trap 'exit 0' TERM INT
trap shutdown EXIT
rpcbind -w -f &
rpcbind_pid=$!
ready=0
for attempt in $(seq 1 50); do
  if rpcinfo -p >/dev/null 2>&1; then ready=1; break; fi
  sleep 0.1
done
if [ "$ready" -ne 1 ]; then echo "rpcbind did not become ready" >&2; exit 1; fi
exportfs -ra
rpc.nfsd -V 3 -V 4 8
rpc.mountd -F &
mountd_pid=$!
wait "$mountd_pid"
