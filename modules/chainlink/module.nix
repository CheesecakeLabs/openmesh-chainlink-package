with import <nixpkgs> {};

let
  eachBor = config.services.bor;

  borOpts = { config, lib, name, ...}: {

    options = {

      enable = lib.mkEnableOption "Bor Node (Polygon)";

      # Bor specific options
      devfakeauthor = mkOption {
        type = types.bool;
        default = false;
        description = "Run miner without validator set authorization [dev mode]. Use with '--bor.withoutheimdall'";
      };

      heimdall = mkOption {
        type = types.str;
        default = "http://localhost:1317";
        description = "URL of Heimdall service.";
      };

      heimdallgRPC = mkOption {
        type = types.str;
        default = null;
        description = "Address of Heimdall gRPC service.";
      };

      logs = mkOption {
        type = types.bool;
        default = false;
        description = "Enables Bor log retrieval.";
      };

      runheimdall = mkOption {
        type = types.bool;
        default = false;
        description = "Run Heimdall service as a child process.";
      };

      runheimdallargs = mkOption {
        type = types.nullOr (types.listOf types.str);
        default = null;
        description = "Arguments to pass to Heimdall service.";
      };

      useheimdallapp = mkOption {
        type = types.bool;
        default = false;
        description = "Use child heimdall process to fetch data (works only when `runheimdall` is true).";
      };

      withoutheimdall = mkOption {
        type = types.bool;
        default = false;
        description = "Run without Heimdall service (for testing purposes).";
      };

      chain = mkOption {
        type = types.str;
        default = "mainnet";
        description = "Name of the chain to sync ('amoy', 'mumbai', 'mainnet') or path to a genesis file.";
      };

      config = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Path to the TOML configuration file.";
      };

      datadir = mkOption {
        type = types.str;
        default = "/var/lib/bor";
        description = "Path of the data directory to store information.";
      };

      datadirAncient = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Data directory for ancient chain segments (default is inside chaindata).";
      };

      dbEngine = mkOption {
        type = types.enum [ "leveldb" "pebble" ];
        default = "leveldb";
        description = "Backing database implementation to use.";
      };

      dev = mkOption {
        type = types.bool;
        default = false;
        description = "Enable developer mode with ephemeral proof-of-authority network.";
      };

      devGasLimit = mkOption {
        type = types.int;
        default = 11500000;
        description = "Initial block gas limit in developer mode.";
      };

      devPeriod = mkOption {
        type = types.int;
        default = 0;
        description = "Block period to use in developer mode (0 = mine only if transaction pending).";
      };

      disableBorWallet = mkOption {
        type = types.bool;
        default = true;
        description = "Disable the personal wallet endpoints.";
      };

      ethRequiredBlocks = mkOption {
        type = types.nullOr (types.str);
        default = null;
        description = "Comma separated block number-to-hash mappings to require for peering.";
      };

      ethstats = mkOption {
        type = types.nullOr (types.str);
        default = null;
        description = "Reporting URL of an ethstats service (format: nodename:secret@host:port).";
      };

      gcmode = mkOption {
        type = types.enum [ "full" "archive" ];
        default = "full";
        description = "Blockchain garbage collection mode.";
      };

      syncmode = mkOption {
        type = types.enum [ "full" ];
        default = "full";
        description = "Blockchain sync mode (only 'full' sync supported by Bor).";
      };

      verbosity = mkOption {
        type = types.int;
        default = 3;
        description = "Logging verbosity for the server (5=trace|4=debug|3=info|2=warn|1=error|0=crit).";
      };

      # Add other CLI options here as required

      extraArgs = mkOption {
        type = types.listOf types.str;
        default = [];
        description = "Additional arguments passed to Bor.";
      };

      package = mkPackageOption pkgs [ "bor" ] { };
    };
  };
in

{

  ###### interface

  options = {
    services.bor = mkOption {
      type = types.attrsOf (types.submodule borOpts);
      default = {};
      description = "Specification of one or more Bor instances.";
    };
  };

  ###### implementation

  config = mkIf (eachBor != {}) {

    environment.systemPackages = flatten (mapAttrsToList (borName: cfg: [
      cfg.package
    ]) eachBor);

    systemd.services = mapAttrs' (borName: cfg: let
      stateDir = "bor/${borName}/mainnet";
      dataDir = "/var/lib/${stateDir}";
    in (
      nameValuePair "bor-${borName}" (mkIf cfg.enable {
      description = "Bor node (Polygon) (${borName})";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];

      serviceConfig = {
        DynamicUser = true;
        Restart = "always";
        StateDirectory = stateDir;

        # Hardening measures
        PrivateTmp = "true";
        ProtectSystem = "full";
        NoNewPrivileges = "true";
        PrivateDevices = "true";
        MemoryDenyWriteExecute = "true";
      };

      script = ''
        ${cfg.package}/bin/bor \
          ${optionalString cfg.devfakeauthor "--bor.devfakeauthor"} \
          ${optionalString (cfg.heimdall != null) "--bor.heimdall ${cfg.heimdall}"} \
          ${optionalString (cfg.heimdallgRPC != null) "--bor.heimdallgRPC ${cfg.heimdallgRPC}"} \
          ${optionalString cfg.logs "--bor.logs"} \
          ${optionalString cfg.runheimdall "--bor.runheimdall"} \
          ${optionalString cfg.useheimdallapp "--bor.useheimdallapp"} \
          ${optionalString cfg.withoutheimdall "--bor.withoutheimdall"} \
          --chain ${cfg.chain} \
          ${optionalString (cfg.config != null) "--config ${cfg.config}"} \
          --datadir ${cfg.datadir} \
          ${optionalString (cfg.datadirAncient != null) "--datadir.ancient ${cfg.datadirAncient}"} \
          --db.engine ${cfg.dbEngine} \
          ${optionalString cfg.dev "--dev"} \
          ${optionalString (cfg.devGasLimit != null) "--dev.gaslimit ${toString cfg.devGasLimit}"} \
          ${optionalString (cfg.devPeriod != null) "--dev.period ${toString cfg.devPeriod}"} \
          ${optionalString cfg.disableBorWallet "--disable-bor-wallet"} \
          ${optionalString (cfg.ethRequiredBlocks != null) "--eth.requiredblocks ${cfg.ethRequiredBlocks}"} \
          ${optionalString (cfg.ethstats != null) "--ethstats ${cfg.ethstats}"} \
          --gcmode ${cfg.gcmode} \
          --syncmode ${cfg.syncmode} \
          --verbosity ${toString cfg.verbosity} \
          ${lib.escapeShellArgs cfg.extraArgs} \
          --datadir ${dataDir}
      '';
    }))) eachBor;

  };

}