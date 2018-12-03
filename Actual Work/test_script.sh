#!/bin/bash

##############################
# Preliminary user check
##############################

if [[ "$(whoami)" != "bnadmin" ]];
then
	printf "Must be executed as bnadmin."
	exit 1
fi

##############################
# Establishing the customer and ironchef master
##############################

printf "Which customer will you be migrating today? (format: cust code)\n"
read cust code
printf "Finding ironchef master for ${cust}_${code}\n"
oldbn=$(ssh bn03ms01 "find-customer ${cust} ${code}")
if [[ ${oldbn} == Usag* ]];
then
	printf "Nope, you made a typo. Bye.\n"
	exit 1
elif [[ ${oldbn} == "" ]];
then
	printf "${cust}_${code} not found anywhere. You should either panic or check your spelling.\n"
	exit 1
fi
printf ${cust}"_"${code}" found on "${oldbn}". Continue? (y/n)\n"
read cont1

##############################
# Establishing the target ironchef master
##############################

if [[ $cont1 == y || $cont1 == Y ]];
then
	printf "Which ironchef master will you be moving to? (format: bn03)\n"
	read newbn
elif [[ $cont1 == n || $cont1 == N ]];
then
	printf "Fine then. Be that way.\n"
	exit 1
else
	printf "What? That's not a yes or no. Come back sober.\n"
	exit 1
fi

##############################
# Creating FQDN out of the oldbn variable
##############################

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
	printf "Error; ironchef master does not exist. This script is probably outdated or otherwise broken.\n"
	exit 1
fi

##############################
# Creating FQDN out of the newbn variable
##############################

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
	printf "Error; ironchef master does not exist. Did you make a typo? You do that sometimes.\n"
	exit 1
fi

##############################
# Validation check
##############################

printf "About to proceed with bnTransferCustomer for ${cust}_${code} on ${fqobn} to ${fqnbn}\nContinue? (y/n)\n"
read ictp1
if [[ $ictp1 != y ]];
then
	printf "Terminating.\n"
	exit 1
fi

##############################
# bnTransferCustomer portion
##############################

printf "Beginning bnTransferCustomer for ${cust}_${code} from ${fqobn} to ${fqnbn}\n"
ssh $fqobn "bnTransferCustomer -c ${cust} ${code} -m ${fqnbn}"
printf "bnTransferCustomer complete for ${cust}_${code} from ${fqobn} to ${fqnbn}.\n"

##############################
# Validation check
##############################

printf "Proceed with ${fqnbn} section? (y/n)\n"
read ictp2
if [[ $ictp2 != y ]];
then
	printf "Terminating.\n"
	exit 1
fi

##############################
# Target ironchef master portion
##############################

printf "Copying/moving transferred data on target ironchef master.\n"
printf "Copying ${cust}-${code}-transfer/config/\n"
step1=$(ssh $fqnbn cp -a /var/tmp/Migration/${cust}-${code}-transfer/config/* /usr/local/baynote/config/customers/)
printf "Config cp output:\n${step1}\n"
printf "Moving ${cust}-${code}-transfer/data/\n"
step2=$(ssh $fqnbn mv /var/tmp/Migration/${cust}-${code}-transfer/data/* /usr/local/baynote/data/)
printf "Config mv output:\n${step2}\nContinue? (y/n)\n"
read step2cont
if [[ $step2cont != y ]];
    then
        printf "Terminating. Please finish process manually.\n"
        exit 1
fi
printf "Creating ${cust}_${code} database\n"
step3=$(ssh $fqnbn bndb -e "create database ${cust}_${code}")
printf "Master database creation output:\n${step3}\n"
step4=$(ssh $fqnbn "for db in ${cust}_${code}; do for i in {1..2}; do ssh ${oldbn}qs0${i} \"bndb -e \\\"create database ${db};\\\"\";done;done;")
printf "Question database creation output:\n${step4}\nContinue? (y/n)\n"
read step4cont
if [[ $step4cont != y ]];
    then
        printf "Terminating. Please finish process manually.\n"
        exit 1
fi
printf "Appending cluster.xml to include ${cust}-${code}\n"
step5=$(ssh $fqnbn sed -i "\$i  <customer name=\"${cust}\" code=\"${code}\" template=\"NORMAL1\"/>" /usr/local/baynote/config/cluster.xml)
printf "Cluster.xml insertion output:\n${step5}\n"
step6=$(ssh $fqnbn bnSyncThisCluster -y)
printf "Cluster sync output:\n${step6}\nContinue? (y/n)\n"
read step6cont
if [[ $step6cont != y ]];
    then
        printf "Terminating. Please finish process manually.\n"
        exit 1
fi
printf "Sql transfer and replication beginning\n"
step7=$(ssh $fqnbn "gunzip -c /var/tmp/Migration/${cust}-${code}-transfer/sql/${cust}_${code}.sql.gz | sed \"s/${oldbn}/${newbn}/g\" | bndb replication")
printf "Sql transfer gzip output:\n${step7}\n"
step8=$(ssh $fqnbn bnsctl StartCustomer ${cust} ${code})
printf "Master server customer start output:\n${step8}\n"
step9=$(ssh $fqnbn "for i in {1..2}; do ssh ${oldbn}qs0${i} \"bnsctl StartCustomer ${cust} ${code}; bnscript -c ${cust} ${code} -f\";done;")
printf "Question servers customer start output:\n${step9}\n"
printf "Continue? (y/n)\n"
read step9cont
if [[ $step9cont != y ]];
    then
        printf "Terminating. Please finish process manually.\n"
        exit 1
fi
printf "Copied/moved transferred data on $fqnbn.\n${cust}_${code} database created on master and question servers.\n"
printf "${cust}_{$code} has been added to cluster.xml. \nExecute baynote-restart when safe to do so.\n"

##############################
# Fabric deploy portion
##############################

printf "Script end.\nFabric commands portion not yet implemented."