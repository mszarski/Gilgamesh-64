#!/bin/bash
cd "$(dirname "$0")"; mkdir -p gshots/sc; rm -f gshots/sc/{ring,boss}*
fightloop(){ local n=$1 p=$2 s=""; for c in $(seq 1 $n); do s="$s Z+UP:0.6 Z+B wait:0.25 Z+B wait:0.25 Z+B wait:0.6"; [ $((c%3)) = 0 ] && s="$s Z+R:1.2"; [ $((c%6)) = 0 ] && s="$s shot:gshots/sc/${p}_$c.png"; done; echo "$s"; }
presses(){ local n=$1 s=""; for i in $(seq 1 $n); do s="$s B wait:1.6"; done; echo "$s"; }
: <<SKIP
# A: oasis seal
./run_rom.sh sc_oasis.z64 30 gshots/sc/oasis_end.png "START wait:4 shot:gshots/sc/oasis0.png UP+LEFT:2.5 wait:3 shot:gshots/sc/oasis1.png $(presses 8) wait:2" >/dev/null 2>&1
SKIP
: <<SKIP2
# B: scorpion camp
./run_rom.sh sc_camp.z64 30 gshots/sc/camp_end.png "START wait:4 shot:gshots/sc/camp0.png $(fightloop 36 camp) wait:2" >/dev/null 2>&1
SKIP2
# C: lion ring -> dusk seal -> gate
./run_rom.sh sc_ring.z64 30 gshots/sc/ring_end.png "A wait:2 A wait:2 A wait:2 A wait:2 shot:gshots/sc/ring0.png $(fightloop 36 ring) wait:3 shot:gshots/sc/ring_cleared.png $(presses 4) UP:0.5 wait:1 RIGHT:0.4 wait:1 DOWN:0.4 wait:1 LEFT:0.4 wait:2 shot:gshots/sc/ring_seal.png $(presses 8) wait:12 shot:gshots/sc/ring_gate.png $(presses 6) wait:2" >/dev/null 2>&1
# D: normal boss fight
./run_rom.sh sc_boss.z64 30 gshots/sc/boss_end.png "A wait:2 A wait:2 A wait:2 A wait:2 UP:3 wait:35 $(presses 10) $(fightloop 80 boss) wait:5 $(presses 14) wait:3" >/dev/null 2>&1
for f in ring boss; do echo "== $f"; grep -E "\[play\]|\[fight\] (HUMBABA|GAME|ENDING|boss fight)" gshots/sc/${f}_end.log; grep -c "\[fight\] boss hit" gshots/sc/${f}_end.log; grep -E "\[fight\] player hit" gshots/sc/${f}_end.log | tail -1; grep -iE "assert|exception" gshots/sc/${f}_end.log | head -2; done
