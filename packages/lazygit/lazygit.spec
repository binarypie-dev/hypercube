Name:           lazygit
Version:        0.57.0
Release:        1%{?dist}
Summary:        Simple terminal UI for git commands

License:        MIT
URL:            https://github.com/jesseduffield/lazygit
Source0:        %{url}/archive/v%{version}/%{name}-%{version}.tar.gz

BuildRequires:  golang >= 1.21
BuildRequires:  git

%description
A simple terminal UI for git commands. Lazygit makes it easier to add files,
resolve merge conflicts, checkout recent branches, scroll through logs/diffs
and more. It's designed to make git less painful.

%prep
%autosetup -n %{name}-%{version}

%build
export GOFLAGS="-buildmode=pie -trimpath"
export LDFLAGS="-X main.version=%{version} -X main.buildSource=rpm"
go build -ldflags "${LDFLAGS}" -o %{name}

%install
install -Dpm 0755 %{name} %{buildroot}%{_bindir}/%{name}

%files
%license LICENSE
%doc README.md
%{_bindir}/%{name}

%changelog
* Mon Dec 16 2024 Hypercube <hypercube@binarypie.dev> - 0.57.0-1
- Initial package for Hypercube
