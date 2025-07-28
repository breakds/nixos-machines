rec {
  hydra = {
    domain = "hydra.breakds.org";
    port = 5855;
  };

  docker-registry = {
    domain = "docker.breakds.org";
    port = 5050;
  };

  grafana = {
    domain = "grafana.breakds.org";
    port = 5810;
  };

  prometheus = {
    port = 5820;
    exporters = {
      node.port = 5821;
      zfs.port = 5822;      
      nginx.port = 5823;
      nvidia-gpu.port = 5824;
      unbound.port = 5825;
      dnsmasq.port = 5826;
    };
  };

  # Deprecated
  traintrack = {
    agents = {
      lorian = { port = 5975; };
      malenia = { port = 5975; };
      octavian = { port = 5975; };
    };
    central = {
      octavian = { port = 5976; };
    };
  };

  paperless = {
    domain = "paperless.breakds.org";
    port = 28981;
  };

  sharing = {
    port = 7478;
  };

  syncthing = {
    # syncthing also reserves 22000 and 21027.
    gui = {
      port = 8384;
    };
  };

  nix-serve = {
    port = 17777;
  };

  interm = {
    port = 6337;
  };

  kiseki = {
    domain = "kiseki.breakds.org";
    port = 28603;
  };

  code-server = {
    domain = "code.breakds.org";
    port = 4445;
  };

  clickhouse-wonder = {
    ports = {
      tcp = 27005;
      http = 27003;
    };
  };

  localsend = {
    port = 53317;
  };

  n8n = {
    port = 45678;
  };

  rustdesk-server = {
    ports = [21115 21116 21117 21118 21119];
  };

  temporal = {
    domain = "temporal.breakds.net";
    ports = {
      api = 7233;
      ui = 8233;

      # Inter-service ports
      pprof = 7236;
      frontendMembership = 7237;
      frontendHttp = 7238;
      matching = 7239;
      matchingMembership = 7240;
      history = 7241;
      historyMembership = 7242;
      worker = 7243;
    };
    uid = 823;
    gid = 823;
  };

  glance = {
    domain = "home.breakds.net";
    port = 7010;
  };

  meilisearch = {
    port = 7700;
  };

  karakeep = {
    domain = "karakeep.breakds.org";
    ports = {
      ui = 7020;
      browser = 7021;
    };
  };

  atuin = {
    domain = "atuin.breakds.org";
    port = 7077;
  };

  home-assistant = {
    domain = "hast.breakds.org";
    port = 7123;
  };

  wyoming = {
    piper.port = 10200;
    faster-whisper.port = 10300;
    openwakeword.port = 10400;
  };
}
