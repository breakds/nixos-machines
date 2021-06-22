{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../base
  ];

  config = {
    vital.mainUser = "cassandra";

    networking = {
      hostName = "zen";
      hostId = "6b6980fa";
    };    

    vital.graphical.enable = true;
    vital.pre-installed.level = 5;
    vital.games.steam.enable = false;

    # TODO(breakds): Replace this with home-manager's programs.vscode.
    vital.programs.vscode.enable = true;

    environment.systemPackages = with pkgs; [
      gimp peek gnupg pass libreoffice
      skypeforlinux
      nodejs-12_x
      (yarn.override { nodejs = nodejs-12_x; })
      (nodePackages.create-react-app.override {
        preRebuild = ''
            substituteInPlace $(find -type f -name createReactApp.js) \
                --replace "path.join(root, 'yarn.lock')" "path.join(root, 'yarn.lock')); fs.chmodSync(path.join(root, 'yarn.lock'), 0o644"
        '';
      })
    ];

    # This value determines the NixOS release from which the default settings
    # for stateful data, like file locations and database versions on your
    # system were taken. It‘s perfectly fine and recommended to leave this value
    # at the release version of the first install of this system. Before
    # changing this value read the documentation for this option (e.g. man
    # configuration.nix or on https://nixos.org/nixos/options.html).
    system.stateVersion = "20.09"; # Did you read the comment?
  };
}
