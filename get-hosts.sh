#/bin/bash

LOGS_DIR="logs"
LOCAL_DATE="hdate.txt"
REMOTE_DATE="http://securemecca.com/Downloads/hdate.txt"
LAST_RUN="$LOGS_DIR/hdate.txt"
LOCAL_HOSTS="hosts.txt"
REMOTE_HOSTS="http://securemecca.com/Downloads/hosts.txt"
BLACKLIST="blacklist.hosts"
ADD_HOSTS="add-hosts.txt"

if [ ! -d "$LOGS_DIR" ]; then
    mkdir "$LOGS_DIR"
fi

if ! wget -qO "$LOCAL_DATE" "$REMOTE_DATE"; then
    echo "Couldn't download $REMOTE_DATE"
    exit 1
fi

if [ -f "$LAST_RUN" ]; then
    if diff -q "$LOCAL_DATE" "$LAST_RUN" > /dev/null; then
        echo "Hosts file is up to date"
        mv "$LOCAL_DATE" "$LAST_RUN"
        exit 0
    else
        echo "Hosts file is out of date - downloading..."
    fi
else
    echo "First run - downloading hosts file..."
fi

if ! wget -qO "$LOCAL_HOSTS" "$REMOTE_HOSTS"; then
    echo "Couldn't download $REMOTE_HOSTS"
    exit 2
fi

echo "Done"

sed 's/$//' "$LOCAL_HOSTS" > "$BLACKLIST"
cat "$ADD_HOSTS" >> "$BLACKLIST"

mv "$LOCAL_DATE" "$LAST_RUN"

