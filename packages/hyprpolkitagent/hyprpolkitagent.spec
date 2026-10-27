%global sdbus_version 2.1.0

Name:           hyprpolkitagent
Version:        0.2.0
Release:        1%{?dist}
Summary:        A simple polkit authentication agent for Hyprland

License:        BSD-3-Clause
URL:            https://github.com/hyprwm/hyprpolkitagent
Source0:        %{url}/archive/v%{version}/%{name}-%{version}.tar.gz
Source1:        https://github.com/Kistler-Group/sdbus-cpp/archive/v%{sdbus_version}/sdbus-%{sdbus_version}.tar.gz

ExcludeArch:    %{ix86}

BuildRequires:  cmake
BuildRequires:  gcc-c++
BuildRequires:  systemd-rpm-macros
BuildRequires:  pkgconfig(hyprgraphics)
BuildRequires:  pkgconfig(hyprlang)
BuildRequires:  pkgconfig(hyprtoolkit) >= 0.6.0
BuildRequires:  pkgconfig(hyprutils)
BuildRequires:  pkgconfig(libdrm)
BuildRequires:  pkgconfig(libsystemd)
BuildRequires:  pkgconfig(pixman-1)
BuildRequires:  pkgconfig(xkbcommon)

Requires:       polkit

Provides:       bundled(sdbus-cpp) = %{sdbus_version}

%description
A simple polkit authentication agent for Hyprland, written in C++ with
hyprtoolkit.

%prep
%autosetup -p1 -a1

%build
pushd sdbus-cpp-%{sdbus_version}
%cmake \
    -DCMAKE_INSTALL_PREFIX=%{_builddir}/sdbus \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=OFF
%cmake_build
cmake --install %{__cmake_builddir}
popd
export PKG_CONFIG_PATH=%{_builddir}/sdbus/%{_lib}/pkgconfig

%cmake
%cmake_build

%install
%cmake_install

%post
%systemd_user_post %{name}.service

%preun
%systemd_user_preun %{name}.service

%postun
%systemd_user_postun %{name}.service

%files
%license LICENSE
%doc README.md
%{_datadir}/dbus-1/services/org.hyprland.%{name}.service
%{_libexecdir}/%{name}
%{_userunitdir}/%{name}.service

%changelog
* Mon Oct 26 2026 Hypercube <hypercube@binarypie.dev> - 0.2.0-1
- Update to 0.2.0 (rewritten on hyprtoolkit; drops Qt/hyprland-qt-support)
- Talks to polkit over D-Bus via a bundled static sdbus-cpp, like hypridle
* Mon Dec 16 2024 Hypercube <hypercube@binarypie.dev> - 0.1.3-1
- Initial package for Hypercube (based on sdegler/hyprland COPR)
