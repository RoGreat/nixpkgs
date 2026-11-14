{
  lib,
  fetchFromGitHub,
  glib,
  gnome,
  gobject-introspection,
  libadwaita,
  libnotify,
  p7zip,
  python3Packages,
  unrar-free,
  webp-pixbuf-loader,
  wrapGAppsHook4,
}:

python3Packages.buildPythonApplication (finalAttrs: {
  pname = "nomm";
  version = "0.15.0";

  src = fetchFromGitHub {
    owner = "NOMM-Team";
    repo = "nomm-app";
    tag = finalAttrs.version;
    hash = "sha256-Si0y5Dkb1t7uvDrO3SXELpkCVZ96mciLu2FK/x+BhSA=";
  };

  postPatch = ''
    substituteInPlace src/nomm/gui/dashboard.py src/nomm/core/archive_manager.py \
        --replace-fail '/app/bin/unrar' "${lib.getExe unrar-free}"
  '';

  nativeBuildInputs = [
    gobject-introspection
    wrapGAppsHook4
  ];

  buildInputs = [
    libadwaita
    libnotify
  ];

  # has no tests
  doCheck = false;

  postInstall = ''
    # https://github.com/NOMM-Team/nomm-app/blob/main/build/flatpak/moe.nomm.Nomm.yaml
    APP_ID=moe.nomm.Nomm
    install -D build/flatpak/$APP_ID.desktop $out/share/applications/$APP_ID.desktop
    install -D build/flatpak/$APP_ID.metainfo.xml $out/share/metainfo/$APP_ID.metainfo.xml
    install -D assets/icons/nomm-logo.svg $out/share/icons/hicolor/scalable/apps/$APP_ID.svg
    cp src/nomm/*.yaml $out/${python3Packages.python.sitePackages}/..
    cp release_bites.yaml $out/${python3Packages.python.sitePackages}/..
    cp -r assets $out/${python3Packages.python.sitePackages}/..
    find locale -name "*.po" | while read -r po; do
      language_code=$(basename "$po" .po)
      install -d "$out/share/locale/$language_code/LC_MESSAGES"
      msgfmt "$po" -o "$out/share/locale/$language_code/LC_MESSAGES/$APP_ID.mo"
    done

    # fix broken images
    export GDK_PIXBUF_MODULE_FILE="${
      gnome._gdkPixbufCacheBuilder_DO_NOT_USE {
        extraLoaders = [
          webp-pixbuf-loader
        ];
      }
    }"
  '';

  preFixup = ''
    makeWrapperArgs+=(
      "''${gappsWrapperArgs[@]}"
      --set PATH ${
        lib.makeBinPath [
          glib.dev # glib-compile-resources
          p7zip # 7z
        ]
      }
    )
  '';

  build-system = with python3Packages; [
    setuptools
    setuptools-scm
  ];

  dependencies = with python3Packages; [
    packaging
    pygobject3
    pyyaml
    rarfile
    requests
    vdf
    dulwich
  ];

  dontWrapGApps = true;
  pyproject = true;
  pythonImportsCheck = [ "nomm" ];

  meta = {
    description = "Native Open Mod Manager";
    homepage = "https://nomm.moe";
    license = lib.licenses.gpl3Plus;
    maintainers = with lib.maintainers; [ RoGreat ];
    platforms = lib.platforms.linux;
    mainProgram = "nomm";
  };
})
