{ config, pkgs, lib, ... }:

{
  imports = [
    ../../../base/traintrack/agent.nix
    ../../../base/traintrack/central.nix
  ];

  config = let
    traintrack-registry = (import ../../../data/service-registry.nix).traintrack;
  in {
    services.traintrack-agent = {
      enable = true;
      port = traintrack-registry.agents.octavian.port;
      user = "breakds";
      group = "breakds";
      settings = {
        workers = [
          # Worker 0 with Tesla T4
          {
            gpu_id = 0;
            gpu_type = "Tesla T4";
            repos = {
              Hobot = {
                path = "/var/lib/traintrack/agent/Hobot0";
                work_dir = "/home/breakds/tmp/alf_sessions";
              };
            };
          }
        ];
      };
    };

    services.traintrack-central = {
      enable = true;
      port = traintrack-registry.central.octavian.port;
      user = "breakds";
      group = "breakds";
      settings = {
        default_blacklist = [ "octavian" "malenia" ];
        schedule_interval = 30;
        agents = [
          {
            name = "lothric";
            port = traintrack-registry.agents.lothric.port;

            ssh_uri = "10.77.1.127";
            ssh_port = 22;
            ssh_key_file = "/home/breakds/.ssh/breakds_samaritan";
          }
          {
            name = "lortian";
            port = traintrack-registry.agents.lorian.port;

            ssh_uri = "10.77.1.128";
            ssh_port = 22;
            ssh_key_file = "/home/breakds/.ssh/breakds_samaritan";
          }
          {
            name = "octavian";
            port = traintrack-registry.agents.octavian.port;

            ssh_uri = "localhost";
            ssh_port = 22;
            ssh_key_file = "/home/breakds/.ssh/breakds_samaritan";
          }
          {
            name = "malenia";
            port = traintrack-registry.agents.malenia.port;

            ssh_uri = "10.77.1.185";
            ssh_port = 22;
            ssh_key_file = "/home/breakds/.ssh/breakds_samaritan";
          }
        ];
      };
    };

    environment.systemPackages = [
      # TODO(breakds): Wrap it with TRAINTRACK_CENTRAL_PORT
      pkgs.traintrack
    ];
  };
}
