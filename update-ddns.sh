#!/bin/bash

log="log.txt"
config="config.txt"
cache_dir="cache"
local_ip="ip.txt"
ddns_service="https://updates.dnsomatic.com/nic/update?hostname=all.dnsomatic.com&myip="

cd "${BASH_SOURCE%/*}" || exit

echo -e "\nLog started $(date)" >> "$log"

if [ ! -f "$config" ]; then
    echo "Missing config file" | tee -a "$log"
    exit 3
fi

while IFS='= ' read key value; do
    case "$key" in
        update_ddns_user)
            ddns_user="$value" ;;
        update_ddns_pass)
            ddns_pass="$value" ;;
        update_ddns_ip_src)
            ip_src="$value" ;;
    esac
done < "$config"

if [ -z "$ip_src" ]; then
    ip_src="https://myip.dnsomatic.com"
fi

if [ -z "$ddns_user" -o -z "$ddns_pass" ]; then
    echo "Config file is missing username and/or password for DDNS service" | tee -a "$log"
    exit 4
fi

if [ ! -d "$cache_dir" ]; then
    mkdir "$cache_dir"
fi

echo "Downloading $ip_src..." | tee -a "$log"

if ! wget -qO "$local_ip" "$ip_src"; then
    echo "Error: $?" | tee -a "$log"
    exit 1
fi

echo "Done" | tee -a "$log"

if [ ! -f "$cache_dir/$local_ip" ]; then
    echo "First run" | tee -a "$log"
    update=true
elif ! diff -q "$local_ip" "$cache_dir/$local_ip" > /dev/null; then
    echo "IP address is out of date" | tee -a "$log"
    update=true
else
    echo "IP address is up to date" | tee -a "$log"
    update=false
fi

ddns_service+=$(cat "$local_ip")

mv "$local_ip" "$cache_dir"

if [ "$update" = true ]; then
    echo "Sending update to $ddns_service..." | tee -a "$log"

    if ! wget -qO - --user="$ddns_user" --password="$ddns_pass" "$ddns_service" > /dev/null 2>&1; then
        echo "Error: $?" | tee -a "$log"
        exit 2
    fi

    echo "Done" | tee -a "$log"
fi

