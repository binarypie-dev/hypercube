# NOTE: This package requires "Enable internet access during builds" in COPR settings

%global debug_package %{nil}

Name:           eza
Version:        0.20.21
Release:        1%{?dist}
Summary:        Modern replacement for ls

License:        EUPL-1.2
URL:            https://github.com/eza-community/eza
Source0:        %{url}/archive/v%{version}/%{name}-%{version}.tar.gz

BuildRequires:  cargo
BuildRequires:  rust
BuildRequires:  pandoc

%description
eza is a modern replacement for the venerable file-listing command-line program
ls that ships with Unix and Linux operating systems, giving it more features
and better defaults.

%prep
%autosetup -n %{name}-%{version}

%build
export RUSTFLAGS="%{build_rustflags}"
cargo build --release --locked

%install
install -Dpm 0755 target/release/%{name} -t %{buildroot}%{_bindir}/

# Generate and install man pages
mkdir -p target/man
for page in eza.1 eza_colors.5 eza_colors-explanation.5; do
    sed "s/\$version/v%{version}/g" "man/${page}.md" | pandoc --standalone -f markdown -t man > "target/man/${page}"
done
install -Dpm 0644 target/man/eza.1 -t %{buildroot}/%{_mandir}/man1/
install -Dpm 0644 target/man/eza_colors.5 -t %{buildroot}/%{_mandir}/man5/
install -Dpm 0644 target/man/eza_colors-explanation.5 -t %{buildroot}/%{_mandir}/man5/

# Install shell completions
install -Dpm 0644 completions/bash/%{name} -t %{buildroot}/%{_datadir}/bash-completion/completions/
install -Dpm 0644 completions/zsh/_%{name} -t %{buildroot}/%{_datadir}/zsh/site-functions/
install -Dpm 0644 completions/fish/%{name}.fish -t %{buildroot}/%{_datadir}/fish/vendor_completions.d/

%files
%license LICENSE.txt
%doc README.md CHANGELOG.md
%{_bindir}/%{name}
%{_mandir}/man1/eza.1*
%{_mandir}/man5/eza_colors*
%{_datadir}/bash-completion/completions/%{name}
%{_datadir}/zsh/site-functions/_%{name}
%{_datadir}/fish/vendor_completions.d/%{name}.fish

%changelog
* Mon Dec 16 2024 Hypercube <hypercube@binarypie.dev> - 0.20.21-1
- Initial package for Hypercube
