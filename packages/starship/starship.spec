Name:           starship
Version:        1.24.1
Release:        1%{?dist}
Summary:        Minimal, blazing-fast, and infinitely customizable prompt for any shell

License:        ISC
URL:            https://github.com/starship/starship
Source0:        %{url}/archive/v%{version}/%{name}-%{version}.tar.gz

BuildRequires:  cargo
BuildRequires:  rust
BuildRequires:  gcc
BuildRequires:  cmake
BuildRequires:  openssl-devel
BuildRequires:  zlib-devel

%description
Starship is the minimal, blazing-fast, and infinitely customizable prompt for
any shell! The prompt shows information you need while you're working, while
staying sleek and out of the way. It works with Bash, Zsh, Fish, PowerShell,
Ion, Elvish, Tcsh, Xonsh, Nushell, and Cmd.

%prep
%autosetup -n %{name}-%{version}

%build
cargo build --release --locked

%install
install -Dpm 0755 target/release/%{name} %{buildroot}%{_bindir}/%{name}

# Generate and install shell completions
mkdir -p %{buildroot}%{_datadir}/bash-completion/completions
mkdir -p %{buildroot}%{_datadir}/zsh/site-functions
mkdir -p %{buildroot}%{_datadir}/fish/vendor_completions.d
target/release/%{name} completions bash > %{buildroot}%{_datadir}/bash-completion/completions/%{name}
target/release/%{name} completions zsh > %{buildroot}%{_datadir}/zsh/site-functions/_%{name}
target/release/%{name} completions fish > %{buildroot}%{_datadir}/fish/vendor_completions.d/%{name}.fish

%files
%license LICENSE
%doc README.md CHANGELOG.md
%{_bindir}/%{name}
%{_datadir}/bash-completion/completions/%{name}
%{_datadir}/zsh/site-functions/_%{name}
%{_datadir}/fish/vendor_completions.d/%{name}.fish

%changelog
* Mon Dec 16 2024 Hypercube <hypercube@binarypie.dev> - 1.24.1-1
- Initial package for Hypercube
