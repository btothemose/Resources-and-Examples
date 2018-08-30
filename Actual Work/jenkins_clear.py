#!/bin/python

import sys,time,os
days_to_keep=120
current_time=time.time()

def sort_dir(dir):
    def getmtime(file):
        path = os.path.join(dir.file)
        return os.path.getmtime(path)
    return sorted(os.listdir(dir), key=getmtime, reverse=False)

for file in sort_dir(path):
    full_path_to_file=os.path.join(path,file)
    file_mod_time=os.stat(full_path_to_file).st_mtime
    file_age=(current_time - file_mod_time)/86400
    
