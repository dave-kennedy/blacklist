#!/bin/bash

LOG="log.txt"
CACHE_DIR="cache"
LOCAL_IP="ip.txt"
REMOTE_IP="http://myip.dnsomatic.com/"
USER="user"
PASSWORD="password"
DNS_SERVICE="https://updates.dnsomatic.com/nic/update?hostname=all.dnsomatic.com&myip="

cd "${BASH_SOURCE%/*}" || exit

echo "Log started $(date)" >> "$LOG"

if [ ! -d "$CACHE_DIR" ]; then
    mkdir "$CACHE_DIR"
fi

echo "Downloading $REMOTE_IP..." | tee -a "$LOG"

if ! wget -qO "$LOCAL_IP" "$REMOTE_IP"; then
    echo "Error: $?" | tee -a "$LOG"
    exit 1
fi

echo "Done" | tee -a "$LOG"

if [ -f "$CACHE_DIR/$LOCAL_IP" ]; then
    if diff -q "$LOCAL_IP" "$CACHE_DIR/$LOCAL_IP" > /dev/null; then
        echo "IP address is up to date" | tee -a "$LOG"
        update=false
    else
        echo "IP address is out of date" | tee -a "$LOG"
        update=true
    fi
else
    echo "First run" | tee -a "$LOG"
    update=true
fi

DNS_SERVICE+=$(cat "$LOCAL_IP")

mv "$LOCAL_IP" "$CACHE_DIR"

if [ "$update" = true ]; then
    echo "Sending update to $DNS_SERVICE..." | tee -a "$LOG"

    if ! wget -qO --user="$USER" --password="$PASSWORD" "$DNS_SERVICE" > /dev/null 2>&1; then
        echo "Error: $?" | tee -a "$LOG"
        exit 2
    fi

    echo "Done" | tee -a "$LOG"
fi

echo "" >> "$LOG"

