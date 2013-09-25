
%define name tomcat7-el6-viasat
%define __tcatinstdir /apps/
Summary: Tomcat 7 build for viasat
Name: %{name}
Version: 0.5.1
Release: 7.0.40
URL: http://itrack.prod.wdc1.wildblue.net/confluence/display/t4sys/Home
License: GPL
Group: Utilities/System
BuildArch: x86_64
Requires: java-1.6.0-openjdk, java-1.6.0-openjdk-devel or java-1.7.0-openjdk, java-1.7.0-openjdk-devel
BuildRoot:  %{_tmppath}/%{name}-%{version}-build
Source0: %{name}.tar.bz2
Packager: Luis E. Cerezo (luis.cerezo@viasat.com) (+1 412 223 7396)

%description
This package installs tomcat7 with the specific configs for ViaSat Exede.
%install
find ./
cp -R ./  %{buildroot}/
%pre
/usr/bin/getent group tomcat || groupadd -r tomcat
/usr/bin/getent passwd tomcat || useradd -r -g tomcat -d /apps/tomcat -s /sbin/bash -c "tomcat 7 service account for ViaSat Apps" tomcat
exit 0
%prep
%setup -n %{name} -q
%preun
/usr/sbin/userdel tomcat
/sbin/chkconfig --del tomcat7
%post
/sbin/chkconfig --add tomcat7
/sbin/chkconfig tomcat7 on
%files
%defattr(0755,tomcat,tomcat)
/apps/*
/etc/init.d/tomcat7
%clean
exit 0
