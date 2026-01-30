# NOTE: This package requires "Enable internet access during builds" in COPR settings
# because go needs to download dependencies

%global debug_package %{nil}

Name:           podman-tui
Version:        1.10.0
Release:        1%{?dist}
Summary:        TUI for managing Podman containers

License:        Apache-2.0
URL:            https://github.com/containers/podman-tui
Source0:        %{url}/archive/v%{version}/%{name}-%{version}.tar.gz

BuildRequires:  golang >= 1.21
BuildRequires:  git

Requires:       podman

%description
Podman TUI is a terminal user interface for managing Podman containers,
pods, images, volumes, and networks. It communicates with local or remote
Podman machines through the Podman socket or SSH.

%prep
%autosetup -n %{name}-%{version}

%build
go build -ldflags "-X main.version=%{version}" -o %{name}

%install
install -Dpm 0755 %{name} %{buildroot}%{_bindir}/%{name}

%files
%license LICENSE
%doc README.md
%{_bindir}/%{name}

%changelog
* Thu Jan 30 2026 Hypercube <hypercube@binarypie.dev> - 1.10.0-1
- Initial package for Hypercube
