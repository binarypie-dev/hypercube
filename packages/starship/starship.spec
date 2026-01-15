%global debug_package %{nil}

Name:           starship
Version:        1.24.2
Release:        1%{?dist}
Summary:        Minimal, blazing-fast, and infinitely customizable prompt for any shell

License:        ISC
URL:            https://github.com/starship/starship
Source0:        %{url}/archive/v%{version}/%{name}-%{version}.tar.gz

BuildRequires:  cargo >= 1.80
BuildRequires:  rust >= 1.80
BuildRequires:  gcc
BuildRequires:  cmake3
BuildRequires:  pkgconfig(openssl)
BuildRequires:  pkgconfig(zlib)

%description
Starship is the minimal, blazing-fast, and infinitely customizable prompt for
any shell! The prompt shows information you need while you're working, while
staying sleek and out of the way. It works with Bash, Zsh, Fish, PowerShell,
Ion, Elvish, Tcsh, Xonsh, Nushell, and Cmd.

%prep
%autosetup -n %{name}-%{version}

%build
# Build handled in install

%install
export CARGO_PROFILE_RELEASE_BUILD_OVERRIDE_OPT_LEVEL=3
export CMAKE=cmake3
RUSTFLAGS='-C strip=symbols' cargo install --root=%{buildroot}%{_prefix} --path=.

# Generate and install shell completions
mkdir -p %{buildroot}%{_datadir}/bash-completion/completions
mkdir -p %{buildroot}%{_datadir}/zsh/site-functions
mkdir -p %{buildroot}%{_datadir}/fish/vendor_completions.d
%{buildroot}%{_bindir}/%{name} completions bash > %{buildroot}%{_datadir}/bash-completion/completions/%{name}
%{buildroot}%{_bindir}/%{name} completions zsh > %{buildroot}%{_datadir}/zsh/site-functions/_%{name}
%{buildroot}%{_bindir}/%{name} completions fish > %{buildroot}%{_datadir}/fish/vendor_completions.d/%{name}.fish

# Remove .crates.toml and .crates2.json created by cargo install
rm -f %{buildroot}%{_prefix}/.crates.toml
rm -f %{buildroot}%{_prefix}/.crates2.json

%files
%license LICENSE
%doc README.md CHANGELOG.md
%{_bindir}/%{name}
%{_datadir}/bash-completion/completions/%{name}
%{_datadir}/zsh/site-functions/_%{name}
%{_datadir}/fish/vendor_completions.d/%{name}.fish

%changelog
* Thu Jan 15 2026 Hypercube <hypercube@binarypie.dev> - 1.24.2-1
- Update to 1.24.2
* Mon Dec 16 2024 Hypercube <hypercube@binarypie.dev> - 1.24.1-1
- Initial package for Hypercube
