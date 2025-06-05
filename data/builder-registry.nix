rec {
  "malenia" = {
    hostName = "10.77.1.185";
    location = "homelab";
    maxJobs = 24;
    speedFactor = 12;
  };

  "octavian" = {
    hostName = "10.77.1.131";
    location = "homelab";    
    maxJobs = 24;
    speedFactor = 10;
  };

  "radahn" = {
    hostName = "10.77.1.35";
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
