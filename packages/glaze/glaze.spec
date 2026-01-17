%global debug_package %{nil}

Name:           glaze
Version:        7.0.1
Release:        1%{?dist}
Summary:        Extremely fast, in memory, JSON and interface library for modern C++

License:        MIT
URL:            https://github.com/stephenberry/glaze
Source:         %{url}/archive/v%{version}/%{name}-%{version}.tar.gz

ExcludeArch:    %{ix86}

BuildRequires:  cmake
BuildRequires:  gcc-c++

%description
Glaze is an extremely fast, in memory, JSON and interface library for modern C++.

%package        devel
Summary:        Development files for %{name}
BuildArch:      noarch
Provides:       %{name}-static = %{version}-%{release}

%description    devel
Development files for %{name}. Glaze is a header-only library.

%prep
%autosetup -p1

%build
%cmake \
    -Dglaze_INSTALL_CMAKEDIR=%{_datadir}/cmake/%{name} \
    -Dglaze_DISABLE_SIMD_WHEN_SUPPORTED:BOOL=ON \
    -Dglaze_DEVELOPER_MODE:BOOL=OFF \
    -Dglaze_ENABLE_FUZZING:BOOL=OFF
%cmake_build

%install
%cmake_install

%files devel
%license LICENSE
%doc README.md
%{_datadir}/cmake/%{name}/
%{_includedir}/%{name}/

%changelog
* Sat Jan 17 2026 Hypercube <hypercube@binarypie.dev> - 7.0.1-1
- Update to 7.0.1
* Thu Jan 15 2026 Hypercube <hypercube@binarypie.dev> - 6.1.0-1
- Downgrade to 6.1.0 for Hyprland 0.53.1 compatibility
* Mon Dec 16 2024 Hypercube <hypercube@binarypie.dev> - 6.1.0-1
- Initial package for Hypercube (based on sdegler/hyprland COPR)
