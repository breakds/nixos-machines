{ config, pkgs, ... }:

let
  registry = import ../../../../data/service-registry.nix;
  idp = registry.kanidm;
  info = registry.forgejo;

  # The auth source name in Forgejo. Part of the OAuth redirect URL, so it
  # must stay in sync with the kanidm originUrl below.
  authName = "kanidm";

  # Forgejo keeps OAuth2 auth sources in its database, not app.ini, so the
  # kanidm source is registered with the admin CLI on every service start
  # (add on first run, update thereafter — both idempotent).
  #
  # The CLI offers no --secret-file, so the client secret briefly appears
  # in the process argv. Acceptable here: the window is sub-second and the
  # secret only guards which app may talk to kanidm, not any user data.
  provisionAuthSource = pkgs.writeShellScript "forgejo-oauth2-provision" ''
    set -euo pipefail

    # Wait for the server to finish starting (and migrating the database
    # on upgrades) before the CLI touches the same database.
    for _ in $(seq 60); do
      curl -sf http://127.0.0.1:${toString info.port}/api/healthz > /dev/null && break
      sleep 1
    done

    exe=${config.services.forgejo.package}/bin/forgejo

    args=(
      --name ${authName}
      --provider openidConnect
      --key forgejo
      --secret "$(cat ${config.age.secrets.kanidm-oauth-forgejo.path})"
      --auto-discover-url https://${idp.domain}/oauth2/openid/forgejo/.well-known/openid-configuration
      --scopes openid --scopes profile --scopes email --scopes groups
      --group-claim-name forgejo_role
      --admin-group Admin
    )

    id=$("$exe" admin auth list | awk -v name=${authName} 'NR > 1 && $2 == name { print $1 }')
    if [ -n "$id" ]; then
      "$exe" admin auth update-oauth --id "$id" "''${args[@]}"
    else
      "$exe" admin auth add-oauth "''${args[@]}"
    fi
  '';
in {
  /*
   * Forgejo <-> kanidm OIDC pairing. Both halves of the contract live in
   * this file: the kanidm side (client registration, capability groups,
   * claim map) and the forgejo side (auth source + oauth2_client policy).
   * Group and claim names are our convention; only the group-claim value
   * "Admin" is echoed in the forgejo --admin-group flag.
   *
   * Access control: only members of forgejo-users can complete the OIDC
   * flow (the scope map grants them the openid scope); forgejo-admins
   * members get site administrator. Membership is managed imperatively:
   *   kanidm group add-members forgejo-users <person>
   *
   * First login for a pre-existing local account: ACCOUNT_LINKING=login
   * makes forgejo ask for the local password once and link the kanidm
   * identity to that account — no insecure auto-matching.
   */

  # OAuth2 client secret. Two readers: kanidm provisioning (sets it on the
  # client) and the forgejo provisioning script above.
  age.secrets.kanidm-oauth-forgejo = {
    file = ../../../../secrets/kanidm-oauth-forgejo.age;
    mode = "0440";
    owner = "kanidm";
    group = "forgejo";
  };

  services.kanidm.provision = {
    # Capability groups; membership is CLI-managed, never clobbered.
    groups = {
      forgejo-users.overwriteMembers = false;
      forgejo-admins.overwriteMembers = false;
    };

    systems.oauth2.forgejo = {
      displayName = "Forgejo";
      originUrl = "https://${info.domain}/user/oauth2/${authName}/callback";
      originLanding = "https://${info.domain}/";
      basicSecretFile = config.age.secrets.kanidm-oauth-forgejo.path;
      # preferred_username claim becomes the short name ("breakds"), not
      # the full SPN. Forgejo usernames follow it (USERNAME = nickname).
      preferShortUsername = true;
      scopeMaps.forgejo-users = [ "openid" "profile" "email" "groups" ];
      # Members of forgejo-admins carry ["Admin"] in the forgejo_role
      # claim, which --admin-group above maps to site administrator.
      claimMaps.forgejo_role = {
        joinType = "array";
        valuesByGroup.forgejo-admins = [ "Admin" ];
      };
    };
  };

  services.forgejo.settings = {
    # No self-registration form, but accounts CAN be created through an
    # external auth source (the kanidm SSO flow). Who gets that far is
    # gated by kanidm: only forgejo-users members complete the flow.
    # (DISABLE_REGISTRATION = true would block SSO signup as well.)
    service = {
      DISABLE_REGISTRATION = false;
      ALLOW_ONLY_EXTERNAL_REGISTRATION = true;
    };

    oauth2_client = {
      ENABLE_AUTO_REGISTRATION = true;
      # Take the forgejo username from preferred_username.
      USERNAME = "nickname";
      # On username/email collision with an existing local account, ask
      # for that account's password once and link, instead of erroring
      # (disabled) or trusting the email claim blindly (auto).
      ACCOUNT_LINKING = "login";
    };
  };

  systemd.services.forgejo = {
    path = [ pkgs.curl pkgs.gawk pkgs.coreutils ];
    serviceConfig.ExecStartPost = [ "${provisionAuthSource}" ];
  };
}
