import time

path = "/mnt/shared/cache-observation.txt"
with open(path, "r", encoding="utf-8") as handle:
    print("initial open:", handle.read().strip(), flush=True)
    time.sleep(2)
    handle.seek(0)
    print("same open, immediate:", handle.read().strip(), flush=True)
    time.sleep(11)
    handle.seek(0)
    print("same open, after actimeo:", handle.read().strip(), flush=True)
with open(path, "r", encoding="utf-8") as handle:
    print("close then reopen:", handle.read().strip(), flush=True)
