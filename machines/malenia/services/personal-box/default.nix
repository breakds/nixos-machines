{ config, pkgs, lib, ... }:

# A dccc box for personal workbenches: errands, finance, family, pet, smart
# home. It sees nothing of malenia unless bound in. Out of it go the internet,
# DNS, and the home services listed below; the rest of the LAN is dropped.

let
  name = "personal";
  user = config.services.dccc.user;
  group = config.users.users.${user}.group;
  home = "/home/${user}";
  link = "ve-${name}";

  # Home services the box may reach on the LAN, as address and port. Home
  # Assistant, immich, and files.breakds.org are on octavian under public
  # names, so the box reaches them as it reaches the internet.
  lan = [
    { address = "10.77.1.1"; proto = "udp"; port = 53; }    # DNS
    { address = "10.77.1.1"; proto = "tcp"; port = 53; }
    { address = "10.77.1.128"; proto = "tcp"; port = 11081; } # basalt on lorian
    { address = "10.77.1.131"; proto = "tcp"; port = 22; }    # Forgejo ssh on octavian
  ];
  private = [ "10.0.0.0/8" "172.16.0.0/12" "192.168.0.0/16" "100.64.0.0/10" "169.254.0.0/16" ];

  # pi starts with basalt on lorian. pi writes settings.json, so the box
  # copies it in once; models.json stays as declared.
  piSettings = pkgs.writeText "pi-settings.json" (builtins.toJSON {
    defaultProvider = "basalt@lorian";
    defaultModel = "DeepSeek-V4.1-Flash-1017 UD-IQ2_XXS";
    defaultThinkingLevel = "high";
  });
  piModels = pkgs.writeText "pi-models.json" (builtins.toJSON {
    providers."basalt@lorian" = {
      baseUrl = "http://10.77.1.128:11081/v1";
      api = "openai-completions";
      apiKey = "basalt";
      compat = {
        supportsDeveloperRole = false;
        supportsStore = false;
        maxTokensField = "max_tokens";
        thinkingFormat = "openai";
      };
      models = [{
        id = "DeepSeek-V4.1-Flash-1017 UD-IQ2_XXS";
        name = "DeepSeek V4.1 Flash 1017 (Lorian Basalt)";
        reasoning = true;
        input = [ "text" ];
        contextWindow = 524288;
        maxTokens = 16384;
        thinkingLevelMap = { off = "none"; minimal = "low"; };
        cost = { input = 0; output = 0; cacheRead = 0; cacheWrite = 0; };
      }];
    };
  });

  # pi skills, one directory each under ./skills, linked into the box.
  skills = builtins.attrNames (builtins.readDir ./skills);

  # The command of the kagi-search skill. Break puts the key in the box by
  # hand at ~/.config/kagi/api-key.
  kagiSearch = pkgs.writeShellApplication {
    name = "kagi-search";
    runtimeInputs = [ pkgs.curl pkgs.jq ];
    text = builtins.readFile ./skills/kagi-search/kagi-search.sh;
  };

in {
  services.dccc.boxes.${name} = {
    hostAddress = "10.56.1.1";
    localAddress = "10.56.1.2";
  };

  # The box's data lives on the boxes drive: its root, and the workspaces
  # of its workbenches. container@NAME requires both mounts, so without the
  # drive the box does not start, rather than fill malenia's root.
  fileSystems."/var/lib/nixos-containers/${name}" = {
    device = "/srv/boxes/${name}/root";
    fsType = "none";
    options = [ "bind" "nofail" ];
    depends = [ "/srv/boxes" ];
  };
  fileSystems."/var/lib/dccc/boxes/${name}" = {
    device = "/srv/boxes/${name}/workspaces";
    fsType = "none";
    options = [ "bind" "nofail" ];
    depends = [ "/srv/boxes" ];
  };

  systemd.services."container@${name}" = {
    serviceConfig = {
      MemoryMax = "16G";
      CPUQuota = "800%";
    };
  };

  containers.${name}.config = {
    nixpkgs.pkgs = pkgs;

    nix.settings.experimental-features = [ "nix-command" "flakes" ];
    programs.direnv.enable = true;

    # The kirkwoods repo on git.breakds.org, through a deploy key made in the
    # box (~/.ssh/kirkwoods). Forgejo's ssh does not answer at the public
    # address, so git goes to octavian on the LAN.
    programs.ssh.extraConfig = ''
      Host git.breakds.org
        HostName 10.77.1.131
        User forgejo
        IdentityFile ~/.ssh/kirkwoods
        IdentitiesOnly yes
    '';
    programs.ssh.knownHosts."git.breakds.org" = {
      hostNames = [ "git.breakds.org" "10.77.1.131" ];
      publicKeyFile = ../../../../data/keys/octavian_host_ed25519.pub;
    };
    programs.git = {
      enable = true;
      config = {
        user.name = "Break Yang";
        user.email = "bds@breakds.org";
        # Benches share one checkout of main.
        pull.rebase = true;
      };
    };

    environment.systemPackages = with pkgs; [
      pi-coding-agent
      git
      gh
      forgejo-cli
      jq
      curl
      kagiSearch
      w3m
      poppler-utils
      # For a shell over ssh.
      tmux
      xh
      bat
      fd
      btop
    ];

    systemd.tmpfiles.rules = [
      "d ${home}/.pi 0755 ${user} ${group} -"
      "d ${home}/.pi/agent 0755 ${user} ${group} -"
      "C ${home}/.pi/agent/settings.json 0644 ${user} ${group} - ${piSettings}"
      "L+ ${home}/.pi/agent/models.json - - - - ${piModels}"
      "d ${home}/.pi/agent/skills 0755 ${user} ${group} -"
      "d ${home}/.config 0755 ${user} ${group} -"
      "d ${home}/.config/kagi 0700 ${user} ${group} -"
    ] ++ map (skill: "L+ ${home}/.pi/agent/skills/${skill} - - - - ${./skills + "/${skill}"}") skills;
  };

  # What leaves the box for the LAN: only the list above. dccc already closes
  # malenia itself to the box, but for its API.
  networking.firewall.extraCommands = ''
    iptables -N ${name}-box-out 2>/dev/null || iptables -F ${name}-box-out
    ${lib.concatMapStrings (s: ''
      iptables -A ${name}-box-out -d ${s.address} -p ${s.proto} --dport ${toString s.port} -j RETURN
    '') lan}
    ${lib.concatMapStrings (range: ''
      iptables -A ${name}-box-out -d ${range} -j DROP
    '') private}
    iptables -D FORWARD -i ${link} -j ${name}-box-out 2>/dev/null || true
    iptables -I FORWARD -i ${link} -j ${name}-box-out
    # The box has no IPv6.
    ip6tables -D FORWARD -i ${link} -j DROP 2>/dev/null || true
    ip6tables -I FORWARD -i ${link} -j DROP
  '';
  networking.firewall.extraStopCommands = ''
    iptables -D FORWARD -i ${link} -j ${name}-box-out 2>/dev/null || true
    ip6tables -D FORWARD -i ${link} -j DROP 2>/dev/null || true
  '';
}
