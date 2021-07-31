{ symlinkJoin, writeShellScriptBin }:

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

in symlinkJoin {
  name = "shuriken";
  version = "1.0.0";
  
  paths = [ git-clean ];
}
