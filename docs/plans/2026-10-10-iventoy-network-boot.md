# iVentoy network boot

## Goal

Put downloaded or locally built ISOs on Octavian, select an ISO through
network boot, and use its live environment or installer normally. No
installer downloads on demand or automatic disk installation.

## Progress

- [x] Package iVentoy for x86-64 NixOS.
  - [x] Pin and inspect the upstream Linux Free release and license.
  - [x] Keep bundled files unchanged and writable state outside the Nix store.
  - [x] Build the package.
  - [x] Verify management UI startup with real root privileges.
- [ ] Add Octavian's systemd service.
  - [x] Configuration prepared in `machines/octavian/services/iventoy.nix`.
  - [x] User deployed Octavian; management UI is reachable on the home LAN.
    Confirmed systemd reports active/running on 2026-10-10; only the UI
    is listening. ExternalNet setup and service restart checks remain pending.
  - Full Octavian system derivation evaluates successfully; checked the
    generated service settings and home-interface firewall port lists.
  - Reserved iVentoy's default ports in `data/service-registry.nix`; the
    service imports those reservations for its firewall rules.
  - Store state and ISOs under `/var/lib/iventoy`.
  - Use external DHCP and restrict access to the home LAN.
  - Verify start, stop, and restart behavior.
- [ ] Extend Pyrechomper's Kea configuration in `../nixos-routers`.
  - [x] Prepared `home-uefi-pxe` class for home90, PXEClient vendor class,
    and architecture 7 or 9. Points to `10.77.1.131` and
    `iventoy_loader_16000_uefi`; deployment is pending.
  - [x] Router system derivation evaluates. Kea 3.0.3 configuration check
    passes with interface bindings omitted only in the local test copy
    (the router's VLAN interfaces do not exist on this development host).
  - Direct home-LAN x86-64 UEFI network boots to Octavian (`10.77.1.131`).
  - Validate configuration before deployment.
- [ ] Test an official NixOS ISO on one physical machine.
  - Verify firmware network boot, menu selection, and entry into the live system.
  - Repeat with an ISO built from `machines/livecd`.
  - Do not install onto disk during boot tests.
- [ ] Check Ubuntu, Debian, and Windows ISOs as needed; document operation.
  - Explain ISO placement, menu refresh, updates, and troubleshooting.

## Packaging findings

- Upstream Linux x86-64 Free release: 1.0.44.
- The server is proprietary; the client includes an iPXE-based component.
- The Free edition permits personal, noncommercial use, with up to 20 clients.
- The server expects a conventional Linux loader and bundled libraries.
  Use `buildFHSEnv` rather than changing the upstream binaries.
- Upstream starts a daemon and writes `/var/run/iventoy.pid`; account for
  daemonization when defining the service in step 2.
- Custom NixOS ISO compatibility remains unverified until step 4.
- Package: `pkgs/iventoy/default.nix`; usage: `pkgs/iventoy/README.md`.
- Package build passed. The local user-namespace test could not mount sysfs.
  On 2026-10-10, copied the package closure to `octavian.local` and verified
  startup under real root using a transient systemd unit with `PrivateNetwork`
  and `PrivateMounts`. The UI returned HTTP success (24,139 bytes), status
  reported the running PID, and shutdown completed successfully.
- Test state is at `/var/lib/iventoy-package-test` on Octavian. The transient
  unit is stopped; no test daemon remains running. No LAN boot traffic was
  enabled. This verifies the management daemon, not ISO boot compatibility.
- Octavian's service and home-interface firewall configuration are deployed.
  Router configuration is unchanged.

## Next deployment checkpoint

The user requested assistance before deploying changes to any machine.
Octavian deployment and `systemctl status iventoy` checks passed.
The service starts only the management UI, at `http://10.77.1.131:26000`.
In the UI, select **ExternalNet** DHCP mode before starting PXE. This mode
leaves DHCP entirely to Kea, even with both servers on the home VLAN.
Keep the default serving ports. Add an ISO to `/var/lib/iventoy/iso` and
select Octavian's home address for boot serving.

User confirmed ExternalNet is saved. An official NixOS GNOME 26.05 x86-64
ISO (3.1 GiB) is present in `/var/lib/iventoy/iso`. Next: start PXE from
the UI using Octavian's home address, deploy the prepared router change,
then test one wired UEFI machine's boot menu.

The PXE service must be started manually in the UI after daemon restarts
at this stage. Add automatic PXE startup only after saved settings and
service lifecycle checks pass. Then prepare and deploy the router's boot
information for UEFI clients; no router change is needed to check the UI.

Sources: [release](https://github.com/ventoy/PXE/releases/tag/v1.0.44),
[usage](https://www.iventoy.com/en/doc_start.html),
[external DHCP](https://www.iventoy.com/en/doc_ext_dhcp.html).
License details are in the release's `doc/EULA_EN.txt` and `doc/LICENSE_EN.txt`.
