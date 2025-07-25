# ZeroInjector

ZeroInjector adalah aplikasi Flutter untuk Android yang memungkinkan bypass internet gratis tanpa root. Aplikasi ini menggunakan teknik injection payload melalui SNI (Server Name Indication) dan SSH tunneling untuk mengakses internet melalui jaringan zero-rated seperti Facebook gratis, WhatsApp CDN, dan lainnya.

## 🚀 Fitur Utama

- **Auto SNI Scanner**: Otomatis mencari dan menguji SNI hosts yang aktif
- **Auto SSH Fetcher**: Mengambil akun SSH gratis dari berbagai sumber
- **Auto Payload Generator**: Membuat kombinasi payload secara otomatis
- **Multi-Tunnel Support**: Mendukung stunnel, SOCKS5, HTTP proxy, dan WebSocket inject
- **Offline Mode**: Menyimpan konfigurasi yang berhasil untuk digunakan offline
- **Real-time Logs**: Menampilkan log koneksi secara real-time
- **No Root Required**: Bekerja tanpa memerlukan akses root

## 📦 Struktur Project

```
lib/
├── main.dart                    # Entry point aplikasi
├── models/                      # Data models
│   ├── ssh_account.dart        # Model akun SSH
│   ├── sni_entry.dart          # Model SNI entry
│   └── payload_config.dart     # Model konfigurasi payload
├── services/                    # Business logic services
│   ├── ssh_scraper.dart        # Service untuk scraping SSH
│   ├── sni_scanner.dart        # Service untuk scanning SNI
│   ├── payload_generator.dart  # Service untuk generate payload
│   ├── connection_tester.dart  # Service untuk test koneksi
│   └── local_storage.dart      # Service untuk local storage
└── screens/                     # UI screens
    ├── dashboard.dart          # Dashboard utama
    ├── config_builder.dart     # Builder konfigurasi
    ├── ssh_manager.dart        # Manager akun SSH
    ├── sni_scanner.dart        # Scanner SNI
    └── offline_configs.dart    # Konfigurasi offline

assets/
├── stunnel_template.conf       # Template konfigurasi stunnel
└── payload_templates.json      # Template payload

android/
└── app/src/main/
    ├── AndroidManifest.xml     # Manifest Android
    └── res/xml/
        └── network_security_config.xml  # Konfigurasi keamanan jaringan
```

## 🛠 Instalasi dan Setup

### Prerequisites

- Flutter SDK (versi 3.0.0 atau lebih baru)
- Android SDK
- Android device atau emulator (API level 21+)

### Langkah Instalasi

1. **Clone repository**
   ```bash
   git clone <repository-url>
   cd zeroinjector
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Setup Android permissions**
   Pastikan file `android/app/src/main/AndroidManifest.xml` sudah memiliki permissions yang diperlukan (sudah termasuk dalam project).

4. **Build dan install**
   ```bash
   # Debug build
   flutter run
   
   # Release build
   flutter build apk --release
   ```

5. **Install APK**
   ```bash
   flutter install
   ```

## 📱 Cara Penggunaan

### 1. Dashboard
- Tampilan utama dengan status koneksi
- Toggle untuk mode otomatis
- Log real-time dari proses koneksi

### 2. SNI Scanner
- Scan otomatis SNI hosts yang tersedia
- Test kecepatan response time
- Tambah custom SNI hosts

### 3. SSH Manager
- Fetch akun SSH gratis otomatis
- Tambah akun SSH manual
- Test koneksi SSH

### 4. Config Builder
- Buat konfigurasi payload manual
- Generate semua kombinasi otomatis
- Edit dan duplicate konfigurasi

### 5. Offline Configs
- Lihat konfigurasi yang berhasil
- Test ulang konfigurasi
- Export konfigurasi

## 🔧 Konfigurasi

### SNI Hosts Default
Aplikasi sudah termasuk SNI hosts untuk:
- Facebook (zero.facebook.com, free.facebook.com)
- WhatsApp (api.whatsapp.com, web.whatsapp.com)
- Instagram (api.instagram.com)
- Facebook CDN (fbcdn.net)

### SSH Sources
Aplikasi mengambil SSH gratis dari:
- SpeedSSH.com
- SSHKit.com
- FastSSH.com

### Payload Templates
Tersedia 8 template payload:
- HTTP CONNECT
- HTTP GET
- WebSocket Upgrade
- HTTP Proxy
- Custom Inject
- Facebook Zero
- WhatsApp CDN
- SSL Bump

## 🔒 Keamanan

- Aplikasi tidak menyimpan data sensitif di server
- Password SSH dienkripsi di local storage
- Hanya menggunakan koneksi yang aman
- Validasi payload sebelum eksekusi

## 🚨 Disclaimer

Aplikasi ini dibuat untuk tujuan edukasi dan penelitian. Pengguna bertanggung jawab penuh atas penggunaan aplikasi ini. Pastikan untuk mematuhi hukum dan regulasi yang berlaku di wilayah Anda.

## 🐛 Troubleshooting

### Koneksi Gagal
1. Pastikan SNI host masih aktif
2. Cek apakah akun SSH masih valid
3. Test koneksi internet dasar
4. Periksa log untuk detail error

### Aplikasi Crash
1. Restart aplikasi
2. Clear app data jika perlu
3. Reinstall aplikasi
4. Periksa kompatibilitas Android version

### Performance Issues
1. Hapus konfigurasi yang tidak terpakai
2. Clear logs secara berkala
3. Restart device jika perlu

## 📄 License

Project ini menggunakan MIT License. Lihat file LICENSE untuk detail lengkap.

## 🤝 Contributing

Kontribusi sangat diterima! Silakan:
1. Fork repository
2. Buat feature branch
3. Commit changes
4. Push ke branch
5. Buat Pull Request

## 📞 Support

Jika mengalami masalah atau memiliki pertanyaan:
1. Buka issue di GitHub
2. Sertakan log error
3. Jelaskan langkah reproduksi
4. Sebutkan versi Android dan device

---

**ZeroInjector v1.0.0** - Auto Injector Bypass Internet Android (No Root)