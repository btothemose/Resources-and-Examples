#!/bin/python

import subprocess

code = subprocess.call(['ls','-l'])
if code==0:
    print("command finished successfully")
else:
    print("failed with code: %i" % code)

# output = subprocess.check_output(['ls','-z'])
# print(output)

try:
    output1=subprocess.check_output(
            ['ls', 'fakefile.txt'],
            stderr=subprocess.STDOUT
            )
except OSError as err:
    print("Caught OSError")
    output=err
except subprocess.CalledProcessError as err:
    print("Caught CalledProcessError")
    output=err
print(output)
