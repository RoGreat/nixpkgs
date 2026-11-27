{
  lib,
  stdenv,
  fetchFromGitHub,
  SDL2,
  bash,
  coreutils,
  curl,
  fpc,
  git,
  glib,
  gnugrep,
  gnused,
  iproute2,
  kmod,
  lazarus-qt6,
  libnotify,
  libx11,
  libz,
  mangohud,
  nix-update-script,
  p7zip,
  patchelfUnstable,
  pciutils,
  polkit,
  procps,
  psmisc,
  python3,
  qt6Packages,
  which,
  writableTmpDirAsHomeHook,
  xdg-utils,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "goverlay";
  version = "nightly-unstable-2026-11-26";

  src = fetchFromGitHub {
    owner = "benjamimgois";
    repo = "goverlay";
    rev = "74b945ce06778e29d5127de128b80f8c42c7eb03";
    hash = "sha256-4kdecS0zTjnmDiegXLIWbUS3c1rJxpZt+a55d9sSN+4=";
  };

  outputs = [
    "out"
    "man"
  ];

  postPatch = ''
    substituteInPlace data/goverlay.sh.in --replace-fail 'mangohud' "${lib.getExe mangohud}"
  '';

  nativeBuildInputs = [
    fpc
    lazarus-qt6
    patchelfUnstable
    qt6Packages.wrapQtAppsHook
    writableTmpDirAsHomeHook
  ];

  buildInputs = [
    qt6Packages.libqtpas
    qt6Packages.qtbase
    SDL2
  ];

  buildPhase = ''
    runHook preBuild

    # goverlay
    lazbuild --lazarusdir=${lazarus-qt6}/share/lazarus -B goverlay.lpi --bm=Release --ws=qt6
    # pascube
    lazbuild --lazarusdir=${lazarus-qt6}/share/lazarus -B pascube_src/pascube.lpi --ws=qt6
    cp --remove-destination pascube_src/pascube ./pascube
    # bgmod-splash
    lazbuild --lazarusdir=${lazarus-qt6}/share/lazarus -B bgmod_splash_src/bgmod_splash.lpi --ws=qt6
    cp bgmod_splash_src/bgmod-splash ./bgmod-splash
    mkdir -p data/bgmod
    cp bgmod-splash data/bgmod/bgmod-splash

    runHook postBuild
  '';

  runtimeInputs = [
    bash # sh
    coreutils # cp, chmod, nohup, ln, mv, uname, sha256sum
    curl
    git
    glib # gdbus
    gnugrep # grep
    gnused # sed
    iproute2 # ip
    kmod # lsmod
    libnotify # notify-send (fallback)
    mangohud
    p7zip # 7z
    pciutils # lspci
    polkit # pkexec
    procps # pgrep
    psmisc # killall
    which
    xdg-utils # xdg-open
  ];

  preFixup = ''
    qtWrapperArgs+=(
      --suffix PATH : ${lib.escapeShellArg (lib.makeBinPath finalAttrs.runtimeInputs)}
    )
    patchelf $out/libexec/goverlay --set-rpath ${
      lib.makeLibraryPath [
        libx11
        qt6Packages.libqtpas
      ]
    }
    patchelf $out/libexec/pascube --set-rpath ${
      lib.makeLibraryPath [
        libx11
        libz
        SDL2
      ]
    }
    patchelf $out/libexec/bgmod-splash --set-rpath ${
      lib.makeLibraryPath [
        libx11
        qt6Packages.libqtpas
      ]
    }
  '';

  installFlags = [ "prefix=$(out)" ];

  passthru.updateScript = nix-update-script { };

  doInstallCheck = true;

  nativeInstallCheckInputs = finalAttrs.runtimeInputs ++ [ python3 ];

  installCheckPhase = ''
    # test-logic
    lazbuild --lazarusdir=${lazarus-qt6}/share/lazarus tests/logic/logic_tests.lpi --ws=qt6
    patchelf ./tests/logic/logic_tests --set-rpath ${
      lib.makeLibraryPath [
        libx11
        qt6Packages.libqtpas
      ]
    }
    ./tests/logic/logic_tests
  '';

  meta = {
    description = "Open source project that aims to create a Graphical UI to help manage Linux overlays";
    homepage = "https://github.com/benjamimgois/goverlay";
    # changelog = "https://github.com/benjamimgois/goverlay/releases/tag/${finalAttrs.src.tag}";
    license = lib.licenses.gpl3Plus;
    maintainers = with lib.maintainers; [ RoGreat ];
    platforms = lib.platforms.linux;
    mainProgram = "goverlay";
  };
})
