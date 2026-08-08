{ config, pkgs, ... }:

let
  registry = (import ../../../data/service-registry.nix).kanidm;
  certDir = config.security.acme.certs."${registry.domain}".directory;
in {
  /*
   * Kanidm — the OIDC identity provider for the self-hosted services.
   *
   * Split of responsibilities (this repo is public):
   *   - Declared here: server config, OAuth2 clients, capability groups
   *     (names only, membership never touched by provisioning).
   *   - Imperative via the `kanidm` CLI: persons, email addresses, group
   *     memberships, passkey enrollment. Source of truth for those is the
   *     database + its online backups on the VAULT_ROOT/kanidm dataset.
   *
   * State lives in /var/lib/kanidm = ZFS dataset VAULT_ROOT/kanidm,
   * created by hand (dataset creation stays out of Nix, repo convention).
   *
   * Administration model — no persistent admin password exists:
   *   - Day-to-day admin is done as a person in the `idm_admins` group,
   *     authenticated by passkey: `kanidm login --name <username>`.
   *   - The built-in idm_admin account is break-glass only. Provisioning
   *     recovers it to a fresh RANDOM password at every service start, so
   *     nobody knows its password and no secret file holds it. To use it
   *     (bootstrap, or all passkeys lost), mint a new password on octavian:
   *
   *       CONF=$(systemctl cat kanidm | sed -n 's|.*server -c \(\S*\).*|\1|p')
   *       sudo -u kanidm kanidmd recover-account idm_admin -c "$CONF"
   *
   *     then `kanidm login --name idm_admin` with the printed password.
   *     The next kanidm.service restart invalidates it again.
   */

  age.secrets = {
    # OAuth2 client secret for Grafana. Two readers: kanidm provisioning
    # (sets it on the client) and grafana ($__file provider in its config).
    kanidm-oauth-grafana = {
      file = ../../../secrets/kanidm-oauth-grafana.age;
      mode = "0440";
      owner = "kanidm";
      group = "grafana";
    };
  };

  services.kanidm = {
    # Kanidm requires sequential upgrades (1.10 -> 1.11 -> ..., no skipping),
    # so the package is pinned explicitly and bumped one step at a time.
    # withSecretProvisioning carries the patches that let provisioning set
    # the idm_admin password and oauth2 basic secrets from files.
    package = pkgs.kanidm_1_10.withSecretProvisioning;

    # The CLI (`kanidm`) on octavian itself, for the imperative half of
    # administration: persons, memberships, credential reset tokens.
    client.enable = true;
    client.settings.uri = "https://${registry.domain}";

    server.enable = true;
    server.settings = {
      # The WebAuthn RP ID. Deliberately the full subdomain, NOT breakds.org:
      # a parent-domain RP ID would let any compromised *.breakds.org app
      # interact with passkey ceremonies. Sticky — changing it invalidates
      # enrolled passkeys and renames every principal.
      domain = registry.domain;
      origin = "https://${registry.domain}";

      bindaddress = "127.0.0.1:${toString registry.port}";
      tls_chain = "${certDir}/fullchain.pem";
      tls_key = "${certDir}/key.pem";

      # nginx sits in front; take real client IPs from X-Forwarded-For.
      # (This replaced the pre-1.8 `trust_x_forward_for` boolean.)
      http_client_address_info."x-forward-for" = true;

      # Daily online backup onto the same ZFS dataset. This is the recovery
      # source for everything managed imperatively (persons, credentials).
      online_backup = {
        schedule = "00 03 * * *";
        versions = 7;
      };
    };

    provision = {
      # With no idmAdminPasswordFile set, provisioning self-authenticates by
      # recovering idm_admin to a random throwaway password at each start.
      enable = true;

      # Capability groups, declared so OAuth2 scope maps below can reference
      # them. overwriteMembers = false: membership is managed with the CLI
      # (kanidm group add-members ...) and never clobbered by provisioning.
      groups = {
        grafana-users.overwriteMembers = false;
        grafana-admins.overwriteMembers = false;
      };

      systems.oauth2.grafana = {
        displayName = "Grafana";
        originUrl = "https://${config.services.grafana.settings.server.domain}/login/generic_oauth";
        originLanding = "https://${config.services.grafana.settings.server.domain}/";
        basicSecretFile = config.age.secrets.kanidm-oauth-grafana.path;
        # preferred_username claim becomes the short name ("breakds"), not
        # the full SPN ("breakds@being.breakds.org").
        preferShortUsername = true;
        scopeMaps.grafana-users = [ "openid" "profile" "email" "groups" ];
        # Members of grafana-admins land in Grafana with the Admin role; see
        # role_attribute_path on the Grafana side.
        claimMaps.grafana_role = {
          joinType = "array";
          valuesByGroup.grafana-admins = [ "Admin" ];
        };
      };
    };
  };

  # The kanidm user reads the ACME cert via the nginx group (cert dirs are
  # acme:nginx 0750 for enableACME vhosts).
  users.users.kanidm.extraGroups = [ "nginx" ];

  security.acme.certs."${registry.domain}" = {
    # Kanidm loads the cert at startup; restart it on renewal or it serves
    # the stale cert until the next reboot.
    reloadServices = [ "kanidm.service" ];
  };

  # On a fresh install the cert does not exist yet; order kanidm after the
  # first successful ACME issuance.
  systemd.services.kanidm.after = [ "acme-finished-${registry.domain}.target" ];

  services.nginx.virtualHosts."${registry.domain}" = {
    enableACME = true;
    forceSSL = true;
    # https, not http: kanidm refuses to speak plaintext.
    locations."/".proxyPass = "https://127.0.0.1:${toString registry.port}";
  };
}
