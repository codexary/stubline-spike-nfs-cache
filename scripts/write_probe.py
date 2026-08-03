import os
import sys
import time
from pathlib import Path

path = "/mnt/shared/cache-observation.txt"
fsync_marker = Path("/tmp/release-writer")
close_marker = Path("/tmp/close-writer")
fsync_marker.unlink(missing_ok=True)
close_marker.unlink(missing_ok=True)
with open(path, "w", encoding="utf-8") as handle:
    handle.write("after!\n")
    handle.flush()
    print("writer has written but remains open", flush=True)
    while not fsync_marker.exists():
        time.sleep(0.1)
    if sys.argv[1] == "fsync":
        os.fsync(handle.fileno())
        print("writer called fsync", flush=True)
        while not close_marker.exists():
            time.sleep(0.1)
print("writer closed", flush=True)
