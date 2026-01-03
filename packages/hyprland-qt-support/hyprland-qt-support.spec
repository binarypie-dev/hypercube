Name:           hyprland-qt-support
Version:        0.1.0
Release:        1%{?dist}
Summary:        A Qt6 Qml style provider for hypr* apps

License:        BSD-3-Clause
URL:            https://github.com/hyprwm/hyprland-qt-support
Source:         %{url}/archive/v%{version}/%{name}-%{version}.tar.gz

ExcludeArch:    %{ix86}

BuildRequires:  cmake
BuildRequires:  gcc-c++
BuildRequires:  qt6-rpm-macros
BuildRequires:  cmake(Qt6Quick)
BuildRequires:  cmake(Qt6QuickControls2)
BuildRequires:  cmake(Qt6Qml)
BuildRequires:  pkgconfig(hyprlang)

%description
%{summary}.

%prep
%autosetup -p1

%build
%cmake -DINSTALL_QMLDIR=%{_qt6_qmldir} -DCMAKE_INSTALL_LIBDIR=%{_libdir}
%cmake_build

%install
%cmake_install

%files
%license LICENSE
%doc README.md
%{_libdir}/libhyprland-quick-style-impl.so
%{_libdir}/libhyprland-quick-style.so
%{_qt6_qmldir}/org/hyprland/

%changelog
* Mon Dec 16 2024 Hypercube <hypercube@binarypie.dev> - 0.1.0-1
- Initial package for Hypercube (based on sdegler/hyprland COPR)
