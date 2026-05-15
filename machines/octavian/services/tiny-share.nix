{ lib, ... }:

let
  authorizedKeyFiles = [
    ../../../data/keys/breakds_malenia.pub
  ];

  readKey = path: lib.removeSuffix "\n" (builtins.readFile path);

in {
  services.share = {
    enable = true;
    domain = "share.breakds.org";
    authorizedKeys = map readKey authorizedKeyFiles;
  };
}
