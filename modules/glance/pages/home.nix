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
        { title = "FileRun"; url = "https://files.breakds.org/";
          icon = "/assets/filerun.png"; }
        { title = "Blog"; url = "https://www.breakds.org/";
          icon = "/assets/tech_blog.png"; }
        { title = "Ollama"; url = "https://llm.breakds.org/";
          icon = "si:ollama"; }
        { title = "Docker"; url = "https://docker.breakds.org/";
          icon = "si:docker"; }
        { title = "Hydra"; url = "https://hydra.breakds.org/";
          icon = "/assets/nixos.svg"; }
        { title = "Plex"; url = "https://plex.breakds.org/";
          icon = "/assets/plex.svg"; }
        { title = "Grafana"; url = "https://grafana.breakds.org/";
          icon = "/assets/grafana.svg"; }
        { title = "Paperless"; url = "https://paperless.breakds.org/";
          icon = "/assets/paperless.svg"; }
        { title = "Temporal"; url = "https://temporal.breakds.net/";
          icon = "/assets/temporal.png"; }
        { title = "Kiseki"; url = "https://kiseki.breakds.org/";
          icon = "/assets/kiseki.png"; }
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
