const { chromium } = require('playwright');
(async () => {
  const [rom] = process.argv.slice(2);
  setTimeout(() => process.exit(0), 120000);
  const b = await chromium.launch({ args: ['--use-gl=angle', '--use-angle=swiftshader', '--enable-unsafe-swiftshader', '--autoplay-policy=no-user-gesture-required'] });
  const p = await b.newPage({ viewport: { width: 640, height: 480 } });
  const fps = [];
  p.on('console', m => { const r = /\[perf\].*fps ([0-9.]+)/.exec(m.text()); if (r) fps.push(+r[1]); });
  await p.goto('http://localhost:8099/emu.html?core=mupen64plus_next&rom=' + rom + '&opts=' + encodeURIComponent(process.env.OPTS || '{"mupen64plus-rdp-plugin":"angrylion","mupen64plus-rsp-plugin":"parallel","mupen64plus-angrylion-vioverlay":"Unfiltered"}'));
  await p.waitForTimeout(15000);
  await p.keyboard.down('Enter'); await p.waitForTimeout(400); await p.keyboard.up('Enter'); await p.waitForTimeout(10000);
  const f = () => p.evaluate(() => EJS_emulator.gameManager.functions.getFrameNum());
  const n0 = fps.length, f0 = await f(); await p.waitForTimeout(40000); const f1 = await f();
  const vi = (f1 - f0) / 40, g = fps.slice(n0); const gf = g.length ? g.reduce((a, c) => a + c) / g.length : NaN;
  console.log(`${rom.padEnd(16)} speed ${(100 * vi / 60).toFixed(0).padStart(3)}% of real time | game ${gf.toFixed(1)} fps (emulated) | seen ${(gf * vi / 60).toFixed(1)} fps`);
  await p.screenshot({ path: 'b2_' + rom + '.png' });
  process.exit(0);
})();
