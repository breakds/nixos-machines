# iVentoy

Pinned upstream Linux x86-64 Free binaries, run unchanged inside Nix's FHS
environment. No Docker daemon is required. The release includes its license
under `doc` in the initialized work directory.

Build from the repository root:

```sh
NIXPKGS_ALLOW_UNFREE=1 nix build --impure path:.#iventoy
```

Run on a test host as root:

```sh
sudo ./result/bin/iventoy /var/lib/iventoy start
sudo ./result/bin/iventoy /var/lib/iventoy status
sudo ./result/bin/iventoy /var/lib/iventoy stop
```

The first invocation initializes a writable copy of the upstream layout.
Put ISOs in `/var/lib/iventoy/iso`. The management UI uses port 26000.
Configure external DHCP in the UI before starting the PXE service. `start`
launches the management daemon; `-R start` also auto-starts PXE using saved
configuration. Firewall and systemd configuration belong to the next step.

The work directory records its release version. Upgrades currently require
a fresh work directory; move the ISOs and review saved configuration before
switching. Do not mix files from different upstream releases.

Validation: package build and launcher argument checks pass. Management UI
startup, HTTP response, status, and shutdown passed on Octavian as root in a
transient systemd unit with isolated networking and mounts. The upstream
daemon mounts sysfs and reads the DMI machine UUID, which requires real root
privileges. Physical PXE boot and ISO compatibility remain untested.
