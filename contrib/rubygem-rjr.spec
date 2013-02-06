%global gem_name rjr
%global rubyabi 1.9.1

Summary:       JSON-RPC Ruby library and server/client utilities
Name:          rubygem-%{gem_name}
Version:       0.10.0
Release:       1
Group:         Development/Languages
License:       ASL 2.0
URL:           https://github.com/movitto/rjr
Source0:       http://rubygems.org/gems/%{gem_name}-%{version}.gem
Provides:      rubygem(%{gem_name}) = %{version}
BuildArch:     noarch

Requires:      ruby(rubygems)
Requires:      ruby(abi) = %{rubyabi}
Requires:      rubygem(eventmachine) = 0.12.10
Requires:      rubygem(json)
Requires:      rubygem(curb)
BuildRequires: ruby(rubygems)
BuildRequires: rubygems-devel
BuildRequires: rubygem(rspec)

%description
RJR is an implementation of the JSON-RPC Version 2.0 Specification.

It allows a developer to register custom JSON-RPC method handlers
which may be invoked simultaneously over a variety of transport mechanisms.

%package doc
Summary: RJR gem documentation
License: ASL 2.0

%description doc
Documentation for rubygem-rjr

%prep
gem unpack %{SOURCE0}
%setup -q -D -T -n  %{gem_name}-%{version}

gem spec %{SOURCE0} -l --ruby > %{gem_name}.gemspec

%build
mkdir -p ./%{gem_dir}

# Create the gem as gem install only works on a gem file
gem build %{gem_name}.gemspec

export CONFIGURE_ARGS="--with-cflags='%{optflags}'"
# gem install compiles any C extensions and installs into a directory
# We set that to be a local directory so that we can move it into the
# buildroot in %%install
gem install -V \
        --local \
        --install-dir ./%{gem_dir} \
        --bindir ./%{_bindir} \
        --force \
        --rdoc \
  %{gem_name}-%{version}.gem

%install
mkdir -p %{buildroot}%{gem_dir}
cp -a ./%{gem_dir}/* %{buildroot}%{gem_dir}/

mkdir -p %{buildroot}%{_bindir}
cp -a ./%{_bindir}/* %{buildroot}%{_bindir}
mv  %{buildroot}%{gem_instdir}/bin/* %{buildroot}%{_bindir}

if [ -d %{buildroot}%{gem_instdir}/.yardoc ] ; then
  rm -rf %{buildroot}%{gem_instdir}/.yardoc
fi

%check
pushd .%{gem_instdir}
rspec specs
popd

%files
%defattr(-, root, root, -)
%dir %{gem_instdir}
%{gem_instdir}/lib
%doc %{gem_instdir}/README.md
%doc %{gem_instdir}/LICENSE
%{gem_dir}/cache/%{gem_name}-%{version}.gem
%{gem_dir}/specifications/%{gem_name}-%{version}.gemspec
%{_bindir}/rjr-server

%files doc
%defattr(-,root,root,-)
%doc %{gem_instdir}/Rakefile
%doc %{gem_instdir}/specs
%doc %{gem_dir}/doc/%{gem_name}-%{version}

%changelog
* Fri Feb 01 2013 Mo Morsi <mo@morsi.org> - 0.10.0-1
- Initial package

* Mon Sep 10 2012 Mo Morsi <mo@morsi.org> - 0.9.0-1
- Initial package
