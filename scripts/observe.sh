#!/usr/bin/env bash
set -euo pipefail
mode=${1:-cached}
case "$mode" in
  cached|close-to-open|noac|write|v4) ;;
  *) echo 'Usage: scripts/observe.sh cached|close-to-open|noac|write|v4' >&2; exit 2 ;;
esac
log=
probe_pid=
cleanup() {
  if [[ -n "$probe_pid" ]]; then wait "$probe_pid" 2>/dev/null || true; fi
  if [[ -n "$log" ]]; then rm -f "$log"; fi
  docker compose down -v
}
trap cleanup EXIT

start_stack() {
  docker compose down -v
  docker compose up --build -d --wait
  for client in client-a client-b; do
    docker compose exec -T "$client" mkdir -p /mnt/shared
    if [[ "$mode" == v4 ]]; then
      docker compose exec -T "$client" mount -t nfs4 -o vers=4.2,actimeo=10 server:/ /mnt/shared
    else
      options=vers=3,nolock,actimeo=10
      if [[ "$mode" == noac || ( "$mode" == write && "$client" == client-b ) ]]; then options=vers=3,nolock,noac; fi
      if [[ "$mode" == write && "$client" == client-a && "${policy:-}" == sync ]]; then options=vers=3,nolock,actimeo=10,sync; fi
      docker compose exec -T "$client" mount -t nfs -o "$options" server:/data /mnt/shared
    fi
  done
  docker compose exec -T client-a sh -c 'printf "before\n" > /mnt/shared/cache-observation.txt; sync'
  # A fresh volume and fresh mounts start every experiment without a previous attribute entry.
}

wait_for_line() {
  local pattern=$1
  for attempt in {1..100}; do
    if grep -q "$pattern" "$log"; then return; fi
    sleep 0.1
  done
  echo "Timed out waiting for $pattern" >&2
  exit 1
}

if [[ "$mode" == write ]]; then
  for policy in async fsync sync; do
    start_stack
    printf '\nwrite policy: %s\n' "$policy"
    printf 'B initial: '
    docker compose exec -T client-b cat /mnt/shared/cache-observation.txt
    log=$(mktemp)
    docker compose exec -T client-a python3 /opt/spike/write_probe.py "$policy" > "$log" &
    probe_pid=$!
    wait_for_line 'writer has written'
    printf 'B while A keeps file open: '
    docker compose exec -T client-b cat /mnt/shared/cache-observation.txt
    docker compose exec -T client-a touch /tmp/release-writer
    wait "$probe_pid"
    probe_pid=
    cat "$log"
    printf 'B after A fsync/close: '
    docker compose exec -T client-b cat /mnt/shared/cache-observation.txt
    rm -f "$log"
    log=
  done
else
  start_stack
  if [[ "$mode" == noac ]]; then
    before=$(docker compose exec -T client-b python3 /opt/spike/getattr.py | tr -d '\r')
  fi
  log=$(mktemp)
  docker compose exec -T client-b python3 /opt/spike/probe.py "$mode" > "$log" &
  probe_pid=$!
  wait_for_line 'initial open:'
  docker compose exec -T client-a sh -c 'printf "after!\n" > /mnt/shared/cache-observation.txt; sync'
  wait "$probe_pid"
  probe_pid=
  cat "$log"
  if [[ "$mode" == noac ]]; then
    after=$(docker compose exec -T client-b python3 /opt/spike/getattr.py | tr -d '\r')
    printf 'NFSv3 GETATTR calls before=%s after=%s delta=%s\n' "$before" "$after" "$((after-before))"
  fi
  if [[ "$mode" == v4 ]]; then
    printf 'NFSv4 delegation counters, when exported by this kernel:\n'
    docker compose exec -T client-b sh -c "grep -i delegation /proc/self/mountstats || true"
  fi
fi
