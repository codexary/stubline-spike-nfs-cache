from pathlib import Path

mount = False
for line in Path("/proc/self/mountstats").read_text().splitlines():
    if line.startswith("device "):
        mount = " mounted on /mnt/shared " in line
    elif mount and line.strip().startswith("GETATTR:"):
        print(line.split(":", 1)[1].split()[0])
        break
else:
    raise SystemExit("GETATTR count unavailable in mountstats")
