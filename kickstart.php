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
chvt 1";
}

if (isset($_GET['hostname']))
	$hostname = $_GET['hostname'];
if (isset($_GET['ip']))
	$ipaddr = $_GET['ip'];
if (isset($_GET['gateway']))
	$gateway = $_GET['gateway'];
if (isset($_GET['vm']))
        $disk = "xvda";
else
	$disk = "sda";
$server = $_SERVER['SERVER_NAME'];

print <<<END
install
url --url http://$server/repos/distros/centos/5.5/os/x86_64/
lang en_US.UTF-8
keyboard us
text
reboot
xconfig --startxonboot --resolution=1600x1200 --depth=24

END;

if (isset($ipaddr) && isset($gateway) && isset($hostname) && $hostname != '') {
	print "network --device eth0 --bootproto=static --noipv6 --hostname=$hostname --ip=$ipaddr --netmask=255.255.240.0 --gateway=$gateway --nameserver=10.20.16.16";
}
elseif ($hostname == '') {
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
bootloader --location=mbr --append="quiet" --md5pass=\[$thisisahash]
clearpart --all --initlabel
part /boot --fstype ext3 --size=512 --ondisk=$disk
part pv.1 --size=0 --grow --ondisk=$disk
volgroup vg0 pv.1 
logvol / --fstype ext3 --vgname=vg0 --name=lvroot --size=20000
logvol swap --fstype swap --vgname=vg0 --name=lvswap --recommended
logvol /local --fstype ext3 --vgname=vg0 --name=lvlocal --size=10000 --grow

%packages
@Administration Tools
@Authoring and Publishing
@Base
@Core
@Development Libraries
@Development Tools
@Editors
@Emacs
@Engineering and Scientific
@GNOME Desktop Environment
@GNOME Software Development
@Games and Entertainment
@Graphical Internet
@Graphics
@Java
@KDE (K Desktop Environment)
@KDE Software Development
@Legacy Network Server
@Legacy Software Development
@Mail Server
@MySQL Database
@Office/Productivity
@PostgreSQL Database
@Ruby
@Server Configuration Tools
@Sound and Video
@System Tools
@Text-based Internet
@Windows File Server
@X Software Development
@X Window System
-rhgb
-xalan
-tomcat
-nspluginwrapper
-firefox.x86_64

END;

print $pre;

print <<<END

%post
rpm -ivh http://$server/repos/post/post-install-rpms/cfengine-current.el5.x86_64
rpm -ivh http://$server/repos/post/post-install-rpms/cfengine-pgs-current

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
EOF
ln -s /usr/lib/libXi.so.6 /usr/lib/libXi.so
ln -s /usr/lib/libXinerama.so.1 /usr/lib/libXinerama.so
chvt 3
ntpdate -u houdc23
END;

?>
