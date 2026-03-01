#!/usr/bin/env bash
#
# Collect network diagnostic information for a given time period.
#
# Usage:
#   collect-network-info.sh --since "2026-03-01 08:00" [--until "2026-03-01 10:00"] [--boot BOOT_ID]
#
# If --until is omitted, collects up to now.
# If --boot is omitted, searches across all boots.

set -euo pipefail

SINCE=""
UNTIL=""
BOOT_ARGS=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --since) SINCE="$2"; shift 2 ;;
        --until) UNTIL="$2"; shift 2 ;;
        --boot)  BOOT_ARGS="-b $2"; shift 2 ;;
        -h|--help)
            echo "Usage: $0 --since TIME [--until TIME] [--boot BOOT_ID]"
            echo ""
            echo "Examples:"
            echo "  $0 --since '2026-03-01 08:00' --until '2026-03-01 10:00'"
            echo "  $0 --since '2026-03-01 08:00' --boot -1"
            echo "  $0 --since '1 hour ago'"
            exit 0
            ;;
        *) echo "Unknown argument: $1"; exit 1 ;;
    esac
done

if [[ -z "$SINCE" ]]; then
    echo "ERROR: --since is required"
    exit 1
fi

TIME_ARGS="--since '$SINCE'"
if [[ -n "$UNTIL" ]]; then
    TIME_ARGS="$TIME_ARGS --until '$UNTIL'"
fi

JOURNAL_CMD="journalctl --no-pager $BOOT_ARGS"

separator() {
    echo ""
    echo "========================================================================"
    echo "=== $1"
    echo "========================================================================"
    echo ""
}

# ---- Section 1: Boot history ----
separator "BOOT HISTORY (recent)"
journalctl --list-boots | tail -10

# ---- Section 2: Current NIC state ----
separator "CURRENT NETWORK INTERFACE STATE"
ip -s link show
echo ""
echo "--- ip addr ---"
ip addr show

# ---- Section 3: NIC link events (ixgbe / driver level) ----
separator "NIC LINK EVENTS (kernel driver messages)"
eval "$JOURNAL_CMD -k $TIME_ARGS" 2>/dev/null \
    | grep -iE "link.is.(up|down)|ixgbe|igb[^e]|e1000|r8169|realtek|mlx|net_ratelimit|carrier" \
    || echo "(no NIC link events found)"

# ---- Section 4: NetworkManager events ----
separator "NETWORKMANAGER EVENTS"
eval "$JOURNAL_CMD -u NetworkManager $TIME_ARGS" 2>/dev/null \
    | tail -100 \
    || echo "(no NetworkManager events found)"

# ---- Section 5: Avahi / mDNS events ----
separator "AVAHI / mDNS EVENTS"
eval "$JOURNAL_CMD -u avahi-daemon $TIME_ARGS" 2>/dev/null \
    | tail -100 \
    || echo "(no avahi events found)"

# ---- Section 6: DHCP events ----
separator "DHCP EVENTS"
eval "$JOURNAL_CMD $TIME_ARGS" 2>/dev/null \
    | grep -iE "dhcp|dhclient|dhcpcd|lease|DHCPACK|DHCPOFFER|DHCPREQUEST|DHCPNAK" \
    || echo "(no DHCP events found)"

# ---- Section 7: SSH daemon events ----
separator "SSHD EVENTS"
eval "$JOURNAL_CMD -u sshd $TIME_ARGS" 2>/dev/null \
    | tail -50 \
    || echo "(no sshd events found)"

# ---- Section 8: Firewall events ----
separator "FIREWALL EVENTS"
eval "$JOURNAL_CMD -u firewall $TIME_ARGS" 2>/dev/null \
    | tail -50 \
    || echo "(no firewall events found)"

# ---- Section 9: Kernel errors and warnings ----
separator "KERNEL ERRORS AND WARNINGS"
eval "$JOURNAL_CMD -k -p warning $TIME_ARGS" 2>/dev/null \
    | tail -80 \
    || echo "(no kernel warnings found)"

# ---- Section 10: System-wide errors ----
separator "SYSTEM-WIDE ERRORS (priority err and above)"
eval "$JOURNAL_CMD -p err $TIME_ARGS" 2>/dev/null \
    | tail -80 \
    || echo "(no system errors found)"

# ---- Section 11: Link flap summary ----
separator "LINK FLAP SUMMARY"
echo "Link-down event counts by interface:"
eval "$JOURNAL_CMD -k $TIME_ARGS" 2>/dev/null \
    | grep -i "link.is.down" \
    | grep -oP '\S+: NIC Link is Down' \
    | sort | uniq -c | sort -rn \
    || echo "(no link-down events found)"
echo ""
echo "Link-down event counts by hour:"
eval "$JOURNAL_CMD -k $TIME_ARGS" 2>/dev/null \
    | grep -i "link.is.down" \
    | awk '{print $1, $2, substr($3,1,2)":00"}' \
    | sort | uniq -c | sort -rn | head -20 \
    || echo "(no link-down events found)"
