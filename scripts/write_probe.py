import os
import sys
import time
from pathlib import Path

path = "/mnt/shared/cache-observation.txt"
marker = Path("/tmp/release-writer")
marker.unlink(missing_ok=True)
with open(path, "w", encoding="utf-8") as handle:
    handle.write("after!\n")
    handle.flush()
    print("writer has written but remains open", flush=True)
    while not marker.exists():
        time.sleep(0.1)
    if sys.argv[1] == "fsync":
        os.fsync(handle.fileno())
        print("writer called fsync", flush=True)
print("writer closed", flush=True)
