
%define name tomcat7-el6-viasat
%define __tcatinstdir /apps/
Summary: Tomcat 7 build for viasat
Name: %{name}
Version: 0.0.1
Release: 1
URL: http://itrack.prod.wdc1.wildblue.net/confluence/display/t4sys/Home
License: GPL
Group: Utilities/System
BuildArch: x86_64
Requires: java-1.6.0-openjdk, java-1.6.0-openjdk-devel
BuildRoot:  %{_tmppath}/%{name}-%{version}-build
Source0: %{name}.tar.bz2
Packager: Luis E. Cerezo (luis.cerezo@viasat.com) (+1 412 223 7396)

%description
This package installs tomcat7 with the specific configs for ViaSat Exede.
%install
find ./
cp -R ./  %{buildroot}/
%pre
/usr/bin/getent group tomcat || grouadd -r tomcat
/usr/bin/getent passwd tomcat || useradd -r -g tomcat -d /apps/tomcat -s /sbin/nologin -c "tomcat 7 service account for ViaSat Apps" tomcat7
exit 0
%prep
%setup -n %{name} -D -q
%preun
/usr/sbin/userdel tomcat
/usr/sbin/chkconfig --del tomcat
%post
/sbin/chkconfig --add tomcat7
/sbin/chkconfig tomcat7 on
%files
%defattr(0755,tomcat,tomcat)
/apps/*
/etc/init.d/tomcat7
%clean
exit 0
