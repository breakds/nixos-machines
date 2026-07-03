rec {
  "malenia" = {
    hostName = "10.77.1.185";
    location = "homelab";
    maxJobs = 24;
    speedFactor = 12;
    publicHostKey = "c3NoLWVkMjU1MTkgQUFBQUMzTnphQzFsWkRJMU5URTVBQUFBSUdDNW1FU2xMVDFHSHR1RWtRaWhLeGs1SmdnQ2o4NnhNQ21qVlIya2hISGsgcm9vdEBtYWxlbmlhCg==";
  };

  "octavian" = {
    hostName = "10.77.1.131";
    location = "homelab";
    maxJobs = 8;
    speedFactor = 10;
    publicHostKey = "c3NoLWVkMjU1MTkgQUFBQUMzTnphQzFsWkRJMU5URTVBQUFBSU1uRlJrcUV0bGRna2VWdEVhYkVuMEFEbzNiOGlTeldKVjBNcWpUNkdCQWEgcm9vdEBuaXhvcwo=";
  };

  "radahn" = {
    hostName = "10.77.1.35";
    location = "homelab";
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
