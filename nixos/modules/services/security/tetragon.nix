{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.tetragon;
  filterEnabled = option: lib.filterAttrs (name: file: file.enable) option;
  buildFilePath = name: file: lib.defaultTo (pkgs.writeText name file.text) file.source;
in
{
  options = {
    services.tetragon = {
      enable = lib.mkEnableOption "Tetragon";
      package = lib.mkPackageOption pkgs "tetragon" { };

      configs = lib.mkOption {
        description = "Override default settings.";
        type = lib.types.attrsOf (
          lib.types.submodule {
            options = {
              enable = lib.mkOption {
                type = lib.types.bool;
                default = true;
                description = ''
                  Whether this config file should be generated. This
                  option allows specific config files to be disabled.
                '';
              };

              text = lib.mkOption {
                type = lib.types.nullOr lib.types.lines;
                default = null;
                description = "Text of the config file.";
              };

              source = lib.mkOption {
                type = lib.types.nullOr lib.types.path;
                default = null;
                description = "Path of the source config file.";
              };
            };
          }
        );
        default = { };
      };

      tracingPolicies = lib.mkOption {
        description = "Tracing policies.";
        type = lib.types.attrsOf (
          lib.types.submodule {
            options = {
              enable = lib.mkOption {
                description = ''
                  Whether this policy file should be generated. This
                  option allows specific policy files to be disabled.
                '';
                type = lib.types.bool;
                default = true;
              };

              text = lib.mkOption {
                description = "Text of the policy file.";
                type = lib.types.nullOr lib.types.lines;
                default = null;
              };

              source = lib.mkOption {
                description = "Path of the source policy file.";
                type = lib.types.nullOr lib.types.path;
                default = null;
              };
            };
          }
        );
        default = { };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services = {
      tetragon = {
        description = "Tetragon eBPF-based Security Observability and Runtime Enforcement";
        unitConfig.DefaultDependencies = "no";
        after = [
          "network.target"
          "local-fs.target"
        ];
        documentation = [ "https://tetragon.io/" ];

        startLimitBurst = 10;
        startLimitIntervalSec = 120;

        serviceConfig = {
          User = "root";
          Group = "root";
          ExecStart = [
            "${lib.getExe cfg.package}"
          ];
          Restart = "on-failure";
          RestartSec = 5;
        };

        wantedBy = [ "multi-user.target" ];
      };
    };

    environment.etc."tetragon/tetragon.conf.d".source = pkgs.linkFarm "tetragon.conf.d" (
      lib.mapAttrsToList (name: file: {
        inherit name;
        path = buildFilePath name file;
      }) (filterEnabled cfg.configs)
    );

    environment.etc."tetragon/tetragon.tp.d".source = pkgs.linkFarm "tetragon.tp.d" (
      lib.mapAttrsToList (name: file: {
        inherit name;
        path = buildFilePath name file;
      }) (filterEnabled cfg.tracingPolicies)
    );

    environment.systemPackages = [ cfg.package ];
  };

  meta.maintainers = with lib.maintainers; [ RoGreat ];
}
