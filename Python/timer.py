#!/bin/python

# Python library package example

import time

# from time import localtime, strftime, mktime
# above would import specific used functions from time
# instead of entire file

start_time = time.localtime()

print("Timer start at %s" % time.strftime("%X", start_time))

raw_input("Press Enter/Return to continue")

stop_time=time.localtime()

difference=time.mktime(stop_time)-time.mktime(start_time)

print("Timer stopped at %s" % time.strftime("%X", stop_time))
print("Total time elapsed: %s" % difference)
