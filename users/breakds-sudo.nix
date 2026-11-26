{
  security.sudo.extraRules = [{
    users = [ "breakds" ];
    commands = [{ command = "ALL"; options = [ "NOPASSWD" ]; }];
  }];
}
