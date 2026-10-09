#!/bin/bash

flagged_ext=(".exe" ".bat" ".vbs" ".scr" ".ps1")
flagged_kw=("virus" "trojan" "malware" "worm" "ransomware")
whitelist="whitelist.txt"

dir="$1"
malicious_dir="$2"
sleep 23

touch "$whitelist"

for f in "$dir"/*; do
    [ -f "$f" ] || continue
    name=$(basename "$f")

    grep -Fxq "$name" "$whitelist" && continue

    ext=".${name##*.}"
    hit=0
    for e in "${flagged_ext[@]}"; do
        [ "$ext" = "$e" ] && hit=1
    done
    for k in "${flagged_kw[@]}"; do
        grep -qi "$k" "$f" 2>/dev/null && hit=1
    done

    if [ "$hit" = "1" ]; then
        echo "$name is malicious and it is DELETED"
        if cp "$f" "$malicious_dir/$name"; then
            rm -f "$f"
        fi
    fi
done