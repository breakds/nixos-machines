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
    maxJobs = 24;
    speedFactor = 10;
  };

  "radahn" = {
    hostName = "radahn";
    location = "lab";
    maxJobs = 32;
    speedFactor = 12;
  };

  "kami" = {
    hostName = "192.168.110.134";
    location = "office";
    maxJobs = 24;
    speedFactor = 6;
    # Note, the local machine's root should be able to ssh to the remote host
    # with this user name WITHOUT password.
    sshUser = "breakds";
    sshKey = "breakds_samaritan";
  };
}
