# ZeroInjector (Web-based Proof of Concept)

This is a web-based proof of concept for the ZeroInjector application. Due to a restrictive development environment, the full functionality of the original Flutter application could not be implemented.

## Limitations

The core tunneling and connection features are **not implemented**. This is because the environment prevents:
- Installation of external Node.js packages (like `ssh2`).
- Execution of external binaries (like `stunnel`).
- Installation of the Flutter SDK.

This version provides the user interface and the data-gathering services (SNI scanning and SSH account scraping) only.

## Features

- **UI:** A simple, single-page web interface with tabs for different functions.
- **SNI Scanner:** A server-side scanner that checks if a given host is reachable on port 443.
- **SSH Scraper:** A server-side scraper that fetches the raw HTML from an SSH provider website.
- **Config Management:** Client-side creation and storage of connection configurations using browser `localStorage`.

## How to Run

1.  Make sure you have Node.js installed.
2.  Run `node index.js` from the project root.
3.  Open your web browser and navigate to `http://localhost:3000`.

## Future Development

To complete this project, the development environment must be updated to allow for:
- Full installation of Node.js dependencies (`npm install`).
- or, Installation of the Flutter SDK.
- The ability to execute child processes and binaries.
