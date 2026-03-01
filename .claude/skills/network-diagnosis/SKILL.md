---
name: Network Diagnosis
description: This skill should be used when the user asks to "diagnose network issues", "investigate network problems", "check why the server is unreachable", "analyze network flapping", or "debug connectivity loss".
---

# Overview

Diagnose network connectivity issues on NixOS machines managed by this repository. This is primarily for the server `radahn`, which uses an Intel 10GbE NIC (`ixgbe` driver) on interface `enp36s0f1`.

## Known Hardware

- **radahn**: Intel 10GbE dual-port NIC (ixgbe driver)
  - `enp36s0f0` (PCI `0000:24:00.0`) — port 0, currently unused (state DOWN)
  - `enp36s0f1` (PCI `0000:24:00.1`) — port 1, primary network interface
  - `wlp38s0` — wireless, currently unused (state DOWN)
- Network: DHCP, Avahi/mDNS enabled (`radahn.local`)

## Known Failure Patterns

### 1. ixgbe NIC Link Flapping

The `enp36s0f1` interface has a history of link flapping (rapid up/down cycles). This manifests as:
- Kernel messages: `ixgbe 0000:24:00.1 enp36s0f1: NIC Link is Down` / `NIC Link is Up`
- Avahi repeatedly withdrawing and re-registering address records
- SSH connections dropping

Common causes: bad cable, failing SFP+ transceiver, switch port issue, or NIC firmware/driver bug.

### 2. Abrupt Connectivity Loss (No Clean Shutdown in Logs)

When the journal ends abruptly without a shutdown sequence, it typically means:
- The OS was still running but unreachable (network failure, not a crash)
- The user had to physically reboot

To distinguish network failure from OS crash, check for:
- Presence of kernel panics, MCE (Machine Check Exception), or OOM events
- Whether the journal ends with a clean `systemd-shutdown` sequence or not

## Workflow

### Step 1: Determine the Time Period

Ask the user when the issue occurred. Use `journalctl --list-boots` to identify the relevant boot if the machine was rebooted.

### Step 2: Run the Diagnostic Script

Run the collection script from the skill's directory:

```bash
bash .claude/skills/network-diagnosis/scripts/collect-network-info.sh \
    --since "YYYY-MM-DD HH:MM" \
    [--until "YYYY-MM-DD HH:MM"] \
    [--boot BOOT_ID]
```

Arguments:
- `--since` (required): start of the time window
- `--until` (optional): end of the time window; defaults to now
- `--boot` (optional): restrict to a specific boot (e.g., `-1` for previous boot, `0` for current)

The script collects:
- Recent boot history
- Current NIC state (`ip link`, `ip addr`)
- NIC link events from kernel (ixgbe, igb, e1000, etc.)
- NetworkManager events
- Avahi/mDNS events
- DHCP events
- SSH daemon events
- Firewall events
- Kernel warnings and errors
- System-wide errors
- Link flap summary (counts by interface and by hour)

### Step 3: Analyze the Output

Focus on these areas in order:

1. **Link flap summary** — If link-down counts are high, this is likely a physical-layer issue (cable, SFP+, switch port).
2. **NIC link events** — Check the pattern: is it periodic flapping, or a single sustained outage?
3. **Kernel errors** — Look for MCE, hardware errors, or driver crashes that would indicate a deeper issue.
4. **Avahi events** — Frequent address withdrawal/re-registration correlates with link instability.
5. **DHCP events** — Failed DHCP renewals can cause IP loss even if the link stays up.
6. **NetworkManager events** — Check for interface state changes or connection profile issues.

### Step 4: Provide Recommendations

Based on findings, suggest concrete actions:

- **Link flapping**: Check/replace cable, reseat/replace SFP+ module, try a different switch port
- **DHCP failure**: Check DHCP server, consider static IP assignment
- **Driver crash**: Check for kernel/driver updates, consider driver parameters
- **No obvious cause**: Suggest monitoring with `journalctl -f -k | grep ixgbe` and setting up alerting
