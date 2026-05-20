{ config, lib, pkgs, ... }:

let
  registry = (import ../../../data/service-registry.nix).forgejo;
in {
  services.forgejo = {
    enable = true;

    database = {
      type = "postgres";
      host = "unix:/run/postgresql";
      name = "forgejo";
      user = "forgejo";
      createDatabase = true;
    };

    settings = {
      server = {
        HTTP_ADDR = "127.0.0.1";
        HTTP_PORT = registry.port;
        DOMAIN = registry.domain;
        ROOT_URL = "https://${registry.domain}";
        # Use host's sshd for git operations.
        # DISABLE_SSH = true tells Forgejo not to start its own SSH server.
        # The NixOS module sets AcceptEnv GIT_PROTOCOL on the host sshd for
        # CVE-2023-27655 mitigation. Git SSH goes through port 22 via host sshd,
        # and Forgejo manages authorized_keys for the forgejo user.
        DISABLE_SSH = true;
        SSH_PORT = 22;
      };
      # Disable open registration — admin creates accounts only
      service = {
        DISABLE_REGISTRATION = true;
      };
    };
  };

  services.nginx.virtualHosts."${registry.domain}" = {
    enableACME = true;
    forceSSL = true;
    locations."/" = {
      proxyPass = "http://localhost:${toString registry.port}";
    };
  };
}
