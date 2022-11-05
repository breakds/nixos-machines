{ symlinkJoin, writeShellScriptBin, writers, scrot, xclip }:

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

    power-win = writers.writePython3Bin "power-win" {} ''
      import sys
      import csv

      table = {
          False: [0, 0, 0, 7, 100, 1_000_000],
          True: [4, 4, 7, 100, 50_000, "WINNER!"]
      }

      ball_symbol = [" ", "①", "②", "③", "④", "⑤", "⑥", "⑦", "⑧", "⑨", "⑩",
                     "⑪", "⑫", "⑬", "⑭", "⑮", "⑯", "⑰", "⑱", "⑲", "⑳",
                     "㉑", "㉒", "㉓", "㉔", "㉕", "㉖", "㉗", "㉘", "㉙", "㉚",
                     "㉛", "㉜", "㉝", "㉞", "㉟", "㊱", "㊲", "㊳", "㊴", "㊵",
                     "㊶", "㊷", "㊸", "㊹", "㊺", "㊻", "㊼", "㊽", "㊾", "㊿"]

      numbers = sys.argv[1].split(" ")
      assert len(numbers) == 6
      numbers = [int(x) for x in numbers]
      path = sys.argv[2]
      total = 0
      win = False
      with open(path, "r") as f:
          reader = csv.reader(f, delimiter=',')
          for row in reader:
              guess = [int(x) for x in row]
              assert len(guess) == 6
              white = []
              for i in range(5):
                  white.append(1 if guess[i] in numbers[:5] else 0)
              red = guess[5] == numbers[5]
              white_sum = sum(white)
              amount = table[red][white_sum]
              if amount == 0:
                  continue
              show = []
              for i in range(5):
                  show.append(f"({guess[i]})" if white[i] == 1 else str(guess[i]))
              show.append(ball_symbol[guess[5]] if red else str(guess[5]))
              print(f"{show[0]:<7}{show[1]:<7}{show[2]:<7}{show[3]:<7}{show[4]:<7}"
                    f" | {show[5]:<7} ---> {amount}")
              if isinstance(amount, str):
                  win = True
              else:
                  total += amount
      print("------------------------------------------------------------")
      print(f"Total: {total}")
      if win:
          print("AND ALSO YOU WIN.")
    '';

in symlinkJoin {
  name = "shuriken";
  version = "1.0.0";

  paths = [ git-clean scrot-org power-win ];
}
