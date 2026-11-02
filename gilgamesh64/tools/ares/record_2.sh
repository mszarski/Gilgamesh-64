#!/bin/bash
cd "$(dirname "$0")"
F(){ local n=$1 s=""; for c in $(seq 1 $n); do s="$s Z+UP:0.6 Z+B:0.35 wait:0.3 Z+B:0.35 wait:0.3 Z+B:0.35 wait:0.6"; [ $((c%4)) = 0 ] && s="$s Z+R:1.0 wait:0.3"; [ $((c%5)) = 0 ] && s="$s Z+LEFT+A:0.35 wait:0.6"; done; echo "$s"; }
RECORD=rec/4_dusk.mkv ./run_rom.sh rec_dusk.z64 3 rec/4.png "wait:10 START:0.35 wait:5 UP:2.5 wait:80" >/dev/null 2>&1
RECORD=rec/5_boss.mkv ./run_rom.sh rec_boss.z64 3 rec/5.png "wait:10 START:0.35 wait:3 UP:2.5 wait:55 $(F 40) wait:90" >/dev/null 2>&1
grep -h "collected\|door opened\|HUMBABA\|ENDING" rec/4.log rec/5.log
