const { chromium } = require('playwright');
(async () => {
  const [rom, dur] = process.argv.slice(2);
  const b = await chromium.launch({ args: ['--use-gl=angle', '--use-angle=swiftshader', '--enable-unsafe-swiftshader', '--autoplay-policy=no-user-gesture-required'] });
  const p = await b.newPage({ viewport: { width: 640, height: 480 } });
  await p.goto('http://localhost:8099/emu.html?core=mupen64plus_next&rom=' + rom + '&opts=' + encodeURIComponent('{"mupen64plus-rdp-plugin":"angrylion","mupen64plus-rsp-plugin":"parallel","mupen64plus-angrylion-vioverlay":"Unfiltered"}'));
  await p.waitForTimeout(15000);
  await p.keyboard.down('Enter'); await p.waitForTimeout(400); await p.keyboard.up('Enter'); await p.waitForTimeout(8000);
  const c = await p.context().newCDPSession(p);
  await c.send('Profiler.enable'); await c.send('Profiler.setSamplingInterval', { interval: 500 });
  await c.send('Profiler.start'); await p.waitForTimeout(+dur); const { profile } = await c.send('Profiler.stop');
  const self = {}; const dt = {};
  for (let i = 0; i < profile.samples.length; i++) dt[profile.samples[i]] = (dt[profile.samples[i]] || 0) + (profile.timeDeltas[i] || 0);
  let tot = 0; for (const n of profile.nodes) { const t = dt[n.id] || 0; tot += t; const k = n.callFrame.functionName || '(anon)'; self[k] = (self[k] || 0) + t; }
  for (const [k, v] of Object.entries(self).sort((a, b) => b[1] - a[1]).slice(0, 80)) console.log((100 * v / tot).toFixed(1).padStart(5) + '%  ' + k);
  await b.close();
})();
