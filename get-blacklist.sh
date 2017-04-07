#!/bin/sh

config="config.txt"
cache_dir="cache"
local_hosts="hosts.txt"
remote_hosts="http://winhelp2002.mvps.org/hosts.txt"
blacklist="blacklist.hosts"

cd "$(dirname "$0")" || exit 1

logger -s "Log started $(date)"

add_hosts=""
remove_hosts=""

if [ -f "$config" ]; then
    while IFS="= " read key value; do
        case "$key" in
            blacklist_add_host)
                add_hosts="$add_hosts $value";;
            blacklist_remove_host)
                remove_hosts="$remove_hosts $value";;
            blacklist_upload_dest)
                upload_dest="$value";;
        esac
    done < "$config"
fi

if [ ! -d "$cache_dir" ]; then
    mkdir "$cache_dir"
fi

logger -s "Downloading $remote_hosts..."

if ! curl -sSo "$cache_dir/$local_hosts" -z "$cache_dir/$local_hosts" "$remote_hosts"; then
    logger -s "Error: could not download $remote_hosts"
    exit 1
fi

logger -s "Done"

logger -s "Building $blacklist..."

sed "s/\r//" "$cache_dir/$local_hosts" > "$blacklist"

for add_host in $add_hosts; do
    echo "0.0.0.0 $add_host" >> "$blacklist"
done

for remove_host in $remove_hosts; do
    sed -i "s/^0.0.0.0 $remove_host/#0.0.0.0 $remove_host/" "$blacklist"
done

logger -s "Done"

if [ -n "$upload_dest" ]; then
    if ! echo "$upload_dest" | grep -Eq ".+@.+:.+"; then
        logger -s "Error: upload destination is not valid"
        exit 1
    fi

    logger -s "Uploading to $upload_dest..."

    cat "$blacklist" | ssh "${upload_dest%:*}" "cat > ${upload_dest#*:}; /etc/init.d/dnsmasq restart"

    logger -s "Done"
fi

logger -s "Log ended $(date)"

