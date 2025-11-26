const http = require('http');
const https = require('https');
const url = require('url');

const PORT = 5310;

function sendCORS(res) {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');
}

const server = http.createServer((req, res) => {
  const parsed = url.parse(req.url, true);
  if (req.method === 'OPTIONS') {
    sendCORS(res);
    res.writeHead(204);
    return res.end();
  }
  if (parsed.pathname === '/segment') {
    const province = parsed.query.province || '四川';
    const year = parsed.query.year || '2021';
    const category = parsed.query.category || '理科';
    const target = `https://opendata.baidu.com/api.php?fromCard=1&resource_id=50266&province=${encodeURIComponent(province)}&year=${encodeURIComponent(year)}&category=${encodeURIComponent(category)}&query=${encodeURIComponent('一分一段')}`;
    https.get(target, (resp) => {
      let data = '';
      resp.on('data', (chunk) => (data += chunk));
      resp.on('end', () => {
        sendCORS(res);
        res.writeHead(200, { 'Content-Type': 'application/json' });
        res.end(data);
      });
    }).on('error', (err) => {
      sendCORS(res);
      res.writeHead(502, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({ error: 'proxy_upstream_error', detail: String(err) }));
    });
  } else {
    sendCORS(res);
    res.writeHead(404, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ error: 'not_found' }));
  }
});

server.listen(PORT, () => {
  console.log(`Proxy listening on http://localhost:${PORT}/segment`);
});