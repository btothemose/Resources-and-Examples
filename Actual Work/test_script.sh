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
# Required variable input
##############################

read -p "Which customer will you be migrating today? (format: cust code)" cust code
read -p "Which bn master will you be moving to? (format: bn01)" newbn

##############################
# Establishing the customer and bn master
##############################

findMaster() {
    printf "Finding bn master for ${cust}_${code}\n"
    oldbn=$(ssh bn03ms01 "find-customer ${cust} ${code}")
    case "$oldbn" in
        Usag* ) printf "Nope, you made a typo. Terminating.\n";;
        bn* ) printf "${cust}_${code} found on ${oldbn}.\n";;
        * ) printf "${cust}_${code} not found anywhere. You should either panic or check your spelling.\n"
            exit 1;;
    esac
}

##############################
# Creating FQDN out of the oldbn variable
##############################

oldMasterDomain() {
    case "${oldbn}" in
        bn03|bn11 ) fqobn="${oldbn}ms01.sjc01.baynote.net";;
        bn20|bn21 ) fqobn="${oldbn}ms01.kord.baynote.net";;
        bn40|bn41 ) fqobn="${oldbn}ms01.eham.baynote.net";;
        bn50 ) fqobn="bn50ms01.pdx01.baynote.net";;
        bn60 ) fqobn="bn60ms01.dub.baynote.net";;
        * ) printf "Error; bn master does not exist. This script is probably outdated or otherwise broken.\n"
            exit 1;;
    esac
}

##############################
# Creating FQDN out of the newbn variable
##############################

newMasterDomain() {
    case "${newbn}" in
        bn03|bn11 ) fqnbn="${newbn}ms01.sjc01.baynote.net";;
        bn20|bn21 ) fqnbn="${newbn}ms01.kord.baynote.net";;
        bn40|bn41 ) fqnbn="${newbn}ms01.eham.baynote.net";;
        bn50 ) fqnbn="bn50ms01.pdx01.baynote.net";;
        bn60 ) fqnbn="bn60ms01.dub.baynote.net";;
        * ) printf "Error; bn master does not exist. This script is probably outdated or otherwise broken.\n"
            exit 1;;
    esac
}

##############################
# Individual functions for original bn master steps
##############################

bnTransfer() {
    read -p "About to proceed with bnTransferCustomer for ${cust}_${code} on ${fqobn} to ${fqnbn}\nContinue? (y/n) " ictp1
    case "$ictp1" in
        y|Y ) printf "Beginning bnTransferCustomer for ${cust}_${code} from ${fqobn} to ${fqnbn}\n";;
        * ) printf "Terminating.\n"
            exit 1;;
    esac
    ssh $fqobn "bnTransferCustomer -c ${cust} ${code} -m ${fqnbn}"
    printf "bnTransferCustomer complete for ${cust}_${code} from ${fqobn} to ${fqnbn}.\n"
}
bnExportThor() {
    read -p "About to proceed with bnexport for ${cust}_${code} on ${fqobn} to ${fqnbn}\nContinue? (y/n) " ttp1
    if [[ $ttp1 != y || $ttp1 != Y ]];
    then
        printf "Terminating.\n"
        exit 1
    fi
    printf "Beginning bnexport for ${cust}_${code} from ${fqobn} to ${fqnbn}\n"
    ssh ${fqobn} "bnexport ${cust} ${code} --noMappers --noAPU --noObservations"
    ssh ${fqnbn} "mkdir -p /var/tmp/Migration/${cust}/"
    ssh ${fqobn} "rsync -aiv /home/OPS/customer_exports/bnc_files/${cust}-${code}-*.bnc ${fqnbn}:/var/tmp/Migration/"
    printf "bnexport complete for ${cust}_${code} from ${fqobn} to ${fqnbn}.\n"
}

##############################
# Individual functions for target bn master steps
##############################

copyMoveData() {
    printf "Copying/moving transferred data on target bn master.\n"
    printf "Copying ${cust}-${code}-transfer/config/\n"
    step1=$(ssh $fqnbn cp -a /var/tmp/Migration/${cust}-${code}-transfer/config/* /usr/local/baynote/config/customers/)
    if [[ $step1 != "" ]];
    then
        printf "Config cp output:\n${step1}\n"
    fi
    printf "Moving ${cust}-${code}-transfer/data/\n"
    step2=$(ssh $fqnbn mv /var/tmp/Migration/${cust}-${code}-transfer/data/* /usr/local/baynote/data/)
    if [[ $step2 != "" ]];
    then
        printf "Config mv output:\n${step2}\n"
    fi
    printf "Continue? (y/n)\n"
    read step2cont
    if [[ $step2cont != y || $step2cont != Y ]];
        then
            printf "Terminating. Please finish process manually.\n"
            exit 1
    fi
}
createDatabase() {
    printf "Creating ${cust}_${code} database\n"
    step3=$(ssh $fqnbn bndb -e "create database ${cust}_${code}")
    printf "Master database creation output:\n${step3}\n"
    step4=$(ssh $fqnbn "for db in ${cust}_${code}; do for i in {1..2}; do ssh ${oldbn}qs0${i} \"bndb -e \\\"create database ${db};\\\"\";done;done;")
    printf "Question database creation output:\n${step4}\nContinue? (y/n)\n"
    read step4cont
    if [[ $step4cont != y || $step4cont != Y ]];
        then
            printf "Terminating. Please finish process manually.\n"
            exit 1
    fi
}
clusterSync() {
    printf "Appending cluster.xml to include ${cust}-${code}\n"
    step5=$(ssh $fqnbn sed -i "\$i  <customer name=\"${cust}\" code=\"${code}\" template=\"NORMAL1\"/>" /usr/local/baynote/config/cluster.xml)
    printf "Cluster.xml insertion output:\n${step5}\n"
    step6=$(ssh $fqnbn bnSyncThisCluster -y)
    printf "Cluster sync output:\n${step6}\nContinue? (y/n)\n"
    read step6cont
    if [[ $step6cont != y || $step6cont != Y ]];
        then
            printf "Terminating. Please finish process manually.\n"
            exit 1
    fi
}
sqlReplication() {
    printf "Sql transfer and replication beginning\n"
    step7=$(ssh $fqnbn "gunzip -c /var/tmp/Migration/${cust}-${code}-transfer/sql/${cust}_${code}.sql.gz | sed \"s/${oldbn}/${newbn}/g\" | bndb replication")
    printf "Sql transfer gzip output:\n${step7}\n"
    step8=$(ssh $fqnbn bnsctl StartCustomer ${cust} ${code})
    printf "Master server customer start output:\n${step8}\n"
    step9=$(ssh $fqnbn "for i in {1..2}; do ssh ${oldbn}qs0${i} \"bnsctl StartCustomer ${cust} ${code}; bnscript -c ${cust} ${code} -f\";done;")
    printf "Question servers customer start output:\n${step9}\n"
    printf "Continue? (y/n)\n"
    read step9cont
    if [[ $step9cont != y $step9cont != Y ]];
        then
            printf "Terminating. Please finish process manually.\n"
            exit 1
    fi
}
startCustomerOnly() {
    printf "Starting customer\n"
    step8a=$(ssh $fqnbn bnsctl StartCustomer ${cust} ${code})
    printf "Master server customer start output:\n${step8a}\n"
    step9a=$(ssh $fqnbn "for i in {1..2}; do ssh ${oldbn}qs0${i} \"bnsctl StartCustomer ${cust} ${code}; bnscript -c ${cust} ${code} -f\";done;")
    printf "Question servers customer start output:\n${step9a}\n"
    printf "Continue? (y/n)\n"
    read step9cont
    if [[ $step9cont != y $step9cont != Y ]];
        then
            printf "Terminating. Please finish process manually.\n"
            exit 1
    fi
}

##############################
# Target bn master portion - Ironchef
##############################

newMasterSetupIronchef() {
    printf "Proceed with ${fqnbn} section? (y/n)\n"
    read ictp2
    if [[ $ictp2 != y || $ictp2 != Y ]];
    then
        printf "Terminating. Please finish process manually.\n"
        exit 1
    fi
    copyMoveData
    createDatabase
    clusterSync
    sqlReplication
    printf "Copied/moved transferred data on $fqnbn.\n${cust}_${code} database created on master and question servers.\n"
    printf "${cust}_{$code} has been added to cluster.xml. \nExecute baynote-restart when safe to do so.\n"
}

##############################
# Target bn master portion - Thor
##############################

newMasterSetupThor() {
    printf "Proceed with ${fqnbn} section? (y/n)\n"
    read ttp2
    if [[ $ttp2 != y || $ttp2 != Y ]];
    then
        printf "Terminating. Please finish process manually.\n"
        exit 1
    fi
    createDatabase
    clusterSync
    startCustomerOnly
    printf "Copied/moved transferred data on $fqnbn.\n${cust}_${code} database created on master and question servers.\n"
    printf "${cust}_{$code} has been added to cluster.xml. \nExecute baynote-restart when safe to do so.\n"
}

##############################
# Fabric deploy portion
##############################

fabDeploy() {
    printf "Switching user to bnops. Continue? (y/n)\n"
    read bnops
    if [[ $bnops != y || $bnops != Y ]];
        then
            printf "Terminating. Please finish process manually.\n"
            exit 1
    fi
    sudo su - bnops
    ssh fabric01.sjc01.baynote.net << EOF
        cd /bnops/fabric/ic_deploy_config_alt/
        fab cust:${cust} code:${code} cluster:${newbn} copymode:scripts deploy
        fab cust:${cust} code:${code} cluster:${newbn} copymode:xsl deploy
        fab cust:${cust} code:${code} cluster:${newbn} copymode:customers deploy
EOF
        printf "Fab deploy commands complete. Disconnecting from fabric.\nSwitching user back to bnadmin\n"
        sudo su - bnadmin
}

##############################
# End of current interation
##############################

endOutput() {
    printf "Still to-do:
    > ${newbn}: sudo /home/OPS/refresh_cust.sh
    > ${newbn}: bnconfigdb update
    > ${newbn}: bnss
        (and look for issues)
    > ${newbn} > Schedule jobs, use info from ${oldbn}, and stop old jobs
    > ${newbn} > Add triggers to trigger file and bntrig reload
    > ${newbn} > Set gatherEvents lastEventId to 0
    > Update opsmanager (insights)
    > Ensure customer is loaded onto new recs
    > Ensure rec heap sizes are up-to-date
    > Check admin page and calls\n
When done with all of this:
    > Execute cutover in verisign
    > Update thorconfig
    > Ensure jobs are disabled on ${oldbn} and enabled on ${newbn}"
}

##############################
# Workflow selection and sequence
##############################

printf "Is this an Ironchef customer? (y/n)\n"
read answeric
if [[ $answeric == y || $answeric == Y ]];
then
    printf "Proceeding with Ironchef migration\n"
    userCheck
    findMaster
    oldMasterDomain
    newMasterDomain
    bnTransfer
    newMasterSetupIronchef
    fabDeploy
    printf "This is the end of the Ironchef portion\n"
elif [[ $answeric == n || $answeric == N ]];
then
    printf "Proceeding with Thor migration\n"
    userCheck
    findMaster
    oldMasterDomain
    newMasterDomain
    bnExportThor
    newMasterSetupThor
    fabDeploy
    printf "This is the end of the Thor portion\n"
else
    printf "That answer is not useful; maybe you should try again sober."
    exit 1
fi

endOutput