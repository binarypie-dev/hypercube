# NOTE: This package requires "Enable internet access during builds" in COPR
# settings — cargo fetches crates over the network during the build.

%global debug_package %{nil}

Name:           alacritty
Version:        0.17.0
Release:        1%{?dist}
Summary:        A cross-platform, OpenGL terminal emulator

License:        Apache-2.0
URL:            https://github.com/alacritty/alacritty
Source0:        %{url}/archive/v%{version}/%{name}-%{version}.tar.gz

# Built with Fedora's own rust/cargo (not rustup): Alacritty's MSRV sits well
# below the Rust that Fedora 44 ships, so there's no need to bootstrap a pinned
# toolchain the way zellij does. cargo still fetches crates, hence the internet
# note above.
BuildRequires:  rust
BuildRequires:  cargo
BuildRequires:  cmake
BuildRequires:  gcc-c++
BuildRequires:  freetype-devel
BuildRequires:  fontconfig-devel
BuildRequires:  libxcb-devel
BuildRequires:  libxkbcommon-devel
BuildRequires:  scdoc
BuildRequires:  gzip
BuildRequires:  desktop-file-utils
BuildRequires:  git
BuildRequires:  ncurses

%description
Alacritty is a modern terminal emulator that comes with sensible defaults, but
allows for extensive configuration. By integrating with other applications,
rather than reimplementing their functionality, it manages to provide a flexible
set of features with high performance.

%prep
%autosetup -n %{name}-%{version}

%build
RUSTFLAGS='-C strip=symbols' cargo build --release --locked

%install
# Main binary
install -Dpm0755 target/release/%{name} %{buildroot}%{_bindir}/%{name}

# Terminfo (alacritty + alacritty-direct), compiled into the package's terminfo db
tic -xe alacritty,alacritty-direct -o %{buildroot}%{_datadir}/terminfo extra/%{name}.info

# Desktop entry + icon
desktop-file-install --dir=%{buildroot}%{_datadir}/applications extra/linux/Alacritty.desktop
install -Dpm0644 extra/logo/alacritty-term.svg %{buildroot}%{_datadir}/pixmaps/Alacritty.svg

# Man pages (scdoc -> gzip)
mkdir -p %{buildroot}%{_mandir}/man1 %{buildroot}%{_mandir}/man5 %{buildroot}%{_mandir}/man7
scdoc < extra/man/alacritty.1.scd          | gzip -c > %{buildroot}%{_mandir}/man1/alacritty.1.gz
scdoc < extra/man/alacritty-msg.1.scd      | gzip -c > %{buildroot}%{_mandir}/man1/alacritty-msg.1.gz
scdoc < extra/man/alacritty.5.scd          | gzip -c > %{buildroot}%{_mandir}/man5/alacritty.5.gz
scdoc < extra/man/alacritty-bindings.5.scd | gzip -c > %{buildroot}%{_mandir}/man5/alacritty-bindings.5.gz
scdoc < extra/man/alacritty-escapes.7.scd  | gzip -c > %{buildroot}%{_mandir}/man7/alacritty-escapes.7.gz

# Shell completions
install -Dpm0644 extra/completions/alacritty.bash %{buildroot}%{_datadir}/bash-completion/completions/%{name}
install -Dpm0644 extra/completions/_alacritty     %{buildroot}%{_datadir}/zsh/site-functions/_%{name}
install -Dpm0644 extra/completions/alacritty.fish %{buildroot}%{_datadir}/fish/vendor_completions.d/%{name}.fish

%files
%license LICENSE-APACHE LICENSE-MIT
%doc README.md CHANGELOG.md
%{_bindir}/%{name}
%{_datadir}/terminfo/a/alacritty
%{_datadir}/terminfo/a/alacritty-direct
%{_datadir}/applications/Alacritty.desktop
%{_datadir}/pixmaps/Alacritty.svg
%{_mandir}/man1/alacritty.1.gz
%{_mandir}/man1/alacritty-msg.1.gz
%{_mandir}/man5/alacritty.5.gz
%{_mandir}/man5/alacritty-bindings.5.gz
%{_mandir}/man7/alacritty-escapes.7.gz
%{_datadir}/bash-completion/completions/%{name}
%{_datadir}/zsh/site-functions/_%{name}
%{_datadir}/fish/vendor_completions.d/%{name}.fish

%changelog
* Fri Jul 04 2026 Hypercube <hypercube@binarypie.dev> - 0.17.0-1
- Initial package for Hypercube
- Build with Fedora's rust/cargo (Alacritty MSRV is below Fedora's Rust)
- Package terminfo, desktop entry, man pages, and shell completions
