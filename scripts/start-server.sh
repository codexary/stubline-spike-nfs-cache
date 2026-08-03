#!/bin/sh
set -eu
mountpoint -q /proc/fs/nfsd || mount -t nfsd nfsd /proc/fs/nfsd
rpcbind -w
exportfs -ra
rpc.nfsd -N 2 -V 3 -V 4 8
exec rpc.mountd -F
