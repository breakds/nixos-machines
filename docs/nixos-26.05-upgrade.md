# NixOS 26.05 Upgrade Summary

This note summarizes the NixOS 26.05 upgrade preparation done for this repo and
the companion `../nixos-home` repo.

## Release Notes Reviewed

- NixOS 26.05 stable release notes:
  <https://nixos.org/manual/nixos/stable/release-notes#sec-release-26.05>
- Nixpkgs 26.05 stable release notes:
  <https://nixos.org/manual/nixpkgs/stable/release-notes#sec-release-26.05>
- Home Manager 26.05 release notes:
  <https://nix-community.github.io/home-manager/release-notes.xhtml#sec-release-26.05>

The NixOS notes drove the module-option migrations. The Nixpkgs notes were
needed for package-level changes such as `n8n`, NVIDIA, and removed package
namespaces. The Home Manager notes covered state-version warnings and module
compatibility.

## Input Updates

In `nixos-machines`:

- Changed `nixpkgs.url` from `github:NixOS/nixpkgs/nixos-25.11` to
  `github:NixOS/nixpkgs/nixos-26.05`.
- Changed `home-manager.url` from
  `github:nix-community/home-manager/release-25.11` to
  `github:nix-community/home-manager/release-26.05`.
- Updated `flake.lock` to nixpkgs rev `ec942ba042dad5ef097e2ef3a3effc034241f011`
  and Home Manager rev `b179bde238977f7d4454fc770b1a727eaf55111c`.

In `../nixos-home`:

- Made the same `nixpkgs` and `home-manager` URL changes.
- Updated its lock file to the same nixpkgs and Home Manager revisions.

This keeps the NixOS systems and Home Manager modules on the same stable release
line and avoids version mismatch warnings.

## NixOS Compatibility Fixes

### GDM Wayland Option Removal

`services.displayManager.gdm.wayland` was removed in GNOME 50. The local
`base/dev/breakds-dev.nix` logic only used it to decide whether to install
`emacs-pgtk`, so it now treats enabled GDM as Wayland.

### Ollama Acceleration Option Removal

`services.ollama.acceleration` no longer has effect in 26.05. The module now
selects the package directly:

- NVIDIA hosts use `pkgs.ollama-cuda`.
- Non-NVIDIA hosts use `pkgs.ollama`.

The custom overlay attribute `ollama-cuda` was also updated to reuse the
26.05/unstable package attribute rather than overriding `ollama` with the removed
`acceleration` argument.

### Immich Vector Options Removal

`services.immich.database.enableVectors` and
`services.immich.database.enableVectorChord` were removed. VectorChord is now the
only supported path and is enabled by the module, so the explicit toggles were
deleted.

### Grafana Secret Key Requirement

Grafana no longer provides a default `services.grafana.settings.security.secret_key`.
The config now explicitly sets the previous implicit default:

```nix
services.grafana.settings.security.secret_key = "SW2YcwTIb9zpOOhoPsMm";
```

This preserves existing encrypted data behavior for the upgrade. It should be
rotated later with a file-provider based secret and a Grafana secret migration
procedure.

### Wyoming Faster Whisper Initial Prompt

The configured Faster Whisper server is disabled, but 26.05 still asserts that
`initialPrompt` is only valid with the supported STT library path. The unused
`initialPrompt` setting was removed.

### Matter Server Extra Args Type Change

`services.matter-server.extraArgs` changed from a CLI argument list to an
attribute set passed through `lib.cli.toCommandLineGNU`. The Matter interface pin
was migrated from:

```nix
extraArgs = [ "--primary-interface=enp4s0f0" ];
```

to:

```nix
extraArgs.primary-interface = "enp4s0f0";
```

### PipeWire / PulseAudio Conflict

`armlet` had PulseAudio enabled while the 26.05 module stack also enabled
PipeWire, which now asserts. `armlet` was migrated to PipeWire with PulseAudio
compatibility:

- `services.pulseaudio.enable = false`
- `services.pipewire.enable = true`
- `services.pipewire.pulse.enable = true`
- `security.rtkit.enable = true`

### NetworkManager / Wireless Conflict

The Raspberry Pi kiosk config lets NetworkManager own WiFi. 26.05 produced a
conflict with `networking.wireless.enable`, so the kiosk config now uses:

```nix
networking.wireless.enable = lib.mkForce false;
```

### OpenSSH Settings Duplicate Key

Container config used `settings.passwordAuthentication`, while other config used
`PasswordAuthentication`. 26.05 asserts on duplicate OpenSSH keys with different
capitalization. The container config now uses `PasswordAuthentication`.

### Niri Portal Defaults

NixOS 26.05 ships its own Niri portal defaults, which conflicted with the local
Niri portal routing. The local config now uses `lib.mkForce [ "gtk" ]` for the
default portal while preserving GNOME portal routing for screencast, remote
desktop, and secrets.

### Xorg Package Namespace Deprecation

The Nixpkgs 26.05 notes deprecate the `xorg` package set. Local uses of
`xorg.xeyes` were changed to top-level `xeyes`.

## Home Manager Compatibility Fixes

In `../nixos-home`:

- `pkgs.gitAndTools.gitFull` was removed in 26.05, so Cassandra's Git package was
  changed to `pkgs.gitFull`.
- `xdg.userDirs.setSessionVariables` changed default behavior for
  `home.stateVersion = "26.05"`. Breakds keeps an older `home.stateVersion`, but
  `setSessionVariables = true` is now explicit to retain the legacy behavior and
  silence ambiguity once this local repo is consumed.
- `machines/breakds-vm.nix` now sets `nixpkgs.config.allowUnfree = true` so the
  VM stub can evaluate the Breakds Home Manager config containing VS Code.

## State Versions

No `system.stateVersion` or `home.stateVersion` values were bumped. They preserve
stateful defaults for existing installations and should only be changed after
reviewing the state-version-specific migrations separately.

## Verification

The final evaluation pass succeeded for every NixOS configuration in
`nixos-machines`:

- `amber`
- `armlet`
- `brock`
- `claw`
- `fortress`
- `kiosk`
- `liveCD`
- `liveStandardCD`
- `lorian`
- `malenia`
- `octavian`
- `olden`
- `radahn`

The local `../nixos-home` Home Manager activation derivations also evaluated for:

- `breakds-vm` / user `breakds`
- `cassandra-vm` / user `cassandra`

No full system builds or deployments were run.

## Remaining Warnings / Follow-ups

- `nixos-machines` consumes `nixos-home` through the GitHub flake input. After
  committing and pushing `../nixos-home`, update the `nixos-home` input lock here
  so the local Home Manager fixes are used by the machine configs.
- Several machine evals still warn that `xdg.userDirs.setSessionVariables`
  changed default in Home Manager 26.05. These warnings come from the currently
  locked GitHub `nixos-home` input and should disappear after consuming the local
  `../nixos-home` changes.
- `programs.ssh.matchBlocks` in `nixos-home` is deprecated in favor of
  `programs.ssh.settings`; this is not blocking 26.05 but should be migrated.
- Some overlays still trigger `system` renamed-to-`stdenv.hostPlatform.system`
  warnings.
- `octavian` warns about older pnpm fetcher hooks in `reading-desk-frontend`;
  this is scheduled for removal in 26.11 and should be migrated separately.
- ZFS configs warn about `boot.zfs.forceImportRoot` defaulting to `true`; 26.11
  will change the default to `false`, so set the desired behavior explicitly.
- `fortress` still has no explicit `system.stateVersion` and currently defaults
  to `26.05`; this should be reviewed because state versions should normally be
  pinned for installed systems.
