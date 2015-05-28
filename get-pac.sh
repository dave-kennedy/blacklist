#/bin/bash

LOG="log.txt"
CACHE_DIR="cache"
LOCAL_DATE="pdate.txt"
REMOTE_DATE="http://securemecca.com/Downloads/pdate.txt"
LOCAL_PAC="pac.txt"
REMOTE_PAC="http://securemecca.com/Downloads/pornproxy_en.txt"
FILTER="filter.pac"
ADD_PAC="add-pac.txt"

cd "${BASH_SOURCE%/*}" || exit

echo -e "\nLog started $(date)" >> "$LOG"

if [ ! -d "$CACHE_DIR" ]; then
    mkdir "$CACHE_DIR"
fi

echo "Downloading $REMOTE_DATE..." | tee -a "$LOG"

if ! wget -qO "$LOCAL_DATE" "$REMOTE_DATE"; then
    echo "Error: $?" | tee -a "$LOG"
    exit 1
fi

echo "Done" | tee -a "$LOG"

if [ ! -f "$CACHE_DIR/$LOCAL_PAC" ]; then
    echo "First run" | tee -a "$LOG"
    download=true
elif [ "$CACHE_DIR/$LOCAL_DATE" -ot "$LOCAL_DATE" ]; then
    echo "PAC file is out of date" | tee -a "$LOG"
    download=true
else
    echo "PAC file is up to date" | tee -a "$LOG"
    download=false
fi

mv "$LOCAL_DATE" "$CACHE_DIR"

if [ "$download" = true ]; then
    echo "Downloading $REMOTE_PAC..." | tee -a "$LOG"

    if ! wget -qO "$CACHE_DIR/$LOCAL_PAC" "$REMOTE_PAC"; then
        echo "Error: $?" | tee -a "$LOG"
        exit 2
    fi

    echo "Done" | tee -a "$LOG"
fi

echo "Building $FILTER..." | tee -a "$LOG"

sed 's/$//' "$CACHE_DIR/$LOCAL_PAC" > "$FILTER"

while read line; do
    list=$(expr match "$line" '\(.*\[\)')
    list=${list::-1}
    sed -i "/$list\[i++\]/{:loop; n; /^$/{s/^$/$line\n/; b}; b loop;}" "$FILTER"
done < "$ADD_PAC"

echo "Done" | tee -a "$LOG"

