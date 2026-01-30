# NOTE: This package requires "Enable internet access during builds" in COPR settings
# because cargo needs to download dependencies

%global debug_package %{nil}

Name:           bluetui
Version:        0.8.1
Release:        1%{?dist}
Summary:        TUI for managing Bluetooth devices

License:        GPL-3.0-only
URL:            https://github.com/pythops/bluetui
Source0:        %{url}/archive/v%{version}/%{name}-%{version}.tar.gz

BuildRequires:  cargo >= 1.80
BuildRequires:  rust >= 1.80
BuildRequires:  gcc
BuildRequires:  dbus-devel

Requires:       bluez

%description
Bluetui is a TUI (Terminal User Interface) for managing Bluetooth devices on Linux.
It provides an intuitive interface for scanning, pairing, connecting, and managing
Bluetooth devices from the terminal.

%prep
%autosetup -n %{name}-%{version}

%build
RUSTFLAGS='-C strip=symbols' cargo build --release --locked

%install
install -Dpm 0755 target/release/bluetui %{buildroot}%{_bindir}/bluetui

%files
%license LICENSE
%doc README.md
%{_bindir}/bluetui

%changelog
* Thu Jan 30 2026 Hypercube <hypercube@binarypie.dev> - 0.8.1-1
- Initial package for Hypercube
