Name:           hyprwire
Version:        0.2.1
Release:        1%{?dist}
Summary:        A fast and consistent wire protocol for IPC

License:        BSD-3-Clause
URL:            https://github.com/hyprwm/hyprwire
Source:         %{url}/archive/v%{version}/%{name}-%{version}.tar.gz

ExcludeArch:    %{ix86}

BuildRequires:  cmake
BuildRequires:  gcc-c++
BuildRequires:  pkgconfig(hyprutils) >= 0.9.0
BuildRequires:  pkgconfig(libffi)
BuildRequires:  pkgconfig(pugixml)

%description
Hyprwire is a fast and consistent wire protocol for IPC (inter-process
communication). It is heavily inspired by Wayland, and heavily anti-inspired
by D-Bus. Both sides need to be on the same page to communicate, making it
strict, fast, and simple to use.

%package        scanner
Summary:        Protocol scanner tool for %{name}
Requires:       %{name}%{?_isa} = %{version}-%{release}

%description    scanner
Protocol scanner tool for generating code from %{name} protocol definitions.

%package        devel
Summary:        Development files for %{name}
Requires:       %{name}%{?_isa} = %{version}-%{release}
Requires:       %{name}-scanner%{?_isa} = %{version}-%{release}

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
%{_libdir}/lib%{name}.so.2
%{_libdir}/lib%{name}.so.%{version}

%files scanner
%{_bindir}/%{name}-scanner
%{_libdir}/pkgconfig/%{name}-scanner.pc
%{_libdir}/cmake/%{name}-scanner/

%files devel
%{_includedir}/%{name}/
%{_libdir}/lib%{name}.so
%{_libdir}/pkgconfig/%{name}.pc

%changelog
* Thu Jan 15 2026 Hypercube <hypercube@binarypie.dev> - 0.2.1-1
- Initial package for Hypercube
