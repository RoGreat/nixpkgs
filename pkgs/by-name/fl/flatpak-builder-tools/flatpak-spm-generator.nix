{
  lib,
  src,
  stdenvNoCC,
  swift,
  version,
}:

stdenvNoCC.mkDerivation (finalAttrs: {
  inherit src version;
  pname = "flatpak-spm-generator";

  sourceRoot = "${finalAttrs.src.name}/spm";

  installPhase = ''
    runHook preInstall
    install -D flatpak-spm-generator.swift $out/lib/flatpak-spm-generator/flatpak-spm-generator.swift
    runHook postInstall
  '';

  preFixup = ''
    makeWrapper ${lib.getExe swift} $out/bin/flatpak-spm-generator \
      --add-flags "$out/lib/flatpak-spm-generator/flatpak-spm-generator.swift"
  '';

  installCheckPhase = ''
    $out/bin/flatpak-spm-generator --help
  '';
})
