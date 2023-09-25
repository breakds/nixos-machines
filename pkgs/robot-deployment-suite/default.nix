{ symlinkJoin, writeShellScriptBin } :

let robnet = writeShellScriptBin "robnet" (builtins.readFile ./robnet.sh);

in symlinkJoin {
  name = "robot-deployment-suite";
  paths = [ robnet ];
}
