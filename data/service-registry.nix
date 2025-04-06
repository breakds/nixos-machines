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

  rsu-taxer = {
    domain = "tax.breakds.org";
    port = 31415;
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
}
