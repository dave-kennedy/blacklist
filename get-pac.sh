#/bin/bash

LOG="log.txt"
CACHE_DIR="cache"
LOCAL_DATE="pdate.txt"
REMOTE_DATE="http://securemecca.com/Downloads/pdate.txt"
LOCAL_PAC="pac.txt"
REMOTE_PAC="http://securemecca.com/Downloads/pornproxy_en.txt"
FILTER="filter"
ADD_PAC="add-pac.txt"

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
        echo "PAC file is up to date" | tee -a "$LOG"
        download=false
    else
        echo "PAC file is out of date" | tee -a "$LOG"
        download=true
    fi
else
    echo "First run" | tee -a "$LOG"
    download=true
fi

mv "$LOCAL_DATE" "$CACHE_DIR"

if [ "$download" = true ]; then
    echo "Downloading $REMOTE_PAC..." | tee -a "$LOG"

    if ! wget -qO "$LOCAL_PAC" "$REMOTE_PAC"; then
        echo "Error: $?" | tee -a "$LOG"
        exit 2
    fi

    echo "Done" | tee -a "$LOG"
fi

sed 's/$//' "$LOCAL_PAC" |
tac |
awk '
    NR == FNR {additional[$1] = $0; next}
    $1 in additional && !found[$1] {print additional[$1]; found[$1] = 1}
    {print}
' "$ADD_PAC" - |
tac > "$FILTER"

mv "$LOCAL_PAC" "$CACHE_DIR"

echo "" >> "$LOG"

