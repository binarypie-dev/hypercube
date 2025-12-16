Name:           quickshell
Version:        0.2.1
Release:        1%{?dist}
Summary:        Flexible QtQuick based desktop shell toolkit

License:        LGPL-3.0-or-later
URL:            https://github.com/quickshell-mirror/quickshell
Source0:        %{url}/archive/v%{version}/%{name}-%{version}.tar.gz

BuildRequires:  cmake
BuildRequires:  ninja-build
BuildRequires:  gcc-c++
BuildRequires:  pkg-config
BuildRequires:  qt6-qtbase-devel >= 6.6.0
BuildRequires:  qt6-qtdeclarative-devel
BuildRequires:  qt6-qtshadertools-devel
BuildRequires:  qt6-qtsvg-devel
BuildRequires:  qt6-qtwayland-devel
BuildRequires:  spirv-tools-devel
BuildRequires:  cli11-devel

# Wayland support
BuildRequires:  wayland-devel
BuildRequires:  wayland-protocols-devel

# X11 support
BuildRequires:  libxcb-devel

# Audio/PipeWire
BuildRequires:  pipewire-devel

# DBus
BuildRequires:  qt6-qtbase-private-devel

# Optional dependencies
BuildRequires:  jemalloc-devel
BuildRequires:  pam-devel
BuildRequires:  polkit-devel
BuildRequires:  glib2-devel
BuildRequires:  libdrm-devel
BuildRequires:  mesa-libgbm-devel

Requires:       qt6-qtbase >= 6.6.0
Requires:       qt6-qtdeclarative
Requires:       qt6-qtwayland
Requires:       qt6-qtsvg

%description
Quickshell is a toolkit for constructing desktop components like status bars,
widgets, and lockscreens using QtQuick on Wayland compositors or window
managers. It supports Hyprland, Sway, and other Wayland compositors.

%prep
%autosetup -n %{name}-%{version}

%build
%cmake \
    -GNinja \
    -DCMAKE_BUILD_TYPE=RelWithDebInfo \
    -DWAYLAND=ON \
    -DX11=ON \
    -DPIPEWIRE=ON \
    -DHYPRLAND=ON \
    -DI3=ON \
    -DCRASH_REPORTER=OFF

%cmake_build

%install
%cmake_install

%files
%license LICENSE LICENSE.GPL
%doc README.md
%{_bindir}/%{name}

%changelog
* Mon Dec 16 2024 Hypercube <hypercube@binarypie.dev> - 0.2.1-1
- Initial package for Hypercube
