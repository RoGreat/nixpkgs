{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.tetragon;
in
{
  options = {
    services.tetragon = {
      enable = lib.mkEnableOption "Tetragon";
      package = lib.mkPackageOption pkgs "tetragon" { };
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services = {
      tetragon = {
        description = "Tetragon eBPF-based Security Observability and Runtime Enforcement";
        wantedBy = [ "multi-user.target" ];
        after = [
          "network.target"
          "local-fs.target"
        ];
        startLimitBurst = 10;
        startLimitIntervalSec = 120;
        documentation = [ "https://tetragon.io/" ];
        serviceConfig = {
          User = "root";
          Group = "root";
          ExecStart = [
            "${lib.getExe cfg.package}"
          ];
          Restart = "on-failure";
          RestartSec = 5;
        };
        unitConfig = {
          DefaultDependencies = "no";
        };
      };
    };

    environment.systemPackages = [ cfg.package ];
  };

  meta.maintainers = with lib.maintainers; [ RoGreat ];
}
