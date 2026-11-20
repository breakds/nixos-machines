let
  breakdsMalenia = builtins.readFile ../data/keys/breakds_malenia.pub;
  octavian = builtins.readFile ../data/keys/octavian_host_ed25519.pub;
  malenia = builtins.readFile ../data/keys/malenia_host_ed25519.pub;
in {
  "frigate-camera-passwords.age".publicKeys = [ breakdsMalenia octavian ];
  "kanidm-oauth-grafana.age".publicKeys = [ breakdsMalenia octavian ];
  "kanidm-oauth-sftpgo.age".publicKeys = [ breakdsMalenia octavian ];
  "kanidm-oauth-forgejo.age".publicKeys = [ breakdsMalenia octavian ];
  "kanidm-oauth-immich.age".publicKeys = [ breakdsMalenia octavian ];
  "kanidm-oauth-gate.age".publicKeys = [ breakdsMalenia octavian ];
  "gate-cookie-secret.age".publicKeys = [ breakdsMalenia octavian ];
  "grafana-secret-key.age".publicKeys = [ breakdsMalenia octavian ];
  # CLOUDFLARE_EMAIL=... and CLOUDFLARE_API_KEY=..., for ACME DNS challenges.
  "cloudflare-env.age".publicKeys = [ breakdsMalenia octavian malenia ];
  # The Index 01 ring's webhook signing secret, as entered in the Pebble app.
  "dccc-ring-secret.age".publicKeys = [ breakdsMalenia malenia ];
}
