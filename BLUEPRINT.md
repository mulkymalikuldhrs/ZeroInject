# Blueprint: ZeroInjector

This document outlines the architectural design of the ZeroInjector application, including the current proof-of-concept implementation and the target architecture.

## Current Architecture (Web-based Proof-of-Concept)

Due to a restrictive development environment, the current implementation is a web-based application built with vanilla Node.js.

- **Frontend:**
  - **Framework:** None (Plain HTML, CSS, JavaScript).
  - **Structure:** A single-page application (`public/index.html`) with tab-based navigation.
  - **State Management:** Browser `localStorage` is used to persist user-created configurations.

- **Backend:**
  - **Framework:** None (built-in Node.js `http` module).
  - **API:** A simple REST-like API provides two main endpoints:
    - `/api/ssh-accounts`: Scrapes raw HTML from an SSH provider.
    - `/api/scan-sni`: Tests TLS connectivity for a given SNI host.
  - **Services:** Logic is separated into a `services` directory.
    - `ssh_scraper.js`: Handles fetching data from SSH websites.
    - `sni_scanner.js`: Handles the logic for testing SNI hosts.

- **Limitations:**
  - **No Dependencies:** The entire application runs without any external packages from `npm`, severely limiting its capabilities.
  - **No Tunneling:** The core feature is absent. The backend cannot create SSH tunnels or run external processes.
  - **Not a Native App:** It runs in a web browser, not as a standalone Android application.

## Target Architecture (Original Flutter-based Plan)

The original and ideal architecture is a native Android application built with Flutter.

- **Platform:** Android (No-Root).
- **Language:** Dart (with Flutter framework).

- **Structure:**
  - `lib/`: Main application code.
    - `main.dart`: App entry point.
    - `screens/`: UI widgets for each tab (Dashboard, Config Builder, etc.).
    - `services/`: Business logic for networking, scraping, and storage.
      - `ssh_scraper.dart`: To fetch and parse SSH accounts.
      - `sni_scanner.dart`: To test SNI hosts.
      - `payload_generator.dart`: To build connection payloads.
      - `connection_tester.dart`: The core service to manage the `stunnel`/SSH tunnel.
      - `local_storage.dart`: To manage the SQLite database.
    - `models/`: Data models for SSH accounts, SNI entries, etc.
  - `assets/`: For static files like stunnel configuration templates and potentially pre-compiled binaries.
  - `db/`: Location for the SQLite database file.

- **Core Connection Logic:**
  - **Tunneling:** The application would use a combination of `stunnel` and an SSH client.
    1. A `stunnel.conf` would be dynamically generated based on the selected SNI and payload.
    2. The `stunnel` binary (included in the app's assets) would be executed as a child process using a plugin like `process_run`.
    3. This would open a local SOCKS5 or HTTP proxy port.
    4. An SSH connection would then be established through this local port.
  - **Background Execution:** A plugin like `flutter_background_service` would be used to keep the tunnel alive as a foreground service, ensuring the connection persists when the app is not in focus.

- **Data Persistence:**
  - `sqflite`: For structured data like saved SSH accounts, SNIs, and successful connection profiles.
  - `shared_preferences`: For simple key-value data like the last active configuration.
