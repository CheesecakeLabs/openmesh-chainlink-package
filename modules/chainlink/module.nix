with import <nixpkgs> {};

let
  eachChainlink = config.services.chainlink;

  chainlinkOpts = { config, lib, name, pkgs, ... }: {
    options = {
      enable = lib.mkEnableOption "Chainlink Node";

      # Chainlink specific options
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
        type = lib.types.str;
        default = null;
        description = "URL of the bridge to connect with.";
      };

      extraArgs = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [];
        description = "Additional arguments to pass to the Chainlink CLI.";
      };

      package = lib.mkOption {
        type = lib.types.str;
        default = "chainlink";
        description = "Chainlink package name.";
      };
    };

    config = lib.mkIf config.enable {
      environment.systemPackages = [ pkgs.chainlink ];

      systemd.services = {
        "chainlink-node" = {
          description = "Chainlink Node Service";
          after = [ "network.target" ];
          wantedBy = [ "multi-user.target" ];

          serviceConfig = {
            ExecStart = "${pkgs.chainlink}/bin/chainlink node start \
              --config ${config.dataDir}/config.toml \
              ${if config.jsonOutput then "--json" else ""} \
              --log-level ${toString config.verbosity} \
              --keystore ${config.keystorePath} \
              --password ${config.passwordFile} \
              --eth-url ${config.ethereumURL} \
              ${optionalString (config.bridgeURL != null) "--bridge-url ${config.bridgeURL}"} \
              ${lib.concatStringsSep " " config.extraArgs}";
            Restart = "always";
            User = "chainlink";
            Group = "chainlink";
            Environment = "CHAINLINK_DATA_DIR=${config.dataDir}";
            PrivateTmp = true;
            ProtectSystem = "full";
            NoNewPrivileges = true;
            MemoryDenyWriteExecute = true;
          };
        };
      };
    };
  };
in

{
  options = {
    services.chainlink = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule chainlinkOpts);
      default = {};
      description = "Configuration for Chainlink Node services.";
    };
  };

  config = lib.mkIf (eachChainlink != {}) {
    services.chainlink = eachChainlink;
  };
}