{ config, lib, pkgs, ... }:

let
  eachChainlink = config.services.chainlink;

  chainlinkOpts = { config, lib, name, ... }: {
    options = {
      enable = lib.mkEnableOption "Chainlink Node";

      jsonOutput = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Enable JSON output format instead of table.";
      };

      verbosity = lib.mkOption {
        type = lib.types.int;
        default = 3;
        description = "Logging verbosity level (5=trace|4=debug|3=info|2=warn|1=error|0=crit).";
      };

      dataDir = lib.mkOption {
        type = lib.types.str;
        default = "/var/lib/chainlink";
        description = "Path to the data directory for Chainlink node.";
      };

      keystorePath = lib.mkOption {
        type = lib.types.str;
        default = "/var/lib/chainlink/keystore";
        description = "Path to the keystore directory.";
      };

      passwordFile = lib.mkOption {
        type = lib.types.str;
        default = "/var/lib/chainlink/password";
        description = "Path to the file containing the keystore password.";
      };

      ethereumURL = lib.mkOption {
        type = lib.types.str;
        default = "http://localhost:8545";
        description = "Ethereum node URL for Chainlink to connect.";
      };

      bridgeURL = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "URL of the bridge to connect with.";
      };

      extraArgs = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [];
        description = "Additional arguments to pass to the Chainlink CLI.";
      };

      package = lib.mkPackageOption pkgs [ "chainlink" ] { };
    };
  };

in {
  ###### Interface
  options = {
    services.chainlink = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule chainlinkOpts);
      default = {};
      description = "Configuration for one or more Chainlink node instances.";
    };
  };

  ###### Implementation
  config = lib.mkIf (eachChainlink != {}) {

    environment.systemPackages = lib.flatten (lib.mapAttrsToList (name: cfg: [
      cfg.package
    ]) eachChainlink);

    systemd.services = lib.mapAttrs' (name: cfg: let
      stateDir = "chainlink/${name}";
      dataDir = "/var/lib/${stateDir}";
    in (
      lib.nameValuePair "chainlink-${name}" (lib.mkIf cfg.enable {
        description = "Chainlink Node (${name})";
        wantedBy = [ "multi-user.target" ];
        after = [ "network-online.target" ];
        wants = [ "network-online.target" ];

        serviceConfig = {
          ExecStart = ''
            ${cfg.package}/bin/chainlink node start \
              --config ${dataDir}/config.toml \
              ${if cfg.jsonOutput then "--json" else ""} \
              --log-level ${toString cfg.verbosity} \
              --keystore ${cfg.keystorePath} \
              --password ${cfg.passwordFile} \
              --eth-url ${cfg.ethereumURL} \
              ${lib.optionalString (cfg.bridgeURL != null) "--bridge-url ${cfg.bridgeURL}"} \
              ${lib.concatStringsSep " " cfg.extraArgs}
          '';
          DynamicUser = true;
          Restart = "always";
          RestartSec = 5;
          StateDirectory = stateDir;

          # Hardening options
          PrivateTmp = true;
          ProtectSystem = "full";
          NoNewPrivileges = true;
          PrivateDevices = true;
          MemoryDenyWriteExecute = true;
          StandardOutput = "journal";
          StandardError = "journal";
          User = "chainlink";
        };
      })
    )) eachChainlink;
  };
}