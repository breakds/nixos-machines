{ config, ... }:

let
  registry = import ../../../../data/service-registry.nix;
  idp = registry.kanidm;
  info = registry.immich;
in {
  /*
   * Immich <-> kanidm OIDC pairing. Both halves of the contract live in
   * this file: the kanidm side (client registration, capability groups,
   * claim map) and the immich side (the oauth section of its config file).
   *
   * Access control: only members of immich-users can complete the OIDC
   * flow (the scope map grants them the openid scope). Membership is
   * managed imperatively:
   *   kanidm group add-members immich-users <person>
   *
   * Pre-existing local accounts merge automatically: on the first SSO
   * login immich looks the account up by the email claim and stores the
   * kanidm subject id on it, so the kanidm person's mail attribute must
   * match the immich account email.
   *
   * immich-admins members carry immich_role=admin, but immich only reads
   * the role claim when it auto-registers a brand-new user — existing
   * accounts keep whatever role they already have in immich's database.
   */

  # OAuth2 client secret. Two readers: kanidm provisioning (as the kanidm
  # user) and the immich config renderer (via systemd LoadCredential).
  age.secrets.kanidm-oauth-immich = {
    file = ../../../../secrets/kanidm-oauth-immich.age;
    mode = "0440";
    owner = "kanidm";
    group = "immich";
  };

  services.kanidm.provision = {
    # Capability groups; membership is CLI-managed, never clobbered.
    groups = {
      immich-users.overwriteMembers = false;
      immich-admins.overwriteMembers = false;
    };

    systems.oauth2.immich = {
      displayName = "Immich";
      # kanidm matches redirect URLs exactly. The web login page and the
      # account-link flow on the user settings page each send their own
      # URL; the third entry is the server-side hop that hands mobile
      # logins back to the app (mobileOverrideEnabled below), which keeps
      # this list https-only.
      originUrl = [
        "https://${info.domain}/auth/login"
        "https://${info.domain}/user-settings"
        "https://${info.domain}/api/oauth/mobile-redirect"
      ];
      originLanding = "https://${info.domain}/auth/login";
      basicSecretFile = config.age.secrets.kanidm-oauth-immich.path;
      scopeMaps.immich-users = [ "openid" "profile" "email" ];
      # immich validates the role claim with isString, so join the values
      # into a plain string (ssv), not a JSON array.
      claimMaps.immich_role = {
        joinType = "ssv";
        valuesByGroup.immich-admins = [ "admin" ];
      };
    };
  };

  services.immich.settings.oauth = {
    enabled = true;
    issuerUrl =
      "https://${idp.domain}/oauth2/openid/immich/.well-known/openid-configuration";
    clientId = "immich";
    clientSecret._secret = config.age.secrets.kanidm-oauth-immich.path;
    scope = "openid email profile";
    # kanidm signs id tokens with ES256; immich defaults to RS256 and would
    # reject the token with "unexpected JWT alg received".
    signingAlgorithm = "ES256";
    buttonText = "Login with kanidm";
    # The mobile app's native redirect is app.immich:///oauth-callback,
    # a custom scheme kanidm will not accept. With the override enabled the
    # server rewrites it to the https URL below (registered in kanidm),
    # which then bounces the browser back into the app.
    mobileOverrideEnabled = true;
    mobileRedirectUri = "https://${info.domain}/api/oauth/mobile-redirect";
  };
}
