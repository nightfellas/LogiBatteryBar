# 🔋 LogiBatteryBar for macOS

<p align="center">
  <b>Widget Menu Bar Native macOS untuk Memantau Status Baterai Perangkat Logitech (MX Master 3S & MX Mechanical Mini) secara Real-Time via Logi Bolt USB Receiver.</b>
</p>

---

## 📌 Latar Belakang Masalah

Di macOS (Ventura, Sonoma, Sequoia), widget baterai bawaan Apple hanya mendukung perangkat Bluetooth standar Apple (seperti AirPods, Magic Mouse, Magic Keyboard). Jika Anda menggunakan mouse dan keyboard Logitech yang tersambung melalui **Logi Bolt USB Receiver**, sistem macOS **tidak dapat membaca maupun menampilkan persentase baterai** perangkat tersebut di desktop maupun Control Center.

Aplikasi resmi Logitech Options+ berukuran cukup besar, memakan memori, dan tidak memiliki indikator persentase angka yang praktis dan selalu terlihat di Menu Bar.

**LogiBatteryBar** hadir sebagai solusi: aplikasi native macOS yang sangat ringan (zero external dependencies) yang berkomunikasi langsung dengan firmware dongle Logi Bolt via protokol hardware **HID++ 2.0** untuk menampilkan baterai mouse dan keyboard Anda setiap saat di pojok atas layar.

---

## ✨ Fitur Utama

- 🖱️ **Indikator Ringkas di Menu Bar:**
  Selalu terlihat saat Anda bekerja tanpa mengganggu aplikasi lain:
  ```
  🖱️ 75%   ⌨️ 80%
  ```
- ⚡ **Deteksi Pengisian Daya (Charging Status):**
  Otomatis memunculkan ikon petir `⚡` saat mouse atau keyboard sedang diisi daya menggunakan kabel USB-C.
- 💤 **Mode Hemat Daya Cerdas (Sleep / Idle Aware):**
  Mendeteksi saat perangkat masuk ke mode tidur (*RF Sleep Mode*). Angka baterai terakhir tetap disimpan dan diberi label keterangan `(zZ)` / `Standby (Idle)`. Begitu tombol ditekan, status langsung kembali aktif.
- 🫧 **Native SwiftUI Popover Bubble Window:**
  Panel popover modern bergaya gelembung native macOS (dengan panah segitiga rapi mengarah ke tombol menu bar) saat diklik, menampilkan:
  - **Nama Perangkat Lengkap:** `MX Master 3S` dan `MX Mechanical Mini`.
  - **Slot Dongle Logi Bolt:** Menampilkan nomor slot perangkat (`Slot 1 • Logi Bolt`, `Slot 5 • Logi Bolt`).
  - **Pill Badge Baterai Dinamis:** Ikon baterai level adaptif dengan warna status (*Hijau > 30%*, *Oranye 15–30%*, *Merah < 15%*).
  - **Progress Bar Baterai.**
  - **Status Konektivitas & Daya:** `⚡ Charging via USB`, `✓ Connected`, atau `💤 Standby (Idle)`.
  - **Waktu Pembaruan:** Jam terakhir telemetry terbaca (`Active • Updated 21:05`).
- 🔄 **Quick Refresh (Dua Cara):**
  - Klik tombol **Refresh** di dalam panel popover.
  - Klik kanan langsung pada teks menu bar untuk memicu pembaruan latar belakang tanpa membuka jendela.
- 🌿 **Sangat Hemat Baterai & Bebas Polling Berlebih:**
  Melakukan pembaruan terjadwal setiap 60 detik, serta otomatis melakukan *instant refresh* saat Mac Anda baru dibangunkan dari mode tidur (*System Wake Notification*).
- 🔒 **Akses Aman & Non-Eksklusif (`kIOHIDOptionsTypeNone`):**
  Tidak mengunci dongle USB receiver, sehingga input mouse/keyboard dan software pendukung seperti Logi Options+ tetap berfungsi normal berdampingan.

---

## 🖥️ Persyaratan Sistem

| Komponen | Spesifikasi Minimum |
| :--- | :--- |
| **Sistem Operasi** | macOS 13.0 (Ventura), macOS 14.0 (Sonoma), macOS 15.0 (Sequoia), atau lebih baru |
| **Arsitektur** | Apple Silicon (M1, M2, M3, M4) & Intel (`x86_64`) |
| **Hardware** | Dongle **Logi Bolt USB Receiver** (Product ID `0xC548` / Vendor ID `0x046D`) |
| **Perangkat Didukung** | Logitech MX Master 3S, MX Mechanical / Mini, MX Keys S, MX Anywhere 3S, dan perangkat Logitech Bolt lainnya |
| **Tools Build** | Xcode Command Line Tools (`swift`, `clang`) bawaan macOS |

---

## 🛠️ Panduan Build & Instalasi

### Langkah 1: Persiapan & Kompilasi (Build)

1. Buka aplikasi **Terminal** di Mac Anda.
2. Masuk ke direktori proyek, contoh:
   ```bash
   cd LogiBatteryBar
   ```
3. Jalankan skrip build otomatis:
   ```bash
   ./build.sh
   ```
   *Skrip ini akan mengompilasi kode Swift menggunakan optimasi rilis (`swift build -c release`), membuat bundle macOS `LogiBatteryBar.app`, menyetel konfigurasi latar belakang `LSUIElement`, dan menandatangani aplikasi secara ad-hoc.*
4. Setelah selesai, berkas `LogiBatteryBar.app` siap pakai akan tercipta di direktori proyek.

---

### Langkah 2: Cara Menjalankan Aplikasi

Anda dapat langsung menjalankan aplikasi melalui Terminal:
```bash
open LogiBatteryBar.app
```
Atau buka folder proyek melalui **Finder** dan klik dua kali berkas **`LogiBatteryBar.app`**. Ikon status baterai mouse dan keyboard Anda akan langsung muncul di Menu Bar kanan atas layar macOS Anda!

---

### Langkah 3: Memasang Permanen ke Folder `/Applications`

Agar aplikasi tersimpan rapi bersama aplikasi macOS lainnya:
```bash
cp -R LogiBatteryBar.app /Applications/
```
Kini Anda bisa menemukan dan membuka `LogiBatteryBar` langsung dari Spotlight (`Cmd + Space`) atau Launchpad.

---

### Langkah 4: Menjadikan Auto-Start saat Mac Dinyalakan (Login Items)

Agar Anda tidak perlu membuka aplikasi secara manual setiap kali me-restart Mac:

1. Buka menu **Apple ()** di pojok kiri atas layar, lalu pilih **System Settings...** (Pengaturan Sistem).
2. Di bilah sisi kiri, pilih menu **General** (Umum).
3. Pilih submenu **Login Items** (Item Masuk).
4. Pada bagian atas bertuliskan **Open at Login** (Buka saat Masuk), klik tombol tambah **(+)**.
5. Di jendela pemilihan file yang muncul, buka folder **Applications**, pilih **`LogiBatteryBar`**, lalu klik **Open**.
6. **Selesai!** Kini setiap kali Mac dinyalakan atau login, status baterai perangkat Logitech Anda akan otomatis terpantau.

---

## 🧭 Panduan Penggunaan Sehari-hari

- **Melihat Status Cepat:** Cukup lirik menu bar di kanan atas. Contoh: `🖱️ 75%  ⌨️ 80%`.
- **Melihat Detail & Status Pengisian Daya:** Klik kiri pada angka baterai di menu bar untuk membuka panel kartu detail.
- **Refresh Manual Cepat:** Klik kanan pada angka baterai di menu bar untuk memaksa dongle membaca status terbaru tanpa membuka jendela.
- **Keluar dari Aplikasi:** Klik kiri ikon di menu bar, lalu klik tombol **Quit** di pojok kanan bawah panel detail.

---

## 🏗️ Struktur Arsitektur Kode

```
widget/
├── Package.swift                    # Konfigurasi Swift Package Manager (macOS 13+)
├── build.sh                         # Skrip build & packaging bundle .app
├── README.md                        # Dokumentasi dan panduan lengkap
├── Sources/
│   └── LogiBatteryBar/
│       ├── App/
│       │   └── LogiBatteryBarApp.swift   # Entry-point SwiftUI dengan MenuBarExtra .window
│       ├── Models/
│       │   └── LogiDevice.swift          # Struktur data perangkat, tipe, dan status daya
│       ├── Services/
│       │   ├── HIDPlusPlusProtocol.swift # Serializer & Parser protokol Logitech HID++ 2.0
│       │   └── LogiBoltHIDService.swift  # IOKit HID Manager & manajemen komunikasi Bolt dongle
│       ├── ViewModels/
│       │   └── BatteryStatusViewModel.swift # Observable State, interval timer, & format judul
│       └── Views/
│           ├── DeviceRowView.swift       # Kartu SwiftUI individual untuk tiap perangkat
│           └── PopoverView.swift         # Panel popup popover container
└── Tests/
    └── LogiBatteryBarTests/         # 13 automated unit tests berbasis XCTest
```

---

## ❓ Troubleshooting & Tanya Jawab

#### 1. Mengapa muncul teks `⚡ Logi (Off)` di menu bar?
Teks ini menandakan dongle Logi Bolt USB Receiver tidak terdeteksi terpasang pada port USB Mac Anda.
- **Solusi:** Pastikan dongle USB Logi Bolt tercolok dengan kencang di port Mac atau di USB Hub yang aktif.

#### 2. Mengapa keyboard berstatus `Standby (Idle)` saat sedang tidak mengetik?
Keyboard wireless Logitech (seperti MX Mechanical Mini) dirancang memiliki mode tidur (*RF Sleep*) sangat agresif untuk menghemat baterai jika tidak ada tombol yang ditekan selama beberapa saat.
- **Solusi:** Ini adalah perilaku normal dan sehat. Aplikasi tetap menampilkan persentase baterai terakhir yang valid. Begitu Anda menekan satu tombol saja, statusnya akan langsung kembali menjadi `Connected`.

#### 3. Apakah aplikasi ini bentrok dengan Logi Options+?
Tidak sama sekali. LogiBatteryBar membuka koneksi IOKit dengan opsi *shared non-exclusive access* (`kIOHIDOptionsTypeNone`). Software resmi Logi Options+ tetap dapat digunakan secara bersamaan untuk mengatur konfigurasi tombol, DPI, dan *gesture*.

#### 4. Bagaimana cara meng-uninstall aplikasi?
Hentikan aplikasi dengan menekan tombol **Quit** di panel popover (atau jalankan `pkill -f LogiBatteryBar` di Terminal), lalu hapus berkas `LogiBatteryBar.app` dari folder `/Applications`.

---

## 📄 Lisensi

Proyek ini dirilis di bawah lisensi **MIT License** — bebas digunakan, dimodifikasi, dan didistribusikan.
