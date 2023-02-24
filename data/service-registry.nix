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
    agent = {
      port = 5975;
    };
  };
}
