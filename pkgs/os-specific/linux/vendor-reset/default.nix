{
  stdenv,
  fetchFromGitHub,
  kernel,
  kernelModuleMakeFlags,
  lib,
}:

stdenv.mkDerivation {
  pname = "vendor-reset";
  version = "unstable-2026-01-09-${kernel.version}";

  src = fetchFromGitHub {
    owner = "matthias-z";
    repo = "vendor-reset";
    rev = "09918556dfcd37010a6153020320fcd3628c3418";
    hash = "sha256-3dslHh8Et1742iT8wHH3ztDvdnnT8SEB6R5VXqMRdBU=";
  };

  nativeBuildInputs = kernel.moduleBuildDependencies;

  hardeningDisable = [ "pic" ];

  makeFlags = kernelModuleMakeFlags ++ [
    "KVER=${kernel.modDirVersion}"
    "KDIR=${kernel.dev}/lib/modules/${kernel.modDirVersion}/build"
  ];

  installPhase = ''
    install -D vendor-reset.ko -t "$out/lib/modules/${kernel.modDirVersion}/kernel/drivers/misc/"
  '';

  enableParallelBuilding = true;

  meta = {
    description = "Linux kernel vendor specific hardware reset module";
    homepage = "https://github.com/matthias-z/vendor-reset";
    license = lib.licenses.gpl2Only;
    maintainers = [ ];
    platforms = [ "x86_64-linux" ];
    broken = kernel.kernelOlder "4.19";
  };
}
