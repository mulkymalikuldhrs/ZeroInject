# Services Documentation

This document provides a brief overview of the backend services implemented in the web-based proof-of-concept.

## SSH Scraper (`services/ssh_scraper.js`)

### Purpose

This service is responsible for fetching data from external websites that provide free SSH accounts.

### Current Implementation

- **Function:** `fetchSshAccounts(callback)`
- **Method:** It uses Node.js's built-in `https` module to perform a GET request to `sshkit.com`.
- **Output:** It returns the entire raw HTML content of the page.
- **Limitations:** It does **not** parse the HTML to extract account details. This was planned but is not feasible without a proper HTML parsing library (like Cheerio), which cannot be installed in the current environment.

### Intended Functionality

The scraper should parse the HTML to find and return a structured list of SSH account objects, including:
- `user`
- `host`
- `port`
- `expired`

## SNI Scanner (`services/sni_scanner.js`)

### Purpose

This service checks if a given Server Name Indication (SNI) host is "alive" and can be used for a potential connection.

### Current Implementation

- **Function:** `scanSni(host, callback)`
- **Method:** It uses Node.js's built-in `tls` module to attempt a TLS handshake with the specified `host` on port 443.
- **`rejectUnauthorized`:** This option is set to `false`. We are not validating the certificate's authenticity; we are only interested in whether a TLS connection can be established, which is a good indicator that the SNI is being correctly routed and is not blocked.
- **Output:** It returns a boolean `true` for a successful connection and `false` for any error or timeout.

### Intended Functionality

The current implementation is close to the intended functionality. In a full application, this would be used to build a list of valid SNIs that the user can then select from when building a configuration.
