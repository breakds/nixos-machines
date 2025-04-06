{ config, lib, pkgs, ... }:

let info = (import ../../../data/service-registry.nix).n8n;

in {
  config = {

    services.n8n = {
      enable = true;
      # Note: n8n is already configured to not "phone home" in `services.n8n` via
      # the environment variable (a.k.a. isolated n8n).
      #
      # Some other defaults are
      #
      # N8N_USER_FOLDER = "/var/lib/n8n";
      # HOME = "/var/lib/n8n";
      settings = {
        port = "${toString info.port}";
        generic.timezone = "America/Los_Angeles";
      };
    };

    # Experiment shows that n8n actually respect this environment variable
    # rather than `settings.port`.
    systemd.services.n8n.environment = {
      N8N_PORT = "${toString info.port}";
    };
  };
}
