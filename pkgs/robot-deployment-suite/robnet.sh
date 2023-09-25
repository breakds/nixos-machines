#!/usr/bin/env bash

OFFICE_PROFILE_NAME="office"
GO1_PROFILE_NAME="go1"

OFFICE_PROFILE_UUID=$(nmcli connection show | grep -w $OFFICE_PROFILE_NAME | awk '{print $2}')
GO1_PROFILE_UUID=$(nmcli connection show | grep -w $GO1_PROFILE_NAME | awk '{print $2}')

DEVICE=$(nmcli device status | grep ethernet | awk '{print $1}' | head -n 1)

echo "Found ethernet device '${DEVICE}'"

# Setup the "office" profile if it does not exist
if [[ -z $OFFICE_PROFILE_UUID ]]; then
    echo "Creating the network profile for 'office' ..."
    nmcli connection add type ethernet ifname $DEVICE con-name $OFFICE_PROFILE_NAME ipv4.method auto
fi

# Setup the "go1" profile if it does not exist
if [[ -z $GO1_PROFILE_UUID ]]; then
    echo "Creating the network profile for 'go1' ..."
    # Create a static IP profile for the go1 network
    nmcli connection add type ethernet ifname $DEVICE con-name $GO1_PROFILE_NAME ipv4.method manual ipv4.addresses 192.168.123.170/24 ipv4.gateway ""
fi

if [[ $# -ne 1 ]]; then
    echo "Usage: $0 [office|go1]"
    exit 1
fi

if [[ $1 == "office" ]]; then
    echo "Switching to network profile 'office'"
    nmcli connection down $GO1_PROFILE_NAME    
    nmcli connection up $OFFICE_PROFILE_NAME
elif [[ $1 == "go1" ]]; then
    echo "Switching to network profile 'go1' ..."
    nmcli connection down $OFFICE_PROFILE_NAME    
    nmcli connection up $GO1_PROFILE_NAME
else
    echo "Invalid argument. Usage: $0 [office|go1]"
    exit 1
fi
