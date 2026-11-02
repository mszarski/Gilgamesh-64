#!/bin/bash
cd "$(dirname "$0")"; mkdir -p gshots/sc3; rm -f gshots/sc3/*
P(){ local n=$1 s=""; for i in $(seq 1 $n); do s="$s B:0.5 wait:1.5"; done; echo "$s"; }
./run_rom.sh sc_full.z64 30 gshots/sc3/full_end.png "START:0.6 wait:6 $(P 12) shot:gshots/sc3/full_introdone.png A:0.5 wait:2 shot:gshots/sc3/full_talk.png $(P 6) LEFT:1.2 wait:1 B:0.5 wait:1 B:0.5 wait:1 B:0.5 wait:2 shot:gshots/sc3/full_pots.png RIGHT:2.5 wait:1 UP:0.6 wait:1 shot:gshots/sc3/full_stele_near.png A:0.5 wait:2 shot:gshots/sc3/full_stele.png $(P 6) START:0.6 wait:3 shot:gshots/sc3/full_pause.png START:0.6 wait:3 shot:gshots/sc3/full_unpause.png" >/dev/null 2>&1
./run_rom.sh sc_check.z64 30 gshots/sc3/check_end.png "START:0.6 wait:4 $(P 2) A:0.5 wait:3 shot:gshots/sc3/check1.png B:0.5 wait:2 B:0.5 wait:2 shot:gshots/sc3/check2.png" >/dev/null 2>&1
./run_rom.sh sc_boss.z64 30 gshots/sc3/die_end.png "START:0.6 wait:3 UP:3 wait:35 $(P 10) wait:150 shot:gshots/sc3/die_gameover.png START:0.6 wait:12 shot:gshots/sc3/die_continue.png" >/dev/null 2>&1
./run_rom.sh sc_god.z64 30 gshots/sc3/god_end.png "START:0.6 wait:3 UP:3 wait:35 $(P 10) wait:60 shot:gshots/sc3/god_mid.png wait:120" >/dev/null 2>&1
for f in full check die god; do echo "== $f"; grep -E "\[play\]|\[fight\] (HUMBABA|GAME|ENDING|boss fight|boss charged|reflected|player)" gshots/sc3/${f}_end.log | sort | uniq -c; grep -iE "assert|exception" gshots/sc3/${f}_end.log | head -2; done
