// node audiocheck.js <rom> <seconds> '<opts>' : frames + audio frames queued to WebAudio every 5s, detects renderer crash
const { chromium } = require('playwright');
(async () => {
  const [rom, secs, opts] = process.argv.slice(2);
  const b = await chromium.launch({ args: ['--use-gl=angle', '--use-angle=swiftshader', '--enable-unsafe-swiftshader', '--autoplay-policy=no-user-gesture-required'] });
  const p = await b.newPage({ viewport: { width: 640, height: 480 } });
  await p.addInitScript(() => {
    window.__aud = { frames: 0, bufs: 0, rate: 0 };
    const AC = window.AudioContext;
    const orig = AC.prototype.createBuffer;
    AC.prototype.createBuffer = function (ch, n, rate) { window.__aud.frames += n; window.__aud.bufs++; window.__aud.rate = rate; return orig.call(this, ch, n, rate); };
  });
  let crashed = false; p.on('crash', () => { crashed = true; console.log('PAGE CRASHED'); });
  await p.goto(`http://localhost:8099/emu.html?core=mupen64plus_next&rom=${rom}&opts=` + encodeURIComponent(opts));
  let lastF = 0;
  for (let t = 5; t <= +secs && !crashed; t += 5) {
    await p.waitForTimeout(5000);
    const r = await p.evaluate(() => [EJS_emulator.gameManager.functions.getFrameNum(), window.__aud.frames, window.__aud.bufs, window.__aud.rate]).catch(e => null);
    if (!r) { console.log(t + 's eval failed'); continue; }
    console.log(`${t}s frames=${r[0]} (+${((r[0]-lastF)/5).toFixed(1)}/s) audioFrames=${r[1]} (${(r[1]/Math.max(r[3],1)).toFixed(1)}s of audio @${r[3]}Hz) buffers=${r[2]}`); lastF = r[0];
  }
  await b.close(); process.exit(0);
})();
