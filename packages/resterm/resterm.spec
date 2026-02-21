# NOTE: This package requires "Enable internet access during builds" in COPR settings
# because go needs to download dependencies

%global debug_package %{nil}

Name:           resterm
Version:        0.23.3
Release:        1%{?dist}
Summary:        TUI REST, gRPC, and WebSocket API client

License:        Apache-2.0
URL:            https://github.com/unkn0wn-root/resterm
Source0:        %{url}/archive/v%{version}/%{name}-%{version}.tar.gz

BuildRequires:  golang >= 1.21
BuildRequires:  git

%description
Resterm is a terminal-based API client supporting REST, gRPC, and WebSocket
protocols. Features include request history, environment variables, SSH tunnels,
and OpenTelemetry integration.

%prep
%autosetup -n %{name}-%{version}

%build
go build -ldflags "-X main.version=%{version}" -o %{name} ./cmd/resterm

%install
install -Dpm 0755 %{name} %{buildroot}%{_bindir}/%{name}

%files
%license LICENSE
%doc README.md
%{_bindir}/%{name}

%changelog
* Sat Feb 21 2026 Hypercube <hypercube@binarypie.dev> - 0.23.3-1
- Update to 0.23.3
* Fri Feb 06 2026 Hypercube <hypercube@binarypie.dev> - 0.21.3-1
- Update to 0.21.3
* Thu Jan 30 2026 Hypercube <hypercube@binarypie.dev> - 0.20.3-1
- Initial package for Hypercube
