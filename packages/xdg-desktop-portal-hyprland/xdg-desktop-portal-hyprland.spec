%global sdbus_version 2.1.0

Name:           xdg-desktop-portal-hyprland
Epoch:          1
Version:        1.5.0
Release:        1%{?dist}
Summary:        xdg-desktop-portal backend for hyprland

License:        BSD-3-Clause
URL:            https://github.com/hyprwm/xdg-desktop-portal-hyprland
Source0:        %{url}/archive/v%{version}/%{name}-%{version}.tar.gz
Source1:        https://github.com/Kistler-Group/sdbus-cpp/archive/v%{sdbus_version}/sdbus-%{sdbus_version}.tar.gz

BuildRequires:  cmake
BuildRequires:  gcc-c++
BuildRequires:  systemd-rpm-macros
BuildRequires:  pkgconfig(gbm)
BuildRequires:  pkgconfig(hyprland-protocols) >= 0.8.0
BuildRequires:  pkgconfig(hyprlang)
BuildRequires:  pkgconfig(hyprtoolkit) >= 0.6.0
BuildRequires:  pkgconfig(hyprutils)
BuildRequires:  pkgconfig(hyprwayland-scanner)
BuildRequires:  pkgconfig(libdrm)
BuildRequires:  pkgconfig(libpipewire-0.3)
BuildRequires:  pkgconfig(libsystemd)
BuildRequires:  pkgconfig(systemd)
BuildRequires:  pkgconfig(uuid)
BuildRequires:  pkgconfig(wayland-client)
BuildRequires:  pkgconfig(wayland-protocols) >= 1.39
BuildRequires:  pkgconfig(wayland-scanner)

Requires:       dbus
Requires:       grim
Requires:       xdg-desktop-portal
Requires:       slurp

Enhances:       hyprland
Supplements:    hyprland

Provides:       bundled(sdbus-cpp) = %{sdbus_version}

%description
%{summary}.

%prep
%autosetup -p1
tar -xf %{SOURCE1} -C subprojects/sdbus-cpp --strip=1

%build
%cmake -DBUILD_SHARED_LIBS:BOOL=OFF -DCMAKE_BUILD_TYPE=Release
%cmake_build

%install
%cmake_install

%post
%systemd_user_post %{name}.service

%preun
%systemd_user_preun %{name}.service

%files
%license LICENSE
%doc README.md
%{_bindir}/hyprland-share-picker
%{_datadir}/dbus-1/services/org.freedesktop.impl.portal.desktop.hyprland.service
%{_datadir}/xdg-desktop-portal/portals/hyprland.portal
%{_libexecdir}/%{name}
%{_userunitdir}/%{name}.service

%changelog
* Wed Nov 04 2026 Hypercube <hypercube@binarypie.dev> - 1.5.0-1
- Update to 1.5.0
- hyprland-share-picker is rewritten on hyprtoolkit: drop Qt6, BuildRequires hyprtoolkit >= 0.6.0
- BuildRequires hyprland-protocols >= 0.8.0 (workspace capture protocol)
* Thu Jul 30 2026 Hypercube <hypercube@binarypie.dev> - 1.4.1-1
- Update to 1.4.1
* Tue Jul 21 2026 Hypercube <hypercube@binarypie.dev> - 1.4.0-1
- Update to 1.4.0
- Add pkgconfig(uuid) build dependency
* Mon May 11 2026 Hypercube <hypercube@binarypie.dev> - 1.3.12-1
- Update to 1.3.12
* Mon Dec 16 2024 Hypercube <hypercube@binarypie.dev> - 1.3.11-1
- Initial package for Hypercube (based on sdegler/hyprland COPR)
