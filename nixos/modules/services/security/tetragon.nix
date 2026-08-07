{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.tetragon;
  enabledTracingPolicies = lib.filterAttrs (n: p: p.enable) cfg.tracingPolicies;
  buildPolicyPath = n: p: lib.defaultTo (pkgs.writeText n p.text) p.source;
in
{
  options = {
    services.tetragon = {
      enable = lib.mkEnableOption "Tetragon";
      package = lib.mkPackageOption pkgs "tetragon" { };

      tracingPolicies = lib.mkOption {
        default = { };
        description = ''
          Tracing policies.
        '';

        type = lib.types.attrsOf (
          lib.types.submodule {
            options = {
              enable = lib.mkOption {
                type = lib.types.bool;
                default = true;
                description = "";
              };

              text = lib.mkOption {
                type = lib.types.lines;
                description = "";
              };

              source = lib.mkOption {
                type = lib.types.nullOr lib.types.path;
                description = "";
                default = null;
              };
            };
          }
        );
      };
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

    environment.etc."tetragon/tetragon.tp.d".source = pkgs.linkFarm "tetragon.tp.d" (
      lib.mapAttrsToList (name: p: {
        inherit name;
        path = buildPolicyPath name p;
      }) enabledTracingPolicies
    );

    environment.systemPackages = [ cfg.package ];
  };

  meta.maintainers = with lib.maintainers; [ RoGreat ];
}
