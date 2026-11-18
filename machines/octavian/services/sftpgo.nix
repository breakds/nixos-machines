{ config, pkgs, ... }:

let
  registry = import ../../../data/service-registry.nix;
  info = registry.sftpgo;
  clientURL = "https://${info.domain}";
  adminURL = "http://127.0.0.1:${toString info.ports.admin}";
  oidc = {
    client_id = "sftpgo";
    client_secret_file = config.age.secrets.kanidm-oauth-sftpgo.path;
    config_url = "https://${registry.kanidm.domain}/oauth2/openid/sftpgo";
    username_field = "preferred_username";
    scopes = [ "openid" "profile" ];
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
    loadDataFile = pkgs.writeText "sftpgo-pilot-accounts.json" (builtins.toJSON {
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
        home_dir = "/var/lib/sftpgo/users/pilot";
        permissions."/" = [ "list" "download" "upload" "create_dirs" ];
      } ];
    });
    settings = {
      data_provider.users_base_dir = "/var/lib/sftpgo/users";
      httpd.bindings = [
        {
          address = "127.0.0.1";
          port = info.ports.client;
          disabled_login_methods = 8; # Disable the WebClient password form.
          oidc = oidc // { redirect_base_url = clientURL; };
          enable_web_admin = false;
          enable_rest_api = false;
          render_openapi = false;
          proxy_allowed = [ "127.0.0.1" ];
          client_ip_proxy_header = "X-Real-IP";
          security = {
            enabled = true;
            https_proxy_headers = [ { key = "X-Forwarded-Proto"; value = "https"; } ];
          };
        }
        {
          address = "127.0.0.1";
          port = info.ports.admin;
          disabled_login_methods = 4; # Disable the WebAdmin password form.
          oidc = oidc // { redirect_base_url = adminURL; role_field = "sftpgo_role"; };
          enable_web_client = false;
          enable_rest_api = false;
        }
      ];
    };
  };

  systemd.services.sftpgo = {
    # SFTPGo discovers the issuer through nginx during startup.
    after = [ "kanidm.service" "nginx.service" ];
    serviceConfig = {
      Restart = "on-failure";
      RestartSec = "10s";
      InaccessiblePaths = [ "-/var/lib/filerun" ];
    };
  };

  services.nginx.virtualHosts."${info.domain}" = {
    enableACME = true;
    forceSSL = true;
    locations."/".proxyPass = "http://127.0.0.1:${toString info.ports.client}";
  };
}
