#/bin/bash

log="log.txt"
config="config.txt"
cache_dir="cache"
local_date="hdate.txt"
remote_date="http://securemecca.com/Downloads/hdate.txt"
local_hosts="hosts.txt"
remote_hosts="http://securemecca.com/Downloads/hosts.txt"
blacklist="blacklist.hosts"
add_blacklist="add-blacklist.txt"

cd "${BASH_SOURCE%/*}" || exit

echo -e "\nLog started $(date)" >> "$log"

if [ -f "$config" ]; then
    while IFS='= ' read key value; do
        case "$key" in
            blacklist_dest)
                declare "$key"="$value"
                ;;
        esac
    done < "$config"
fi

if [ ! -d "$cache_dir" ]; then
    mkdir "$cache_dir"
fi

echo "Downloading $remote_date..." | tee -a "$log"

if ! wget -qO "$local_date" "$remote_date"; then
    echo "Error: $?" | tee -a "$log"
    exit 1
fi

echo "Done" | tee -a "$log"

if [ ! -f "$cache_dir/$local_hosts" ]; then
    echo "First run" | tee -a "$log"
    download=true
elif [ "$cache_dir/$local_date" -ot "$local_date" ]; then
    echo "Hosts file is out of date" | tee -a "$log"
    download=true
else
    echo "Hosts file is up to date" | tee -a "$log"
    download=false
fi

mv "$local_date" "$cache_dir"

if [ "$download" = true ]; then
    echo "Downloading $remote_hosts..." | tee -a "$log"

    if ! wget -qO "$cache_dir/$local_hosts" "$remote_hosts"; then
        echo "Error: $?" | tee -a "$log"
        exit 2
    fi

    echo "Done" | tee -a "$log"
fi

echo "Building $blacklist..." | tee -a "$log"

sed 's/$//' "$cache_dir/$local_hosts" > "$blacklist"
cat "$add_blacklist" >> "$blacklist"

echo "Done" | tee -a "$log"

if [ -n "$blacklist_dest" ]; then
    scp "$blacklist" "$blacklist_dest"
fi

