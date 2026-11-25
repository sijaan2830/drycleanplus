// Captures App Store iPhone screenshots (1179x2556 = 393x852pt @3x) from the
// web build of tool/app_store_screenshots/screenshot_main.dart.
//
// Usage: node tool/app_store_screenshots/capture.mjs [shot ...]
// Needs: build/web_screenshots (flutter build web -t tool/app_store_screenshots/screenshot_main.dart -o build/web_screenshots)
import { createServer } from 'node:http';
import { readFile, mkdir, writeFile, mkdtemp } from 'node:fs/promises';
import { spawn } from 'node:child_process';
import { join, extname, resolve } from 'node:path';
import { tmpdir } from 'node:os';

const ROOT = resolve('build/web_screenshots');
const OUT = resolve('app_store_screenshots_iphone');
const CHROME = 'C:/Program Files/Google/Chrome/Application/chrome.exe';
const PORT = 8765;
const DEBUG_PORT = 9333;
const WIDTH = 393, HEIGHT = 852, SCALE = 3;

// name -> [query string, wait ms]
const SHOTS = {
  '01_onboarding': ['shot=onboarding&home=dark', 15000],
  '02_home': ['shot=home', 15000],
  '03_prices': ['shot=prices', 15000],
  '04_service_overview': ['shot=service&home=dark', 15000],
  '05_tracking': ['shot=tracking', 15000],
  '06_prepaid': ['shot=prepaid', 15000],
  '07_select_services': ['shot=select_services&home=dark', 15000],
  '08_more': ['shot=more', 15000],
  '09_faq': ['shot=faq', 15000],
  '10_membership': ['shot=membership', 15000],
};

const MIME = {
  '.html': 'text/html', '.js': 'text/javascript', '.mjs': 'text/javascript',
  '.json': 'application/json', '.wasm': 'application/wasm', '.png': 'image/png',
  '.jpg': 'image/jpeg', '.svg': 'image/svg+xml', '.ttf': 'font/ttf', '.otf': 'font/otf',
  '.css': 'text/css', '.ico': 'image/x-icon',
};

const server = createServer(async (req, res) => {
  let p = decodeURIComponent(new URL(req.url, 'http://x').pathname);
  if (p.endsWith('/')) p += 'index.html';
  const file = join(ROOT, p);
  if (!file.startsWith(ROOT)) { res.writeHead(403).end(); return; }
  try {
    const data = await readFile(file);
    res.writeHead(200, { 'Content-Type': MIME[extname(file)] || 'application/octet-stream' });
    res.end(data);
  } catch {
    res.writeHead(404).end();
  }
}).listen(PORT);

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

const profile = await mkdtemp(join(tmpdir(), 'dcp-shots-'));
const chrome = spawn(CHROME, [
  '--headless=new', `--remote-debugging-port=${DEBUG_PORT}`, `--user-data-dir=${profile}`,
  '--no-first-run', '--no-default-browser-check', '--hide-scrollbars',
  '--force-color-profile=srgb', `--window-size=${WIDTH},${HEIGHT}`, 'about:blank',
], { stdio: 'ignore' });

let wsUrl;
for (let i = 0; i < 50 && !wsUrl; i++) {
  try {
    const targets = await (await fetch(`http://127.0.0.1:${DEBUG_PORT}/json/list`)).json();
    wsUrl = targets.find((t) => t.type === 'page')?.webSocketDebuggerUrl;
  } catch { /* not up yet */ }
  if (!wsUrl) await sleep(200);
}
if (!wsUrl) throw new Error('Chrome did not start');

const ws = new WebSocket(wsUrl);
await new Promise((r) => ws.addEventListener('open', r, { once: true }));
let nextId = 1;
const pending = new Map();
const consoleLines = [];
ws.addEventListener('message', (ev) => {
  const msg = JSON.parse(ev.data);
  if (msg.id && pending.has(msg.id)) {
    const { resolve: ok, reject } = pending.get(msg.id);
    pending.delete(msg.id);
    msg.error ? reject(new Error(msg.error.message)) : ok(msg.result);
  } else if (msg.method === 'Runtime.consoleAPICalled') {
    consoleLines.push(msg.params.args.map((a) => a.value ?? a.description).join(' '));
  }
});
const send = (method, params = {}) => new Promise((ok, reject) => {
  const id = nextId++;
  pending.set(id, { resolve: ok, reject });
  ws.send(JSON.stringify({ id, method, params }));
});

await send('Page.enable');
await send('Runtime.enable');
await send('Emulation.setDeviceMetricsOverride', {
  width: WIDTH, height: HEIGHT, deviceScaleFactor: SCALE, mobile: true,
  screenWidth: WIDTH, screenHeight: HEIGHT,
});
await send('Emulation.setTouchEmulationEnabled', { enabled: true, maxTouchPoints: 5 });
await send('Emulation.setUserAgentOverride', {
  userAgent: 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.0 Mobile/15E148 Safari/604.1',
  platform: 'iPhone',
});

await mkdir(OUT, { recursive: true });
const wanted = process.argv.slice(2);
for (const [name, [query, wait]] of Object.entries(SHOTS)) {
  if (wanted.length && !wanted.some((w) => name.includes(w))) continue;
  consoleLines.length = 0;
  await send('Page.navigate', { url: `http://localhost:${PORT}/?${query}&t=${Date.now()}` });
  await sleep(wait);
  const { data } = await send('Page.captureScreenshot', { format: 'png', captureBeyondViewport: false });
  const file = join(OUT, `iPhone_6.3in_${name}.png`);
  await writeFile(file, Buffer.from(data, 'base64'));
  console.log('saved', file);
  const errs = consoleLines.filter((l) => /error|exception/i.test(l));
  if (errs.length) console.log('  console:', errs.slice(0, 3).join(' | ').slice(0, 400));
}

ws.close();
chrome.kill();
server.close();
