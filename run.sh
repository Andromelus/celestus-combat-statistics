#!/bin/bash

echo "Calculator version 2.0.0"

nbr_reports=$(ls -l ./reports/*.htm | wc -l)

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
awk -f ./src/calculated_stats.awk tmp_stats
rm tmp_stats
