let
  breakdsMalenia = builtins.readFile ../data/keys/breakds_malenia.pub;
  octavian = builtins.readFile ../data/keys/octavian_host_ed25519.pub;
in { "frigate-camera-passwords.age".publicKeys = [ breakdsMalenia octavian ]; }
