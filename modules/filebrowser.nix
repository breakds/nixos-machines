{ config, pkgs, lib, ... }:

let rootPath = "/var/lib/filebrowser";
    dataPath = "${rootPath}/data";
    dbPath = "${rootPath}/filebrowser.db";
    settingsPath = "${rootPath}/filebrowser.json";

    domain = "filebrowser.breakds.org";

    port = 19575;

    # TODO(breakds): It is not recommended to run it as a normal user.
    # Let's create a dedicate user for this.
    user = config.users.users.breakds;
    group = config.user.users.breakds;

in {
  config = {
    virtualisation.oci-containers.containers."filebrowser" = {
      image = "filebrowser/filebrowser";
      environment = {
        "PUID" = "${toString user.uid}";
        "PGID" = "${toString group.gid}";
      };
      ports = [ "${toString port}:80" ];
      volumes = [
        "${dataPath}:/srv"
        "${dbPath}:/database/filebrowser.db"
        "${settingsPath}:/.filebrowser.json"
      ];
    };

    systemd.tmpfiles.rules = [
      "d ${dataPath} 775 ${toString user.uid} ${toString group.gid} -"
      # If you don't already have a database file, make sure to create a new empty file
      # under the path you specified.
      "f ${dbPath} 775 ${toString user.uid} ${toString group.gid} -"
    ];

    systemd.services.init-filebrowser = {
      description = "Create files for filebrowser";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig.Type = "oneshot";

      script = ''
        # Path to the settings file
        file_path="${settingsPath}"

        # Check if the file exists
        if [ ! -f "$file_path" ]; then
            # If the file does not exist, create it and add the specified content
                echo '{
                  "port": 80,
                  "baseURL": "",
                  "address": "",
                  "log": "stdout",
                  "database": "/database/filebrowser.db",
                  "root": "/srv",
                  "branding": {
                    "name": "General AI Lab NAS"
                  }
                }' > "$file_path"

            chown ${toString user.uid}:${toString group.gid} "$file_path"
        fi
      '';
    };

    # The nginx configuration to expose it if nginx is enabled.
    services.nginx.virtualHosts = lib.mkIf config.services.nginx.enable {
      "${domain}" = {
        enableACME = true;
        forceSSL = true;
        locations."/".proxyPass = "http://localhost:${toString port}";
      };
    };
  };
}
