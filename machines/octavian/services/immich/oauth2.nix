{ config, ... }:

let
  registry = import ../../../../data/service-registry.nix;
  info = registry.immich;
in {
  /*
   * Immich <-> kanidm OIDC pairing. The kanidm half (client registration,
   * capability groups, claim map) is declared here; the immich half lives
   * in immich's own database and is configured once through the admin UI,
   * because declaring services.immich.settings would make the entire
   * system-settings UI read-only (see the note in default.nix).
   *
   * Admin UI runbook — Administration > Settings > OAuth:
   *   Issuer URL:    https://being.breakds.org/oauth2/openid/immich/.well-known/openid-configuration
   *   Client ID:     immich
   *   Client Secret: ssh octavian.local 'sudo cat /run/agenix/kanidm-oauth-immich'
   *   Scope:         openid email profile
   *   Signing Algorithm: ES256
   *     (kanidm signs id tokens with ES256; the RS256 default fails with
   *     "unexpected JWT alg received")
   *   Button Text:   Login with kanidm
   *   Auto Register: enabled
   *   Mobile Redirect URI Override: enabled, set to
   *     https://pic.breakds.org/api/oauth/mobile-redirect
   *     (the app's native redirect is app.immich:///oauth-callback, a
   *     custom scheme kanidm will not accept; the server rewrites it to
   *     this https URL, which is what the originUrl list below registers)
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

  # OAuth2 client secret. Read by kanidm provisioning; pasted into the
  # immich admin UI by hand (see runbook above).
  age.secrets.kanidm-oauth-immich = {
    file = ../../../../secrets/kanidm-oauth-immich.age;
    owner = "kanidm";
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
      # logins back to the app (the mobile override in the runbook above),
      # which keeps this list https-only.
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
}
