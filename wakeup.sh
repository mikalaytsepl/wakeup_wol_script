#!/bin/bash

TARGET="$1"
IP_ADD="$2" 
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

find_target() {
    local NAME="$1"

    while read -r host mac ip; do
        if [[ "$NAME" == "$host" ]]; then
            echo "$mac $ip"
            return 0
        fi
    done < "$SCRIPT_DIR/known_hosts"

    return 1
}

#if not mac address, use lookup function to search in known hosts
if ! [[ "$TARGET" =~ ^([0-9a-zA-Z]{2}:){5}[0-9a-zA-Z]{2}$ ]]; then
    if ! result=$(find_target "$TARGET"); then
        echo "Host not found" >&2
        exit 1
    else
        read -r TARGET IP_ADD <<< "$result"
    fi
fi

wakeonlan "$TARGET"

if [[ -n $IP_ADD && $IP_ADD =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then

    TIMEOUT=120 # waiting timeout for the server to get up
    INTERVAL=5 # periodically check if ssh is open

    start_time=$(date +%s)

    notify-send "Valid IP provided, notification will be send when the server is up"
    echo "$IP_ADD"

    while true; do
        # check if the ssh port is open already 
        if nc -z -w 1 "$IP_ADD" 22; then
            notify-send "Server Ready" "SSH is available"
            break
        fi

        # check timeout 
        elapsed=$(( $(date +%s) - start_time ))
        if (( elapsed >= TIMEOUT )); then
            notify-send "Server $IP_ADD is still down after $TIMEOUT seconds"
            exit 1
        fi

        # wait between retries
        sleep "$INTERVAL"
    done
else
    notify-send "No valid IP provided, can't verify if the host is up" 
fi
