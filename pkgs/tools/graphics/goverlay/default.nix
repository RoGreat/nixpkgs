{
  autoPatchelfHook,
  bash,
  fetchFromGitHub,
  fpc,
  iproute2,
  lazarus-qt6,
  lib,
  libGL,
  libGLU,
  libX11,
  libqtpas,
  lsb-release,
  nix-update-script,
  qt6,
  stdenv,
  wrapQtAppsHook,
}:

stdenv.mkDerivation rec {
  pname = "goverlay";
  version = "1.2";

  src = fetchFromGitHub {
    owner = "benjamimgois";
    repo = pname;
    rev = version;
    sha256 = "sha256-tSpM+XLlFQLfL750LTNWbWFg1O+0fSfsPRXuRCm/KlY=";
  };

  outputs = [
    "out"
    "man"
  ];

  postPatch = ''
    substituteInPlace Makefile \
      --replace-fail 'prefix = /usr/local' "prefix = $out"

    substituteInPlace overlayunit.pas \
      --replace-fail '/bin/bash' "${lib.getExe' bash "bash"}" \
      --replace-fail '/sbin/ip' "${lib.getExe' iproute2 "ip"}" \
      --replace-fail '/usr/lib/os-release' '/etc/os-release' \
      --replace-fail '/usr/share/icons/hicolor/128x128/apps/goverlay.png' "$out/share/icons/hicolor/128x128/apps/goverlay.png" \
      --replace-fail 'io_stats' "" \
      --replace-fail 'lsb_release' "${lib.getExe' lsb-release "lsb_release"} 2> /dev/null"
  '';

  nativeBuildInputs = [
    autoPatchelfHook
    lazarus-qt6
    wrapQtAppsHook
  ];

  buildInputs = [
    fpc
    libGL
    libGLU
    libX11
    libqtpas
    qt6.qtbase
  ];

  runtimeDependencies = [
    bash
    iproute2
    lsb-release
  ];

  buildPhase = ''
    runHook preBuild
    HOME=$(mktemp -d) lazbuild --lazarusdir=${lazarus-qt6}/share/lazarus -B goverlay.lpi
    runHook postBuild
  '';

  passthru.updateScript = nix-update-script { };

  meta = with lib; {
    description = "Opensource project that aims to create a Graphical UI to help manage Linux overlays";
    homepage = "https://github.com/benjamimgois/goverlay";
    license = licenses.gpl3Plus;
    maintainers = with maintainers; [ ];
    platforms = platforms.linux;
    mainProgram = "goverlay";
  };
}
