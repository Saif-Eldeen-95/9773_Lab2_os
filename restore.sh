#!/bin/bash

whitelist="whitelist.txt"

if [ $# -ne 2 ]; then
    echo "Usage: $0 dir malicious_dir"
    exit 1
fi

dir="$1"
malicious_dir="$2"
touch "$whitelist"

while true; do
    files=("$malicious_dir"/*)
    if [ ! -e "${files[0]}" ]; then
        echo "No malicious files to review."
        exit 0
    fi

    echo ""
    echo "Quarantined files:"
    i=1
    for f in "${files[@]}"; do
        echo "  $i) $(basename "$f")"
        i=$((i+1))
    done

    read -p "Pick a number (0 to quit): " choice
    [ "$choice" = "0" ] && exit 0

    if ! [[ "$choice" =~ ^[0-9]+$ ]] || [ "$choice" -lt 1 ] || [ "$choice" -gt ${#files[@]} ]; then
        echo "Invalid choice."
        continue
    fi

    selected="${files[$((choice-1))]}"
    name=$(basename "$selected")

    echo "1) Restore  2) Delete  3) Skip"
    read -p "Choose: " action

    case "$action" in
        1)
            mv "$selected" "$dir/$name"
            grep -Fxq "$name" "$whitelist" || echo "$name" >> "$whitelist"
            echo "Restored $name to $dir."
            ;;
        2)
            rm -f "$selected"
            echo "$name permanently deleted."
            ;;
        3)
            ;;
        *)
            echo "Invalid option."
            ;;
    esac
done