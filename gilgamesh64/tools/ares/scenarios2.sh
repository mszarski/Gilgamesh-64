#!/bin/bash
cd "$(dirname "$0")"; mkdir -p gshots/sc2; rm -f gshots/sc2/*
fightloop(){ local n=$1 p=$2 s=""; for c in $(seq 1 $n); do s="$s Z+UP:0.6 Z+B wait:0.25 Z+B wait:0.25 Z+B wait:0.6"; [ $((c%3)) = 0 ] && s="$s Z+R:1.2"; [ $((c%8)) = 0 ] && s="$s shot:gshots/sc2/${p}_$c.png"; done; echo "$s"; }
presses(){ local n=$1 s=""; for i in $(seq 1 $n); do s="$s B wait:1.6"; done; echo "$s"; }
START="A wait:2 A wait:2 A wait:2 A wait:2"
./run_rom.sh sc_dusk.z64 30 gshots/sc2/dusk_end.png "$START shot:gshots/sc2/dusk0.png UP:2.5 wait:3 shot:gshots/sc2/dusk1.png $(presses 8) wait:6 shot:gshots/sc2/dusk_cut.png wait:20 shot:gshots/sc2/dusk_gate.png $(presses 6) wait:2" >/dev/null 2>&1
./run_rom.sh sc_boss.z64 30 gshots/sc2/boss_end.png "$START UP:3 wait:35 $(presses 10) $(fightloop 85 boss) wait:30 shot:gshots/sc2/boss_after.png $(presses 16) wait:5" >/dev/null 2>&1
for f in dusk boss; do echo "== $f"; grep -E "\[play\]|\[fight\] (HUMBABA|GAME|ENDING|boss fight)" gshots/sc2/${f}_end.log; grep "\[fight\] boss hit" gshots/sc2/${f}_end.log | tail -1; grep -E "\[fight\] player hit" gshots/sc2/${f}_end.log | tail -1; grep -iE "assert|exception" gshots/sc2/${f}_end.log | head -2; done
