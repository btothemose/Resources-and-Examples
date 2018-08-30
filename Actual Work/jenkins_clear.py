#!/bin/python

###########################################################
# UNFINISHED, DO NOT USE THIS ON ANY LIVE JENKINS SERVERS #
###########################################################
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
    if file_mod_time < (current_time - (days_to_keep*86400)):
        print
        print ("Deleting %s") % (full_path_to_file)
        os.remove(full_path_to_file)
    else:
        sys.stdout.write('.')
        sys.stdout.flush()
        break
