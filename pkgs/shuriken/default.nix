{ symlinkJoin, writeShellScriptBin, scrot, xclip }:

let git-clean = writeShellScriptBin "git-clean" ''
  # Step 1, Clean up local origin/* that does not exist on remote.
  git fetch -p

  # Step 2, find all the local branches whose origin/* counterpart is "gone".
  filename="/tmp/git-clean-$(date +%s)"
  git branch -vv | grep ': gone]' | awk '{print $1}' > ''${filename}
  num_branches=$(wc -l ''${filename} | awk '{print $1}')
  if [ ''${num_branches} == '0' ]; then
    echo "No stale local branches."
    exit 0
  fi
  ''${EDITOR} ''${filename} && xargs git branch -D < ''${filename}
'';

    scrot-org = writeShellScriptBin "scrot-org" ''
      date_prefix="$(date +%Y%m%d)"
      rel_path="images/gail/''${date_prefix}_$1.jpg"
      ${scrot}/bin/scrot -s $HOME/org/work/''${rel_path}
      echo "./''${rel_path}" | ${xclip}/bin/xclip -selection clipboard
    '';

in symlinkJoin {
  name = "shuriken";
  version = "1.0.0";
  
  paths = [ git-clean scrot-org ];
}
