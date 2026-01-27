import builtins
import os
import sys
import threading
from datetime import datetime
from concurrent.futures import ThreadPoolExecutor, as_completed
from queue import Queue

import bypy


MAX_WORKERS = 1024
executor = ThreadPoolExecutor(max_workers=MAX_WORKERS)

thread_local = threading.local()
original_print = builtins.print


class bfile:
    def __init__(self, data: list[str]):
        self.name = data[1]
        self.type = data[2]
        self.size = int(data[3])
        self.time = datetime.strptime(data[4], "%Y-%m-%d, %H:%M:%S")
        self.hash = data[5]


def new_print(output):
    splited = output.split("/")
    if len(splited) > 6:
        original_print(output)
        return

    if splited[0] == "$":
        if not hasattr(thread_local, "cache"):
            thread_local.cache = []
        thread_local.cache.append(bfile(splited))


builtins.print = new_print

b = bypy.ByPy()

# rootpath
if len(sys.argv) > 1:
    rootpath = sys.argv[1]
else:
    rootpath = os.path.expanduser("~") + "/.bypy/cache/"


# ------------------------------
# 线程池要做的任务：列目录 + 建文件
# ------------------------------
def process_dir(path: str):
    # 初始化当前线程 cache
    thread_local.cache = []

    # 调 b.list
    b.list(path, "$/$f/$t/$s/$m/$d")

    # 返回刚产生的子文件/目录
    return path, thread_local.cache


# ------------------------------
# 主调度循环（不会死锁）
# ------------------------------
def run():
    q = Queue()
    q.put("/")

    futures = []
    active = 0  # 当前线程池任务数量

    results = []

    while not q.empty() or active:
        # 如果队列有目录、线程池有空闲 → 提交任务
        while not q.empty() and active < MAX_WORKERS:
            p = q.get()
            fut = executor.submit(process_dir, p)
            futures.append(fut)
            active += 1

        # 处理已完成任务
        done = [f for f in futures if f.done()]
        for f in done:
            futures.remove(f)
            active -= 1

            path, items = f.result()

            for i in items:
                local_path = os.path.join(rootpath, path.lstrip("/"), i.name)

                if i.type == "D":
                    os.makedirs(local_path, exist_ok=True)
                    ts = i.time.timestamp()
                    os.utime(local_path, (ts, ts))

                    # 子目录放回队列，而不是递归 submit
                    subpath = path.rstrip("/") + "/" + i.name
                    q.put(subpath)

                else:
                    os.makedirs(os.path.dirname(local_path), exist_ok=True)
                    with open(local_path, "w"):
                        pass
                    ts = i.time.timestamp()
                    os.utime(local_path, (ts, ts))


run()
executor.shutdown()
