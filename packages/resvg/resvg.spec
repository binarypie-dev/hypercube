# NOTE: This package requires "Enable internet access during builds" in COPR settings
# because cargo needs to download dependencies

%global debug_package %{nil}

Name:           resvg
Version:        0.47.0
Release:        1%{?dist}
Summary:        SVG rendering library and CLI tool

License:        Apache-2.0 OR MIT
URL:            https://github.com/linebender/resvg
Source0:        %{url}/archive/v%{version}/%{name}-%{version}.tar.gz

BuildRequires:  cargo >= 1.80
BuildRequires:  rust >= 1.80
BuildRequires:  gcc

%description
resvg is an SVG rendering library and CLI tool. It can be used to render SVG
files to PNG images or to parse SVG files for further processing.

%prep
%autosetup -n %{name}-%{version}

%build
RUSTFLAGS='-C strip=symbols' cargo build --release --locked -p resvg

%install
install -Dpm 0755 target/release/resvg %{buildroot}%{_bindir}/resvg

%files
%license LICENSE-APACHE LICENSE-MIT
%doc README.md
%{_bindir}/resvg

%changelog
* Wed Feb 11 2026 Hypercube <hypercube@binarypie.dev> - 0.47.0-1
- Update to 0.47.0
* Thu Jan 30 2026 Hypercube <hypercube@binarypie.dev> - 0.46.0-1
- Initial package for Hypercube
