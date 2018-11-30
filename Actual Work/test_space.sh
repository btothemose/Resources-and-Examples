#!/bin/bash
echo "enter test customer"
read cust code
ssh bn60ms01.dub.baynote.net << EOF
    echo ${cust} >> cust.doc
    echo ${code} >> cust.doc
    cp cust.doc ./test-omer/${cust}.doc
EOF