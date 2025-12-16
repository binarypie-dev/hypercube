# NOTE: This package requires "Enable internet access during builds" in COPR settings
# Building from main branch commit that supports zig 0.15.2 (Fedora 43)

%global commit ab3a3805aa2db46eafc8c7a497df24665fa5e21b
%global shortcommit %(c=%{commit}; echo ${c:0:7})
%global commitdate 20251216

Name:           ghostty
Version:        1.2.3^%{commitdate}git%{shortcommit}
Release:        1%{?dist}
Summary:        Fast, feature-rich, and cross-platform terminal emulator

License:        MIT
URL:            https://github.com/ghostty-org/ghostty
Source0:        %{url}/archive/%{commit}/%{name}-%{shortcommit}.tar.gz

ExclusiveArch:  x86_64 aarch64

BuildRequires:  blueprint-compiler
BuildRequires:  fontconfig-devel
BuildRequires:  freetype-devel
BuildRequires:  glib2-devel
BuildRequires:  gtk4-devel
BuildRequires:  gtk4-layer-shell-devel
BuildRequires:  harfbuzz-devel
BuildRequires:  libadwaita-devel
BuildRequires:  libpng-devel
BuildRequires:  oniguruma-devel
BuildRequires:  pandoc-cli
BuildRequires:  pixman-devel
BuildRequires:  pkg-config
BuildRequires:  wayland-protocols-devel
BuildRequires:  zig
BuildRequires:  zlib-ng-devel

Requires:       fontconfig
Requires:       freetype
Requires:       glib2
Requires:       gtk4
Requires:       harfbuzz
Requires:       libadwaita
Requires:       libpng
Requires:       oniguruma
Requires:       pixman
Requires:       zlib-ng

%description
Ghostty is a terminal emulator that differentiates itself by being both
fast and feature-rich. It uses platform-native UI and GPU acceleration.

%prep
%setup -q -n %{name}-%{commit}

%build
zig build \
    --summary all \
    --prefix "%{_prefix}" \
    -Dversion-string=%{version}-%{release} \
    -Doptimize=ReleaseFast \
    -Dcpu=baseline \
    -Dpie=true \
    -Demit-docs

%install
DESTDIR=%{buildroot} zig build install \
    --prefix "%{_prefix}" \
    -Dversion-string=%{version}-%{release} \
    -Doptimize=ReleaseFast \
    -Dcpu=baseline \
    -Dpie=true \
    -Demit-docs

# Remove terminfo that conflicts with ncurses
rm -f "%{buildroot}%{_datadir}/terminfo/g/ghostty"

%files
%license LICENSE
%{_bindir}/ghostty
%{_datadir}/applications/com.mitchellh.ghostty.desktop
%{_datadir}/bash-completion/completions/ghostty.bash
%{_datadir}/bat/syntaxes/ghostty.sublime-syntax
%{_datadir}/fish/vendor_completions.d/ghostty.fish
%{_datadir}/ghostty/
%{_datadir}/icons/hicolor/*/apps/com.mitchellh.ghostty.png
%{_datadir}/kio/servicemenus/com.mitchellh.ghostty.desktop
%{_datadir}/man/man1/ghostty.1*
%{_datadir}/man/man5/ghostty.5*
%{_datadir}/nautilus-python/extensions/ghostty.py
%{_datadir}/nvim/site/compiler/ghostty.vim
%{_datadir}/nvim/site/ftdetect/ghostty.vim
%{_datadir}/nvim/site/ftplugin/ghostty.vim
%{_datadir}/nvim/site/syntax/ghostty.vim
%{_datadir}/vim/vimfiles/compiler/ghostty.vim
%{_datadir}/vim/vimfiles/ftdetect/ghostty.vim
%{_datadir}/vim/vimfiles/ftplugin/ghostty.vim
%{_datadir}/vim/vimfiles/syntax/ghostty.vim
%{_datadir}/zsh/site-functions/_ghostty
%{_datadir}/dbus-1/services/com.mitchellh.ghostty.service
%{_datadir}/locale/*/LC_MESSAGES/com.mitchellh.ghostty.mo
%{_datadir}/metainfo/com.mitchellh.ghostty.metainfo.xml

%changelog
* Mon Dec 16 2024 Hypercube <hypercube@binarypie.dev> - 1.2.3-1
- Initial package for Hypercube
