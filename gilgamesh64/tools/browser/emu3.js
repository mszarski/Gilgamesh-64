const { chromium } = require('playwright');
(async () => {
  const [core, rom, out, waitS, opts] = process.argv.slice(2);
  setTimeout(() => { console.log('HARD EXIT'); process.exit(0); }, (+waitS + 40) * 1000);
  const b = await chromium.launch({ args: ['--use-gl=angle', '--use-angle=swiftshader', '--enable-unsafe-swiftshader'] });
  const p = await b.newPage({ viewport: { width: 640, height: 480 } });
  const logs = []; const t0 = Date.now();
  p.on('console', m => logs.push(((Date.now()-t0)/1000).toFixed(1) + ' ' + m.text().slice(0, 170)));
  p.on('pageerror', e => logs.push('PAGEERROR ' + e.message));
  let url = `http://localhost:8099/emu.html?core=${core}&rom=${rom}`; if (opts) url += '&opts=' + encodeURIComponent(opts);
  await p.goto(url);
  await new Promise(r => setTimeout(r, +waitS * 1000));
  console.log(logs.filter(l => /libretro|PAGEERROR|rsp|RSP|rdp|RDP|DBG/.test(l) && !/Translation/.test(l)).slice(-(+process.env.NLOG||14)).join('\n'));
  try { await p.screenshot({ path: out, timeout: 25000 }); console.log('shot ok'); } catch (e) { console.log('shot failed: ' + e.message.slice(0, 80)); }
  process.exit(0);
})();
