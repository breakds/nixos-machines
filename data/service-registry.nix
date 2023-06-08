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

  traintrack = {
    agents = {
      lothric = { port = 5975; };
      lorian = { port = 5975; };
      gail3 = { port = 5975; };
      samaritan = { port = 5975; };
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
}
