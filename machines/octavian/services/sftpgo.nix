{ config, pkgs, ... }:

let
  registry = import ../../../data/service-registry.nix;
  info = registry.sftpgo;
  clientURL = "https://${info.domain}";
  adminURL = "https://${info.adminDomain}";
  nasHome = "/srv/nas/user-files";
  privateFolders = [ "paperless" "other" ".filerun.trash" ];
  oidc = {
    client_id = "sftpgo";
    client_secret_file = config.age.secrets.kanidm-oauth-sftpgo.path;
    config_url = "https://${registry.kanidm.domain}/oauth2/openid/sftpgo";
    username_field = "preferred_username";
    scopes = [ "openid" "profile" ];
  };
  # nginx terminates TLS and supplies the client address for Defender.
  proxySettings = {
    proxy_allowed = [ "127.0.0.1" ];
    client_ip_proxy_header = "X-Real-IP";
    security = {
      enabled = true;
      https_proxy_headers = [ { key = "X-Forwarded-Proto"; value = "https"; } ];
    };
  };
in {
  age.secrets.kanidm-oauth-sftpgo = {
    file = ../../../secrets/kanidm-oauth-sftpgo.age;
    owner = "kanidm";
    group = "sftpgo";
    mode = "0440";
  };

  services.kanidm.provision = {
    groups.sftpgo-users.overwriteMembers = false;
    groups.sftpgo-admins.overwriteMembers = false;
    systems.oauth2.sftpgo = {
      displayName = "SFTPGo";
      originUrl = [ "${clientURL}/web/oidc/redirect" "${adminURL}/web/oidc/redirect" ];
      originLanding = clientURL;
      basicSecretFile = oidc.client_secret_file;
      preferShortUsername = true;
      scopeMaps.sftpgo-users = oidc.scopes;
      claimMaps.sftpgo_role = {
        joinType = "ssv";
        valuesByGroup.sftpgo-admins = [ "admin" ];
      };
    };
  };

  services.sftpgo = {
    enable = true;
    # SFTPGo 2.7.5 omits PKCE; Kanidm requires S256 for this client.
    package = pkgs.sftpgo.overrideAttrs (old: {
      patches = (old.patches or []) ++ [ ../../../pkgs/sftpgo/oidc-pkce.patch ];
    });
    # WebAdmin and WebClient use separate accounts for the same Kanidm identity.
    # Create missing accounts once; preserve later edits on restart.
    extraArgs = [ "--loaddata-mode" "1" ];
    extraReadWriteDirs = [ "${nasHome}/Uploads" ];
    loadDataFile = pkgs.writeText "sftpgo-accounts.json" (builtins.toJSON {
      version = 17;
      admins = [ {
        username = "breakds";
        status = 1;
        permissions = [ "*" ];
        # SFTPGo requires a hash for admins. The random input was discarded.
        password = "$2a$05$V16HkmsezLtWVEJXhkbCMuK3P.cUfFfFp3Mmgf6Hx.wtSV4IJQ2WC";
      } ];
      users = [ {
        username = "breakds";
        status = 1;
        home_dir = nasHome;
        permissions = {
          "/" = [ "list" "download" ];
          "/Uploads" = [ "list" "download" "upload" "create_dirs" ];
        };
        filters.file_patterns = [ {
          path = "/";
          denied_patterns = privateFolders;
          deny_policy = 1; # Hide the masked directories in WebClient.
        } ];
      } ];
    });
    settings = {
      common.defender.enabled = true;
      data_provider.users_base_dir = "/var/lib/sftpgo/users";
      webdavd.bindings = [ {
        address = "127.0.0.1";
        port = info.ports.webdav;
        prefix = "/dav";
        inherit (proxySettings) proxy_allowed client_ip_proxy_header;
      } ];
      httpd.bindings = [
        (proxySettings // {
          address = "127.0.0.1";
          port = info.ports.client;
          disabled_login_methods = 8; # Disable the WebClient password form.
          oidc = oidc // { redirect_base_url = clientURL; };
          enable_web_admin = false;
          enable_rest_api = false;
          render_openapi = false;
        })
        (proxySettings // {
          address = "127.0.0.1";
          port = info.ports.admin;
          disabled_login_methods = 4; # Disable the WebAdmin password form.
          oidc = oidc // { redirect_base_url = adminURL; role_field = "sftpgo_role"; };
          enable_web_client = false;
          enable_rest_api = false;
        })
      ];
    };
  };

  systemd.services.sftpgo = {
    # SFTPGo discovers the issuer through nginx during startup.
    after = [ "kanidm.service" "nginx.service" "zfs-mount.service" ];
    unitConfig.RequiresMountsFor = "/srv/nas";
    # The create-only seed preserves live accounts. Migrate the existing pilot
    # once, expiring its public shares before their paths get a different root.
    preStart = ''
      if [ -f sftpgo.db ]; then
        ${pkgs.sqlite}/bin/sqlite3 -bail sftpgo.db <<'SQL'
        BEGIN IMMEDIATE;
        CREATE TEMP VIEW pilot AS
          SELECT id FROM users WHERE username = 'breakds' AND home_dir = '/var/lib/sftpgo/users/pilot';
        DELETE FROM shares WHERE user_id IN (SELECT id FROM pilot);
        WITH nas(account) AS (
          SELECT json_extract(CAST(readfile('${config.services.sftpgo.loadDataFile}') AS TEXT), '$.users[0]')
        )
        UPDATE users SET
          home_dir = json_extract(nas.account, '$.home_dir'),
          permissions = json_extract(nas.account, '$.permissions'),
          filters = json_set(COALESCE(CAST(filters AS TEXT), '{}'), '$.file_patterns',
                             json_extract(nas.account, '$.filters.file_patterns')),
          updated_at = CAST(unixepoch('subsec') * 1000 AS INTEGER)
        FROM nas WHERE users.id IN (SELECT id FROM pilot);
        COMMIT;
      SQL
      fi
    '';
    serviceConfig = {
      ExecCondition = "${pkgs.util-linux}/bin/findmnt --mountpoint /srv/nas --types zfs --source VAULT_ROOT/nas --noheadings";
      Restart = "on-failure";
      RestartSec = "10s";
      InaccessiblePaths = [ "-/var/lib/filerun" "-/srv/nas/web" "-/srv/nas/db" "-/var/lib/paperless" ]
        ++ map (name: "${nasHome}/${name}") privateFolders;
    };
  };

  services.nginx.virtualHosts."${info.domain}" = {
    enableACME = true;
    forceSSL = true;
    locations."/".proxyPass = "http://127.0.0.1:${toString info.ports.client}";
    locations."/dav/".proxyPass = "http://127.0.0.1:${toString info.ports.webdav}";
  };

  security.acme.certs."${info.adminDomain}" = {
    dnsProvider = "cloudflare";
    group = config.services.nginx.group;
    environmentFile = "/home/breakds/certs/cloudflare.env";
  };
  services.nginx.virtualHosts."${info.adminDomain}" = {
    forceSSL = true;
    useACMEHost = info.adminDomain;
    locations."/" = {
      proxyPass = "http://127.0.0.1:${toString info.ports.admin}";
      extraConfig = ''
        allow 10.77.1.0/24;
        deny all;
      '';
    };
  };
}
