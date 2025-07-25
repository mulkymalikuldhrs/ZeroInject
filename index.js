const http = require('http');
const fs = require('fs');
const path = require('path');

const sshScraper = require('./services/ssh_scraper');

const sniScanner = require('./services/sni_scanner');
const url = require('url');

const server = http.createServer((req, res) => {
  const parsedUrl = url.parse(req.url, true);

  if (parsedUrl.pathname === '/api/ssh-accounts') {
    sshScraper.fetchSshAccounts((error, data) => {
      if (error) {
        res.writeHead(500);
        res.end('Error fetching SSH accounts');
        return;
      }
      res.writeHead(200, { 'Content-Type': 'text/plain' });
      res.end(data);
    });
    return;
  }

  if (parsedUrl.pathname === '/api/scan-sni') {
    const host = parsedUrl.query.host;
    if (!host) {
      res.writeHead(400);
      res.end('Missing host parameter');
      return;
    }

    sniScanner.scanSni(host, (error, success) => {
      if (error) {
        res.writeHead(500);
        res.end(JSON.stringify({ host: host, success: false, error: error.message }));
        return;
      }
      res.writeHead(200, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({ host: host, success: success }));
    });
    return;
  }

  let filePath = '.' + req.url;
  if (filePath === './') {
    filePath = './public/index.html';
  }

  const extname = String(path.extname(filePath)).toLowerCase();
  const contentType = {
    '.html': 'text/html',
    '.js': 'text/javascript',
    '.css': 'text/css',
    '.json': 'application/json',
    '.png': 'image/png',
    '.jpg': 'image/jpg',
    '.gif': 'image/gif',
    '.svg': 'image/svg+xml',
  }[extname] || 'application/octet-stream';

  fs.readFile(filePath, (error, content) => {
    if (error) {
      if (error.code == 'ENOENT') {
        fs.readFile('./404.html', (error, content) => {
          res.writeHead(404, { 'Content-Type': 'text/html' });
          res.end(content, 'utf-8');
        });
      } else {
        res.writeHead(500);
        res.end('Sorry, check with the site admin for error: ' + error.code + ' ..\n');
      }
    } else {
      res.writeHead(200, { 'Content-Type': contentType });
      res.end(content, 'utf-8');
    }
  });
});

const port = process.env.PORT || 3000;
server.listen(port, () => {
  console.log(`Server running at http://localhost:${port}/`);
});
