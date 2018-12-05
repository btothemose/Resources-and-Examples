#!/bin/bash

read -p "enter something " var

case $var in
    "s" ) ;;
    * ) echo "bad";;
esac

echo "complete"