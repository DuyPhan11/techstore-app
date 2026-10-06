// Isolated UI verification: serves frontend against the test backend on 8081.
const http = require('node:http');
const fs = require('node:fs');
const path = require('node:path');
const root = path.resolve(__dirname, '../frontend');
const types = { '.html': 'text/html; charset=utf-8', '.js': 'text/javascript; charset=utf-8', '.css': 'text/css; charset=utf-8', '.png': 'image/png', '.svg': 'image/svg+xml' };
http.createServer((req, res) => {
    const pathname = new URL(req.url, 'http://localhost').pathname;
    let file;
    try { file = path.resolve(root, '.' + decodeURIComponent(pathname === '/' ? '/index.html' : pathname)); }
    catch { res.writeHead(400).end(); return; }
    if (!file.startsWith(root + path.sep)) { res.writeHead(403).end(); return; }
    fs.readFile(file, (error, data) => {
        if (error) { res.writeHead(404).end(); return; }
        if (path.extname(file) === '.html') data = data.toString().replace('<head>', '<head><meta name="api-base-url" content="http://127.0.0.1:8081/api/v1">');
        res.writeHead(200, { 'Content-Type': types[path.extname(file)] || 'application/octet-stream', 'Cache-Control': 'no-store' }).end(data);
    });
}).listen(5501, '127.0.0.1', () => console.log('Test UI: http://127.0.0.1:5501'));
