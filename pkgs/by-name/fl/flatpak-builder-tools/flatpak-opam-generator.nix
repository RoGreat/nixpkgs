{
  python3Packages,
  src,
  version,
}:

python3Packages.buildPythonApplication (finalAttrs: {
  inherit src version;
  pname = "flatpak-opam-generator";
  pyproject = false;

  sourceRoot = "${finalAttrs.src.name}/opam";

  dependencies = with python3Packages; [
    requests
  ];

  postInstall = ''
    install -D flatpak-opam-generator.py $out/bin/flatpak-opam-generator
  '';

  installCheckPhase = ''
    $out/bin/flatpak-opam-generator --help
  '';
})
