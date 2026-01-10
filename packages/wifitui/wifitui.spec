# NOTE: This package requires "Enable internet access during builds" in COPR settings
# because go needs to download dependencies

%global debug_package %{nil}

Name:           wifitui
Version:        0.10.0
Release:        1%{?dist}
Summary:        Fast featureful friendly wifi terminal UI

License:        MIT
URL:            https://github.com/shazow/wifitui
Source0:        %{url}/archive/v%{version}/%{name}-%{version}.tar.gz

BuildRequires:  golang >= 1.21
BuildRequires:  git

%description
A fast, featureful, and friendly replacement for nmtui. Features include
multiple backends (NetworkManager and iwd), fuzzy filtering, QR code sharing,
sort by recency, and more. Powered by bubbletea.

%prep
%autosetup -n %{name}-%{version}

%build
go build -ldflags "-X main.version=%{version}" -o %{name} .

%install
install -Dpm 0755 %{name} %{buildroot}%{_bindir}/%{name}

%files
%license LICENSE
%doc README.md
%{_bindir}/%{name}

%changelog
* Sat Jan 10 2026 Hypercube <hypercube@binarypie.dev> - 0.10.0-1
- Update to 0.10.0
* Thu Jan 09 2025 Hypercube <hypercube@binarypie.dev> - 0.9.0-1
- Initial package for Hypercube
