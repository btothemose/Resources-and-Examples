#!/bin/bash
cust="cust"
code="code"
fqnbn="127.0.0.1"

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