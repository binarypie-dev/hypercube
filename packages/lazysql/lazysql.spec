# NOTE: This package requires "Enable internet access during builds" in COPR settings
# because go needs to download dependencies

%global debug_package %{nil}

Name:           lazysql
Version:        0.5.5
Release:        1%{?dist}
Summary:        TUI database management client

License:        MIT
URL:            https://github.com/jorgerojas26/lazysql
Source0:        %{url}/archive/v%{version}/%{name}-%{version}.tar.gz

BuildRequires:  golang >= 1.21
BuildRequires:  git

Recommends:     xclip

%description
LazySQL is a cross-platform TUI database management tool. It supports
PostgreSQL, MySQL, SQLite, and Microsoft SQL Server. Features include
query execution, table browsing, and connection management.

%prep
%autosetup -n %{name}-%{version}

%build
go build -ldflags "-X main.version=%{version}" -o %{name}

%install
install -Dpm 0755 %{name} %{buildroot}%{_bindir}/%{name}

%files
%license LICENSE.txt
%doc README.md
%{_bindir}/%{name}

%changelog
* Tue Jun 30 2026 Hypercube <hypercube@binarypie.dev> - 0.5.5-1
- Update to 0.5.5
* Tue Jun 09 2026 Hypercube <hypercube@binarypie.dev> - 0.5.4-1
- Update to 0.5.4
* Tue Jun 02 2026 Hypercube <hypercube@binarypie.dev> - 0.5.3-1
- Update to 0.5.3
* Fri May 08 2026 Hypercube <hypercube@binarypie.dev> - 0.5.0-1
- Update to 0.5.0
* Wed Feb 18 2026 Hypercube <hypercube@binarypie.dev> - 0.4.8-1
- Update to 0.4.8
* Thu Jan 30 2026 Hypercube <hypercube@binarypie.dev> - 0.4.6-1
- Initial package for Hypercube
