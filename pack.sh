#!/bin/bash
# Copyright terabit 2016
# Copyright kaneda  2016


if [ $# -le 1 ]; then
   echo "Usage: pack.sh </path/prepend-script.sh> </path/binary-program>"
   exit
fi
OUT=$2".out"

cat $1 > $OUT
echo "#PAYLOAD:" >> $OUT
cat $2 >> $OUT
mv $OUT $2
chmod a+x $2
sed -i "s/MYPATH/$(basename $2)/" $2