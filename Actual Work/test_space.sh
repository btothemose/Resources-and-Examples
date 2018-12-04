#!/bin/bash

var=t

case $var in
    "" ) echo "empty";;
    * ) echo "test";;
esac

echo "complete"