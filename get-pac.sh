#/bin/bash

LOGS_DIR="logs"
LOCAL_DATE="pdate.txt"
REMOTE_DATE="http://securemecca.com/Downloads/pdate.txt"
LAST_RUN="$LOGS_DIR/pdate.txt"
LOCAL_PAC="pac.txt"
REMOTE_PAC="http://securemecca.com/Downloads/pornproxy_en.txt"

if [ ! -d "$LOGS_DIR" ]; then
    mkdir "$LOGS_DIR"
fi

if ! wget -qO "$LOCAL_DATE" "$REMOTE_DATE"; then
    echo "Couldn't download $REMOTE_DATE"
    exit 1
fi

if [ -f "$LAST_RUN" ]; then
    if diff -q "$LOCAL_DATE" "$LAST_RUN" > /dev/null; then
        echo "PAC file is up to date"
        mv "$LOCAL_DATE" "$LAST_RUN"
        exit 0
    else
        echo "PAC file is out of date - downloading..."
    fi
else
    echo "First run - downloading PAC file..."
fi

if ! wget -qO "$LOCAL_PAC" "$REMOTE_PAC"; then
    echo "Couldn't download $REMOTE_PAC"
    exit 2
fi

echo "Done"

sed -i "s/$//" "$LOCAL_PAC"

mv "$LOCAL_DATE" "$LAST_RUN"

