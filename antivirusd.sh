#!/bin/bash

flagged_ext=(".exe" ".bat" ".vbs" ".scr" ".ps1")
flagged_kw=("virus" "trojan" "malware" "worm" "ransomware")
whitelist="whitelist.txt"

if [ $# -ne 3 ]; then
    echo "Usage: $0 dir malicious_dir interval_secs"
    exit 1
fi

dir="$1"
malicious_dir="$2"
interval_secs="$3"

if [ ! -d "$dir" ]; then
    echo "Error: Source directory does not exist"
    exit 1
fi
mkdir -p "$malicious_dir" || exit 1

touch "$whitelist"

is_malicious() {
    fname=$(basename "$1")
    grep -Fxq "$fname" "$whitelist" && return 1

    ext=".${fname##*.}"
    for e in "${flagged_ext[@]}"; do
        [ "$ext" = "$e" ] && { echo "EXT MATCH: $ext"; return 0; }
    done

    for k in "${flagged_kw[@]}"; do
        grep -qi "$k" "$1" 2>/dev/null && { echo "MATCH: $k in $1"; return 0; }
    done
    return 1
}

scan() {
    for f in "$dir"/*; do
        [ -f "$f" ] || continue
        if is_malicious "$f"; then
            name=$(basename "$f")
            echo "$name is malicious and it is DELETED"
            if cp "$f" "$malicious_dir/$name"; then
    rm -f "$f"
else
    echo "Error: Failed to quarantine $name"
fi
        fi
    done
}

if [ ! -f directory-info.last ]; then
    scan
    ls -l "$dir" > directory-info.last
fi
while true; do
        sleep "$interval_secs"
        ls -l "$dir" > directory-info.new
        if ! cmp -s directory-info.last directory-info.new; then
            scan
            cp directory-info.new directory-info.last
        fi
done