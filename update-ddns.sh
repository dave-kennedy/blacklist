#!/bin/sh

config="config.txt"
cache_dir="cache"
local_ip="ip.txt"
ddns_service="https://updates.dnsomatic.com/nic/update?hostname=all.dnsomatic.com&myip="

cd "$(dirname "$0")" || exit 1

if [ ! -f "$config" ]; then
    logger -s "Error: missing config file"
    exit 1
fi

while IFS="= " read key value; do
    case "$key" in
        ddns_user)
            ddns_user="$value";;
        ddns_pass)
            ddns_pass="$value";;
        ddns_ip_src)
            ip_src="$value";;
        ddns_ca_dir)
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
    logger -s "Error: missing username and/or password for DDNS service"
    exit 1
fi

if [ ! -d "$cache_dir" ]; then
    mkdir "$cache_dir"
fi

logger -s "Downloading $ip_src..."

if ! curl -sSo "$local_ip" "$ip_src"; then
    logger -s "Error: could not download $ip_src"
    exit 1
fi

logger -s "Done"

if [ ! -f "$cache_dir/$local_ip" ]; then
    logger -s "First run"
    update=true
elif [ "$(cat "$local_ip")" != "$(cat "$cache_dir/$local_ip")" ]; then
    logger -s "IP address is out of date"
    update=true
else
    logger -s "IP address is up to date"
    update=false
fi

ddns_service="$ddns_service$(cat "$local_ip")"

mv "$local_ip" "$cache_dir"

if [ "$update" = true ]; then
    logger -s "Sending update to $ddns_service..."

    if ! curl --capath "$ca_dir" -sSu "$ddns_user:$ddns_pass" "$ddns_service"; then
        logger -s "Error: could not send update to $ddns_service"
        exit 1
    fi

    logger -s "Done"
fi

