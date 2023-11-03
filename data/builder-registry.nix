rec {
  "malenia" = {
    hostName = "malenia.local";
    location = "homelab";
    maxJobs = 24;
    speedFactor = 12;
  };

  "octavian" = {
    hostName = "octavian.local";
    location = "homelab";    
    maxJobs = 12;
    speedFactor = 6;
  };

  "GAIL3" = {
    hostName = "gail3";
    location = "lab";
    maxJobs = 14;
    speedFactor = 8;
  };

  "radahn" = {
    hostName = "radahn";
    location = "lab";
    maxJobs = 32;
    speedFactor = 12;
  };

  "kami" = {
    hostName = "kami";
    location = "office";
    maxJobs = 24;
    speedFactor = 6;
    sshUser = "breakds";
    sshKey = "breakds_samaritan";
  };
}
