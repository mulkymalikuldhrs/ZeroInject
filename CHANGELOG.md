# Changelog

## 0.1.0 (2025-07-25)

### Features

- **Web UI:** Created a basic single-page application UI with HTML, CSS, and vanilla JavaScript.
- **API Server:** Implemented a basic Node.js HTTP server without external dependencies.
- **SNI Scanner:** Added a server-side API endpoint (`/api/scan-sni`) to test TLS connectivity to a given host.
- **SSH Scraper:** Added a server-side API endpoint (`/api/ssh-accounts`) to fetch raw HTML from `sshkit.com`.
- **Config Management:** Implemented client-side configuration creation and storage using browser `localStorage`.
- **Documentation:** Created initial `README.md`.

### Known Issues

- Core connection and tunneling functionality is missing due to restrictive development environment.
- SSH scraping only fetches raw HTML and does not parse the data.
- The application is a web proof-of-concept and not a native Android app.
