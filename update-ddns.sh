#!/bin/sh

log="log.txt"
config="config.txt"
cache_dir="cache"
local_ip="ip.txt"
ddns_service="https://updates.dnsomatic.com/nic/update?hostname=all.dnsomatic.com&myip="

cd "$(dirname "$0")" || exit 1

printf "\nLog started $(date)\n" >> "$log"

if [ ! -f "$config" ]; then
    echo "Error: missing config file" | tee -a "$log"
    exit 1
fi

while IFS="= " read key value; do
    case "$key" in
        update_ddns_user)
            ddns_user="$value";;
        update_ddns_pass)
            ddns_pass="$value";;
        update_ddns_ip_src)
            ip_src="$value";;
        update_ddns_ca_dir)
            ca_dir="$value";;
    esac
done < "$config"

if [ -z "$ip_src" ]; then
    ip_src="http://myip.dnsomatic.com"
fi

if [ -z "$ca_dir" ]; then
    ca_dir="/etc/ssl/certs"
fi

if [ -z "$ddns_user" -o -z "$ddns_pass" ]; then
    echo "Error: missing username and/or password for DDNS service" | tee -a "$log"
    exit 1
fi

if [ ! -d "$cache_dir" ]; then
    mkdir "$cache_dir"
fi

echo "Downloading $ip_src..." | tee -a "$log"

if ! curl -sSo "$local_ip" "$ip_src"; then
    echo "Error: could not download $ip_src" | tee -a "$log"
    exit 1
fi

echo "Done" | tee -a "$log"

if [ ! -f "$cache_dir/$local_ip" ]; then
    echo "First run" | tee -a "$log"
    update=true
elif [ "$(cat "$local_ip")" != "$(cat "$cache_dir/$local_ip")" ]; then
    echo "IP address is out of date" | tee -a "$log"
    update=true
else
    echo "IP address is up to date" | tee -a "$log"
    update=false
fi

ddns_service="$ddns_service$(cat "$local_ip")"

mv "$local_ip" "$cache_dir"

if [ "$update" = true ]; then
    echo "Sending update to $ddns_service..." | tee -a "$log"

    if ! curl --capath "$ca_dir" -sSu "$ddns_user:$ddns_pass" "$ddns_service"; then
        echo "Error: could not send update to $ddns_service" | tee -a "$log"
        exit 1
    fi

    echo "Done" | tee -a "$log"
fi

