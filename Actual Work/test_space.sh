#!/bin/bash
printf "Proceed with target ironchef master section? (y/n)"
read ictp
if [[ $ictp != y ]];
then
	printf "Terminating."
	exit 1
fi
printf "test"