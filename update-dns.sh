#!/bin/bash

log="log.txt"
cache_dir="cache"
local_ip="ip.txt"
remote_ip="http://myip.dnsomatic.com"
user="user"
password="password"
dns_service="https://updates.dnsomatic.com/nic/update?hostname=all.dnsomatic.com&myip="

cd "${BASH_SOURCE%/*}" || exit

echo -e "\nLog started $(date)" >> "$log"

if [ ! -d "$cache_dir" ]; then
    mkdir "$cache_dir"
fi

echo "Downloading $remote_ip..." | tee -a "$log"

if ! wget -qO "$local_ip" "$remote_ip"; then
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

dns_service+=$(cat "$local_ip")

mv "$local_ip" "$cache_dir"

if [ "$update" = true ]; then
    echo "Sending update to $dns_service..." | tee -a "$log"

    if ! wget -qO - --user="$user" --password="$password" "$dns_service" > /dev/null 2>&1; then
        echo "Error: $?" | tee -a "$log"
        exit 2
    fi

    echo "Done" | tee -a "$log"
fi

