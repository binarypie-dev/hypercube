Name:           aquamarine
Version:        0.14.0
Release:        1%{?dist}
Summary:        A very light linux rendering backend library

License:        BSD-3-Clause
URL:            https://github.com/hyprwm/aquamarine
Source:         %{url}/archive/v%{version}/%{name}-%{version}.tar.gz

ExcludeArch:    %{ix86}

BuildRequires:  cmake
BuildRequires:  gcc-c++
BuildRequires:  mesa-libEGL-devel
BuildRequires:  pkgconfig(gbm)
BuildRequires:  pkgconfig(hwdata)
BuildRequires:  pkgconfig(hyprutils)
BuildRequires:  pkgconfig(hyprwayland-scanner)
BuildRequires:  pkgconfig(libdisplay-info)
BuildRequires:  pkgconfig(libdrm)
BuildRequires:  pkgconfig(libinput)
BuildRequires:  pkgconfig(libseat)
BuildRequires:  pkgconfig(libudev)
BuildRequires:  pkgconfig(pixman-1)
BuildRequires:  pkgconfig(wayland-client)
BuildRequires:  pkgconfig(wayland-protocols)

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
%cmake -DCMAKE_BUILD_TYPE=Release
%cmake_build

%install
%cmake_install

%files
%license LICENSE
%doc README.md
%{_libdir}/lib%{name}.so.%{version}
%{_libdir}/lib%{name}.so.13

%files devel
%{_includedir}/%{name}/
%{_libdir}/lib%{name}.so
%{_libdir}/pkgconfig/%{name}.pc

%changelog
* Tue Jul 28 2026 Hypercube <hypercube@binarypie.dev> - 0.14.0-1
- Update to 0.14.0
- Bump SONAME from 12 to 13 to match 0.14.0
* Tue Jul 21 2026 Hypercube <hypercube@binarypie.dev> - 0.13.0-1
- Update to 0.13.0
- Bump SONAME from 11 to 12 to match 0.13.0
* Fri Jun 12 2026 Hypercube <hypercube@binarypie.dev> - 0.12.1-1
- Update to 0.12.1
* Sun May 31 2026 Hypercube <hypercube@binarypie.dev> - 0.12.0-1
- Update to 0.12.0
* Mon May 11 2026 Hypercube <hypercube@binarypie.dev> - 0.11.0-1
- Update to 0.11.0
* Mon Dec 16 2024 Hypercube <hypercube@binarypie.dev> - 0.10.0-1
- Initial package for Hypercube (based on sdegler/hyprland COPR)
