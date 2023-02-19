Name:           harbour-qrclip
Summary:        QR code generator
Version:        1.0.11
Release:        1
License:        BSD
Group:          Applications/Productivity
URL:            https://github.com/monich/harbour-qrclip
Source0:        %{name}-%{version}.tar.gz

Requires:       sailfishsilica-qt5
Requires:       qt5-qtsvg-plugin-imageformat-svg
BuildRequires:  pkgconfig(sailfishapp)
BuildRequires:  pkgconfig(Qt5Core)
BuildRequires:  pkgconfig(Qt5Qml)
BuildRequires:  pkgconfig(Qt5Quick)
BuildRequires:  pkgconfig(Qt5Concurrent)
BuildRequires:  qt5-qttools-linguist

%{!?qtc_qmake5:%define qtc_qmake5 %qmake5}
%{!?qtc_make:%define qtc_make make}
%{?qtc_builddir:%define _builddir %qtc_builddir}

%description
Generates QR codes from clipboard contents.

%if "%{?vendor}" == "chum"
Categories:
 - Utility
Icon: https://raw.githubusercontent.com/monich/harbour-qrclip/master/icons/harbour-qrclip.svg
Screenshots:
- https://home.monich.net/chum/harbour-qrclip/screenshots/screenshot-001.png
- https://home.monich.net/chum/harbour-qrclip/screenshots/screenshot-002.png
- https://home.monich.net/chum/harbour-qrclip/screenshots/screenshot-003.png
- https://home.monich.net/chum/harbour-qrclip/screenshots/screenshot-004.png
Url:
  Homepage: https://openrepos.net/content/slava/qr-clip
%endif

%prep
%setup -q -n %{name}-%{version}

%build
%qtc_qmake5 %{name}.pro
%qtc_make %{?_smp_mflags}

%install
rm -rf %{buildroot}
%qmake5_install

desktop-file-install --delete-original \
  --dir %{buildroot}%{_datadir}/applications \
   %{buildroot}%{_datadir}/applications/*.desktop

%files
%defattr(-,root,root,-)
%{_bindir}/%{name}
%{_datadir}/%{name}
%{_datadir}/applications/%{name}.desktop
%{_datadir}/icons/hicolor/*/apps/%{name}.png
