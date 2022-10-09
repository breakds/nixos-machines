{ pkgs }:

pkgs.poetry2nix.mkPoetryApplication {
  projectDir = ./.;
  overrides = pkgs.poetry2nix.overrides.withDefaults (self: super: {
    bottle = pkgs.python3Packages.bottle;
    click = pkgs.python3Packages.click;
    loguru = pkgs.python3Packages.loguru;
    pyperclip = pkgs.python3Packages.pyperclip;
  });
}
