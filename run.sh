#!/bin/bash

echo "Calculator version 3.0.0"

nbr_reports=$(ls -l ./reports/*.htm | wc -l)

if [[ -z "$1" ]]; then
    echo "notice: no output style set. Stats will be displayed as list."
    output_style=""
else
    output_style="$1"
fi

if [[ $nbr_reports -eq 1 ]]; then
    if ! awk -f ./src/stats.awk ./reports/*.htm >> tmp_stats ; then
        tail -1 tmp_stats
        exit 1
    fi
else
    for file in ./reports/*htm; do
        if ! awk -f ./src/stats.awk "$file" >> tmp_stats  ; then
            tail -1 tmp_stats
            exit 1
        fi
    done
fi
awk -f ./src/calculated_stats.awk -v output_style="$output_style" tmp_stats
rm tmp_stats
