#/bin/bash

LOG="log.txt"
CACHE_DIR="cache"
LOCAL_DATE="hdate.txt"
REMOTE_DATE="http://securemecca.com/Downloads/hdate.txt"
LOCAL_HOSTS="hosts.txt"
REMOTE_HOSTS="http://securemecca.com/Downloads/hosts.txt"
BLACKLIST="blacklist.hosts"
ADD_HOSTS="add-hosts.txt"

cd "${BASH_SOURCE%/*}" || exit

echo "Log started $(date)" >> "$LOG"

if [ ! -d "$CACHE_DIR" ]; then
    mkdir "$CACHE_DIR"
fi

echo "Downloading $REMOTE_DATE..." | tee -a "$LOG"

if ! wget -qO "$LOCAL_DATE" "$REMOTE_DATE"; then
    echo "Error: $?" | tee -a "$LOG"
    exit 1
fi

echo "Done" | tee -a "$LOG"

if [ -f "$CACHE_DIR/$LOCAL_DATE" ]; then
    if diff -q "$LOCAL_DATE" "$CACHE_DIR/$LOCAL_DATE" > /dev/null; then
        echo "Hosts file is up to date" | tee -a "$LOG"
        download=false
    else
        echo "Hosts file is out of date" | tee -a "$LOG"
        download=true
    fi
else
    echo "First run" | tee -a "$LOG"
    download=true
fi

mv "$LOCAL_DATE" "$CACHE_DIR"

if [ "$download" = true ]; then
    echo "Downloading $REMOTE_HOSTS..." | tee -a "$LOG"

    if ! wget -qO "$LOCAL_HOSTS" "$REMOTE_HOSTS"; then
        echo "Error: $?" | tee -a "$LOG"
        exit 2
    fi

    echo "Done" | tee -a "$LOG"
fi

sed 's/$//' "$LOCAL_HOSTS" > "$BLACKLIST"
cat "$ADD_HOSTS" >> "$BLACKLIST"

mv "$LOCAL_HOSTS" "$CACHE_DIR"

echo "" >> "$LOG"

