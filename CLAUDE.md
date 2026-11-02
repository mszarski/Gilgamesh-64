# CLAUDE.md

Guidance for Claude Code (and other agents; `AGENTS.md` is a symlink to this file).

## Project

Gilgamesh 64: a late-90s-N64-style 3D action-adventure demo of Tablet V of the *Epic of Gilgamesh*
(collect three Seals of Shamash, open the cedar door, fight Humbaba). Everything lives under `gilgamesh64/`;
`gilgamesh64/README.md` is the user-facing doc (level walkthrough, controls, build, release steps).

Three tracks of the same level:

| Path | What | Run |
|------|------|-----|
| `gilgamesh64/index.html` | Single-file three.js prototype (320x240, dithered), used to iterate on level/combat design | `python3 -m http.server -d gilgamesh64 8064` (needs network: three.js from jsDelivr) |
| `gilgamesh64/n64/` | The real game: C, libdragon (preview branch) + tiny3d, builds `gilgamesh64.z64` | see Build |
| `gilgamesh64/web/` | Static EmulatorJS page that plays the ROM in a browser via a patched mupen64plus core | `python3 -m http.server -d gilgamesh64/web 8098` |

The prototype and the N64 port are separate implementations; a gameplay change usually needs doing in both
if they are to stay in step.

## Build (N64 ROM)

Needs the libdragon MIPS toolchain + libdragon preview and a built tiny3d checkout (not installed locally by default).

```bash
export N64_INST=/opt/libdragon
make -C gilgamesh64/n64 T3D_INST=/path/to/tiny3d          # -> gilgamesh64/n64/gilgamesh64.z64
make -C gilgamesh64/n64 T3D_INST=/path/to/tiny3d clean    # required when changing EXTRA_CFLAGS
```

- Compile-time options go through `EXTRA_CFLAGS` (appended to `N64_CFLAGS`). Object files don't track
  flags, so always `clean` before rebuilding with different flags.
- Browser ROM: `EXTRA_CFLAGS="-DGAME_FPS=20 -DVI_FILTERS=FILTERS_RESAMPLE"` (20 fps cap, no VI AA/de-dither,
  which costs software emulators ~40%). Defaults are 30 fps and `FILTERS_RESAMPLE_ANTIALIAS_DEDITHER`.
- Pinned, tested SDK versions are `LIBDRAGON_REF` / `TINY3D_REF` in `.github/workflows/gilgamesh64.yml`.
- There are no automated tests; verification is building and playing in ares (or Gopher64 / the web page).

## Architecture (`gilgamesh64/n64/src/`)

- `game.h`: all shared declarations and the global `Game G` state. Game logic is in meters; the renderer
  uses decimeters (`RS = 10`) because tiny3d's fixed-point pipeline prefers larger values.
- `main.c`: init, main loop, camera, cutscenes, game-state transitions, debug start setups.
- `world.c`: terrain, level geometry, collision. +z is south (Uruk), -z is north (Cedar Forest).
- `actors.c`: player, Enkidu, enemies, Humbaba boss AI, pickups, projectiles, particles; models are part hierarchies.
- `mesh.c`: procedural mesh builder baked into tiny3d vertex batches inside rspq blocks (static scenery has baked lighting).
- `ui.c`: HUD, dialogue, area cards, overlays (rdpq 2D). `synth.c`: software synth for SFX + two music loops at 16 kHz.
- All models, level and music are generated in code; the only assets are two CC0 fonts in `n64/assets/`.
- Performance is the main constraint (an earlier synth ate the whole CPU and the game ran at ~5 fps): avoid
  per-sample/per-frame `expf`/`powf`/`sinf`, keep draw ranges, LOD and fog distance tight.

## Debug aids

Pass as `EXTRA_CFLAGS="-D..."` (clean first):

- Start position: `DEBUG_GATE` (+ `DEBUG_GATE_X/Z`, all seals, door open), or `DEBUG_POS` (+ `DEBUG_POS_X/Z`),
  optionally with `DEBUG_SEALS=<bitmask>` and `DEBUG_DUSK` (lion ring cleared, Dusk seal spawned).
- `DEBUG_GOD` (no damage), `DEBUG_NOAUDIO`, `DEBUG_AUTODIALOG` (dialogue advances on a reading timer, for recording).
- Render isolation: `DEBUG_NOWORLD`, `DEBUG_NOACTORS`, `DEBUG_NOHUD`, `DEBUG_NOFOG`, `DEBUG_FOGFAR=<m>`.
- `debugf` logs tagged `[play]` / `[fight]` events (seals, kills, hits, boss attacks, ending); read them in the emulator's debug log.

## Web build / emulator core

- `web/data/` is vendored EmulatorJS (GPL-3.0); `web/data/cores/mupen64plus_next-wasm.data` is a custom core
  build. Rebuild instructions, base commit and the libdragon patch are in `web/emulator/` and must ship
  alongside the page (license obligation). Stock browser N64 cores can't run modern libdragon homebrew.
- `web/index.html` sets `EJS_disableLocalStorage = true`; that is required for `EJS_defaultOptions` to apply.
- `web/gilgamesh64.z64` is committed, but CI overwrites it with a fresh browser build before deploying.
  If you update it by hand, build it with the browser flags above, not the cartridge flags.

## CI / deploy

`.github/workflows/gilgamesh64.yml` (triggers only on changes under `gilgamesh64/` or the workflow itself):
builds cartridge + browser ROMs as artifacts; a `gilgamesh64-v*` tag creates a Release with the cartridge ROM.
The game is deliberately not deployed to GitHub Pages; `gilgamesh64/web/` is only served locally.

## Gotchas

- Root `.gitignore` ignores `*.png`, so the screenshots referenced in `gilgamesh64/README.md` were never committed;
  use `git add -f` if adding them.
