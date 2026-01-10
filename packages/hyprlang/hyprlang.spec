Name:           hyprlang
Version:        0.6.8
Release:        1%{?dist}
Summary:        The official implementation library for the hypr config language

License:        LGPL-3.0-only
URL:            https://github.com/hyprwm/hyprlang
Source:         %{url}/archive/v%{version}/%{name}-%{version}.tar.gz

ExcludeArch:    %{ix86}

BuildRequires:  cmake
BuildRequires:  gcc-c++
BuildRequires:  pkgconfig(hyprutils)

%description
%{summary}.

%package        devel
Summary:        Development files for %{name}
Requires:       %{name}%{?_isa} = %{version}-%{release}

%description    devel
Development files for %{name}.

%prep
%autosetup -p1
sed 's/.*/%{version}/' -i VERSION

%build
%cmake
%cmake_build

%install
%cmake_install

%check
%ctest

%files
%license LICENSE
%doc README.md
%{_libdir}/libhyprlang.so.2
%{_libdir}/libhyprlang.so.%{version}

%files devel
%{_includedir}/hyprlang.hpp
%{_libdir}/libhyprlang.so
%{_libdir}/pkgconfig/hyprlang.pc

%changelog
* Sat Jan 10 2026 Hypercube <hypercube@binarypie.dev> - 0.6.8-1
- Update to 0.6.8
* Mon Dec 16 2024 Hypercube <hypercube@binarypie.dev> - 0.6.7-1
- Update to 0.6.7

* Mon Dec 16 2024 Hypercube <hypercube@binarypie.dev> - 0.6.4-1
- Initial package for Hypercube (based on sdegler/hyprland COPR)
