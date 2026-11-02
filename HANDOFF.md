# Gilgamesh 64: session handoff

Written at the end of the first development session (Oct 31 – Nov 2, 2026) so that a fresh session,
in a new repository, can continue without the original conversation. Everything lives under
`gilgamesh64/` (plus `.github/workflows/gilgamesh64.yml` and `.nojekyll` at the root). The rest of this
repo (`trajectory_classifier/`, `CLAUDE.md`, `AGENTS.md`) is an unrelated project.

---

## 1. Goal

Build **"Gilgamesh 64"**: an original Nintendo 64 game in the style of late-90s 3D action-adventures
(Ocarina-of-Time-like *genre*: lock-on targeting, sword combo, roll, shield, companion, dialogue boxes,
dungeon-style boss), based on **Tablet V of the Epic of Gilgamesh** (the journey to the Cedar Forest and
the fight with Humbaba). The user asked for "an n64 demo level" to start.

The user then made the requirement explicit: it must be a **real N64 ROM** that runs on an actual N64,
**and** be playable **on the web through an emulator**. A browser imitation is not the deliverable.

Success / "done" for the demo:
- A `.z64` ROM that boots on real hardware (flashcart) and accurate emulators and plays the whole level:
  three seals → cedar door → Humbaba → ending. **Status: done in emulators; never tried on real hardware.**
- A web page where anyone can play the same ROM in a browser at a usable speed. **Status: works, but
  below full speed (≈57% of real time in the test container).**
- Distributable: GitHub Pages / Releases via GitHub Actions. **Status: set up, never run on GitHub.**
- Must stay an *original* game (no Zelda assets, names, logos or recreated levels); this was a deliberate
  constraint throughout.

## 2. Current state (latest results)

### What exists

| Piece | Path | State |
|---|---|---|
| Browser prototype (three.js, not the deliverable) | `gilgamesh64/index.html` | Playable, kept as a design reference. Loads three@0.160.0 from jsDelivr. |
| N64 game source (C, libdragon preview + tiny3d) | `gilgamesh64/n64/` | Complete demo level, builds to a 320 KB ROM. |
| Web emulator page | `gilgamesh64/web/` | Playable static site (EmulatorJS 4.2.3 + patched mupen64plus core + browser ROM). |
| Patched emulator core source | `gilgamesh64/web/emulator/` | Full diff vs the EmulatorJS mupen64plus-libretro-nx fork + build notes + Asyncify list. |
| Tooling (ares harness, browser benchmarks, core rebuild) | `gilgamesh64/tools/` | Copied from the workspace at handoff. See its README. |
| CI | `.github/workflows/gilgamesh64.yml` | Written and dry-run locally; **never executed on GitHub**. |
| Screenshots | `gilgamesh64/screenshots/n64-*.png` | Committed at handoff (were gitignored). |
| Published artifact | https://claude.ai/artifact/PbrRY4j8A3nMaf8oPKYJa6 | Private (owner only). Version 3 = the "faster build". |
| Gameplay video (3:52, silent, 9.4 MB) | *not committed* | Lived only in the ephemeral workspace; will be lost. Recreate with `tools/ares/record_all.sh` + `record_2.sh`. |

### Game content (N64 build)
Title screen (camera orbit) → 5-line intro narration → Steppe of Uruk (walls + lapis gate, ziggurat,
palms, stele, pots) → three Seals of Shamash: **Dawn** on a pedestal by the oasis (14.4, 19.5), **Noon**
at the scorpion-men camp (-25.5, -1.5, 3 scorpion-men), **Dusk** appears on the altar at (14, -10) once
the 3 lions in the stone ring die → cedar door cutscene at z = -22 → Cedar Forest → Humbaba in the
clearing (centre (0, -52), radius 17) → mercy dialogue → "Tablet V complete" screen with time + lapis.
Player: lock-on (Z/L), 3-hit combo (B), roll/talk/read (A), shield (R) that reflects fireballs, C-left/right
camera. Enkidu follows and gives context hints. Humbaba: walk, ground slam (shockwave, roll through),
charge (stuns him if he hits the arena edge; stun doubles damage), fireballs (reflect with shield),
phase 2 at half HP (24 HP total). Hearts/lapis from pots and enemies, game over → continue at checkpoint,
pause screen with quest list. Music + SFX from an in-code software synth.

### Verified by actually playing (scripted input in ares)
Every feature above has been exercised **from debug start positions**: oasis seal pickup, scorpion camp
(all killed, lapis drop), lion ring → Dusk seal reveal, Dusk pickup → door cutscene → door opens,
stele read, Enkidu talk, gate "Check" without seals, pots, pause/resume, game over → continue,
Humbaba charge-stun, shield reflect, **Humbaba beaten at normal health** (player ended at 2 HP) and in
the invincible build through to the ending screen.
**Never done:** one uninterrupted run title → ending; running on a real N64; opening the published
artifact or Pages site in a real desktop browser.

### Performance numbers
- **Cartridge ROM in ares** (true N64 timing): **26–30 fps** at the start area with the 30 fps cap; world
  ≈2,000–2,900 triangles drawn per frame (logged as `[perf] world triangles drawn: N, fps F`). Before the
  synth fix the game ran at **~3–5 fps on "hardware"** (see Dead ends / Gotchas).
- **Web page in this container** (headless Chromium, SwiftShader, 4 vCPUs, no GPU), measured with
  `tools/browser/bench2.js` at the steppe start:
  - before this session's perf work: speed 74% of real time but the game only drew 3.1 fps → **2.3 fps seen**
  - after (synth rewrite, VI filter off, LOD, culling, baked light, Asyncify removal): **speed 57%,
    game 20 fps (cap), ≈11.3 fps seen**; forest ≈52–55%.
  - A normal desktop browser should be faster; phones will be slow. Never measured on a real machine.
- Static world ≈10k triangles baked into 20 m chunks (it was 17.9k before cuts).

## 3. Decisions and reasons

- **Built a three.js browser prototype first**, because a real ROM needed toolchain access I wasn't
  sure of. The user corrected course ("make it so it can be played on an n64… use an emulator… make that
  work on web"). The prototype is kept only as a reference; don't extend it.
- **libdragon (preview branch) + tiny3d** instead of the official SDK: open source, modern, good
  homebrew 3D (tiny3d's RSP microcode). Pinned: libdragon `39d0d6096130836a65710da6730290701d060272`,
  tiny3d `f2eccc3998967f1915be58d52f1c5bb6d5598a8c`.
- **Everything procedural in C** (meshes, level, characters, music) — no model/texture pipeline, no GLTF,
  no textures except two CC0 pixel fonts (`monogram`, `abaddon`). Keeps the repo self-contained and the
  look deliberately low-poly/flat-shaded.
- **Units:** game logic in metres; renderer in decimetres (`RS = 10`), because tiny3d's fixed-point
  pipeline prefers larger numbers. World meshes are baked in RS units; character/prop meshes are authored
  in **centimetres** with builder unit 1 and scaled by `RS*0.01` at draw time.
- **ares as the reference emulator** for testing (most accurate, what libdragon devs use), run headless
  under Xvfb with Mesa lavapipe for paraLLEl-RDP.
- **Web: EmulatorJS + mupen64plus_next rebuilt from source** with low-level RSP and angrylion software RDP,
  single-threaded (no SharedArrayBuffer, because the claude.ai artifact host and GitHub Pages can't send
  COOP/COEP headers). Rejected: stock EmulatorJS cores (can't run libdragon), parallel_n64 (too old),
  threads build (header requirements), GLideN64 (see Dead ends).
- **parallel-rsp with a new portable interpreter** (the agent wrote `rsp_interp.cpp`; upstream parallel-rsp
  only has JIT backends that can't run in WASM) is the recommended RSP; cxd4 also works.
- **Separate web ROM build:** `-DGAME_FPS=20 -DVI_FILTERS=FILTERS_RESAMPLE` (20 fps like Ocarina; no VI
  AA/dedither, which costs ~40% of angrylion time). Cartridge build keeps 30 fps and full VI filtering.
- **Debug options are compile-time flags** (`EXTRA_CFLAGS`) so release ROMs contain none of them.
- **Artifact publishing:** binaries renamed to `.wasm` (host only serves standard web types) and mapped back
  with `EJS_paths` + a fetched blob URL for the ROM.
- **Distribution:** user liked the GitHub Actions idea; then asked whether simply pointing branch-based
  Pages at this branch works — it does (`/ (root)` → `…/gilgamesh64/web/`), so `.nojekyll` was added. The
  workflow's `deploy-pages` job only works with Pages source = "GitHub Actions"; the two approaches conflict.

## 4. Dead ends (don't repeat)

- **Stock EmulatorJS N64 cores:** `mupen64plus_next` from npm has only HLE RSP + GLideN64 (the strings
  "cxd4"/"angrylion" in the wasm are just option labels); libdragon's custom RSP code can't run. `parallel_n64`
  is old: unknown CIC, then hangs after ~538 frames.
- **Swapping libdragon IPL3 revisions (r7–r9, compat, warm-boot hack)** to please the emulator: the boot
  code was never the problem; the dev IPL3 showed it boots fine once the emulator's RDRAM model was fixed.
- **GLideN64 (GPU) for libdragon:** after extending the DP-interrupt fix to GLideN64, it boots but corrupts
  RDRAM (font data overwritten with `EE69EE69`) via framebuffer copy-back; with copy-backs off it's a black
  screen (libdragon's VI scans out from RDRAM). Would be a project of its own.
- **Additive blending on the RDP** for glow effects: the blender wraps on overflow → purple bands over bright
  sand. Use alpha blending (`RDPQ_BLENDER_MULTIPLY`). Seal light-beams were removed for the same reason.
- **Assuming the scene was the bottleneck:** fog off / no HUD / shorter fog changed web speed by ≤3 points.
  The real costs were the synth (CPU), the VI filter (angrylion), the RSP interpreter and the rasterizer.
- **Measuring "emulated VI frames per second" alone:** it went *down* when the game got faster (the game
  started reaching its frame cap, so more work per emulated second). Use `bench2.js`, which reports speed,
  game fps and seen fps.
- **Unpkg/jsDelivr/cdnjs from the container** (blocked by the egress proxy); npm registry works, so three.js
  for local testing was fetched from `registry.npmjs.org` and routed in Playwright.
- **Running two ares instances in parallel** halves speed and makes timed input scripts miss their windows.

## 5. Gotchas

**Network / environment (the original cloud container)**
- `git clone` from GitHub works; GitHub archive/tarball URLs and `api.github.com` are 403; the libdragon
  toolchain `.deb` release asset *did* download; npm registry, PyPI, apt, storage.googleapis work.
- Emscripten's zlib port download is blocked → pre-seed `emsdk/upstream/emscripten/cache/ports/zlib/zlib-1.2.13`
  (git clone tag `v1.2.13`) plus a `.emscripten_url` marker file containing the port URL.
- Claude Code **auto mode refused** installing the toolchain `.deb` / cloning third-party code ("code from
  external") even after the user approved in chat; the user switched to **Accept edits** mode to allow it.

**libdragon / tiny3d / N64**
- Vertex positions are int16: the original "giant brown slabs" bug was character meshes authored in cm but
  built with unit 100 (overflow). Keep `mb_new(1)` for cm meshes, `mb_new(RS)` for world meshes.
- `mb_bake` batches ≤64 vertices (tiny3d cache is 70) and pads to even counts (vertices are packed in pairs).
- Geometry is CCW-outward everywhere; `T3D_FLAG_CULL_BACK` is on. Mirrored transforms flip winding.
- Static world vertex colours are **pre-lit** (`light_color()` in `mesh.c`) and drawn with
  `T3D_FLAG_NO_LIGHT`; actors use real lights. The two light palettes must stay in sync
  (`mesh.c` ↔ `main.c`, steppe→forest blend by z).
- tiny3d fog uses vertex/shade alpha → disable fog for the alpha-blended shadow/effects pass.
- `rdpq_text_print` with `WRAP_WORD` asserts if `width == 0` (crashed the HUD once).
- `display_set_fps_limit(GAME_FPS)` caps the game; `display_get_fps()` is logged every 120 frames.
- The original synth did `expf/powf/sinf` per sample per voice at 22.05 kHz → nearly the whole VR4300.
  The current synth is incremental at 16 kHz. Don't reintroduce per-sample transcendental math.
- VI filter `FILTERS_RESAMPLE_ANTIALIAS_DEDITHER` is free on hardware but ~40% of angrylion's time.
- libdragon ROMs need **ares or Gopher64** (or the patched core); older mupen64plus/Project64 builds fail.
- The dev IPL3 (`libdragon/boot`, built without `PROD=1`) logs boot progress over ISViewer — great for
  diagnosing emulators.

**Web emulator (EmulatorJS / mupen64plus core)**
- `EJS_defaultOptions` is **ignored unless `EJS_disableLocalStorage = true`**.
- Required core options: `mupen64plus-rdp-plugin: angrylion`, `mupen64plus-rsp-plugin: parallel`
  (or `cxd4`), plus `mupen64plus-angrylion-vioverlay: Unfiltered` for speed.
- Bugs fixed in the core (all in `web/emulator/mupen64plus-libretro-nx-libdragon.patch`): upstream RDRAM/RI
  model; 64-bit uncached addresses (`0x90000000…`) truncated → TLB exception before `main()`; emulator-detect
  opcode as no-op; LLD/SCD; MI repeat mode; RSP completion/interrupt forwarding for non-standard tasks;
  spurious DP interrupt on every `DPC_END` write (libdragon asserts) — now only on real SYNC_FULL for
  angrylion/parallel/GLideN64; cxd4 vector load/store accuracy; RSP DMA wraparound in DMEM/IMEM; 24-bit
  `DPC_START/END`; angrylion forced to 1 thread without pthreads; **AI DMA address not masked** (audio read
  and byte-swapped ~2.6 GB past RDRAM → renderer crash with no JS error); Cause register exception code
  clobbered by pending interrupts (broke libdragon's nested FPU-enable exception → audio froze).
- The core Makefile **doesn't track header dependencies**: after editing a `.h`/`.def`, touch the `.c` files.
- `ASYNCIFY_REMOVE=@asyncify_remove.json` (all angrylion + parallel-rsp functions) at link time is safe
  because the only yield point is `new_vi()` → `retro_return()` → `co_switch` on the CPU path.
- The core also needs `EJS_paths` for renamed files; `EJS_gameUrl` must be a string (blob URL), not a Blob,
  and `EJS_gameName='gilgamesh64.z64'` keeps the extension.
- Headless Chromium blocks audio until a gesture; tests use `--autoplay-policy=no-user-gesture-required`.

**ares test harness**
- Emulation runs at roughly 25–50% speed in the container, so: short taps get missed (hold ≥0.35–0.5 s),
  holds >~0.5 s trigger X11 auto-repeat (START toggled pause twice), boot takes longer under load (wait 30 s
  before the first input), and `START` also advances dialogue. A near Enkidu/steles/gate means Talk/Read/Check.
- Screen recordings are converted to real time with
  `crop=625:480:84:57,mpdecimate=hi=64:lo=32:frac=0,setpts=N/30/TB` (works because the game is frame-capped).
- `--kiosk` segfaults in that ares build; the runner uses `--no-file-prompt`.

**Repo / publishing**
- Root `.gitignore` has `*.png` and `n64/.gitignore` has `*.z64`: screenshots needed `git add -f`; build
  output isn't committed except `web/gilgamesh64.z64` (the browser build).
- Branch-based Pages needs `.nojekyll` (added). Pages on a private repo needs a paid plan.
- `CLAUDE.md` describes the unrelated trajectory project and asks for `bd` issue tracking; it was not used
  for this project and must not be edited from here (user's instruction).

## 6. User preferences (from this conversation)

- Wants the **real thing**: a genuine N64 ROM playable on hardware and in an emulator on the web — not a
  web remake. Original content only.
- Happy to approve third-party installs (toolchains, emulators, npm/apt packages); runs the session in
  **Accept edits** mode when that's needed. Explain what's blocked and how to unblock instead of working
  around safety checks.
- Likes **parallel work** ("can we do this in parallel… running an emulator not on the web and then in
  parallel getting to work on the web") — background agents for independent tracks worked well.
- Wants things **actually tested by playing** ("test the full boss fight", "keep playing", "play more"),
  with screenshots/logs as evidence, and honest reporting of what was *not* verified.
- Asked for the published web artifact to be **updated with the latest build** after changes.
- Asked for speed ("make it run faster on the web") and practical distribution help.
- Commits go to the working branch and are pushed; **no PR unless asked** (a PR was offered, never requested).
- Don't edit `CLAUDE.md`.

## 7. Next steps (priority order)

1. **Move to the new repo**: carry over `gilgamesh64/`, `.github/workflows/gilgamesh64.yml`, `.nojekyll`.
   Paths in the workflow assume `gilgamesh64/` at the repo root — adjust if the new repo flattens it.
2. **Run CI on GitHub once** (workflow_dispatch) and fix whatever breaks (cache restore into `/opt/libdragon`,
   Pages permissions). Decide Pages source: "GitHub Actions" (workflow deploys a fresh browser ROM) vs a
   branch (commit `web/gilgamesh64.z64` manually); remove `deploy-pages` if branch-based.
3. **Verify in real browsers**: open the Pages site / artifact on a desktop (Chrome, Firefox) and a phone;
   measure speed with the page's frame counter (or `EJS_emulator.gameManager.functions.getFrameNum()`).
   Nothing has been tested outside headless Chromium.
4. **One uninterrupted playthrough** (title → ending) in ares, and ideally **real hardware** (EverDrive 64 /
   SummerCart64) for the cartridge build.
5. **Web speed** (currently ≈57% real time here): biggest remaining costs are the RSP interpreter (~25–28%)
   and angrylion's `edgewalker_for_prims` (~22–24%). Options: faster RSP interpreter dispatch; a threads
   build of the core for hosts that can send COOP/COEP (itch.io has a SharedArrayBuffer option); fewer
   character parts / more LOD; revisit GLideN64 only as a separate project.
6. **Polish**: sword trail looks greenish/dithered (now alpha-blended — check its look); input feel at 20 fps;
   Humbaba charge-stun rarely happens unless the player keeps distance; area/HUD text over dialogue.
7. **Content**: Tablet VI (the Bull of Heaven) is teased on the ending screen.
8. **Gameplay video with audio** (needs frame-exact capture or real-time emulation) and decide whether to
   commit the video.

Open questions for the user: licence for the game code (none yet; suggested MIT); hosting choice
(GitHub Pages vs itch.io); whether to keep the three.js prototype in the new repo; keep the 20 fps web cap?

## 8. Pointers

**Repos / branches / URLs**
- Current repo/branch: `mszarski/claude_playground`, branch `claude/affectionate-einstein-rkvv78` (default
  branch `main`; none of this work is on `main`).
- Artifact (private): https://claude.ai/artifact/PbrRY4j8A3nMaf8oPKYJa6 — published files: `index.html`,
  `data/...`, `data/cores/mupen64plus_next-core.wasm` (the 7z core, renamed), `gilgamesh64-rom.wasm` (ROM).
- Planned Pages URL from this repo: https://mszarski.github.io/claude_playground/gilgamesh64/web/ (branch
  source) or `…/claude_playground/` (Actions source).
- libdragon: https://github.com/DragonMinded/libdragon (preview) @ `39d0d60…`; toolchain:
  `https://github.com/DragonMinded/libdragon/releases/download/toolchain-continuous-prerelease/gcc-toolchain-mips64-x86_64.deb`
  (installs to `/opt/libdragon`, self-contained; needs zlib/zstd).
- tiny3d: https://github.com/HailToDodongo/tiny3d @ `f2eccc3…` (only `make` is needed; uses `build/libt3d.a`).
- EmulatorJS 4.2.3 (npm `@emulatorjs/emulatorjs`); core fork https://github.com/EmulatorJS/mupen64plus-libretro-nx
  base commit `4a3925d`; RetroArch fork https://github.com/EmulatorJS/RetroArch (`Makefile.emulatorjs`);
  build scripts https://github.com/EmulatorJS/build; emsdk 3.1.74; upstream https://github.com/mupen64plus/mupen64plus-core
  (source of the RDRAM/RI files).
- ares https://github.com/ares-emulator/ares @ `e9639eb`, built with `ARES_CORES=n64`, Release, SDL3 3.2.24
  built from source (`release-3.2.24`), run with lavapipe Vulkan under Xvfb.

**Key source files** (`gilgamesh64/n64/src/`)
- `main.c` — init, input, camera, cutscenes, story text, render loop, debug start flags, `GAME_FPS`, `VI_FILTERS`.
- `actors.c` — part-based models, player/Enkidu/enemies/Humbaba/pickups/pots/projectiles/particles, LOD.
- `world.c` — `height_at()`, colliders, `camera_push()`, chunked level geometry, doors.
- `mesh.c` — procedural mesh builder, batching/baking, baked lighting, matrix pool.
- `ui.c` — HUD, dialogue (incl. `DEBUG_AUTODIALOG`), overlays. `synth.c` — music/SFX. `game.h` — shared API.

**Build commands**
```bash
export N64_INST=/opt/libdragon PATH=/opt/libdragon/bin:$PATH
make -C gilgamesh64/n64 T3D_INST=/path/to/tiny3d                       # cartridge ROM
make -C gilgamesh64/n64 T3D_INST=/path/to/tiny3d clean
make -C gilgamesh64/n64 T3D_INST=/path/to/tiny3d EXTRA_CFLAGS="-DGAME_FPS=20 -DVI_FILTERS=FILTERS_RESAMPLE"   # browser ROM -> copy to gilgamesh64/web/gilgamesh64.z64
python3 -m http.server -d gilgamesh64/web 8098                          # serve the web page locally
```
Debug flags (via `EXTRA_CFLAGS`): `DEBUG_POS` + `DEBUG_POS_X/Z` (start anywhere), `DEBUG_GATE` +
`DEBUG_GATE_X/Z` (all seals, door open), `DEBUG_SEALS=<bitmask>`, `DEBUG_DUSK` (ring cleared, Dusk seal
out), `DEBUG_GOD` (no damage, logs hits), `DEBUG_AUTODIALOG` (timed dialogue), `DEBUG_NOAUDIO`,
`DEBUG_NOFOG`, `DEBUG_FOGFAR=<m>`, `DEBUG_NOACTORS`, `DEBUG_NOWORLD`, `DEBUG_NOHUD`, `NO_SKY`.
Useful log lines (ISViewer → ares log / browser console): `[fight] …`, `[play] …`, `[perf] world triangles drawn: N, fps F`.

**Web core rebuild** (from the workspace layout `S/{emsdk,ejs-m64,ejs-retroarch,corepkg,site}`):
`gilgamesh64/tools/browser/rebuild_core.sh` — `emmake make … LLE=1 HAVE_THR_AL=1 HAVE_PARALLEL_RSP_INTERP=1`,
link with `Makefile.emulatorjs` (ASYNC=1, no threads, `EMCC_CFLAGS=-sASYNCIFY_REMOVE=@asyncify_remove.json`),
then 7z-pack `mupen64plus_next_libretro.{js,wasm}` + `core.json`, `build.json`, `license.txt` into
`mupen64plus_next-wasm.data`. Takes ~5 min incremental.

**Licences**: EmulatorJS GPL-3.0 (`web/data/LICENSE-EmulatorJS.txt`), mupen64plus GPL-2.0 — keep
`web/emulator/` (corresponding source) with any hosted copy. Fonts CC0. Story text is my paraphrase of the
public-domain epic. Game code: no licence chosen yet.
