let clock = {
      type = "clock";
      hour-format = "24h";
      timezones = [
        { timezone = "America/Los_Angeles"; label = "California"; }
        { timezone = "America/New_York"; label = "New York"; }
        { timezone = "Asia/Shanghai"; label = "Shanghai"; }
      ];
    };

    weather = {
      type = "weather";
      units = "metric";
      hour-format = "24h";
      location = "San Jose, California, United States";
    };

    markets = {
      type = "markets";
      title = "Indices";
      markets = [
        { symbol = "SPY"; name = "S&P 500"; }
        { symbol = "BTC-USD"; name = "BTC"; }
        { symbol = "ETH-USD"; name = "ETH"; }
        { symbol = "DOGE-USD"; name = "DOGE"; }
        { symbol = "WRD"; name = "WeRide"; }
        { symbol = "PONY"; name = "Pony AI"; }
        { symbol = "NVDA"; name = "Nvidia"; }
        { symbol = "MSFT"; name = "Microsoft"; }
        { symbol = "SHOP"; name = "Shopify"; }
      ];
    };

    hostServies = {
      type = "monitor";
      cache = "1m";
      title = "Host Services";
      sites = [
        { title = "Jellyfin";    url = "https://yourdomain.com/"; icon = "si:jellyfin"; }
        { title = "Gitea";       url = "https://yourdomain.com/"; icon = "si:gitea"; }
        { title = "qBittorrent"; url = "https://yourdomain.com/"; icon = "si:qbittorrent"; }
        { title = "Immich";      url = "https://yourdomain.com/"; icon = "si:immich"; }
        { title = "AdGuard Home";url = "https://yourdomain.com/"; icon = "si:adguard"; }
        { title = "Vaultwarden"; url = "https://yourdomain.com/"; icon = "si:vaultwarden"; }
      ];
    };

in {
  name = "Home";
  center-vertically = true;
  columns = [
    { size = "small"; widgets = [ markets ]; }
    { size = "full"; widgets = [ hostServies ]; }
    { size = "small"; widgets = [ clock weather ]; }    
  ];
}
