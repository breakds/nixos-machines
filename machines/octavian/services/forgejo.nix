{ config, lib, pkgs, ... }:

let
  registry = (import ../../../data/service-registry.nix).forgejo;
in {
  /*
   * Forgejo (self-hosted Git) service configuration:
   *
   * System user: forgejo (default, used for process execution and file ownership)
   * PostgreSQL:  forgejo/forgejo db+user (created via NixOS declarative config)
   * SSH clone:   forgejo@... (clone URLs match the actual system user)
   *
   * Users clone with: git clone forgejo@git.breakds.org:owner/repo.git
   */

  services.forgejo = {
    enable = true;

    # Enable git-lfs for large file support
    lfs = {
      enable = true;
    };

    # PostgreSQL backend via local Unix socket (peer auth, no password needed).
    # NixOS module creates the database and user declaratively on first boot.
    # Assertion requires db user == db name when auto-creating.
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

        # Git over SSH: clone URL is forgejo@git.breakds.org:owner/repo.git
        # Forgejo does NOT start its own SSH server — it uses the host's sshd.
        # Users add their SSH public key in Forgejo's web UI, and Forgejo writes
        # it to the authorized_keys file for the "forgejo" system user.
        # The host's sshd authenticates the connection, and Forgejo handles the git
        # operation via the command= prefix in authorized_keys.
        SSH_USER = "forgejo";  # displayed in clone URLs
        SSH_PORT = 22;
      };

      # Disable open registration — admin creates accounts only
      service = {
        DISABLE_REGISTRATION = true;
      };

      # TLS terminates at nginx, so Forgejo sees plain HTTP and won't set the
      # Secure flag on session cookies on its own. Force it on.
      session = {
        COOKIE_SECURE = true;
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
