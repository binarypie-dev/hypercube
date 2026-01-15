Name:           hyprgraphics
Version:        0.5.0
Release:        1%{?dist}
Summary:        Hyprland graphics / resource utilities

License:        BSD-3-Clause
URL:            https://github.com/hyprwm/hyprgraphics
Source:         %{url}/archive/v%{version}/%{name}-%{version}.tar.gz

ExcludeArch:    %{ix86}

BuildRequires:  cmake
BuildRequires:  gcc-c++
BuildRequires:  pkgconfig(cairo)
BuildRequires:  pkgconfig(hyprutils)
BuildRequires:  pkgconfig(libjpeg)
BuildRequires:  pkgconfig(libjxl_cms)
BuildRequires:  pkgconfig(libjxl_threads)
BuildRequires:  pkgconfig(libjxl)
BuildRequires:  pkgconfig(libmagic)
BuildRequires:  pkgconfig(libwebp)
BuildRequires:  pkgconfig(pixman-1)
BuildRequires:  pkgconfig(libpng)
BuildRequires:  pkgconfig(pangocairo)
BuildRequires:  pkgconfig(libheif)
BuildRequires:  pkgconfig(librsvg-2.0)

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

%check
%ctest

%files
%license LICENSE
%doc README.md
%{_libdir}/lib%{name}.so.4
%{_libdir}/lib%{name}.so.%{version}

%files devel
%{_includedir}/%{name}/
%{_libdir}/lib%{name}.so
%{_libdir}/pkgconfig/%{name}.pc

%changelog
* Sat Jan 10 2026 Hypercube <hypercube@binarypie.dev> - 0.5.0-1
- Update to 0.5.0
* Mon Dec 16 2024 Hypercube <hypercube@binarypie.dev> - 0.4.0-1
- Update to 0.4.0

* Mon Dec 16 2024 Hypercube <hypercube@binarypie.dev> - 0.2.0-1
- Initial package for Hypercube (based on sdegler/hyprland COPR)
