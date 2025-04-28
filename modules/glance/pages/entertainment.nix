let entries = {
      youtube = {
        title = "YouTube";
        url = "https://www.youtube.com";
        icon = "si:youtube";
      };

      netflix = {
        title = "Netflix";
        url = "https://netflix.com";
        icon = "si:netflix";
      };

      primevideo = {
        title = "Prime Video";
        url = "https://www.amazon.com/gp/video/storefront/";
        icon = "si:primevideo";
      };

      iyf = {
        title = "爱壹帆";
        url = "https://iyf.tv";
        icon = "si:googleplay";
      };

      bilibili = {
        title = "B站";
        url = "https://bilibili.com";
        icon = "si:bilibili";
      };

      plex = {
        title = "Plex";
        url = "https://plex.breakds.org";
        icon = "si:plex";
      };
    };

    streaming = {
      type = "bookmarks";
      css-class = "streaming-links";
      groups = [{
        title = "Streaming";
        hide-arrow = true;
        color = "10 70 50";
        links = with entries; [
          youtube netflix primevideo
          iyf bilibili plex
        ];
      }];
    };

    hackernews = {
      type = "hacker-news";
      limit = 25;
      collapse-after = 10;
    };

    search = {
      type = "search";
      autofocus = true;
      search-engine = "https://www.google.com/search?q={QUERY}";
    };
  
in {
  name = "Entertainment";
  width = "slim";
  
  center-vertically = true;
  columns = [
    { size = "full"; widgets = [
        search
        streaming
        hackernews
      ];
    }
  ];
}
