Name:           eza
Version:        0.20.21
Release:        1%{?dist}
Summary:        Modern replacement for ls

License:        EUPL-1.2
URL:            https://github.com/eza-community/eza
Source0:        %{url}/archive/v%{version}/%{name}-%{version}.tar.gz

BuildRequires:  cargo
BuildRequires:  rust
BuildRequires:  gcc
BuildRequires:  pandoc
BuildRequires:  git

%description
eza is a modern replacement for the venerable file-listing command-line program
ls that ships with Unix and Linux operating systems, giving it more features
and better defaults.

%prep
%autosetup -n %{name}-%{version}

%build
cargo build --release --locked

%install
install -Dpm 0755 target/release/%{name} %{buildroot}%{_bindir}/%{name}

# Generate and install man pages
mkdir -p %{buildroot}%{_mandir}/man1
mkdir -p %{buildroot}%{_mandir}/man5
pandoc --standalone -f markdown -t man man/eza.1.md -o %{buildroot}%{_mandir}/man1/eza.1
pandoc --standalone -f markdown -t man man/eza_colors.5.md -o %{buildroot}%{_mandir}/man5/eza_colors.5
pandoc --standalone -f markdown -t man man/eza_colors-explanation.5.md -o %{buildroot}%{_mandir}/man5/eza_colors-explanation.5

# Install shell completions
install -Dpm 0644 completions/bash/%{name} %{buildroot}%{_datadir}/bash-completion/completions/%{name}
install -Dpm 0644 completions/zsh/_%{name} %{buildroot}%{_datadir}/zsh/site-functions/_%{name}
install -Dpm 0644 completions/fish/%{name}.fish %{buildroot}%{_datadir}/fish/vendor_completions.d/%{name}.fish

%files
%license LICENCE
%doc README.md CHANGELOG.md
%{_bindir}/%{name}
%{_mandir}/man1/eza.1*
%{_mandir}/man5/eza_colors.5*
%{_mandir}/man5/eza_colors-explanation.5*
%{_datadir}/bash-completion/completions/%{name}
%{_datadir}/zsh/site-functions/_%{name}
%{_datadir}/fish/vendor_completions.d/%{name}.fish

%changelog
* Mon Dec 16 2024 Hypercube <hypercube@binarypie.dev> - 0.20.21-1
- Initial package for Hypercube
