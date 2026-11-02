# CLAUDE.md

Guidance for Claude Code (and other agents; `AGENTS.md` is a symlink to this file).

**Read `HANDOFF.md` first** for current state, verified/unverified features, perf numbers, history and
next steps. This file holds only durable rules and facts.

## Working with the user

- Wants **the real thing**: a genuine N64 ROM that runs on real hardware *and* is playable on the web via an
  emulator. A browser remake is not the deliverable (the three.js prototype was a wrong turn the user
  corrected: "make it so it can be played on an n64... use an emulator... make that work on web").
- **Original content only**: no Zelda assets, names, logos or recreated levels; Ocarina-like *genre* only.
- Wants things **actually tested by playing** ("test the full boss fight", "keep playing", "play more"),
  with screenshots/logs as evidence, and **honest reporting of what was not verified**.
- Likes **parallel work** (e.g. native emulator testing in one track, web in another); background agents
  for independent tracks worked well.
- Happy to approve third-party installs (toolchains, emulators, npm/apt). If a safety check blocks one,
  explain what is blocked and how to unblock it (they switch to Accept-edits mode); never work around it.
- After changes, asked for the published web artifact to be **updated with the latest build**.
- Cares about web speed ("make it run faster on the web") and practical distribution help.
- **No PR unless asked.**

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
  Toolchain: libdragon `toolchain-continuous-prerelease` `gcc-toolchain-mips64-x86_64.deb` (installs to
  `/opt/libdragon`, needs zlib/zstd). tiny3d only needs `make` (uses `build/libt3d.a`).
- Why libdragon preview + tiny3d (not the official SDK): open source, modern, good homebrew 3D via tiny3d's RSP microcode.
- There are no automated tests; verification is building and playing in ares (or Gopher64 / the web page).
  ares is the reference emulator (most accurate): headless under Xvfb with Mesa lavapipe Vulkan, built with
  `ARES_CORES=n64`. Harness scripts in `gilgamesh64/tools/ares/` (run, scenarios, recording); see `tools/README.md`.
- libdragon ROMs need ares, Gopher64 or the patched web core; older mupen64plus/Project64 fail.

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
- Keep it procedural (no model/texture pipeline, no GLTF): self-contained repo, deliberate low-poly flat look.
- Debug options stay compile-time flags so release ROMs contain none of them.

## N64 / tiny3d gotchas

- Vertex positions are int16. Character/prop meshes are authored in **cm**: `mb_new(1)`, scaled by `RS*0.01`
  at draw time; world meshes use `mb_new(RS)`. Wrong unit overflowed into "giant brown slabs".
- `mb_bake` batches <=64 vertices (tiny3d cache is 70) and pads to even counts (vertices packed in pairs).
- Geometry is CCW-outward; `T3D_FLAG_CULL_BACK` is on; mirrored transforms flip winding.
- Static world is **pre-lit** (`light_color()` in `mesh.c`, drawn with `T3D_FLAG_NO_LIGHT`); actors use real
  lights. Keep the two light palettes in sync (`mesh.c` <-> `main.c`, steppe->forest blend by z).
- tiny3d fog uses shade alpha: disable fog for the alpha-blended shadow/effects pass.
- No additive blending on the RDP (blender wraps -> purple bands); use `RDPQ_BLENDER_MULTIPLY` alpha blending.
- `rdpq_text_print` with `WRAP_WORD` asserts if `width == 0`.
- Boot problems in an emulator are not IPL3's fault (swapping IPL3 revisions was a dead end). The dev IPL3
  (`libdragon/boot` without `PROD=1`) logs boot progress over ISViewer, useful for diagnosing emulators.

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
- `web/gilgamesh64.z64` is the only committed build output (`n64/.gitignore` ignores `*.z64`). If you update
  it, build it with the browser flags above, not the cartridge flags.
- Core choice (don't revisit casually): mupen64plus_next rebuilt from source with LLE RSP (`parallel` with the
  portable `rsp_interp.cpp` written here, or `cxd4`) + angrylion software RDP, **single-threaded** (hosts like
  GitHub Pages/claude.ai can't send COOP/COEP, so no SharedArrayBuffer). Dead ends: stock npm cores (HLE RSP +
  GLideN64 only), parallel_n64 (unknown CIC, hangs ~538 frames), GLideN64 for libdragon (RDRAM corruption via
  framebuffer copy-back / black screen), threads build.
- Required core options: `mupen64plus-rdp-plugin: angrylion`, `mupen64plus-rsp-plugin: parallel` (or `cxd4`),
  `mupen64plus-angrylion-vioverlay: Unfiltered`.
- `EJS_gameUrl` must be a string (blob URL), not a Blob; `EJS_gameName='gilgamesh64.z64'` keeps the extension;
  renamed files need `EJS_paths`. For the claude.ai artifact, binaries are renamed to `.wasm` (host serves only
  standard web types) and mapped back with `EJS_paths`.
- Core rebuild: `gilgamesh64/tools/browser/rebuild_core.sh` (emsdk 3.1.74, `LLE=1 HAVE_THR_AL=1
  HAVE_PARALLEL_RSP_INTERP=1`, `Makefile.emulatorjs` ASYNC=1, `-sASYNCIFY_REMOVE=@asyncify_remove.json`, then
  7z-pack into `mupen64plus_next-wasm.data`; ~5 min incremental). The core Makefile **doesn't track header
  deps**: touch the `.c` files after editing a `.h`/`.def`. All core fixes live in
  `web/emulator/mupen64plus-libretro-nx-libdragon.patch`; read its list before debugging the core.
- Asyncify removal is safe only because the sole yield point is `new_vi()` -> `retro_return()` -> `co_switch`.
- Measure web speed with `tools/browser/bench2.js` (speed, game fps, seen fps). Emulated VI fps alone misleads
  (drops when the game gets faster). Scene tweaks (fog/HUD) barely matter; real costs were synth, VI filter,
  RSP interpreter, rasterizer. Headless Chromium needs `--autoplay-policy=no-user-gesture-required`.

## CI / deploy

`.github/workflows/gilgamesh64.yml` (triggers only on changes under `gilgamesh64/` or the workflow itself):
builds cartridge + browser ROMs as artifacts; a `gilgamesh64-v*` tag creates a Release with the cartridge ROM.
The game is deliberately not deployed to GitHub Pages (the Pages deploy and `.nojekyll` were removed by the
user's decision; ignore older notes about Pages); `gilgamesh64/web/` is only served locally.

## Other gotchas

- ares harness: emulation runs at ~25-50% speed in containers, so hold inputs >=0.35-0.5 s, but >~0.5 s triggers
  X11 auto-repeat (START toggles pause twice); wait ~30 s after boot before input; `START` also advances
  dialogue; never run two ares instances at once (halves speed, scripted inputs miss). `--kiosk` segfaults;
  use `--no-file-prompt`. Recordings -> real time: `crop=625:480:84:57,mpdecimate=hi=64:lo=32:frac=0,setpts=N/30/TB`.
- Cloud-container egress: unpkg/jsDelivr/cdnjs, GitHub archive URLs and `api.github.com` were blocked; `git clone`,
  npm registry, PyPI, apt worked. Emscripten's zlib port download is blocked: pre-seed
  `emsdk/upstream/emscripten/cache/ports/zlib/zlib-1.2.13` (tag `v1.2.13`) plus a `.emscripten_url` marker.
- Root `.gitignore` ignores `*.png` except `gilgamesh64/screenshots/*.png`; other PNGs need `git add -f`.
- Licences: EmulatorJS GPL-3.0, mupen64plus GPL-2.0 (ship `web/emulator/` with any hosted copy); fonts CC0;
  story text paraphrases the public-domain epic; game code has no licence chosen yet.
