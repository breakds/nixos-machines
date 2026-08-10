{ config, ... }:

let
  registry = import ../../../data/service-registry.nix;
  idp = registry.kanidm;
  info = registry.gate;
in {
  /*
   * The gate — an oauth2-proxy forward-auth wall in front of services that
   * have no authentication of their own (e.g. solar assistant).
   *
   * How it works: a protected app declares itself in
   * services.oauth2-proxy.nginx.virtualHosts (next to its own nginx vhost);
   * nginx then sub-requests /oauth2/auth on every request, and when the
   * session cookie is missing redirects the browser to this vhost for the
   * kanidm OIDC dance. The cookie spans .breakds.org, so one login covers
   * every gated app.
   *
   * Access control: only members of gate-users can complete the OIDC flow
   * (the scope map grants them the openid scope). Membership is managed
   * imperatively:
   *   kanidm group add-members gate-users <person>
   * Note the gate is all-or-nothing: any gate-users member can reach every
   * gated vhost.
   */

  # OAuth2 client secret. kanidm provisioning reads it directly; oauth2-proxy
  # gets it through systemd LoadCredential (read as root), so kanidm is the
  # only user that needs to open the file itself.
  age.secrets.kanidm-oauth-gate = {
    file = ../../../secrets/kanidm-oauth-gate.age;
    owner = "kanidm";
  };

  # Encrypts/signs the gate's own session cookie; kanidm never sees this one.
  age.secrets.gate-cookie-secret.file = ../../../secrets/gate-cookie-secret.age;

  services.kanidm.provision = {
    # Capability group; membership is CLI-managed, never clobbered.
    groups.gate-users.overwriteMembers = false;

    systems.oauth2.gate = {
      displayName = "Gate";
      originUrl = "https://${info.domain}/oauth2/callback";
      originLanding = "https://${info.domain}/";
      basicSecretFile = config.age.secrets.kanidm-oauth-gate.path;
      preferShortUsername = true;
      scopeMaps.gate-users = [ "openid" "email" "profile" ];
    };
  };

  services.oauth2-proxy = {
    enable = true;
    provider = "oidc";
    clientID = "gate";
    clientSecretFile = config.age.secrets.kanidm-oauth-gate.path;
    oidcIssuerUrl = "https://${idp.domain}/oauth2/openid/gate";
    redirectURL = "https://${info.domain}/oauth2/callback";
    httpAddress = "http://127.0.0.1:${toString info.port}";
    reverseProxy = true;
    scope = "openid email profile";
    # Authorization already happened in kanidm (the gate-users scope map),
    # so any authenticated email is acceptable here.
    email.domains = [ "*" ];
    # Report the identity back to nginx via X-Auth-Request-* headers, which
    # the nginx integration forwards to upstreams as X-User / X-Email.
    setXauthrequest = true;
    cookie = {
      domain = ".breakds.org";
      secretFile = config.age.secrets.gate-cookie-secret.path;
    };
    nginx.domain = info.domain;
    extraConfig = {
      # kanidm runs its clients in enforced-PKCE mode.
      code-challenge-method = "S256";
      # Allow the post-login redirect to land back on the protected vhosts,
      # which live on sibling subdomains of the gate.
      whitelist-domain = ".breakds.org";
      # There is only one IdP; go straight into the kanidm flow instead of
      # showing oauth2-proxy's own "Sign in with ..." interstitial.
      skip-provider-button = true;
    };
  };

  # The gate's own vhost. The oauth2-proxy nginx integration adds the
  # /oauth2/ locations to it; there is nothing else to serve here.
  services.nginx.virtualHosts."${info.domain}" = {
    enableACME = true;
    forceSSL = true;
  };
}
