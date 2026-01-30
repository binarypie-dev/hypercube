# NOTE: This package requires "Enable internet access during builds" in COPR settings
# because go needs to download dependencies

%global debug_package %{nil}

Name:           lazysql
Version:        0.4.6
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
* Thu Jan 30 2026 Hypercube <hypercube@binarypie.dev> - 0.4.6-1
- Initial package for Hypercube
