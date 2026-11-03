// POC service for eBPF instrumentation. Node's built-in http only, so it runs on the
// stock node image with no npm install.
const http = require('http');

const PORT = 3000;
const SELF = process.env.SELF_URL || 'http://ebpf-poc-app:3000';

function json(res, status, body) {
  res.writeHead(status, { 'Content-Type': 'application/json' });
  res.end(JSON.stringify(body));
}

const server = http.createServer((req, res) => {
  if (req.url === '/healthz') return json(res, 200, { ok: true });

  if (req.url === '/api/hello') {
    return setTimeout(() => json(res, 200, { message: 'hello', secretLoaded: Boolean(process.env.APP_SECRET) }), 40);
  }

  // Calls /api/hello over the Service, so one request becomes a trace with a child call.
  if (req.url === '/api/chain') {
    return http.get(`${SELF}/api/hello`, (up) => {
      let data = '';
      up.on('data', (c) => (data += c));
      up.on('end', () => json(res, 200, { chained: true, upstream: JSON.parse(data) }));
    }).on('error', (e) => json(res, 502, { error: e.message }));
  }

  json(res, 404, { error: 'not found' });
});

server.listen(PORT, () => console.log(`[app] listening on ${PORT}`));
