#!/bin/bash

newbn="bn60"

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