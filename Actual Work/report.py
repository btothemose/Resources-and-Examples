#!/usr/bin/python/

import subprocess
import sys

host="prod-ebcp03.dub.baynote.net"
command="pwd"

ssh = subprocess.Popen(["ssh", "%s" % host, command],
                            shell=False,
                            stdout=subprocess.PIPE,
                            stderr=subprocess.PIPE)
result = ssh.stdout.readlines()
if result == []:
    error = ssh.stderr.readlines()
    print >>sys.stderr, "ERROR: %s" % error
else:
    print result