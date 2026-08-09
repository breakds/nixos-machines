{ config, ... }:

let
  registry = import ../../../../../data/service-registry.nix;
  idp = registry.kanidm;
in {
  /*
   * Grafana <-> kanidm OIDC pairing. Both halves of the contract live in
   * this file: the kanidm side (client registration, capability groups,
   * claim map — merged into services.kanidm.provision by NixOS) and the
   * grafana side (generic_oauth). The group and claim names are our own
   * convention; only the role values ("Admin", "Viewer") are grafana
   * vocabulary.
   *
   * Access control: only members of grafana-users can complete the OIDC
   * flow at all (the scope map is what grants them the openid scope).
   * Membership is managed imperatively: kanidm group add-members ...
   */

  # OAuth2 client secret. Two readers: kanidm provisioning (sets it on the
  # client) and grafana ($__file provider in its config).
  age.secrets.kanidm-oauth-grafana = {
    file = ../../../../../secrets/kanidm-oauth-grafana.age;
    mode = "0440";
    owner = "kanidm";
    group = "grafana";
  };

  services.kanidm.provision = {
    # Capability groups, declared so the scope maps below can reference
    # them. overwriteMembers = false: membership is managed with the CLI
    # and never clobbered by provisioning.
    groups = {
      grafana-users.overwriteMembers = false;
      grafana-admins.overwriteMembers = false;
    };

    systems.oauth2.grafana = {
      displayName = "Grafana";
      originUrl =
        "${config.services.grafana.settings.server.root_url}login/generic_oauth";
      originLanding = config.services.grafana.settings.server.root_url;
      basicSecretFile = config.age.secrets.kanidm-oauth-grafana.path;
      # preferred_username claim becomes the short name ("breakds"), not
      # the full SPN ("breakds@being.breakds.org").
      preferShortUsername = true;
      scopeMaps.grafana-users = [ "openid" "profile" "email" "groups" ];
      # Members of grafana-admins land in Grafana with the Admin role; see
      # role_attribute_path below.
      claimMaps.grafana_role = {
        joinType = "array";
        valuesByGroup.grafana-admins = [ "Admin" ];
      };
    };
  };

  # SSO via kanidm. Local login at /login stays enabled as the escape
  # hatch; the local admin account is unaffected by OIDC.
  services.grafana.settings."auth.generic_oauth" = {
    enabled = true;
    name = "Kanidm";
    client_id = "grafana";
    client_secret = "$__file{${config.age.secrets.kanidm-oauth-grafana.path}}";
    scopes = "openid,profile,email,groups";
    auth_url = "https://${idp.domain}/ui/oauth2";
    token_url = "https://${idp.domain}/oauth2/token";
    api_url = "https://${idp.domain}/oauth2/openid/grafana/userinfo";
    use_pkce = true;
    # Tether grafana sessions to kanidm: the short-lived access token is
    # renewed on the back channel, so revoking access in kanidm takes
    # effect within minutes instead of at cookie expiry.
    use_refresh_token = true;
    # Account creation on first login is effectively gated by kanidm:
    # only members of grafana-users get the openid scope at all.
    allow_sign_up = true;
    login_attribute_path = "preferred_username";
    groups_attribute_path = "groups";
    # grafana_role is the kanidm claim map above, fed by grafana-admins
    # membership.
    role_attribute_path =
      "contains(grafana_role[*], 'Admin') && 'Admin' || 'Viewer'";
  };
}
