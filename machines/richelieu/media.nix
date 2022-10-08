{ config, lib, ... }:

{
  # The option dataDir uses the default: /var/lib/plex
  services.plex = {
    enable = true;
    openFirewall = false;  # So that we can disable 32400 and manually whitelist the rest.
  };

  # See here https://github.com/NixOS/nixpkgs/blob/nixos-21.11/nixos/modules/services/misc/plex.nix#L157-L160
  networking.firewall = {
    allowedTCPPorts = [ 3005 8324 32469 ];
    allowedUDPPorts = [ 1900 5353 32410 32412 32413 32414 ];
  };

  services.nginx = {
    virtualHosts = {
      "plex.breakds.org" = {
        enableACME = true;
        forceSSL = true;

        locations."/" = {
          proxyPass = "http://localhost:32400";
          proxyWebsockets = true;
        };
        
        extraConfig = ''
          # Some players don't reopen a socket and playback stops totally instead of resuming after an extended pause
          send_timeout 100m;
          # Plex headers
          proxy_set_header X-Plex-Client-Identifier $http_x_plex_client_identifier;
          proxy_set_header X-Plex-Device $http_x_plex_device;
          proxy_set_header X-Plex-Device-Name $http_x_plex_device_name;
          proxy_set_header X-Plex-Platform $http_x_plex_platform;
          proxy_set_header X-Plex-Platform-Version $http_x_plex_platform_version;
          proxy_set_header X-Plex-Product $http_x_plex_product;
          proxy_set_header X-Plex-Token $http_x_plex_token;
          proxy_set_header X-Plex-Version $http_x_plex_version;
          proxy_set_header X-Plex-Nocache $http_x_plex_nocache;
          proxy_set_header X-Plex-Provides $http_x_plex_provides;
          proxy_set_header X-Plex-Device-Vendor $http_x_plex_device_vendor;
          proxy_set_header X-Plex-Model $http_x_plex_model;
          # Buffering off send to the client as soon as the data is received from Plex.
          proxy_redirect off;
          proxy_buffering off;
        '';
      };
    };
  };

  # TOOD(breakds): Enable Bittorrent when I get a better idea on how
  # it works from the networking side.
  services.deluge = {
    enable = false;

    web = {
      enable = true;
      port = 8112;
      openFirewall = true;
    };

    declarative = true;
    dataDir = "/var/lib/deluge";
    openFirewall = true;
    authFile = "/var/lib/deluge/auth";
  };

  users.extraUsers = {
    "breakds" = {
      extraGroups = [
        "deluge"
      ];
    };
  };
}
