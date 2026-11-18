let registry = (import ../../../data/service-registry.nix).sftpgo;

in {
  services.sftpgo = {
    enable = true;
    settings = {
      data_provider.users_base_dir = "/var/lib/sftpgo/users";
      httpd.bindings = [
        {
          address = "127.0.0.1";
          port = registry.ports.client;
          enable_web_admin = false;
          enable_rest_api = false;
          render_openapi = false;
          proxy_allowed = [ "127.0.0.1" ];
          client_ip_proxy_header = "X-Real-IP";
          security = {
            enabled = true;
            https_proxy_headers = [ { key = "X-Forwarded-Proto"; value = "https"; } ];
          };
        }
        {
          address = "127.0.0.1";
          port = registry.ports.admin;
          enable_web_client = false;
          enable_rest_api = false;
        }
      ];
    };
  };

  # Keep the pilot away from the live paperless tree and all FileRun data.
  systemd.services.sftpgo.serviceConfig.InaccessiblePaths = [ "-/var/lib/filerun" ];

  services.nginx.virtualHosts."${registry.domain}" = {
    enableACME = true;
    forceSSL = true;
    locations."/".proxyPass = "http://127.0.0.1:${toString registry.ports.client}";
  };
}
