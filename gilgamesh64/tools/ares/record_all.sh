#!/bin/bash
cd "$(dirname "$0")"; mkdir -p rec
P(){ local n=$1 w=${2:-1.6} s=""; for i in $(seq 1 $n); do s="$s B:0.4 wait:$w"; done; echo "$s"; }
F(){ local n=$1 s=""; for c in $(seq 1 $n); do s="$s Z+UP:0.6 Z+B:0.35 wait:0.3 Z+B:0.35 wait:0.3 Z+B:0.35 wait:0.6"; [ $((c%4)) = 0 ] && s="$s Z+R:1.0 wait:0.3"; [ $((c%5)) = 0 ] && s="$s Z+LEFT+A:0.35 wait:0.6"; done; echo "$s"; }
# 1 title + narration
RECORD=rec/1_title.mkv ./run_rom.sh rec_full.z64 3 rec/1.png "wait:28 START:0.35 wait:8 $(P 6 2.5) wait:2" >/dev/null 2>&1
# 2 steppe: walk, smash a pot, wander with Enkidu
RECORD=rec/2_steppe.mkv ./run_rom.sh rec_steppe.z64 3 rec/2.png "wait:10 START:0.35 wait:5 LEFT:1.6 wait:0.5 B:0.35 wait:1 B:0.35 wait:2.5 RIGHT:1.2 UP:5 wait:0.5 A:0.35 wait:2 UP+RIGHT:4 wait:1 DOWN:2 wait:2" >/dev/null 2>&1
# 3 scorpion camp fight
RECORD=rec/3_camp.mkv ./run_rom.sh rec_camp.z64 3 rec/3.png "wait:10 START:0.35 wait:4 $(F 14) wait:3" >/dev/null 2>&1
# 4 seal of dusk -> cedar door
RECORD=rec/4_dusk.mkv ./run_rom.sh rec_dusk.z64 3 rec/4.png "wait:10 START:0.35 wait:5 UP:2.5 wait:2 $(P 7 2.2) wait:30 $(P 5 2.2) wait:3" >/dev/null 2>&1
# 5 Humbaba: intro, fight, mercy dialogue, ending
RECORD=rec/5_boss.mkv ./run_rom.sh rec_boss.z64 3 rec/5.png "wait:10 START:0.35 wait:3 UP:2.5 wait:30 $(P 8 2.5) $(F 75) wait:30 $(P 9 2.8) wait:12" >/dev/null 2>&1
for f in rec/*.mkv; do echo "$f $(ffprobe -v error -show_entries format=duration -of csv=p=0 $f)"; done
grep -h "\[fight\] HUMBABA\|ENDING\|collected\|defeated\|door opened" rec/*.log 2>/dev/null
