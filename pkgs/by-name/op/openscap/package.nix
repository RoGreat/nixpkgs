{
  acl,
  asciidoc,
  bzip2,
  cmake,
  curl,
  dbus,
  doxygen,
  fetchFromGitHub,
  glib,
  gnome2,
  graphviz,
  libgcrypt,
  libselinux,
  libsepol,
  libxml2,
  libxslt,
  opendbx,
  pcre,
  pcre2,
  pkg-config,
  popt,
  procps,
  rpm,
  stdenv,
  swig,
  systemd,
  util-linux,
  xmlsec,
}:

stdenv.mkDerivation rec {
  pname = "openscap";
  version = "1.3.10";

  src = fetchFromGitHub {
    owner = "OpenSCAP";
    repo = "openscap";
    rev = version;
    hash = "sha256-P7k+Ygz/XmpTSKBEqbyJsd1bIDVJ1HA/RJdrEtjYD5g=";
  };

  nativeBuildInputs = [
    acl
    asciidoc
    bzip2
    cmake
    curl
    dbus
    doxygen
    glib
    gnome2.GConf
    gnome2.ORBit2
    graphviz
    libgcrypt
    libselinux
    libsepol
    libxml2
    libxslt
    opendbx
    pcre
    pcre2
    pkg-config
    popt
    procps
    rpm
    swig
    systemd
    util-linux
    xmlsec
  ];
}
