#!/bin/bash
# Incremental rebuild of mupen64plus_next WASM core + EJS package
set -e
S="${S:?set S to the work dir holding emsdk/, ejs-m64/, ejs-retroarch/, corepkg/, site/}"
source $S/emsdk/emsdk_env.sh >/dev/null 2>&1
cd $S/ejs-m64
emmake make -j4 platform=emscripten INITIAL_HEAP=268435456 AUTO_MEMORY_GROWTH=1 LLE=1 HAVE_THR_AL=${THR_AL:-1} HAVE_PARALLEL_RSP_INTERP=1 > $S/m64_inc.log 2>&1 || { tail -30 $S/m64_inc.log; exit 1; }
cp mupen64plus_next_libretro_emscripten.bc $S/ejs-retroarch/libretro_emscripten.a
cd $S/ejs-retroarch
rm -f mupen64plus_next_libretro.js mupen64plus_next_libretro.wasm
EMCC_CFLAGS="-sASYNCIFY_REMOVE=@$S/asyncify_remove.json" emmake make -f Makefile.emulatorjs HAVE_7ZIP=1 HAVE_CHD=1 HAVE_THREADS=0 PTHREAD_POOL_SIZE=0 ASYNC=1 HAVE_OPENGLES3=1 STACK_SIZE=134217728 INITIAL_HEAP=536870912 HAVE_AL=0 HAVE_RWEBAUDIO=1 LIGHT_DEBUG=0 TARGET=mupen64plus_next_libretro.js -j4 > $S/ra_inc.log 2>&1 || { tail -30 $S/ra_inc.log; exit 1; }
cp mupen64plus_next_libretro.js mupen64plus_next_libretro.wasm $S/corepkg/
cd $S/corepkg
python3 -c "
import py7zr,os
out='$S/site/data/cores/mupen64plus_next-wasm.data'
if os.path.exists(out): os.remove(out)
with py7zr.SevenZipFile(out,'w') as z:
    for f in ['mupen64plus_next_libretro.js','mupen64plus_next_libretro.wasm','core.json','build.json','license.txt']: z.write(f,f)
"
echo REBUILD OK
