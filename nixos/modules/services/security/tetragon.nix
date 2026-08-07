{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.tetragon;
  enabledTracingPolicies = lib.filterAttrs (name: file: file.enable) cfg.tracingPolicies;
  enabledConfigs = lib.filterAttrs (name: file: file.enable) cfg.configs;
  buildPath = name: file: lib.defaultTo (pkgs.writeText name file.text) file.source;
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

      configs = lib.mkOption {
        default = { };
        description = ''
          Override default configuration.
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
      lib.mapAttrsToList (name: file: {
        inherit name;
        path = buildPath name file;
      }) enabledTracingPolicies
    );

    environment.etc."tetragon/tetragon.conf.d".source = pkgs.linkFarm "tetragon.conf.d" (
      lib.mapAttrsToList (name: file: {
        inherit name;
        path = buildPath name file;
      }) enabledConfigs
    );

    environment.systemPackages = [ cfg.package ];
  };

  meta.maintainers = with lib.maintainers; [ RoGreat ];
}
