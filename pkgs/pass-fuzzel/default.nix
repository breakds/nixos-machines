{ writeShellApplication
, pass
, fuzzel
, ydotool
, wl-clipboard
, findutils
, gnused
, coreutils
, gnugrep
}:

writeShellApplication {
  name = "pass-fuzzel";
  runtimeInputs = [
    (pass.withExtensions (exts: [ exts.pass-otp ]))
    fuzzel
    ydotool
    wl-clipboard
    findutils
    gnused
    coreutils
    gnugrep
  ];
  text = builtins.readFile ./pass-fuzzel.sh;
}
