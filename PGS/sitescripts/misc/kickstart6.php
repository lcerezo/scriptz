<?php
header('Content-type: text/plain');

if (!isset($_GET['hostname']) || $_GET['hostname'] == '') {
	#die("No hostname specified, specify a hostname in the form of kickstart.php?hostname=somehostname !! http://pinky.onshore.pgs.com/wiki/index.php/Kickstart");
$pre = "
%pre
exec < /dev/tty6 > /dev/tty6
chvt 6
clear
echo \"Enter hostname: \"
read hostname
hostname \$hostname
echo \$hostname > /etc/hostname
chvt 1
%end
";
}

if (isset($_GET['hostname']))
	$hostname = $_GET['hostname'];
if (isset($_GET['ip']))
	$ipaddr = $_GET['ip'];
if (isset($_GET['gateway']))
	$gateway = $_GET['gateway'];
if (isset($_GET['vm']))
        $disk = "xvda";
elseif (isset($_GET['ondisk']))
	$disk = $_GET['ondisk'];
else
	$disk = 'sda'; 
$server = $_SERVER['SERVER_NAME'];

print <<<END
install
url --url http://$server/repos/distros/centos/6/os/x86_64/
lang en_US.UTF-8
keyboard us
text
reboot
sshpw --username=kickstart kickstart --plaintext
services --disabled xinetd,avahi-daemon,avahi-dnsconfd,bluetooth,cpuspeed,firstboot
firstboot --disabled
xconfig --startxonboot

END;

if (isset($ipaddr) && isset($gateway) && isset($hostname) && $hostname != '') {
	print "network --device eth0 --bootproto=static --noipv6 --hostname=$hostname --ip=$ipaddr --netmask=255.255.240.0 --gateway=$gateway --nameserver=10.20.16.16";
}
elseif (!isset($hostname)) {
	print "network --device eth0 --bootproto=dhcp --noipv6 --nameserver=10.20.16.16";
}
else {
	print "network --device eth0 --bootproto=dhcp --noipv6 --hostname=$hostname --nameserver=10.20.16.16";
}
print <<<END

rootpw --iscrypted \$1\$I4b1Q87X\$kAXRJydttLs.dc.M1RcOE.
firewall --disabled
selinux --disabled
authconfig --enableshadow --enablemd5 
timezone America/Chicago
bootloader --location=mbr --append="quiet rdblacklist=nouveau" --md5pass=\$1\$Jee5ZZgZ\$8PfpunZ5CQS6uLL8ZA5so1

END;

if (isset($noformat)) {
print <<<END

part /boot --fstype ext4 --size=512 --onpart=sda1
part pv.1 --onpart=sda2 --noformat
volgroup vg0 pv.1 --noformat --useexisting
logvol / --fstype ext4 --vgname=vg0 --name=lvroot --useexisting
logvol swap --fstype swap --vgname=vg0 --name=lvswap --useexisting
logvol /local --fstype ext3 --vgname=vg0 --name=lvlocal --useexisting --noformat

END;
}
else {
print <<<END

clearpart --all --initlabel
part /boot --fstype ext4 --size=512 --ondisk=$disk
part pv.1 --size=1 --grow --ondisk=$disk
volgroup vg0 pv.1
logvol / --fstype ext4 --vgname=vg0 --name=lvroot --size=20000
logvol swap --fstype swap --vgname=vg0 --name=lvswap --recommended
logvol /local --fstype ext4 --vgname=vg0 --name=lvlocal --size=10000 --grow

END;
}

print <<<END

%packages
@backup-client
@base
@compat-libraries
@console-internet
@debugging
@dial-up
@directory-client
@hardware-monitoring
@infiniband
@java-platform
@large-systems
@legacy-unix
@mainframe-access
@network-file-system-client
@network-tools
@performance
@perl-runtime
@print-client
@scientific
@security-tools
@smart-card
@storage-client-fcoe
@storage-client-iscsi
@storage-client-multipath
@backup-server
@cifs-file-server
@directory-server
@ftp-server
@mail-server
@network-server
@nfs-file-server
@print-server
@server-platform
@storage-server
@system-admin-tools
@php
@turbogears
@web-server
@web-servlet
@mysql
@mysql-client
@postgresql
@postgresql-client
@system-management
@system-management-messaging-client
@system-management-messaging-server
@system-management-snmp
@system-management-wbem
@basic-desktop
@desktop-debugging
@desktop-platform
@fonts
@general-desktop
@graphical-admin-tools
@input-methods
@kde-desktop
@legacy-x
@remote-desktop-clients
@x11
@emacs
@graphics
@internet-browser
@technical-writing
@tex
@additional-devel
@desktop-platform-devel
@development
@eclipse
@server-platform-devel
@office-suite
-nspluginwrapper
-firefox.x86_64
%end

END;

print $pre;

print <<<END

%post
rpm -ivh http://$server/repos/post/post-install-rpms/cfengine-current.el5.x86_64
rpm -ivh http://$server/repos/post/post-install-rpms/cfengine-pgs-current
echo "blacklist nouveau" >> /etc/modprobe.d/blacklist.conf

END;

#hostname business
if ($pre != '') { //pre is set, lets hack hostname
print <<<END
HOST=`hostname`
NET=`grep NETWORKING /etc/sysconfig/network`
echo \$NET > /etc/sysconfig/network
echo "HOSTNAME=\$HOST" >> /etc/sysconfig/network
END;
}
print <<<END

cat <<EOF >> /etc/rc.local
if [ -f /etc/nv ]; then
        exit
else
        wget -O /tmp/nvidia-current.sh http://$server/repos/post/drivers/Nvidia/x86_64/current
        chmod 777 /tmp/nvidia-current.sh
        /tmp/nvidia-current.sh -s
        /usr/bin/nvidia-xconfig --query-gpu-info
        /usr/bin/nvidia-xconfig --twinview
        touch /etc/nv
fi
cfagent -qv && cfagent -qv
EOF
chvt 3
ln -s /usr/lib/libXi.so.6 /usr/lib/libXi.so
ln -s /usr/lib/libXinerama.so.1 /usr/lib/libXinerama.so
ntpdate -u houdc23
%end

END;

?>
