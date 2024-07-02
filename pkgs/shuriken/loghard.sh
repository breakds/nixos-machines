# Log hardware related metrics intesively for debugging purpose
# You will need to run it as sudo

while true; do
    d=$(date +"%Y-%m-%d %H:%M:%S")
    echo "═════════ ${d} ═════════"

    # Memory
    free -h | sed -n "2p"

    # Temperatures
    sensors

    # Harddrive temp
    smartctl --all $1 | ag -i "tempera"

    sleep 1
done
