Name:           neovim
Version:        0.11.5
Release:        1%{?dist}
Summary:        Vim-fork focused on extensibility and usability

License:        Apache-2.0 AND Vim
URL:            https://github.com/neovim/neovim
Source0:        %{url}/archive/v%{version}/%{name}-%{version}.tar.gz

BuildRequires:  cmake >= 3.16
BuildRequires:  ninja-build
BuildRequires:  gcc
BuildRequires:  make
BuildRequires:  gettext
BuildRequires:  glibc-gconv-extra
BuildRequires:  git
BuildRequires:  unzip

# Runtime dependencies
Requires:       lua
Requires:       python3-neovim

%description
Neovim is a refactor, and sometimes redactor, in the tradition of Vim (which
itself derives from Stevie). It is not a rewrite but a continuation and
extension of Vim. Many clones and derivatives exist, some very clever - but
none are Vim. Neovim is built for users who want the good parts of Vim, and
more.

%package -n python3-neovim
Summary:        Python client for Neovim
BuildArch:      noarch
Requires:       python3
Requires:       python3-msgpack
Requires:       python3-greenlet

%description -n python3-neovim
Python client library for Neovim, enabling Python plugins and remote
communication with Neovim instances.

%prep
%autosetup -n %{name}-%{version}

%build
%cmake \
    -GNinja \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX=%{_prefix}

%cmake_build

%install
%cmake_install

# Desktop file and icons are installed by cmake

%files
%license LICENSE.txt
%doc README.md CONTRIBUTING.md
%{_bindir}/nvim
%{_datadir}/nvim/
%{_datadir}/applications/nvim.desktop
%{_datadir}/icons/hicolor/*/apps/nvim.*
%{_datadir}/locale/*/LC_MESSAGES/nvim.mo
%{_mandir}/man1/nvim.1*

%changelog
* Mon Dec 16 2024 Hypercube <hypercube@binarypie.dev> - 0.11.5-1
- Initial package for Hypercube
