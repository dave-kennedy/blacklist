#/bin/bash

log="log.txt"
config="config.txt"
cache_dir="cache"
local_date="pdate.txt"
remote_date="http://securemecca.com/Downloads/pdate.txt"
local_pac="pac.txt"
remote_pac="http://securemecca.com/Downloads/pornproxy_en.txt"
filter="filter.pac"

cd "${BASH_SOURCE%/*}" || exit

echo -e "\nLog started $(date)" >> "$log"

add_good_domains=()
remove_good_domains=()
add_bad_domains=()
remove_bad_domains=()
add_bad_url_parts=()
remove_bad_url_parts=()
add_bad_host_parts=()
remove_bad_host_parts=()

if [ -f "$config" ]; then
    while IFS='= ' read key value; do
        case "$key" in
            filter_add_good_domain)
                add_good_domains=("${add_good_domains[@]}" "$value") ;;
            filter_remove_good_domain)
                remove_good_domains=("${remove_good_domains[@]}" "$value") ;;
            filter_add_bad_domain)
                add_bad_domains=("${add_bad_domains[@]}" "$value") ;;
            filter_remove_bad_domain)
                remove_bad_domains=("${remove_bad_domains[@]}" "$value") ;;
            filter_add_bad_url_part)
                add_bad_url_parts=("${add_bad_url_parts[@]}" "$value") ;;
            filter_remove_bad_url_part)
                remove_bad_url_parts=("${remove_bad_url_parts[@]}" "$value") ;;
            filter_add_bad_host_part)
                add_bad_host_parts=("${add_bad_host_parts[@]}" "$value") ;;
            filter_remove_bad_host_part)
                remove_bad_host_parts=("${remove_bad_host_parts[@]}" "$value") ;;
            filter_upload_dest)
                upload_dest="$value" ;;
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

sed "/\\/\\/\\/\\/\\/\\/\\/\\/\\/\\/\\/\\/\\/\\/\\/\\/\\/\\/\\/\\/\\/\\/\\/\\/\\/\\/\\//,\$d" "$cache_dir/$local_pac" | sed "s///" > "$filter"

for add_good_domain in "${add_good_domains[@]}"; do
    echo "GoodDomains.push(\"$add_good_domain\");" >> "$filter"
done
for add_bad_domain in "${add_bad_domains[@]}"; do
    echo "BadDomains.push(\"$add_bad_domain\");" >> "$filter"
done
for add_bad_url_part in "${add_bad_url_parts[@]}"; do
    echo "BadURL_Parts.push(\"$add_bad_url_part\");" >> "$filter"
done
for add_bad_host_part in "${add_bad_host_parts[@]}"; do
    echo "BadHostParts.push(\"$add_bad_host_part\");" >> "$filter"
done

sed -n "/\\/\\/\\/\\/\\/\\/\\/\\/\\/\\/\\/\\/\\/\\/\\/\\/\\/\\/\\/\\/\\/\\/\\/\\/\\/\\/\\//,\$p" "$cache_dir/$local_pac" | sed "s///" >> "$filter"

for remove_good_domain in "${remove_good_domains[@]}"; do
    sed -i "s/^GoodDomains\[i++\] = \"${remove_good_domain/[/\\[}\";/\/\/ GoodDomains[i++] = \"$remove_good_domain\";/" "$filter"
done
for remove_bad_domain in "${remove_bad_domains[@]}"; do
    sed -i "s/^BadDomains\[i++\] = \"${remove_bad_domain/[/\\[}\";/\/\/ BadDomains[i++] = \"$remove_bad_domain\";/" "$filter"
done
for remove_bad_url_part in "${remove_bad_url_parts[@]}"; do
    sed -i "s/^BadURL_Parts\[i++\] = \"${remove_bad_url_part/[/\\[}\";/\/\/ BadURL_Parts[i++] = \"$remove_bad_url_part\";/" "$filter"
done
for remove_bad_host_part in "${remove_bad_host_parts[@]}"; do
    sed -i "s/^BadHostParts\[i++\] = \"${remove_bad_host_part/[/\\[}\";/\/\/ BadHostParts[i++] = \"$remove_bad_host_part\";/" "$filter"
done

echo "Done" | tee -a "$log"

if [ -n "$upload_dest" ]; then
    echo "Uploading to $upload_dest..." | tee -a "$log"

    scp -q "$filter" "$upload_dest"

    echo "Done" | tee -a "$log"
fi

