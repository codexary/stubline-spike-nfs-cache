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
exportfs -ra
rpc.nfsd -V 3 -V 4 8
rpc.mountd -F &
mountd_pid=$!
wait "$mountd_pid"
