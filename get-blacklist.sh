#/bin/bash

LOG="log.txt"
CACHE_DIR="cache"
LOCAL_DATE="hdate.txt"
REMOTE_DATE="http://securemecca.com/Downloads/hdate.txt"
LOCAL_HOSTS="hosts.txt"
REMOTE_HOSTS="http://securemecca.com/Downloads/hosts.txt"
BLACKLIST="blacklist.hosts"
ADD_BLACKLIST="add-blacklist.txt"

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

if [ ! -f "$CACHE_DIR/$LOCAL_HOSTS" ]; then
    echo "First run" | tee -a "$LOG"
    download=true
elif [ "$CACHE_DIR/$LOCAL_DATE" -ot "$LOCAL_DATE" ]; then
    echo "Hosts file is out of date" | tee -a "$LOG"
    download=true
else
    echo "Hosts file is up to date" | tee -a "$LOG"
    download=false
fi

mv "$LOCAL_DATE" "$CACHE_DIR"

if [ "$download" = true ]; then
    echo "Downloading $REMOTE_HOSTS..." | tee -a "$LOG"

    if ! wget -qO "$CACHE_DIR/$LOCAL_HOSTS" "$REMOTE_HOSTS"; then
        echo "Error: $?" | tee -a "$LOG"
        exit 2
    fi

    echo "Done" | tee -a "$LOG"
fi

echo "Building $BLACKLIST..." | tee -a "$LOG"

sed 's/$//' "$CACHE_DIR/$LOCAL_HOSTS" > "$BLACKLIST"
cat "$ADD_BLACKLIST" >> "$BLACKLIST"

echo "Done" | tee -a "$LOG"

