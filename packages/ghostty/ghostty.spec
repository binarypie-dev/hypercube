Name:           ghostty
Version:        1.2.3
Release:        1%{?dist}
Summary:        Fast, feature-rich, cross-platform terminal emulator

License:        MIT
URL:            https://github.com/ghostty-org/ghostty
Source0:        %{url}/archive/v%{version}/%{name}-%{version}.tar.gz

# Ghostty requires Zig 0.15.2 which is not in Fedora repos
# We download the official binary
%global zig_version 0.15.0
%global zig_arch x86_64

BuildRequires:  gcc
BuildRequires:  git
BuildRequires:  pkg-config
BuildRequires:  fontconfig-devel
BuildRequires:  freetype-devel
BuildRequires:  gtk4-devel
BuildRequires:  libadwaita-devel
BuildRequires:  libX11-devel
BuildRequires:  libXcursor-devel
BuildRequires:  libXrandr-devel
BuildRequires:  pandoc
BuildRequires:  bzip2-devel
BuildRequires:  oniguruma-devel
BuildRequires:  lz4-devel
BuildRequires:  zstd-devel
BuildRequires:  libpng-devel

Requires:       fontconfig
Requires:       freetype
Requires:       gtk4
Requires:       libadwaita

%description
Ghostty is a terminal emulator that differentiates itself by being both
incredibly fast and feature-rich. It's built with GPU acceleration,
native platform feel, and a focus on performance.

%prep
%autosetup -n %{name}-%{version}

# Download Zig
curl -L -o zig.tar.xz https://ziglang.org/download/%{zig_version}/zig-linux-%{zig_arch}-%{zig_version}.tar.xz
tar xf zig.tar.xz
export PATH="$PWD/zig-linux-%{zig_arch}-%{zig_version}:$PATH"

# Fetch dependencies for offline build
./nix/build-support/fetch-zig-cache.sh

%build
export PATH="$PWD/zig-linux-%{zig_arch}-%{zig_version}:$PATH"
zig build \
    --prefix %{_prefix} \
    --system \
    -Doptimize=ReleaseFast \
    -Dcpu=baseline \
    -Dpie=true

%install
export PATH="$PWD/zig-linux-%{zig_arch}-%{zig_version}:$PATH"
DESTDIR=%{buildroot} zig build install \
    --prefix %{_prefix} \
    --system \
    -Doptimize=ReleaseFast \
    -Dcpu=baseline \
    -Dpie=true

%files
%license LICENSE
%doc README.md
%{_bindir}/%{name}
%{_datadir}/applications/%{name}.desktop
%{_datadir}/icons/hicolor/*/apps/%{name}.*
%{_datadir}/%{name}/
%{_datadir}/bash-completion/completions/%{name}
%{_datadir}/zsh/site-functions/_%{name}
%{_datadir}/fish/vendor_completions.d/%{name}.fish
%{_mandir}/man1/%{name}.1*
%{_mandir}/man5/%{name}.5*

%changelog
* Mon Dec 16 2024 Hypercube <hypercube@binarypie.dev> - 1.2.3-1
- Initial package for Hypercube
