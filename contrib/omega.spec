%global app_root %{_datadir}/%{name}

Name:    omega
Summary: Omega Universal simulation framework
Version: 0.4.0
Release: 1
Group:   Development/Languages
License: AGPLv3+
URL:     http://github.com/movitto/omega
Source0: http://github.com/movitto/omega/tarball/%{name}-%{version}.tgz
Source1: http://github.com/movitto/omega/files/%{name}-server.init
Source2: http://github.com/movitto/omega/files/%{name}-backup.cron
BuildArch: noarch

Requires(post):   chkconfig
Requires:             httpd
Requires:   rabbitmq-server
#BuildRequires: rubygem(rspec)

%description

%package doc
Summary: Documentation for %{name}
Group: Documentation
Requires:%{name} = %{version}-%{release}

%description doc
Documentation for %{name}

# TODO split out subpackages for server / client binaries?

%prep
%setup -q
cp %{SOURCE1} .
cp %{SOURCE2} .

%build

%install
mkdir -p %{buildroot}%{app_root}
mkdir -p %{buildroot}%{_initddir}
mkdir -p %{buildroot}%{_sysconfdir}
mkdir -p %{buildroot}%{_sysconfdir}/cron.d
mkdir -p %{buildroot}%{_bindir}

cp -r * %{buildroot}%{app_root}
rm -rf %{buildroot}%{app_root}/vendor
mv %{buildroot}%{app_root}/omega.yml %{buildroot}%{_sysconfdir}
mv %{buildroot}/%{app_root}/%{name}-backup.cron %{buildroot}%{_sysconfdir}/cron.d/%{name}-backup
mv %{buildroot}/%{app_root}/%{name}-server.init %{buildroot}%{_initddir}/%{name}-server

# TODO copy util executables
mv %{buildroot}/%{app_root}/bin/omega-server %{buildroot}%{_bindir}/omega-server
mv %{buildroot}/%{app_root}/bin/omega-backup %{buildroot}%{_bindir}/omega-backup
mv %{buildroot}/%{app_root}/bin/omega-restore %{buildroot}%{_bindir}/omega-restore
rm -rf %{buildroot}/%{app_root}/bin

%pre
/usr/sbin/groupadd omega || :
/usr/sbin/useradd -g omega -c "omega" \
  -s /sbin/nologin -r -d /usr/share/omega omega 2> /dev/null || :

%files
%defattr(640,omega,omega,-)
%config %{_sysconfdir}/omega.yml

%defattr(644,omega,omega,755)
%{_sysconfdir}/cron.d/%{name}-backup
%dir %{app_root}/
%{app_root}/lib
%{app_root}/site
%{app_root}/LICENSE
%{app_root}/COPYING

%defattr(755,root,root,-)
%{_initddir}/%{name}-server
%{_bindir}/omega-server
%{_bindir}/omega-backup
%{_bindir}/omega-restore

# FIXME need to package isaac seperately
#%{app_root}/vendor

%files doc
#%{_defaultdocdir}/%{name}
%{app_root}/examples
%{app_root}/spec
%{app_root}/Rakefile
%{app_root}/README.md

%changelog
* Sat Sep 14 2013 Mo Morsi <mo@morsi.org> - 0.4.0-1
- New Release

* Wed Apr 17 2013 Mo Morsi <mo@morsi.org> - 0.3.0-1
- New Release

* Mon Sep 10 2012 Mo Morsi <mo@morsi.org> - 0.1.0-1
- Initial package
