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
    # Note, the local machine's root should be able to ssh to the remote host
    # with this user name WITHOUT password.
    sshUser = "breakds";
    sshKey = "breakds_samaritan";
  };
}
