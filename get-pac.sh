#/bin/bash

CACHE_DIR="cache"
LOCAL_DATE="pdate.txt"
REMOTE_DATE="http://securemecca.com/Downloads/pdate.txt"
LOCAL_PAC="pac.txt"
REMOTE_PAC="http://securemecca.com/Downloads/pornproxy_en.txt"
BLACKLIST="blacklist.pac"
ADD_PAC="add-pac.txt"

if [ ! -d "$CACHE_DIR" ]; then
    mkdir "$CACHE_DIR"
fi

if ! wget -qO "$LOCAL_DATE" "$REMOTE_DATE"; then
    echo "Couldn't download $REMOTE_DATE"
    exit 1
fi

if [ -f "$CACHE_DIR/$LOCAL_DATE" ]; then
    if diff -q "$LOCAL_DATE" "$CACHE_DIR/$LOCAL_DATE" > /dev/null; then
        echo "PAC file is up to date"
        mv "$LOCAL_DATE" "$CACHE_DIR"
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

sed 's/$//' "$LOCAL_PAC" |
tac |
awk '
    NR == FNR {additional[$1] = $0; next}
    $1 in additional && !found[$1] {print additional[$1]; found[$1] = 1}
    {print}
' "$ADD_PAC" - |
tac > "$BLACKLIST"

mv "$LOCAL_DATE" "$LOCAL_PAC" "$CACHE_DIR"

