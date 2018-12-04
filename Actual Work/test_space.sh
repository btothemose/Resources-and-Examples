#!/bin/bash
    read -p "give me a fake cust and code " cust code
    printf "Finding bn master for ${cust}_${code}\n"
    read -p "give me a fake bn master " oldbn
    case "$oldbn" in
        Usag* ) printf "Nope, you made a typo. Terminating.\n";;
        bn* ) printf "${cust}_${code} found on ${oldbn}.\n";;
        * ) printf "${cust}_${code} not found anywhere. You should either panic or check your spelling.\n"
            exit 1;;
    esac