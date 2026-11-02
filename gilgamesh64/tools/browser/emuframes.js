const { chromium } = require('playwright');
(async () => {
  const [core, rom, out, wait, opts] = process.argv.slice(2);
  const b = await chromium.launch({ args: ['--use-gl=angle', '--use-angle=swiftshader', '--enable-unsafe-swiftshader', '--autoplay-policy=no-user-gesture-required'] });
  const p = await b.newPage({ viewport: { width: 640, height: 480 } });
  let url = `http://localhost:8099/emu.html?core=${core}&rom=${rom}`; if (opts) url += '&opts=' + encodeURIComponent(opts);
  const logs=[]; p.on('console', m => logs.push(Date.now()+' '+m.text().slice(0,160))); p.on('pageerror', e => logs.push(Date.now()+' PAGEERROR '+e.message+' '+(e.stack||'').split('\n').slice(1,4).join(' | '))); const t0=Date.now(); await p.goto(url);
  for (let t = 0; t < (+wait || 30000); t += 5000) {
    await p.waitForTimeout(5000);
    const f = await p.evaluate(() => { try { return EJS_emulator.gameManager.functions.getFrameNum() + ' paused=' + EJS_emulator.paused; } catch (e) { return 'n/a ' + e.message; } });
    console.log((t + 5000) / 1000 + 's frames:', f);
  }
  await p.screenshot({ path: out }); console.log(logs.filter(l=>!/Translation|not compiled/.test(l)).slice(-12).map(l=>((+l.split(' ')[0]-t0)/1000).toFixed(1)+'s '+l.split(' ').slice(1).join(' ')).join('\n'));
  await b.close();
})();
