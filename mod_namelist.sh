#!/usr/bin/env bash


numinst=36

for ni in `seq 1 $numinst`; do
    strinst=`printf "%04d" $ni`
    echo "    stream_year_last_popdens = 2100" >> user_nl_elm_${strinst}
done
