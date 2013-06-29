# $Id: cfengine-pgs.spec,v 1.6 2011/09/26 20:22:18 lcerezo Exp $
# Authority: pgs

Summary: Additional cfengine files for PGS
Name: cfengine-pgs
Version: 1.0.9
Release: 3
URL: http://pinky.onshore.pgs.com/wiki/index.php/Cfengine
License: GPL
Group: Utilities/System
BuildArch: noarch
Requires: cfengine
BuildRoot: /tmp/rpm/%{name}-root/
Packager: Luis E. Cerezo (luis.cerezo@pgs.com) (+1 412 223 7396)

%description
This package adds specific custom files for PGS
to the cfengine configuration.
Requires cfengine 2. 
%define _rpmdir /tmp/rpm/
%install

%files
%defattr(774,root,root)
/var/cfengine/inputs/update.conf
/var/cfengine/inputs/failover.cf
/var/cfengine/inputs/cfagent.conf
/var/cfengine/inputs/cfservd.conf
/var/cfengine/inputs/cfservers.cf
/var/cfengine/ppkeys/root-10.20.24.83.pub
/var/cfengine/ppkeys/root-10.26.16.15.pub
/var/cfengine/ppkeys/root-10.21.24.20.pub
/var/cfengine/ppkeys/root-10.21.24.152.pub
/var/cfengine/ppkeys/root-157.147.224.49.pub
/var/cfengine/ppkeys/root-172.16.17.50.pub
/var/cfengine/ppkeys/root-10.27.16.25.pub
/var/cfengine/ppkeys/root-10.22.16.17.pub
/var/cfengine/ppkeys/root-10.30.24.8.pub
%attr(644,root,root)/etc/cron.d/cfagent
