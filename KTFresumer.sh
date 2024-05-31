#!/bin/bash

#This script sets nodes in the down state due to "Kill task fail" back to the resume state.

#The for loop condition just identifies the ccc nodes with down reason "Kill task failed".

for resumenode in $(sinfo -R | grep ccc | grep "Kill task failed" | grep -oP 'ccc.*')
do
    if ping -c 1 "$resumenode" &> /dev/null #test to see if the node is reachable. if it is, set state to resume
    then
        scontrol update nodename="$resumenode" state=resume #set slurm state to "resume"
        printf "$resumenode date +%Y%m%d%H%M%S\n" >> killtaskfail.log #log that the node was resumed
    else                                  #if the node isn't reachable... reboot it and wait 10mins so it can boot
        rpower "$resumenode" reset          #...reboot it and wait 10mins so it can boot
        sleep 600
        if ping -c 1 "$resumenode" &> /dev/null #second check in case the node takes >10mins to boot
        then                                    #Yes, I know I should write functions for this whatever sue me
            scontrol update nodename="$resumenode" state=resume
            printf "$resumenode date +%Y%m%d%H%M%S\n" >> killtaskfail.log
        else
            sleep 300
            scontrol update nodename="$resumenode" state=resume
            printf "$resumenode date +%Y%m%d%H%M%S\n" >> killtaskfail.log
        fi
    fi
done