#!/bin/bash

CACHE_DIR="cache"
LOCAL_IP="ip.txt"
REMOTE_IP="http://myip.dnsomatic.com/"
USER="user"
PASSWORD="password"
DNS_SERVICE="https://updates.dnsomatic.com/nic/update?hostname=all.dnsomatic.com&myip="

if [ ! -d "$CACHE_DIR" ]; then
    mkdir "$CACHE_DIR"
fi

if ! wget -qO "$LOCAL_IP" "$REMOTE_IP"; then
    echo "Couldn't download $REMOTE_IP"
    exit 1
fi

if [ -f "$CACHE_DIR/$LOCAL_IP" ]; then
    if diff -q "$LOCAL_IP" "$CACHE_DIR/$LOCAL_IP" > /dev/null; then
        echo "IP address has not changed since last run"
        mv "$LOCAL_IP" "$CACHE_DIR"
        exit 0
    else
        echo "IP address has changed - sending update to DNS service..."
    fi
else
    echo "First run - sending IP address to DNS service..."
fi

DNS_SERVICE+=$(cat "$LOCAL_IP")

if ! wget -qO - --user="$USER" --password="$PASSWORD" "$DNS_SERVICE"; then
    echo "Couldn't post to $DNS_SERVICE"
    exit 2
fi

echo ""

mv "$LOCAL_IP" "$CACHE_DIR"

