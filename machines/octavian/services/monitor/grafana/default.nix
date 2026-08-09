{ config, lib, ... }:

let
  registry = import ../../../../../data/service-registry.nix;
  info = registry.grafana;
  idp = registry.kanidm;

in {
  config = {
    age.secrets.grafana-secret-key = {
      file = ../../../../../secrets/grafana-secret-key.age;
      mode = "0400";
      owner = "grafana";
    };

    # NOTE: At the first time you access the grafana instance, the username and
    # password is both admin. After login you will be forced to change the
    # password for admin.
    services.grafana = {
      enable = true;

      settings.server = {
        domain = info.domain;
        http_addr = "127.0.0.1";
        http_port = info.port;
        # The public URL behind nginx. Without it Grafana derives
        # http://<domain>:<port>/ and sends that as the OAuth redirect_uri,
        # which kanidm rejects (exact-match against the registered https URL).
        root_url = "https://${info.domain}/";
      };

      # Rotated away from the historical hardcoded value (public in git
      # history). Nothing encrypted with the old key existed at rotation
      # time — the only provisioned datasource carries no credentials.
      settings.security.secret_key =
        "$__file{${config.age.secrets.grafana-secret-key.path}}";

      # TRANSITIONAL — REMOVE after the first successful kanidm login. Lets
      # Grafana link the incoming kanidm identity to the pre-existing local
      # user by matching email (breakds@gmail.com). The link is then stored
      # by subject, so this email matching is only needed once. Safe here:
      # kanidm is the only IdP and its mail attribute is admin-assigned.
      settings.auth.oauth_allow_insecure_email_lookup = true;

      # SSO via kanidm. Local admin login remains available at /login as the
      # escape hatch until the OIDC path is proven.
      settings."auth.generic_oauth" = {
        enabled = true;
        name = "Kanidm";
        client_id = "grafana";
        client_secret = "$__file{${config.age.secrets.kanidm-oauth-grafana.path}}";
        scopes = "openid,profile,email,groups";
        auth_url = "https://${idp.domain}/ui/oauth2";
        token_url = "https://${idp.domain}/oauth2/token";
        api_url = "https://${idp.domain}/oauth2/openid/grafana/userinfo";
        use_pkce = true;
        use_refresh_token = true;
        # Account creation on first login is effectively gated by kanidm:
        # only members of grafana-users get the openid scope at all.
        allow_sign_up = true;
        login_attribute_path = "preferred_username";
        groups_attribute_path = "groups";
        # grafana_role is a kanidm claim map fed by grafana-admins membership.
        role_attribute_path =
          "contains(grafana_role[*], 'Admin') && 'Admin' || 'Viewer'";
      };

      provision.datasources.settings.datasources = [{
        name = "Prometheus";
        type = "prometheus";
        access = "proxy";
        url = "http://localhost:${toString config.services.prometheus.port}";
      }];

      # Note: not using provision for reproducible dashboards and alerts at this
      # moment, but their jsons are committed anyway for future improvements.
    };

    services.nginx = {
      virtualHosts = {
        "${config.services.grafana.settings.server.domain}" = {
          enableACME = true;
          forceSSL = true;

          locations."/" = {
            proxyPass = "http://localhost:${
                toString config.services.grafana.settings.server.http_port
              }";
            proxyWebsockets = true;
          };
        };
      };
    };
  };
}
