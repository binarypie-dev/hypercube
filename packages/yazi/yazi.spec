# NOTE: This package requires "Enable internet access during builds" in COPR settings
# because cargo needs to download dependencies

%global debug_package %{nil}

Name:           yazi
Version:        26.1.22
Release:        1%{?dist}
Summary:        Blazing fast terminal file manager written in Rust

License:        MIT
URL:            https://github.com/sxyazi/yazi
Source0:        %{url}/archive/v%{version}/%{name}-%{version}.tar.gz

BuildRequires:  cargo >= 1.80
BuildRequires:  rust >= 1.80
BuildRequires:  gcc
BuildRequires:  make
BuildRequires:  git

Requires:       file

Recommends:     ffmpeg
Recommends:     p7zip
Recommends:     jq
Recommends:     poppler-utils
Recommends:     fd-find
Recommends:     ripgrep
Recommends:     fzf
Recommends:     zoxide
Recommends:     ImageMagick
Recommends:     resvg

%description
Yazi is a blazing fast terminal file manager written in Rust, based on async I/O.
It provides an efficient, user-friendly, and customizable file management experience
with features like image preview, plugin support, and multi-tab interface.

%prep
%autosetup -n %{name}-%{version}

%build
export YAZI_GEN_COMPLETIONS=1
RUSTFLAGS='-C strip=symbols' cargo build --release --locked

%install
install -Dpm 0755 target/release/yazi %{buildroot}%{_bindir}/yazi
install -Dpm 0755 target/release/ya %{buildroot}%{_bindir}/ya

# Install shell completions
install -Dpm 0644 yazi-boot/completions/yazi.bash %{buildroot}%{_datadir}/bash-completion/completions/yazi
install -Dpm 0644 yazi-boot/completions/yazi.fish %{buildroot}%{_datadir}/fish/vendor_completions.d/yazi.fish
install -Dpm 0644 yazi-boot/completions/_yazi %{buildroot}%{_datadir}/zsh/site-functions/_yazi

install -Dpm 0644 yazi-cli/completions/ya.bash %{buildroot}%{_datadir}/bash-completion/completions/ya
install -Dpm 0644 yazi-cli/completions/ya.fish %{buildroot}%{_datadir}/fish/vendor_completions.d/ya.fish
install -Dpm 0644 yazi-cli/completions/_ya %{buildroot}%{_datadir}/zsh/site-functions/_ya

# Remove cargo artifacts
rm -f %{buildroot}%{_prefix}/.crates.toml
rm -f %{buildroot}%{_prefix}/.crates2.json

%files
%license LICENSE
%doc README.md
%{_bindir}/yazi
%{_bindir}/ya
%{_datadir}/bash-completion/completions/yazi
%{_datadir}/bash-completion/completions/ya
%{_datadir}/fish/vendor_completions.d/yazi.fish
%{_datadir}/fish/vendor_completions.d/ya.fish
%{_datadir}/zsh/site-functions/_yazi
%{_datadir}/zsh/site-functions/_ya

%changelog
* Thu Jan 30 2026 Hypercube <hypercube@binarypie.dev> - 26.1.22-1
- Initial package for Hypercube
