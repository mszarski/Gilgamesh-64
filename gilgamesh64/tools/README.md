# Test and build tooling

Copied from the development workspace so future sessions don't have to rebuild it from scratch.
Paths inside the scripts assume the layout described in `/HANDOFF.md` (section "Pointers").

## `ares/`: headless N64 testing in the ares emulator

- `run_rom.sh <rom.z64> <seconds> <out.png> [key-sequence]`: boots a ROM in ares under Xvfb, plays a
  scripted key sequence, saves screenshots (`shot:FILE.png`) and the ares log (`<out>.log`, includes
  libdragon `debugf` output). Run `run_rom.sh` with no arguments for the full token syntax.
  - `ARES=/path/to/ares` overrides the binary (default `./ares/build/rundir/bin/ares`).
  - `RECORD=out.mkv` records the whole Xvfb display losslessly (see `record_all.sh` for conversion to real time).
  - Key map: A=x B=c Z=z START=Return L=q R=e, stick=arrows, d-pad=i/k/j/l, C=w/s/a/d.
- `ares-settings.template.bml` + `make_settings.py`: the settings file the runner copies per run
  (keyboard bindings, muted audio, input while unfocused, HomebrewMode for ISViewer logging).
- `scenarios*.sh`, `record_all.sh`, `record_2.sh`: the scripted test runs and the gameplay-video
  recording used in the original session. They expect debug ROMs named e.g. `sc_boss.z64`; see the
  build commands in `/HANDOFF.md`.

## `browser/`: the web emulator (EmulatorJS + patched mupen64plus core)

- `emu.html`: test page; `emu.html?core=mupen64plus_next&rom=x.z64&opts=<json EJS_defaultOptions>`.
  Serve it next to an EmulatorJS `data/` folder (e.g. a copy of `gilgamesh64/web/data/`).
- `bench2.js <rom>`: Playwright benchmark; prints game speed (% of real time), the game's own fps
  (from the ROM's `[perf]` log) and the fps a viewer actually sees.
- `emu3.js`, `emuframes.js`, `audiocheck.js`, `emuprof2.js`: boot+log+screenshot, frame counter,
  audio-output check, and a CPU profiler (needs a core linked with `--profiling-funcs`).
- `rebuild_core.sh`: incremental rebuild + link + 7z packaging of the WASM core (set `S=` first).
