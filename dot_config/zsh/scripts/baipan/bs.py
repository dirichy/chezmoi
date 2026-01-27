import builtins
import os
import sys
from datetime import datetime

import bypy

# 保存原始的 print 函数
original_print = print


cache = []
if len(sys.argv) > 1:
    rootpath = sys.argv[1]
else:
    rootpath = os.path.expanduser("~") + "/.bypy/cache/"


class bfile:
    def __init__(self, data: list[str]):
        self.name = data[1]
        self.type = data[2]
        self.size = int(data[3])
        self.time = datetime.strptime(data[4], "%Y-%m-%d, %H:%M:%S")
        self.hash = data[5]

    def __str__(self) -> str:
        return f"bfile(name={self.name}, type={self.type}, size={self.size}, time={self.time}, hash={self.hash})"


def new_print(output):
    splited = output.split("/")
    if len(splited) > 6:
        original_print(output)
    if splited[0] == "$":
        cache.append(bfile(data=splited))


builtins.print = new_print

b = bypy.ByPy()


def fetch_path(path: str):
    b.list(path, "$/$f/$t/$s/$m/$d")
    result = []
    global cache
    result, cache = cache, result
    for i in result:
        name = rootpath + path + "/" + i.name
        if i.type == "D":
            os.makedirs(exist_ok=True, name=name)
            os.utime(name, (i.time.timestamp(), i.time.timestamp()))
            fetch_path(path + "/" + i.name)
        else:
            with open(name, "w"):
                pass
            os.utime(name, (i.time.timestamp(), i.time.timestamp()))


fetch_path("/")
