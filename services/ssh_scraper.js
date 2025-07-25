const https = require('https');

function fetchSshAccounts(callback) {
  const options = {
    hostname: 'sshkit.com',
    port: 443,
    path: '/',
    method: 'GET'
  };

  const req = https.request(options, res => {
    let data = '';

    res.on('data', chunk => {
      data += chunk;
    });

    res.on('end', () => {
      // For now, just return the raw HTML
      callback(null, data);
    });
  });

  req.on('error', error => {
    callback(error, null);
  });

  req.end();
}

module.exports = { fetchSshAccounts };
