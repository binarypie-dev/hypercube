# NOTE: This package requires "Enable internet access during builds" in COPR settings
# because cargo needs to download dependencies

%global debug_package %{nil}

Name:           regreet
Version:        0.2.0
Release:        1%{?dist}
Summary:        Clean and customizable GTK4 greeter for greetd

License:        GPL-3.0-or-later
URL:            https://github.com/rharish101/ReGreet
Source0:        %{url}/archive/%{version}/%{name}-%{version}.tar.gz

ExcludeArch:    %{ix86}

BuildRequires:  rust >= 1.75.0
BuildRequires:  cargo
BuildRequires:  pkgconfig(gtk4) >= 4.0
BuildRequires:  pkgconfig(glib-2.0)
BuildRequires:  pkgconfig(pango)
BuildRequires:  pkgconfig(cairo)

Requires:       greetd
Requires:       gtk4
Requires:       cage

%description
ReGreet is a clean and customizable GTK4-based greeter for greetd.
It provides a modern login screen experience for Wayland compositors.

Features:
- Customizable appearance with CSS
- Background image support
- Session selection
- User management

%prep
%autosetup -n ReGreet-%{version}

%build
cargo build --release -F gtk4_8

%install
install -Dpm 0755 target/release/%{name} %{buildroot}%{_bindir}/%{name}

# Create cache directory
install -dm 0755 %{buildroot}%{_localstatedir}/cache/%{name}

%files
%license LICENSE
%doc README.md
%{_bindir}/%{name}
%dir %{_localstatedir}/cache/%{name}

%changelog
* Tue Dec 31 2024 Hypercube <hypercube@binarypie.dev> - 0.2.0-1
- Initial package for Hypercube
