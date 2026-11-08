# NOTE: This package requires "Enable internet access during builds" in COPR settings
# because go needs to download dependencies

%global debug_package %{nil}

Name:           lazyjournal
Version:        0.8.7
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
# Upstream go.mod may require a newer Go than the chroot ships; let Go fetch
# the required toolchain (internet access is already enabled for this package)
export GOTOOLCHAIN=auto
go build -ldflags "-X main.version=%{version}" -o %{name}

%install
install -Dpm 0755 %{name} %{buildroot}%{_bindir}/%{name}

%files
%license LICENSE
%doc README.md
%{_bindir}/%{name}

%changelog
* Fri Nov 06 2026 Hypercube <hypercube@binarypie.dev> - 0.8.7-1
- Update to 0.8.7
* Tue Mar 17 2026 Hypercube <hypercube@binarypie.dev> - 0.8.6-1
- Update to 0.8.6
* Fri Feb 06 2026 Hypercube <hypercube@binarypie.dev> - 0.8.5-1
- Update to 0.8.5
* Fri Jan 30 2026 Hypercube <hypercube@binarypie.dev> - 0.8.4-1
- Initial package for Hypercube
