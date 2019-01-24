#!/usr/bin/python/

import os
from fabric.api import *

host="prod-ebcp03.dub.baynote.net"
command="pwd"

env.user = os.getenv('ben.moseley', 'vagrant')
env.password = os.getenv('password', 'vagrant')

@hosts(host)
def do_something():
    run(command)