{ poetry2nix, bottle, click, loguru, pyperclip }:

poetry2nix.mkPoetryApplication {
  projectDir = ./.;
  overrides = poetry2nix.overrides.withDefaults (self: super: {
    bottle = bottle;
    click = click;
    loguru = loguru;
  });
}
