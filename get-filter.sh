#/bin/bash

log="log.txt"
cache_dir="cache"
local_date="pdate.txt"
remote_date="http://securemecca.com/Downloads/pdate.txt"
local_pac="pac.txt"
remote_pac="http://securemecca.com/Downloads/pornproxy_en.txt"
filter="filter.pac"
add_filter="add-filter.txt"

cd "${BASH_SOURCE%/*}" || exit

echo -e "\nLog started $(date)" >> "$log"

if [ ! -d "$cache_dir" ]; then
    mkdir "$cache_dir"
fi

echo "Downloading $remote_date..." | tee -a "$log"

if ! wget -qO "$local_date" "$remote_date"; then
    echo "Error: $?" | tee -a "$log"
    exit 1
fi

echo "Done" | tee -a "$log"

if [ ! -f "$cache_dir/$local_pac" ]; then
    echo "First run" | tee -a "$log"
    download=true
elif [ "$cache_dir/$local_date" -ot "$local_date" ]; then
    echo "PAC file is out of date" | tee -a "$log"
    download=true
else
    echo "PAC file is up to date" | tee -a "$log"
    download=false
fi

mv "$local_date" "$cache_dir"

if [ "$download" = true ]; then
    echo "Downloading $remote_pac..." | tee -a "$log"

    if ! wget -qO "$cache_dir/$local_pac" "$remote_pac"; then
        echo "Error: $?" | tee -a "$log"
        exit 2
    fi

    echo "Done" | tee -a "$log"
fi

echo "Building $filter..." | tee -a "$log"

sed 's/$//' "$cache_dir/$local_pac" > "$filter"

while read line; do
    list=$(expr match "$line" '\(.*\[\)')
    list=${list::-1}
    sed -i "/$list\[i++\]/{:loop; n; /^$/{s/^$/$line\n/; b}; b loop;}" "$filter"
done < "$add_filter"

echo "Done" | tee -a "$log"

