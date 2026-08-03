#!/usr/bin/env bash
set -euo pipefail
mode=${1:-cached}
case "$mode" in
  cached) options=actimeo=10 ;;
  noac) options=noac ;;
  sync) options=actimeo=10,sync ;;
  *) echo 'Usage: scripts/observe.sh cached|noac|sync' >&2; exit 2 ;;
esac
docker compose up --build -d
for client in client-a client-b; do
  docker compose exec -T "$client" mkdir -p /mnt/shared
  docker compose exec -T "$client" sh -c 'mountpoint -q /mnt/shared && umount /mnt/shared || true'
  docker compose exec -T "$client" mount -t nfs4 -o "vers=4,$options" server:/ /mnt/shared
done
docker compose exec -T client-a sh -c 'printf "before\n" > /mnt/shared/cache-observation.txt; sync'
log=$(mktemp)
docker compose exec -T client-b python3 /opt/spike/probe.py > "$log" &
probe_pid=$!
trap 'wait "$probe_pid" 2>/dev/null || true; rm -f "$log"' EXIT
for attempt in {1..50}; do
  if grep -q 'initial open:' "$log"; then break; fi
  sleep 0.1
done
if ! grep -q 'initial open:' "$log"; then echo 'Client B did not begin reading' >&2; exit 1; fi
docker compose exec -T client-a sh -c 'printf "after!\n" > /mnt/shared/cache-observation.txt; sync'
wait "$probe_pid"
cat "$log"
