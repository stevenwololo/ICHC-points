#!/bin/bash
echo "1" > ichcStatus;
echo "($RANDOM % 300) + 1800" | bc -q > TIME;


while [ true ]
do
        grep "1" ichcStatus -q;
        if [ $? -eq 0 ]
        then
                ./bot.normal.sh
        fi
        ##check for reboot command
        grep "2" ichcStatus -q;
        if [ $? -eq 0 ]
        then
                ./bot.normal.sh;
        fi
        sleep 5;
done
