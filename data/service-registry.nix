rec {
  hydra = {
    domain = "hydra.breakds.org";
    port = 5855;
  };

  shiori = {
    domain = "shiori.breakds.org";
    port = 5931;
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
    nodePort = 5821;
  };

  # Deprecated
  traintrack = {
    agents = {
      lothric = { port = 5975; };
      lorian = { port = 5975; };
      malenia = { port = 5975; };
      octavian = { port = 5975; };
    };
    central = {
      octavian = { port = 5976; };
    };
  };

  famass = {
    domain = "famass.breakds.org";
    port = 5928;
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

  karakeep = {
    domain = "karakeep.breakds.org";
    ports = {
      ui = 7020;
      browser = 7021;
      meilisearch = 7700;
    };
  };
}
