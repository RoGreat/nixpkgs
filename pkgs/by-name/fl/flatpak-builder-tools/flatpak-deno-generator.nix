{
  deno,
  lib,
  makeWrapper,
  src,
  stdenvNoCC,
  version,
}:

stdenvNoCC.mkDerivation (finalAttrs: {
  inherit src version;
  pname = "flatpak-deno-generator";

  sourceRoot = "${finalAttrs.src.name}/deno";

  nativeBuildInputs = [ makeWrapper ];

  installPhase = ''
    runHook preInstall
    mkdir -p $out/lib/flatpak-deno-generator
    cp -a * $out/lib/flatpak-deno-generator
    runHook postInstall
  '';

  preFixup = ''
    makeWrapper ${lib.getExe deno} $out/bin/flatpak-deno-generator \
      --add-flags "-RN -W=. $out/lib/flatpak-deno-generator/src/main.ts"
  '';

  installCheckPhase = ''
    $out/bin/flatpak-deno-generator --help
  '';
})
