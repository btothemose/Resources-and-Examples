#!/bin/bash

#####
# Establishing the customer and ironchef master
#####
echo "Which customer will you be migrating today? (format: cust code)"
read cust code
echo "Finding ironchef master for "$cust"_"$code
oldbn=$(ssh bn03ms01 "find-customer $cust $code")
if [[ $oldbn == Usag* ]];
then
	echo "Nope, you made a typo. Bye."
	exit 1
elif [[ $oldbn == "" ]];
then
	echo $cust"_"$code" not found anywhere. You should either panic or check your spelling."
	exit 1
fi
echo $cust"_"$code" found on "$oldbn". Continue? (y/n)"
read cont1

#####
# Establishing the target ironchef master
#####
if [[ $cont1 == y || $cont1 == Y ]];
then
	echo "Which ironchef master will you be moving to? (format: bn03)"
	read newbn
elif [[ $cont1 == n || $cont1 == N ]];
then
	echo "Fine then. Be that way."
	exit 1
else
	echo "What? That's not a yes or no. Come back sober."
	exit 1
fi

#####
# Creating FQDN out of the oldbn variable
#####
if [[ $oldbn == bn03 || $oldbn == bn11 ]];
then
	fqobn=$oldbn"ms01.sjc01.baynote.net"
elif [[ $oldbn == bn20 || $oldbn == bn21 ]];
then
	fqobn=$oldbn"ms01.kord.baynote.net"
elif [[ $oldbn == bn40 || $oldbn == bn41 ]];
then
	fqobn=$oldbn"ms01.eham.baynote.net"
elif [[ $oldbn == bn50 ]];
then
	fqobn="bn50ms01.pdx01.baynote.net"
elif [[ $oldbn == bn60 ]];
then
	fqobn="bn60ms01.dub.baynote.net"
else
	echo "Error; ironchef master does not exist. This script is probably outdated or otherwise broken."
	exit 1
fi

#####
# Creating FQDN out of the newbn variable
#####
if [[ $newbn == bn03 || $newbn == bn11 ]];
then
	fqnbn=$newbn"ms01.sjc01.baynote.net"
elif [[ $newbn == bn20 || $newbn == bn21 ]];
then
	fqnbn=$newbn"ms01.kord.baynote.net"
elif [[ $newbn == bn40 || $newbn == bn41 ]];
then
	fqnbn=$newbn"ms01.eham.baynote.net"
elif [[ $newbn == bn50 ]];
then
	fqnbn="bn50ms01.pdx01.baynote.net"
elif [[ $newbn == bn60 ]];
then
	fqnbn="bn60ms01.dub.baynote.net"
else
	echo "Error; ironchef master does not exist. Did you make a typo? You do that sometimes."
	exit 1
fi

#####
# bnTransferCustomer portion
#####
echo "Beginning bnTransferCustomer for "$cust"_"$code" from $fqobn to $fqnbn"
# vvvvvvvvv Test Lines, Echo Actual Lines vvvvvvvvv
otest=$(ssh $fqobn "echo WOULD RUN: bnTransferCustomer -c $cust $code -m $fqnbn")
echo $otest
# vvvvvvvvv Actual Migration Lines vvvvvvvvv
# ssh $fqobn "bnTransferCustomer -c $cust $code -m $fqnbn"

#####
# Target ironchef master portion
#####
cppath="/var/tmp/Migration/"$cust"-"$code"-transfer/config/\* /usr/local/baynote/config/customers/"
mvpath="/var/tmp/Migration/"$cust"-"$code"-transfer/data/\* /usr/local/baynote/data/"
echo "Copying/moving transferred data on target ironchef master."
# vvvvvvvvv Test Lines, Echo Actual Lines vvvvvvvvv
ntest=$(ssh $fqnbn "echo WOULD RUN: cp -a $cppath; echo WOULD RUN: mv $mvpath")
echo $ntest
# vvvvvvvvv Actual Migration Lines vvvvvvvvv
# ssh $fqnbn "cp -a $cppath; mv $mvpath"
# echo $endout
