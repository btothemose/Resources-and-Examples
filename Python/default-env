#!/bin/python

import os

# OS Package used for environment variables

stage=(os.getenv("STAGE") or "development").upper()

# If env variable isn't stated before running script,
# the script will default to "development" string entry.

output = "We're running in %s" % stage

if stage.startswith("PROD"):
    output = "DANGER!!! - " + output

print(output)
