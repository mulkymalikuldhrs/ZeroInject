# TODO List

This list outlines the remaining work required to complete the ZeroInjector application as originally envisioned. Most of these tasks are currently blocked by environment restrictions.

## Blocked by Environment

- [ ] **Setup Flutter Project:** The original goal was a Flutter application. This requires the ability to install the Flutter SDK.
- [ ] **Install Dependencies:** The web-based alternative is blocked by the inability to install Node.js packages (`npm install`). Key packages needed:
  - [ ] `express`: For a more robust server.
  - [ ] `cheerio`: For parsing HTML from SSH scraper.
  - [ ] `ssh2-client`: For programmatic SSH connections.
  - [ ] `cordova` / `capacitor`: For wrapping the web app into an Android APK.
- [ ] **Implement Stunnel/SSH Tunnel:** The core feature. Requires either:
  - [ ] The ability to execute a pre-compiled `stunnel` binary.
  - [ ] The ability to create a native SSH tunnel using a library like `ssh2-client`.

## Core Functionality

- [ ] **Parse SSH Account Data:** The current scraper only gets raw HTML. A parser needs to be written to extract username, host, port, and expiration data.
- [ ] **Implement Connection Logic:** Create the "Auto" mode that iterates through saved SNIs, SSH accounts, and payloads to find a working connection.
- [ ] **Real-time Logging:** The dashboard needs to show real-time logs from the connection process.
- [ ] **Background Service:** For a native app, a foreground/background service is needed to keep the connection alive.

## UI/UX

- [ ] **Improve UI:** The current UI is a barebones proof-of-concept. It needs proper styling and a better user experience.
- [ ] **Offline Configs Tab:** Implement the UI for the "Offline Configs" tab to show and manage previously successful configurations.

## Build & Deployment

- [ ] **Build Android APK:** Once the core functionality is built (either in Flutter or with a web-wrapper), build the final APK.
- [ ] **Permissions:** Ensure the Android manifest has the correct permissions (`INTERNET`, `FOREGROUND_SERVICE`, etc.).
