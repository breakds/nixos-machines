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
        # START_SSH_SERVER = true is a workaround for the module state machine:
        # it prevents the module from overriding openssh settings (AcceptEnv),
        # while DISABLE_SSH = true tells Forgejo not to start its own SSH server.
        # Net result: git SSH goes through port 22 via host sshd, and the module
        # still manages authorized_keys for the forgejo user.
        START_SSH_SERVER = true;
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
