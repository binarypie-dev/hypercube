# NOTE: This package requires "Enable internet access during builds" in COPR settings
# because cargo needs to download dependencies

%global debug_package %{nil}

Name:           iamb
Version:        0.0.11
Release:        1%{?dist}
Summary:        Matrix chat client with Vim-like keybindings

License:        Apache-2.0
URL:            https://github.com/ulyssa/iamb
Source0:        %{url}/archive/v%{version}/%{name}-%{version}.tar.gz

BuildRequires:  cargo >= 1.83
BuildRequires:  rust >= 1.83
BuildRequires:  gcc

%description
iamb is a Matrix client for the terminal that uses Vim keybindings. It supports
multiple profiles, threads, spaces, notifications, custom commands, and more.
The interface is designed to be familiar to Vim users while providing full
Matrix functionality.

%prep
%autosetup -n %{name}-%{version}

%build
RUSTFLAGS='-C strip=symbols' cargo build --release --locked

%install
install -Dpm 0755 target/release/iamb %{buildroot}%{_bindir}/iamb

%files
%license LICENSE
%doc README.md
%{_bindir}/iamb

%changelog
* Thu Jan 30 2026 Hypercube <hypercube@binarypie.dev> - 0.0.11-1
- Initial package for Hypercube
