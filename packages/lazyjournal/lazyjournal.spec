# NOTE: This package requires "Enable internet access during builds" in COPR settings
# because go needs to download dependencies

%global debug_package %{nil}

Name:           lazyjournal
Version:        0.8.4
Release:        1%{?dist}
Summary:        TUI for viewing systemd journal and container logs

License:        MIT
URL:            https://github.com/Lifailon/lazyjournal
Source0:        %{url}/archive/%{version}/%{name}-%{version}.tar.gz

BuildRequires:  golang >= 1.21
BuildRequires:  git

%description
LazyJournal is a TUI for viewing journalctl/systemd logs as well as Docker,
Podman, and Kubernetes container logs. It provides a unified interface for
browsing and filtering logs from multiple sources.

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
* Thu Jan 30 2026 Hypercube <hypercube@binarypie.dev> - 0.8.4-1
- Initial package for Hypercube
