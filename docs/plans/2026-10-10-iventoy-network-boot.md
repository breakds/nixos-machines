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
  - Configuration prepared in `machines/octavian/services/iventoy.nix`.
    Deployment and service lifecycle checks remain pending.
  - Full Octavian system derivation evaluates successfully; checked the
    generated service settings and home-interface firewall port lists.
  - Store state and ISOs under `/var/lib/iventoy`.
  - Use external DHCP and restrict access to the home LAN.
  - Verify start, stop, and restart behavior.
- [ ] Extend Pyrechomper's Kea configuration in `../nixos-routers`.
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
- Octavian's service and home-interface firewall configuration are prepared
  in the repository but have not been deployed. Router configuration is unchanged.

## Next deployment checkpoint

The user requested assistance before deploying changes to any machine.
Deploy Octavian's configuration first, then verify `systemctl status iventoy`.
The service starts only the management UI, at `http://10.77.1.131:26000`.
In the UI, select **ExternalNet** DHCP mode before starting PXE. This mode
leaves DHCP entirely to Kea, even with both servers on the home VLAN.
Keep the default serving ports. Add an ISO to `/var/lib/iventoy/iso` and
select Octavian's home address for boot serving.

The PXE service must be started manually in the UI after daemon restarts
at this stage. Add automatic PXE startup only after saved settings and
service lifecycle checks pass. Then prepare and deploy the router's boot
information for UEFI clients; no router change is needed to check the UI.

Sources: [release](https://github.com/ventoy/PXE/releases/tag/v1.0.44),
[usage](https://www.iventoy.com/en/doc_start.html),
[external DHCP](https://www.iventoy.com/en/doc_ext_dhcp.html).
License details are in the release's `doc/EULA_EN.txt` and `doc/LICENSE_EN.txt`.
