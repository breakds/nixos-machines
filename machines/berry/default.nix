{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../base
  ];

  config = {
    vital.mainUser = "cassandra";

    # Machine-specific networking configuration.
    networking.hostName = "berry";
    # Generated via `head -c 8 /etc/machine-id`
    networking.hostId = "fe156831";

    boot.kernelPackages = pkgs.linuxPackages_5_10;
    services.xserver.videoDrivers = [ "displaylink" "modesetting" ];
    
    # +----------+
    # | Desktop  |
    # +----------+

    vital.graphical = {
      enable = true;
      remote-desktop.enable = false;
      xserver.dpi = 120;
    };

    # +----------+
    # | Packages |
    # +----------+

    vital.pre-installed.level = 5;
    vital.games.steam.enable = false;

    vital.programs = {
      modern-utils.enable = true;
      vscode.enable = false; # Use the one from home-manager
    };

    environment.systemPackages = with pkgs; [
      dbeaver
      gimp peek gnupg pass libreoffice
      skypeforlinux
      nodejs-14_x
      (yarn.override { nodejs = nodejs-14_x; })
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
    system.stateVersion = "21.05"; # Did you read the comment?
  };
}
