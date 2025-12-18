Name:           livesys-scripts
Version:        0.9.1
Release:        1.hypercube%{?dist}
Summary:        Scripts for auto-configuring live media during boot (with Hyprland support)

License:        GPL-3.0-or-later
URL:            https://github.com/binarypie-dev/livesys-scripts
Source:         https://github.com/binarypie-dev/livesys-scripts/archive/refs/heads/main.tar.gz

BuildRequires:  systemd-rpm-macros
BuildRequires:  make

BuildArch:      noarch

# This package provides livesys-scripts with Hyprland support
Provides:       livesys-scripts = %{version}-%{release}
Obsoletes:      livesys-scripts < %{version}-%{release}

%description
Scripts for auto-configuring live media during boot.
This version includes Hyprland session support.


%prep
%autosetup -n %{name}-main -p1


%build
# Nothing to do

%install
%make_install

# Make ghost files
mkdir -p %{buildroot}%{_sharedstatedir}/livesys
touch %{buildroot}%{_sharedstatedir}/livesys/livesys-session-extra
touch %{buildroot}%{_sharedstatedir}/livesys/livesys-session-late-extra


%preun
%systemd_preun livesys.service livesys-late.service


%post
%systemd_post livesys.service livesys-late.service


%postun
%systemd_postun livesys.service livesys-late.service


%files
%license COPYING
%doc README.md
%config(noreplace) %{_sysconfdir}/sysconfig/livesys
%{_libexecdir}/livesys/
%{_unitdir}/livesys*
%dir %{_sharedstatedir}/livesys
%ghost %{_sharedstatedir}/livesys/livesys-session-extra
%ghost %{_sharedstatedir}/livesys/livesys-session-late-extra


%changelog
* Mon Dec 16 2024 Hypercube <hypercube@binarypie.dev> - 0.9.1-1.hypercube
- Add Hyprland session support
- Based on upstream 0.9.1
