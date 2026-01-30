# NOTE: This package requires "Enable internet access during builds" in COPR settings
# because cargo needs to download dependencies

%global debug_package %{nil}

Name:           meli
Version:        0.8.13
Release:        1%{?dist}
Summary:        Terminal email client

License:        GPL-3.0-or-later
URL:            https://meli-email.org
Source0:        https://git.meli-email.org/meli/meli/archive/v%{version}.tar.gz

BuildRequires:  cargo >= 1.85
BuildRequires:  rust >= 1.85
BuildRequires:  gcc
BuildRequires:  pkgconfig
BuildRequires:  pkgconfig(sqlite3)
BuildRequires:  pkgconfig(dbus-1)
BuildRequires:  openssl-devel
BuildRequires:  perl-interpreter
BuildRequires:  mandoc
BuildRequires:  zlib-devel
BuildRequires:  libcurl-devel
BuildRequires:  libnghttp2-devel

Recommends:     gpgme
Recommends:     notmuch

%description
meli is a configurable and extensible terminal email client with sane defaults.
It supports IMAP, Maildir, notmuch, JMAP, mbox, and NNTP backends. Features include
email threading, tabs for multitasking, GPG support, and contact management.

%prep
%autosetup -n %{name}

%build
export OPENSSL_NO_VENDOR=1
export LIBZ_SYS_STATIC=0
export LIBSQLITE3_SYS_USE_PKG_CONFIG=1
RUSTFLAGS='-C strip=symbols' cargo build --release --locked --bin meli --no-default-features --features "sqlite3 notmuch smtp dbus-notifications gpgme cli-docs jmap"

%install
install -Dpm 0755 target/release/meli %{buildroot}%{_bindir}/meli

%files
%license COPYING
%doc README.md
%{_bindir}/meli

%changelog
* Thu Jan 30 2026 Hypercube <hypercube@binarypie.dev> - 0.8.13-1
- Initial package for Hypercube
