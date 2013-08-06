# $Id: cfengine-pgs.spec,v 1.6 2011/09/26 20:22:18 lcerezo Exp $
# Authority: pgs

Summary: Tomcat 7 build for viasat
Name: tomcat7-el6-viasat
Version: 0.0.1
Release: 1
URL: http://itrack.prod.wdc1.wildblue.net/confluence/display/t4sys/Home
License: GPL
Group: Utilities/System
BuildArch: noarch
Requires: java-1.6.0-openjdk, java-1.6.0-openjdk-devel
BuildRoot: /tmp/rpm/%{name}-root/
Packager: Luis E. Cerezo (luis.cerezo@viasat.com) (+1 412 223 7396)

%description
This package installs tomcat7 with the specific configs for ViaSat Exede.
%define _rpmdir /tmp/rpm/
%install

%files
%defattr(774,root,root)
%attr(644,root,root)/etc/cron.d/cfagent

