{ stateDir, ports }:

{
  log = {
    stdout = true;
    level = "info";
  };

  # TODO: Use postgresql isntead of sqlite for production persistence
  persistence = {
    defaultStore     = "sqlite-default";
    visibilityStore  = "sqlite-visibility";
    numHistoryShards = 4;
    datastores = {
      sqlite-default = {
        sql = {
          pluginName       = "sqlite";
          databaseName     = "${stateDir}/default.db";
          connectAddr      = "localhost";
          connectProtocol  = "tcp";
          connectAttributes = {
            cache = "private";
            setup = true;
          };
        };
      };

      sqlite-visibility = {
        sql = {
          pluginName       = "sqlite";
          databaseName     = "${stateDir}/visibility.db";
          connectAddr      = "localhost";
          connectProtocol  = "tcp";
          connectAttributes = {
            cache = "private";
            setup = true;
          };
        };
      };
    };
  };

  global = {
    membership = {
      maxJoinDuration   = "30s";
      broadcastAddress  = "127.0.0.1";
    };
    pprof = {
      port = ports.pprof;
    };
  };

  services = {
    frontend = {
      rpc = {
        grpcPort       = ports.api;
        membershipPort = ports.frontendMembership;
        bindOnIP       = "0.0.0.0";
        httpPort       = ports.frontendHttp;
      };
    };

    matching = {
      rpc = {
        grpcPort       = ports.matching;
        membershipPort = ports.matchingMembership;
        bindOnLocalHost = true;
      };
    };

    history = {
      rpc = {
        grpcPort       = ports.history;
        membershipPort = ports.historyMembership;
        bindOnLocalHost = true;
      };
    };

    worker = {
      rpc = {
        membershipPort = ports.worker;
      };
    };
  };

  clusterMetadata = {
    enableGlobalNamespace   = false;
    failoverVersionIncrement = 10;
    masterClusterName       = "active";
    currentClusterName      = "active";
    clusterInformation = {
      active = {
        enabled               = true;
        initialFailoverVersion = 1;
        rpcName               = "frontend";
        rpcAddress            = "localhost:${toString ports.api}";
        httpAddress           = "localhost:${toString ports.frontendHttp}";
      };
    };
  };

  dcRedirectionPolicy = {
    # No cross data center replication
    policy = "noop";
  };
}
