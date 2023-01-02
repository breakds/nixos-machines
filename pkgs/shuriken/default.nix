{ symlinkJoin
, writeShellScriptBin
, writers
, python3Packages
, scrot
, xclip
, rsync }:

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

    alf-wandb = writers.writePython3Bin "alf-wandb" {
      libraries = with python3Packages; [
        click
        wandb
        loguru
      ];
    } (builtins.readFile ./alf-wandb.py);

    power-win = writers.writePython3Bin "power-win" {
      libraries = [
        python3Packages.click
        python3Packages.numpy
        rsync
      ];
    } ''
      import csv
      import click
      import numpy as np


      @click.group()
      def app():
          pass


      @app.command()
      @click.argument("numbers", type=str)
      @click.argument("path", type=str)
      def scan(numbers, path):
          table = {
              False: [0, 0, 0, 7, 100, 1_000_000],
              True: [4, 4, 7, 100, 50_000, "WINNER!"]
          }

          ball_symbol = [" ", "①", "②", "③", "④", "⑤", "⑥", "⑦", "⑧", "⑨", "⑩",
                         "⑪", "⑫", "⑬", "⑭", "⑮", "⑯", "⑰", "⑱", "⑲", "⑳",
                         "㉑", "㉒", "㉓", "㉔", "㉕", "㉖", "㉗", "㉘", "㉙", "㉚",
                         "㉛", "㉜", "㉝", "㉞", "㉟", "㊱", "㊲", "㊳", "㊴", "㊵",
                         "㊶", "㊷", "㊸", "㊹", "㊺", "㊻", "㊼", "㊽", "㊾", "㊿"]

          numbers = numbers.split(" ")
          assert len(numbers) == 6
          numbers = [int(x) for x in numbers]
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
                      show.append(f"({guess[i]})" if white[i] == 1
                                  else str(guess[i]))
                  show.append(ball_symbol[guess[5]] if red else str(guess[5]))
                  print(f"{show[0]:<7}{show[1]:<7}{show[2]:<7}{show[3]:<7}"
                        f"{show[4]:<7}"
                        f" | {show[5]:<7} ---> {amount}")
                  if isinstance(amount, str):
                      win = True
                  else:
                      total += amount
          print("------------------------------------------------------------")
          print(f"Total: {total}")
          if win:
              print("AND ALSO YOU WIN.")


      @app.command()
      @click.argument("count", type=int)
      @click.option("-w", "--top-white", type=int, default=20)
      @click.option("-r", "--top-red", type=int, default=15)
      def gen(count, top_white, top_red):
          # The white balls that has the highest draw rate historically
          white_freq = np.array([0.0, 54.0, 57.0, 65.0, 46.0, 54.0, 63.0,
                                 54.0, 59.0, 49.0, 64.0, 54.0, 57.0,
                                 45.0, 59.0, 59.0, 61.0, 59.0, 59.0,
                                 57.0, 66.0, 73.0, 60.0, 70.0, 46.0,
                                 52.0, 44.0, 65.0, 65.0, 52.0, 55.0,
                                 51.0, 77.0, 62.0, 44.0, 47.0, 70.0,
                                 65.0, 53.0, 69.0, 61.0, 60.0, 57.0,
                                 50.0, 59.0, 58.0, 47.0, 57.0, 53.0,
                                 47.0, 55.0, 49.0, 59.0, 65.0, 55.0,
                                 55.0, 62.0, 58.0, 52.0, 68.0, 52.0,
                                 78.0, 69.0, 73.0, 63.0, 54.0, 52.0,
                                 57.0, 57.0, 72.0])
          assert abs(white_freq[69] - 72.0) < 1e-8
          assert abs(white_freq[39] - 69.0) < 1e-8
          assert abs(white_freq[16] - 61.0) < 1e-8

          red_freq = np.array([0.0, 28.0, 28.0, 32.0, 36.0, 31.0, 33.0,
                               26.0, 31.0, 31.0, 33.0, 31.0, 24.0,
                               34.0, 30.0, 25.0, 26.0, 29.0, 42.0,
                               32.0, 28.0, 34.0, 28.0, 22.0, 45.0,
                               31.0, 33.0])
          assert abs(red_freq[26] - 33.0) < 1e-8
          assert abs(red_freq[15] - 25.0) < 1e-8
          assert abs(red_freq[7] - 26.0) < 1e-8

          w = np.argsort(np.array(white_freq))[-top_white:]
          print(f"Consider white balls {w}")
          pw = white_freq[w]
          pw /= pw.sum()
          r = np.argsort(np.array(red_freq))[-top_red:]
          print(f"Consider red balls {r}")
          pr = red_freq[r]
          pr /= pr.sum()

          visited = []
          for i in range(count):
              while True:
                  white_balls = np.random.choice(w, size=5, replace=False, p=pw)
                  red_ball = np.random.choice(r, replace=False, p=pr)
                  ll = sorted(white_balls.tolist())
                  ll.append(red_ball)
                  if ll not in visited:
                      # print(f"{i:>10} {white_balls} {red_ball}")
                      print(",".join([str(x) for x in ll]))
                      visited.append(ll)
                      break


      if __name__ == "__main__":
          app()
    '';

in symlinkJoin {
  name = "shuriken";
  version = "1.0.0";

  paths = [
    git-clean
    scrot-org
    alf-wandb
    power-win
  ];
}
