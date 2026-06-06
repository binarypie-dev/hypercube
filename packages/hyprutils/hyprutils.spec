Name:           hyprutils
Version:        0.13.1
Release:        2%{?dist}
Summary:        Hyprland utilities library used across the ecosystem

License:        BSD-3-Clause
URL:            https://github.com/hyprwm/hyprutils
Source:         %{url}/archive/v%{version}/%{name}-%{version}.tar.gz

ExcludeArch:    %{ix86}

BuildRequires:  cmake
BuildRequires:  gcc-c++
BuildRequires:  pkgconfig(pixman-1)

%description
%{summary}.

%package        devel
Summary:        Development files for %{name}
Requires:       %{name}%{?_isa} = %{version}-%{release}

%description    devel
Development files for %{name}.

%prep
%autosetup -p1

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
%{_libdir}/lib%{name}.so.%{version}
%{_libdir}/lib%{name}.so.12

%files devel
%{_includedir}/%{name}/
%{_libdir}/lib%{name}.so
%{_libdir}/pkgconfig/%{name}.pc

%changelog
* Sat Jun 06 2026 Hypercube <hypercube@binarypie.dev> - 0.13.1-2
- Bump SONAME from 10 to 12 to match 0.13.1
* Mon May 11 2026 Hypercube <hypercube@binarypie.dev> - 0.13.1-1
- Update to 0.13.1
* Mon Dec 16 2024 Hypercube <hypercube@binarypie.dev> - 0.11.0-1
- Update to 0.11.0 (adds cli/Logger.hpp needed by aquamarine)

* Mon Dec 16 2024 Hypercube <hypercube@binarypie.dev> - 0.10.0-1
- Initial package for Hypercube (based on sdegler/hyprland COPR)
