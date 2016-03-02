#!/bin/sh

log="log.txt"
config="config.txt"
cache_dir="cache"
local_hosts="hosts.txt"
remote_hosts="http://winhelp2002.mvps.org/hosts.txt"
blacklist="blacklist.hosts"

cd "$(dirname "$0")" || exit 1

printf "\nLog started $(date)\n" >> "$log"

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

echo "Downloading $remote_hosts..." | tee -a "$log"

if ! curl -o "$cache_dir/$local_hosts" -s -z "$cache_dir/$local_hosts" "$remote_hosts"; then
    echo "Error: $?" | tee -a "$log"
    exit 1
fi

echo "Done" | tee -a "$log"

echo "Building $blacklist..." | tee -a "$log"

sed "s/\r//" "$cache_dir/$local_hosts" > "$blacklist"

for add_host in $add_hosts; do
    echo "0.0.0.0 $add_host" >> "$blacklist"
done

for remove_host in $remove_hosts; do
    sed -i "s/^0.0.0.0 $remove_host/#0.0.0.0 $remove_host/" "$blacklist"
done

echo "Done" | tee -a "$log"

if [ -n "$upload_dest" ]; then
    if ! echo "$upload_dest" | grep -Eq ".+@.+:.+"; then
        echo "Upload destination is not valid" | tee -a "$log"
        exit 2
    fi

    echo "Uploading to $upload_dest..." | tee -a "$log"

    cat "$blacklist" | ssh "${upload_dest%:*}" "cat > ${upload_dest#*:}; /etc/init.d/dnsmasq restart"

    echo "Done" | tee -a "$log"
fi

