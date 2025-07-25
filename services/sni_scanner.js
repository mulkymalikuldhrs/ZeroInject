const tls = require('tls');

function scanSni(host, callback) {
  const options = {
    host: host,
    port: 443,
    servername: host,
    rejectUnauthorized: false // We don't need to validate the cert, just see if it connects
  };

  const socket = tls.connect(options, () => {
    socket.end();
    callback(null, true); // Success
  });

  socket.on('error', (err) => {
    callback(err, false); // Failure
  });

  socket.setTimeout(5000, () => { // 5 second timeout
    socket.destroy(new Error('Timeout'));
  });
}

module.exports = { scanSni };
