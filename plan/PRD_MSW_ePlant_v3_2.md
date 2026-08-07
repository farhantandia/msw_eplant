# Product Requirements Document
## MSW ePlant Mobile Application — Version 3.2 (Codebase-Aligned)
**PT Makmur Sejahtera Wisesa (MSW) — Adaro Group**
**2×30 MW CFPP + Solar PV Plant**
**App Versi Aktual: v1.0.2**

---

> **Refined Prompt (sebelum menjawab):**
>
> *"Saya ingin merancang ulang dan mengembangkan mobile app MSW ePlant (Flutter) untuk operasional pembangkit listrik yang terdiri dari 2 unit PLTU 135 MW dan instalasi Solar PV. App saat ini memiliki fitur monitoring sensor boiler dan CEMS dengan side-panel navigation dan widget card. Bantu saya buat PRD lengkap yang mencakup: (1) redesign navigasi dari side-panel ke bottom navigation bar yang lebih intuitif; (2) homepage dashboard ringkasan operasional real-time; (3) fitur baru — NPHR monitoring, perbandingan grafik sensor multi-parameter, Company OKR dashboard, Operator Digital Logsheet terintegrasi Google Sheets, input Sales & Emisi manual, dan cuaca real-time via API; (4) sistem autentikasi role-based (Operator, Supervisor, Admin); serta (5) saran fitur tambahan yang lazim di plant mobile apps industri. Tech stack: Flutter, Firebase Realtime Database untuk data sensor, Firestore untuk data lainnya, Google Sheets API untuk logsheet."*

---

## Ringkasan Status Implementasi

**Versi Aktual: v1.0.2** — Berdasarkan kode sumber yang sudah diimplementasikan.

| Fitur | Status | Keterangan |
|-------|--------|------------|
| **Navigasi** | | |
| Bottom Navigation Bar (5 tabs) | ✅ | Home, Plant, Analytics, Logsheet, More |
| Dark Theme + Glass-morphism Cards | ✅ | Tema gelap konsisten di semua halaman |
| **Home Dashboard** | | |
| Weather Widget (OpenWeatherMap) | ✅ | Suhu, kondisi, lokasi Tanjung |
| Total Generation (PLTU) | ✅ | Angka real-time dari RTDB |
| Solar PV Display | ⚠️ **BELUM SELESAI** | Hanya angka hardcoded 148 MWh |
| Unit Load Real-time | ✅ | Warna status (hijau/kuning/merah) |
| Load Distribution (PLN/AI) | ✅ | Dari data RTDB |
| NPHR Cards | ✅ | Unit 1 & 2 dengan target |
| Sales Progress Bar | ✅ | Dari SharedPreferences |
| CEMS Compliance Ringkasan | ✅ | SO₂, NOx, Particulate, Hg |
| Pull-to-Refresh | ✅ | Di homepage |
| **Plant Monitoring** | | |
| Unit 1 & 2 Cards | ✅ | Color-coded by load status |
| Unit Detail Sensor Grid | ✅ | Semua parameter dengan indikator warna |
| Trip/Shutdown Banner | ✅ | Load < 2 MW terdeteksi otomatis |
| Alarm Detection | ✅ | Nilai out-of-range berwarna merah |
| Solar PV Dedicated Page | 🔜 **RENCANA** | Belum ada halaman khusus |
| **NPHR** | | |
| NPHR Curve Chart | ✅ | Polynomial curve 5-30 MW |
| Real-time Data Point Overlay | ✅ | Unit 1 & 2 diplot di kurva |
| NPHR Trend 7 Hari | 🔜 **RENCANA** | Belum ada chart historis |
| **CEMS** | | |
| CEMS Monitoring Page | ✅ | Dual unit (CEMS 1 & 2) via bottom tab |
| CEMS Detail View | ✅ | Grid parameter dengan nilai real-time |
| Compliance Badge + Notifikasi | 🔜 **RENCANA** | Belum ada pengecekan baku mutu |
| Trend Chart 24 Jam | 🔜 **RENCANA** | Belum ada |
| CSV Export | 🔜 **RENCANA** | Belum ada |
| **Analytics** | | |
| Multi-Parameter Chart | ⚠️ **BELUM SELESAI** | Max 3 parameter (PRD: 6), single Y-axis |
| Single Parameter Chart | ✅ | History + MIN/AVG/MAX stats |
| Dual Y-axis | 🔜 **RENCANA** | Belum ada |
| Preset Configurations | 🔜 **RENCANA** | Belum ada |
| Export PNG/CSV | 🔜 **RENCANA** | Belum ada |
| Crosshair Tooltip | ✅ | Ada pada chart |
| **Digital Logsheet** | | |
| Logsheet Main Page (Draft List) | ✅ | View, continue, delete drafts |
| Data Entry Form (2-step wizard) | ✅ | Unit/shift selection → field input |
| Boiler Fields (62 fields, 10 groups) | ✅ | Complete field definitions |
| Steam Turbine Fields (57 fields) | ✅ | Complete field definitions |
| Google Sheets Sync (OAuth2) | ✅ | Create/update spreadsheets |
| Google Sign-In | ✅ | Untuk akses Sheets API |
| Draft Auto-save (5 detik) | ✅ | Ke SharedPreferences |
| Random Data Generator | ✅ | Realistic test data |
| Operator/Supervisor Name Mgmt | ✅ | Dropdown + "Lainnya..." custom |
| Auto-populate dari Sensor | 🔜 **RENCANA** | Semua field input manual |
| Supervisor Approval Flow | 🔜 **RENCANA** | Langsung sync ke Google Sheets |
| Firestore Draft Storage | 🔜 **RENCANA** | Tidak menggunakan Firestore |
| History Search | 🔜 **RENCANA** | Belum ada |
| **More Menu** | | |
| Sales Manual Input | ✅ | Form + progress preview |
| Settings (Decimal Places) | ⚠️ **BELUM SELESAI** | Hanya decimal places, belum unit labels |
| Hazard Report | ⚠️ **BELUM SELESAI** | Hanya link Google Form, belum foto/geolocation |
| OKR Dashboard | 🔜 **RENCANA** | Belum ada |
| Emisi Manual Input | 🔜 **RENCANA** | Belum ada |
| **Autentikasi & Keamanan** | | |
| Firebase Auth + Login Screen | 🔜 **RENCANA** | App langsung ke dashboard tanpa login |
| Role-Based Access Control (RBAC) | 🔜 **RENCANA** | Semua user akses sama |
| **Notifikasi** | | |
| Local Notification (Daily Reminder) | ✅ | Pukul 08:00 WITA via flutter_local_notifications |
| Push Notification (FCM) | 🔜 **RENCANA** | Belum ada |
| Notification Center | 🔜 **RENCANA** | Belum ada |
| **Offline & Penyimpanan** | | |
| SharedPreferences (draft + settings) | ✅ | Draft logsheet + decimal config |
| Firebase RTDB Streaming | ✅ | Sensor data real-time |
| Hive/SQLite Structured Cache | 🔜 **RENCANA** | Belum ada |
| Firebase Offline Persistence | 🔜 **RENCANA** | Belum diaktifkan |
| **State Management** | | |
| setState + StreamSubscription | ✅ | Sederhana, tanpa library tambahan |
| Riverpod / Bloc | 🔜 **RENCANA** | Sesuai rekomendasi PRD |
| **Infrastruktur** | | |
| Firebase Realtime Database | ✅ | 5 path: table1, table2, cems1, cems2, nphr |
| Cloud Firestore | 🔜 **RENCANA** | Belum digunakan sama sekali |
| Google Sheets API v4 | ✅ | OAuth2 via google_sign_in |
| OpenWeatherMap API | ✅ | Current weather + 5-day forecast |
| url_launcher | ✅ | Untuk hazard report link |

---

## 1. Overview & Latar Belakang

### 1.1 Product Summary

MSW ePlant adalah aplikasi mobile internal berbasis Flutter untuk monitoring dan operasional PT Makmur Sejahtera Wisesa, sebuah pembangkit listrik batubara (CFPP) 2×30 MW yang dilengkapi dengan fasilitas Solar PV. **Versi Aktual: v1.0.2** — PRD ini mencakup fitur yang sudah diimplementasikan (✅), fitur yang sebagian selesai (⚠️), dan fitur yang masih dalam rencana pengembangan (🔜).

### 1.2 Masalah yang Diselesaikan

| Masalah Saat Ini | Solusi | Status |
|---|---|---|---|
| Navigasi side-panel tidak efisien di lapangan | Bottom navigation bar dengan tap area besar | ✅ |
| Tidak ada ringkasan KPI di satu layar | Homepage dashboard terintegrasi | ✅ |
| NPHR hanya tampil di halaman tersendiri tanpa konteks | NPHR terintegrasi dengan beban unit real-time | ✅ |
| Logsheet masih manual (kertas/Excel desktop) | Digital Logsheet terhubung Google Sheets | ✅ (⚠️ auto-populate 🔜) |
| Tidak ada visibilitas OKR untuk operator | Company OKR page per departemen | 🔜 RENCANA |
| Data sales dan emisi tidak ada di app | Input manual dengan history dan validasi | ⚠️ Sales ✅, Emisi 🔜 |

### 1.3 Target Pengguna

> ⚠️ **BELUM SELESAI:** Role-Based Access Control (RBAC) dan autentikasi Firebase belum diimplementasikan. Saat ini semua pengguna memiliki akses penuh ke seluruh fitur tanpa login.

| Role | Akses (Target) | Deskripsi |
|---|---|---|
| **Operator** | Read + Logsheet input | Operator shift di control room dan lapangan |
| **Supervisor** | Read + Approve | Supervisor shift, approval logsheet |
| **Manager/Admin** | Full access + Input | Input sales, emisi, OKR; manage users |
| **Executive** | Read-only dashboard | Pimpinan, summary KPI saja |

---

## 2. Arsitektur & Tech Stack

### 2.1 Tech Stack

```
✅ = Aktif digunakan   |   🔜 = Rencana pengembangan

Frontend:       Flutter (Dart) 3.x — Android & iOS ✅
Realtime Data:  Firebase Realtime Database (sensor data streaming) ✅
Database:       Cloud Firestore 🔜 RENCANA (saat ini tidak digunakan)
Auth:           Firebase Authentication 🔜 RENCANA (saat ini tanpa login)
Logsheet Sync:  Google Sheets API v4 (via OAuth2 google_sign_in) ✅
Weather:        OpenWeatherMap API (free tier) ✅
Push Notif:     flutter_local_notifications (local only) ✅
                Firebase Cloud Messaging (FCM) 🔜 RENCANA
State Mgmt:     setState + StreamSubscription ✅
                Riverpod / Bloc 🔜 RENCANA
Charts:         fl_chart ^1.1.1 ✅
Local Storage:  shared_preferences ^2.2.3 ✅
Notifications:  flutter_local_notifications ^17.1.2 ✅
Internet:       http ^1.2.1 (Google Sheets + OpenWeatherMap) ✅
Auth Sheets:    google_sign_in ^6.2.1 ✅
Timezone:       timezone ^0.9.3 ✅
URL Launcher:   url_launcher ^6.3.1 ✅
```

### 2.2 Struktur Data Firebase

#### ✅ Firebase Realtime Database (Aktif)

```
Format: Array of Arrays dari Excel/Sistem Power Plant (baris pertama = header)

/excel_data/  (RTDB — real-time streaming)
├── /table1/  → Boiler Unit 1
│   [DATETIME, UNIT 1 LOAD, TOTAL HOUSE LOAD, MAIN STEAM PRESS, ...]
├── /table2/  → Boiler Unit 2
│   [DATETIME, UNIT 2 LOAD, TOTAL LOAD, MAIN STEAM PRESS, ...]
├── /cems1/   → CEMS Unit 1
│   [DATETIME, SO2, NOX, PARTICULATE, HG, ...]
├── /cems2/   → CEMS Unit 2
└── /nphr/    → NPHR
    [unit1_value, unit2_value]
```

#### 🔜 Cloud Firestore (Rencana — Saat Ini Belum Digunakan)

```
Firestore Collections (belum diimplementasikan):
├── /users/{uid}            — role, name, department, unit_access
├── /logsheets/{date}/{shift} — operator entries, timestamps, approvals
├── /sales/{month}          — energy_mwh_sold, revenue_idr, buyer, notes
├── /emissions/{month}      — so2_ton, nox_ton, co2_ton, notes
├── /okr/{year}/{quarter}/{dept} — objectives, key_results, progress
├── /hazard_reports/{id}    — reporter, location, description, status
└── /notifications/{id}     — type, severity, message, timestamp, ack
```

#### ✅ Google Sheets (Aktif — untuk Logsheet)

```
Spreadsheet per unit per bulan:
  "Logsheet Unit 1 - Juni 2026"
  ├── Sheet "Pagi 07-15"    (header row + data rows per time slot)
  ├── Sheet "Siang 15-23"
  └── Sheet "Malam 23-07"

Spreadsheet ID dicache di Firebase RTDB: /logsheet_config/{unit}/spreadsheetId
```

---

## 3. Desain Navigasi & UI

### 3.1 Redesign Navigasi

**From:** Side-panel drawer (tidak efisien saat pakai sarung tangan)
**To:** Bottom Navigation Bar (5 tab utama) ✅ — Sudah diimplementasikan

```
┌─────────────────────────────────┐
│  MSW ePlant                     │  ← Top bar: judul saja
├─────────────────────────────────┤
│                                 │
│         [KONTEN UTAMA]          │
│                                 │
│                                 │
├─────────────────────────────────┤
│  🏠     ⚙️      📊     📋    ⚡  │  ← Bottom Nav
│ Home  Plant  Analytics  Log  More│
└─────────────────────────────────┘
```

> ⚠️ **BELUM SELESAI:** Top bar notifikasi (🔔) dan user profile (👤) belum diimplementasikan. Saat ini hanya menampilkan judul halaman.

**Bottom Nav Tabs:**

| Tab | Icon | Konten |
|---|---|---|
| **Home** | 🏠 | Dashboard ringkasan KPI & cuaca ✅ |
| **Plant** | ⚙️ | Unit 1 ✅, Unit 2 ✅, CEMS ✅, NPHR ✅ — Solar PV 🔜 |
| **Analytics** | 📊 | Multi-parameter chart ✅ (⚠️ max 3 parameter, no preset/export) |
| **Logsheet** | 📋 | Digital logsheet shift ✅ (⚠️ manual input only, no approval) |
| **More** | ⚡ | Sales ✅, Hazard Report ⚠️, Settings ⚠️ — OKR 🔜, Emisi 🔜 |

### 3.2 Design System

```
Tema: Dark (sesuai app saat ini, friendly untuk low-light control room) ✅

Color Palette: ✅
  Background:     #0D0D0D (near black)
  Surface:        #1A1A2E (widget card)
  Primary:        #00B4D8 (nilai operasional, interactive)
  Success/Normal: #06D6A0 (nilai dalam batas normal)
  Warning:        #FFB703 (nilai mendekati batas)
  Danger:         #EF233C (alarm, nilai di luar batas)
  Text Primary:   #FFFFFF
  Text Secondary: #8D8D9B

Typography: ⚠️ BELUM SELESAI — Font kustom belum diimplementasikan, masih menggunakan default Material Design Flutter

Widget Card Anatomy: ✅
  Border-radius:  12px
  Padding:        16px
  Label:          uppercase, warna sekunder
  Value:          bold, ukuran besar, color-coded
```

---

## 4. Fitur Detail Per Halaman

---

### 4.1 HOME — Dashboard Ringkasan Operasional ✅

**Tujuan:** Satu layar, semua informasi kritis tanpa scroll berlebihan. ✅ Sudah diimplementasikan.

```
┌─────────────────────────────────┐
│  MSW ePlant                     │
│  ☀️ 32°C Tanjung, S.Kal  Cerah  │  ← Weather widget ✅
├─────────────────────────────────┤
│  TOTAL PEMBANGKITAN HARI INI    │
│  ┌─────────┐  ┌─────────┐      │
│  │ PLTU    │  │ Solar PV│      │
│  │ 2,840   │  │  148    │      │
│  │  MWh    │  │  MWh    │      │
│  └─────────┘  └─────────┘      │
│  ⚠️ Solar PV: angka hardcoded  │
├─────────────────────────────────┤
│  BEBAN UNIT (REAL-TIME) ✅      │
│  ┌──────────┐  ┌──────────┐    │
│  │ UNIT 1   │  │ UNIT 2   │    │
│  │ 12.5 MW  │  │ 118.3 MW │    │
│  └──────────┘  └──────────┘    │
│  (color-coded: green/amber/red) │
├─────────────────────────────────┤
│  DISTRIBUSI BEBAN ✅            │
│  Load to AI:   8.4 MW           │
│  Load to PLN: 10.7 MW (+ U2)   │
├─────────────────────────────────┤
│  NPHR (Nett Plant Heat Rate) ✅ │
│  Unit 1: 4,230  Unit 2: 3,980  │
│  Target: ≤4,500 kcal/kWh  ✅   │
├─────────────────────────────────┤
│  CEMS COMPLIANCE ✅             │
│  SO₂, NOx, Particulate, Hg     │
├─────────────────────────────────┤
│  SALES BULAN INI ✅             │
│  ██████████░░░  84% of target  │
│  42,100 / 50,000 MWh            │
└─────────────────────────────────┘
```

**Data Sources:**
- Cuaca: OpenWeatherMap API (update setiap 30 menit) ✅
- Pembangkitan PLTU: nilai terbaru dari Firebase RTDB `/excel_data/table1/` & `/excel_data/table2/` ✅
- Solar PV: **⚠️ BELUM SELESAI** — masih angka hardcoded (148 MWh), belum terhubung ke data aktual
- Beban unit: Firebase RTDB `/excel_data/table1/` & `/excel_data/table2/` ✅
- NPHR: Firebase RTDB `/excel_data/nphr/` ✅
- Sales: SharedPreferences (diset via halaman Manual Input) ✅ — 🔜 rencana pindah ke Firestore
- CEMS: Firebase RTDB `/excel_data/cems1/` & `/excel_data/cems2/` ✅

**Behavior:**
- Pull-to-refresh untuk update manual ✅
- Widget beban berwarna: hijau (normal), kuning (low load), merah (trip/0 MW) ✅
- Tap pada setiap widget → navigasi ke halaman detail masing-masing ✅

---

### 4.2 PLANT — Monitoring Unit ⚠️

> Navigasi sub-menu Plant saat ini menggunakan daftar kartu (bukan tab bar horizontal): menampilkan Unit 1, Unit 2, CEMS 1, CEMS 2, dan NPHR sebagai kartu terpisah.

#### 4.2.1 Unit 1 & Unit 2 — Sensor Dashboard ✅

**Status: ✅ Sudah diimplementasikan** — Grid parameter sensor dengan indikator warna.

**Parameter yang ditampilkan (per unit):**

| Widget | Satuan | Status |
|---|---|---|
| Unit Load | MW | ✅ |
| Total Load | MW | ✅ |
| Main Steam Pressure | Bar | ✅ |
| Main Steam Temperature | °C | ✅ |
| Main Steam Flow | T/h | ✅ |
| Drum Level | mm | ✅ |
| Feed Water Flow | T/h | ✅ |
| Coal Flow | T/h | ✅ |
| Condenser Vacuum | mmHg | ✅ |
| Flue Gas Temperature | °C | ✅ |
| Generator Output | MW | ✅ |
| Load to PLN/AI | MW | ✅ |

**Fitur yang sudah ada:**
- ✅ Indikator warna otomatis per nilai (hijau/kuning/merah) berdasarkan ambang batas
- ✅ Trip detection (load < 2 MW → banner merah "TRIP"/"RESERVE SHUTDOWN")
- ✅ Tap widget → navigasi ke chart detail (chart_page.dart)

**Fitur yang belum ada:**
- 🔜 Tap widget → mini chart 24 jam (modal bottom sheet)
- 🔜 Badge "ALARM" eksplisit (saat ini hanya perubahan warna)

#### 4.2.2 Solar PV Monitoring 🔜

> ⚠️ **BELUM SELESAI:** Halaman monitoring Solar PV belum diimplementasikan. Saat ini hanya menampilkan angka hardcoded "148 MWh" di Home Dashboard.

```
🔜 RENCANA:
┌─────────────────────────────────┐
│  SOLAR PV                       │
│  Power Output:    148.2 kW  ☀️  │
│  Irradiance:      842 W/m²      │
│  Performance Ratio: 78.4%       │
│  ┌────────────────────────────┐ │
│  │ Grafik produksi hari ini   │ │
│  └────────────────────────────┘ │
│  Produksi hari ini: 1,024 kWh   │
└─────────────────────────────────┘
```

#### 4.2.3 NPHR — Nett Plant Heat Rate ⚠️

**Status: ✅ Sebagian sudah, ⚠️ Trend 7 hari 🔜**

```
┌─────────────────────────────────┐
│  NPHR CURVE ✅                  │
│  [Grafik curve NPHR vs MW]      │
│   Baseline ── Target ·· Unit1 ● │
│   Unit2 ◆                       │
├─────────────────────────────────┤
│  UNIT 1              UNIT 2 ✅  │
│  4,230 kcal/kWh  3,980 kcal/kWh│
│  Beban: 12.5 MW  Beban: 118 MW  │
│  Status: ⚠️ Low Load  ✅ Normal │
├─────────────────────────────────┤
│  TREND NPHR 7 HARI 🔜 RENCANA   │
│  [Line chart Unit1 vs Unit2]    │
├─────────────────────────────────┤
│  TARGET BULAN INI               │
│  ≤ 4,500 kcal/kWh               │
│  Rata-rata aktual: 4,120  ✅    │
└─────────────────────────────────┘
```

**✅ Sudah:**
- Kurva polynomial NPHR vs beban (5-30 MW, step 1 MW)
- Real-time data point overlay untuk Unit 1 (ungu) dan Unit 2 (hijau)
- Target line
- Nilai NPHR aktual + status

**🔜 Rencana:**
- Trend NPHR 7 hari (line chart historis)

#### 4.2.4 CEMS — Continuous Emission Monitoring ✅

**Status: ✅ Sudah diimplementasikan** — Halaman CEMS dengan dual unit via bottom tab.

```
┌─────────────────────────────────┐
│  CEMS — UNIT 1        UNIT 2 ✅ │
├─────────────────────────────────┤
│  SO₂      142 mg/Nm³  138      │
│  NOx       91 mg/Nm³   87      │
│  Particulate  ...      ...      │
│  Hg (Mercury)  ...     ...     │
└─────────────────────────────────┘
```

**✅ Sudah:**
- Tampilan parameter CEMS real-time untuk Unit 1 dan Unit 2
- Navigasi ke halaman detail CEMS (grid parameter)
- Bottom tab switch antara CEMS 1 dan CEMS 2

**🔜 Rencana / ⚠️ Belum:**
- Compliance threshold checking (badge merah jika melebihi baku mutu)
- Push notification jika ada parameter超标
- Grafik trend 24 jam per parameter
- Export CSV / history

---

### 4.3 ANALYTICS — Perbandingan Grafik Sensor ⚠️

**Status: ⚠️ Sebagian sudah diimplementasikan, beberapa fitur 🔜 rencana.**

```
┌─────────────────────────────────┐
│  ANALYTICS                      │
│  ┌──────────────────────────┐  │
│  │ + Tambah Parameter        │  │  ← Chip selector ✅
│  └──────────────────────────┘  │
│  Parameter aktif:               │
│  [Unit1: Main Steam Temp ×]     │
│  [Unit2: Main Steam Temp ×]     │
│  [Unit1: Load MW ×]             │
├─────────────────────────────────┤
│  Rentang waktu:                 │
│  [1J] [6J] [24J] [7H]          │
├─────────────────────────────────┤
│  [Multi-line chart area] ✅     │
│  Single Y-axis (auto-scaling) ✅│
├─────────────────────────────────┤
│  ⚠️ Export: 🔜 RENCANA          │
│  Preset: 🔜 RENCANA             │
└─────────────────────────────────┘
```

**✅ Sudah diimplementasikan:**
- Multi-parameter line chart dengan fl_chart ✅
- Pilih parameter dari bottom sheet picker ✅
- Parameter dikelompokkan per sumber data (Boiler 1, Boiler 2, CEMS 1, CEMS 2, NPHR) ✅
- Skala Y-axis dinamis (auto-scaling berdasarkan data aktual) ✅
- Crosshair tooltip saat tap pada grafik ✅
- Warna berbeda per parameter (color palette) ✅
- Rentang waktu: 1J, 6J, 24J, 7H ✅

**⚠️ Perbedaan dari PRD asli:**
- Maksimal **3 parameter** (PRD menyebut 6)
- **Single Y-axis** saja (belum ada dual Y-axis untuk parameter beda satuan)
- Belum bisa pilih parameter dari Solar PV (karena belum ada datanya)

**🔜 Rencana:**
- Dual Y-axis otomatis untuk parameter dengan satuan berbeda
- Simpan/load preset konfigurasi (contoh: "Steam Quality Check")
- Export chart sebagai PNG
- Export data sebagai CSV

---

### 4.4 LOGSHEET — Digital Operator Logsheet ⚠️

**Tujuan:** Menggantikan logsheet kertas/Excel manual, terintegrasi ke Google Sheets sebagai master record.

**Status: ✅ Sebagian besar sudah diimplementasikan. ⚠️ Beberapa fitur masih 🔜 rencana.**

#### 4.4.1 Flow Logsheet (Aktual)

```
Operator buka tab Logsheet ✅
    ↓
Login Google Sign-In (untuk akses Sheets API) ✅
    ↓
Pilih area: Boiler atau Steam Turbine ✅
    ↓
Pilih unit & shift (auto-detect jam) ✅
    ↓
Pilih operator & supervisor (dropdown + "Lainnya...") ✅
    ↓
Form input terstruktur — SEMUA MANUAL ⚠️
    ↓
Isi field per time slot (accordion groups) ✅
    ↓
Draft auto-save tiap 5 detik ke SharedPreferences ✅
    ↓
Submit → langsung sync ke Google Sheets ✅
       (tanpa approval, tanpa Firestore)
```

> ⚠️ **Perbedaan dari PRD asli:**
> 1. **Tidak ada auto-populate dari sensor** — semua field diisi manual (atavia tombol "Generate Random Data")
> 2. **Tidak ada Firestore** — draft di SharedPreferences, submit langsung ke Google Sheets
> 3. **Tidak ada approval flow** — supervisor tidak review/approve di app
> 4. **Draft auto-save tiap 5 detik** (PRD: 60 detik)

#### 4.4.2 Struktur Form Logsheet (Aktual)

**Step 1 — Identitas ✅**
- Pilih: Unit (Unit 1 / Unit 2), Shift (otomatis sesuai jam), Tanggal (otomatis)
- Nama Operator & Supervisor: dropdown dari daftar + opsi "Lainnya..." untuk custom entry

**Step 2 — Data ✅**
- **Boiler (62 fields, 10 groups):** Load MW, Steam Pressure, Steam Temp, Drum Level, Flue Gas Temp, Condenser Vacuum, Coal Flow, Feed Water Flow, Main Steam Flow, Hot Reheat Steam Temp, Cold Reheat Steam Press, BFP, CEP, ID Fan, FD Fan, PA Fan, dll.
- **Steam Turbine (57 fields, 11 groups):** Generator Output, Bearing Vibration, Bearing Temperature, Lube Oil Temp/Press, EHC Oil Temp/Press, Seal Steam, Condenser, Gland Steam, dll.
- Setiap field: input teks + indikator validasi warna (hijau/oren/merah) + remark opsional
- Tombol "Generate Random Data" untuk testing

**Fitur:**
- ✅ Draft otomatis tersimpan setiap 5 detik ke SharedPreferences
- ✅ Daftar draft tersimpan (lanjutkan atau hapus)
- ✅ Submit langsung ke Google Sheets via OAuth2
- ✅ Spreadsheet dibuat otomatis per unit per bulan
- ✅ Sheet tabs per shift (Pagi/Siang/Malam) dengan header row dari definisi field

**🔜 Rencana:**
- Auto-populate dari sensor Firebase RTDB
- Supervisor approval workflow
- History logsheet bisa dicari per tanggal/shift
- Notifikasi jika logsheet belum diisi
- Firestore sebagai master data (dengan Google Sheets sebagai backup/sync)

---

### 4.5 MORE — Menu Tambahan ⚠️

**Status:** ✅ Sales sudah, ⚠️ Hazard & Settings sebagian, 🔜 OKR & Emisi rencana.

#### 4.5.1 Company OKR Dashboard 🔜

> 🔜 **RENCANA:** Belum diimplementasikan. OKR Dashboard termasuk halaman, data, dan input progress belum ada.

```
🔜 RENCANA:
┌─────────────────────────────────┐
│  OKR — Q2 2026                  │
│  [EIC] [Operations] [Safety]    │
├─────────────────────────────────┤
│  🎯 Objective 1                 │
│  NPHR ≤ 4,500 kcal/kWh  92%    │
│  Plant Availability ≥ 90  72%   │
└─────────────────────────────────┘
```

**Hak akses:** Admin/Manager input dan update progress. Semua role bisa melihat.
🔜 Memerlukan Firestore collection `/okr/` yang belum ada.

#### 4.5.2 Sales — Input Manual ✅

**Status: ✅ Sudah diimplementasikan**

```
┌─────────────────────────────────┐
│  SALES ENERGI                   │
├─────────────────────────────────┤
│  INPUT PENJUALAN                │
│  Penjualan (MWh): [____]        │
│  Target (MWh):    [____]        │
│  Revenue (Rp):    [____]        │
│  [Simpan]                       │
├─────────────────────────────────┤
│  REKAP                          │
│  Progress: 84% (progress bar)   │
│  (Tampil juga di Home Dashboard)│
└─────────────────────────────────┘
```

**✅ Sudah:**
- Form input penjualan, target, revenue
- Progress bar calculation
- Tersimpan di SharedPreferences
- Muncul di widget Home Dashboard

**🔜 Rencana:**
- Multiple entry per bulan (saat ini hanya satu nilai)
- Firestore storage (bukan SharedPreferences)
- History tracking
- Export Excel

#### 4.5.3 Total Emisi — Input Manual 🔜

> 🔜 **RENCANA:** Belum diimplementasikan.

```
🔜 RENCANA:
┌─────────────────────────────────┐
│  LAPORAN EMISI                  │
│  Periode: Juni 2026             │
├─────────────────────────────────┤
│  INPUT EMISI                    │
│  SO₂: [___] ton   NOx: [___] ton│
│  CO₂: [___] ton   Ash: [___] ton│
└─────────────────────────────────┘
```

#### 4.5.4 Hazard Report ⚠️

**Status: ⚠️ Sebagian — saat ini hanya berupa link ke Google Form via url_launcher.**

- ✅ Versi sederhana: tombol "Laporkan Bahaya" → membuka Google Form di browser
- 🔜 Enhancement: form built-in dengan foto + deskripsi
- 🔜 Geolocation otomatis
- 🔜 Status tracking: Open → In Review → Resolved
- 🔜 Push notif ke Safety Officer
- 🔜 Export PDF

#### 4.5.5 Settings & Configuration ⚠️

**Status: ⚠️ Sebagian — hanya pengaturan decimal places.**

- ✅ **Pengaturan Presisi Desimal**: Dropdown 0–3 angka di belakang koma, tersimpan di SharedPreferences
- 🔜 **Pengaturan Satuan (Unit)**: Belum ada — label satuan masih hardcoded
- 🔜 Sinkronisasi ke Firestore: belum ada (tersimpan lokal saja)

---

## 5. Fitur Tambahan yang Disarankan 🔜 RENCANA

> 🔜 **RENCANA:** Seluruh fitur di section ini belum diimplementasikan dan merupakan saran pengembangan ke depan.

### 5.1 🔔 Alarm & Notification Center 🔜
- Push notif untuk parameter di luar batas (integrasi FCM)
- Riwayat alarm dengan filter severity (Critical / Major / Minor)
- Acknowledge alarm dari app (dengan timestamp dan user)
- Silence/snooze untuk alarm non-kritis (max 30 menit, dicatat)

### 5.2 🔧 Work Order Mini (Maintenance Ticketing) 🔜
- Buat Work Order darurat langsung dari app (tanpa buka Maximo/D365)
- Isi: deskripsi, lokasi, priority, foto
- Status tracking: Open → In Progress → Closed
- Integrasi opsional ke Maximo via REST API atau D365

### 5.3 📦 Konsumsi Batubara & Chemical 🔜
- Input manual konsumsi batubara harian (ton)
- Stok batubara saat ini vs target (hari operasi tersisa)
- Input konsumsi chemical (NaOH, HCl, dll.)
- Grafik tren konsumsi vs produksi (korelasi efisiensi bahan bakar)

### 5.4 🌡️ Equipment Health Monitoring 🔜
- Status On/Off untuk equipment utama (BFP, CEP, ID/FD Fan, Mill)
- Running hours per equipment
- Alert jika running hours mendekati jadwal PM (Preventive Maintenance)

### 5.5 📸 Plant Gallery / Document Hub 🔜
- Foto kondisi plant (ter-timestamp dan geo-tagged)
- Upload SOP dan manual yang bisa diakses offline
- QR code scan untuk akses dokumen equipment spesifik

### 5.6 📅 Shift Handover Report 🔜
- Template laporan serah terima shift yang bisa di-generate otomatis dari logsheet
- Dikirim via email/WhatsApp ke tim shift berikutnya
- Mencakup: event penting, alarm aktif, pekerjaan ongoing, rekomendasi

### 5.7 💧 Water Chemistry Monitoring 🔜
- Input manual hasil uji kimia air (pH, conductivity, silica, hardness)
- Trend dan batas normal per parameter
- Notifikasi jika hasil uji di luar spesifikasi HRSG/Boiler

---

## 6. Autentikasi & Role-Based Access Control ⚠️ BELUM SELESAI

> ⚠️ **BELUM SELESAI:** Fitur autentikasi dan RBAC belum diimplementasikan sama sekali. Aplikasi saat ini langsung menampilkan dashboard tanpa login. Seluruh pengguna memiliki akses penuh ke semua fitur.
>
> Satu-satunya mekanisme "login" adalah Google Sign-In yang hanya digunakan untuk otorisasi akses Google Sheets API pada fitur Logsheet, bukan untuk autentikasi pengguna aplikasi.

### 6.1 Login Flow (Target — 🔜 RENCANA)

```
Splash Screen (3 detik)
    ↓
Cek session Firebase Auth
    ↓ (belum login)
Login Screen
  - Email + Password
  - "Lupa Password" → reset via email
    ↓
Fetch user role dari Firestore /users/{uid}
    ↓
Render app sesuai role (menu dan aksi yang visible berbeda)
```

### 6.2 Permission Matrix (Target — 🔜 RENCANA)

| Fitur | Operator | Supervisor | Manager/Admin | Executive |
|---|---|---|---|---|
| Home Dashboard | ✅ | ✅ | ✅ | ✅ |
| Plant Monitoring | ✅ | ✅ | ✅ | ✅ |
| Analytics Charts | ✅ | ✅ | ✅ | ✅ |
| Logsheet (isi) | ✅ | ✅ | ✅ | ❌ |
| Logsheet (approve) | ❌ | ✅ | ✅ | ❌ |
| OKR (lihat) | ✅ | ✅ | ✅ | ✅ |
| OKR (input/edit) | ❌ | ❌ | ✅ | ❌ |
| Sales (input) | ❌ | ❌ | ✅ | ❌ |
| Emisi (input) | ❌ | ❌ | ✅ | ❌ |
| Hazard Report | ✅ | ✅ | ✅ | ❌ |
| Alarm Acknowledge | ✅ | ✅ | ✅ | ❌ |
| Work Order (buat) | ✅ | ✅ | ✅ | ❌ |
| User Management | ❌ | ❌ | ✅ | ❌ |

---

## 7. Notifikasi & Alarm ⚠️

> ⚠️ **Status: Sebagian.** Saat ini hanya local notification untuk daily reminder. FCM dan notification center belum diimplementasikan.

### 7.1 Notifikasi yang Sudah Ada ✅

| Notifikasi | Trigger | Channel | Implementasi |
|---|---|---|---|
| **Daily Reminder** | Setiap jam 08:00 WITA | Local notification via `flutter_local_notifications` | ✅ Sudah |

### 7.2 Kategori Notifikasi (Target — 🔜 RENCANA)

| Kategori | Trigger | Channel | Penerima |
|---|---|---|---|
| **CRITICAL** | Parameter unit trip / alarm kritis | Push notif + sound | Semua user aktif |
| **MAJOR** | Parameter mendekati batas (warning) | Push notif | Operator + Supervisor on-shift |
| **CEMS** | Kadar emisi melebihi baku mutu | Push notif + email | Operator + Manager |
| **LOGSHEET** | Logsheet belum diisi H-1 jam shift end | Push notif | Operator yang bertugas |
| **MAINTENANCE** | Running hours mendekati PM interval | Push notif | Supervisor + Maintenance |
| **SALES** | Sales progress < 50% di pertengahan bulan | Push notif | Manager |

### 7.3 Notification Center 🔜 RENCANA
- Semua notif tersimpan di Firestore
- Filter: Semua / Belum dibaca / Per kategori
- Swipe untuk dismiss atau acknowledge

---

## 8. Offline Support & Sinkronisasi ⚠️

> ⚠️ **BELUM SELESAI:** Offline support masih sangat terbatas. Belum ada Hive/SQLite atau Firebase offline persistence yang diaktifkan.

### 8.1 Offline Behavior Aktual ✅

| Halaman | Offline Behavior |
|---|---|
| Home Dashboard | ❌ Tidak ada cache — data kosong/tidak muncul saat offline |
| Plant Monitoring | ❌ Tidak ada cache — bergantung pada RTDB streaming |
| Analytics | ❌ Tidak ada cache — chart kosong saat offline |
| Logsheet | ✅ Draft tersimpan lokal di **SharedPreferences**, bisa dilanjutkan saat online |
| Sales / Emisi input | ✅ Sales tersimpan di SharedPreferences (tidak perlu sync) |

### 8.2 🔜 Target Implementasi ke Depan

| Halaman | Target Offline Behavior |
|---|---|
| Home Dashboard | Tampilkan data cache terakhir + banner "Offline – data per HH:MM" |
| Plant Monitoring | Data statis dari cache, tidak streaming |
| Analytics | Chart dari cache, tidak update |
| Logsheet | Draft tersimpan lokal (Hive/SQLite), sync saat online |
| Sales / Emisi input | Queue lokal, auto-sync saat koneksi pulih |

**Target implementasi:** Firebase offline persistence + Hive/SQLite lokal untuk logsheet draft + structured cache RTDB.

---

## 9. User Flow Utama

### 9.1 Morning Handover — Aktual ✅

```
1. Buka app → langsung Home Dashboard (tanpa login) ✅
2. Cek beban kedua unit + NPHR (apakah dalam batas?) ✅
3. Cek cuaca, sales progress, CEMS compliance ✅
4. Buka Plant → Unit 1 & 2 (verifikasi parameter) ✅
5. Buka Logsheet → Google Sign-In → pilih shift ✅
6. Isi data manual per time slot ✅
7. Submit → langsung sync ke Google Sheets ✅
8. 🔜 Rencana: cek notifikasi alarm dari shift sebelumnya
9. 🔜 Rencana: logsheet auto-populated dari sensor
10. 🔜 Rencana: supervisor approval workflow
```

### 9.2 Admin Input Sales Bulanan — Aktual ✅

```
1. Buka app → More → Sales ✅
2. Isi form: Penjualan (MWh), Target (MWh), Revenue (Rp) ✅
3. Simpan → tersimpan di SharedPreferences ✅
4. Home Dashboard otomatis update progress bar sales ✅
5. 🔜 Rencana: history multiple entry per bulan
6. 🔜 Rencana: Firestore storage (bukan SharedPreferences)
```

### 9.3 Supervisor Approve Logsheet 🔜 RENCANA

```
🔜 RENCANA — Belum diimplementasikan:
1. Notif masuk: "Logsheet Shift Pagi oleh [Nama] menunggu approval"
2. Buka notif → langsung ke detail logsheet
3. Review data, tambah komentar jika perlu
4. Tap [Approve] → status berubah "Approved"
5. Cloud Function memicu sync ke Google Sheets
```

---

## 10. Milestone & Prioritas Pengembangan — Status Aktual

### ✅ Phase 1 — Foundation (Selesai)
| Item | Status | Keterangan |
|------|--------|------------|
| Redesign navigasi (bottom nav bar) | ✅ | 5 tabs: Home, Plant, Analytics, Logsheet, More |
| Home Dashboard (beban, NPHR, cuaca, sales) | ✅ | Semua widget berfungsi dengan data real-time |
| Firebase Auth + RBAC | ❌ **Belum** | 🔜 Rencana phase berikutnya |
| Plant monitoring Unit 1 & 2 | ✅ | Sensor grid + alarm detection + trip banner |

### ⚠️ Phase 2 — Core Features (Sebagian Selesai)
| Item | Status | Keterangan |
|------|--------|------------|
| NPHR page (curve) | ✅ | Kurva polynomial + real-time overlay |
| NPHR page (trend 7 hari) | 🔜 | Belum ada chart historis |
| CEMS (dual unit) | ✅ | Bottom tab CEMS 1 & 2 |
| CEMS (compliance badge) | 🔜 | Belum ada threshold checking |
| Analytics (multi-parameter chart) | ⚠️ | ✅ 3 parameter, 🔜 6 parameter + dual Y-axis + preset + export |
| Solar PV monitoring page | ❌ **Belum** | 🔜 Rencana |

### ⚠️ Phase 3 — Operations (Sebagian Selesai)
| Item | Status | Keterangan |
|------|--------|------------|
| Digital Logsheet + Google Sheets sync | ✅ | Full CRUD ke Google Sheets via OAuth2 |
| Logsheet auto-populate dari sensor | 🔜 | Masih manual input |
| Logsheet approval flow | 🔜 | Belum ada |
| Hazard Report (enhanced) | ⚠️ | ✅ link Google Form, 🔜 foto + geolocation + tracking |
| Push Notification Center (FCM) | ❌ **Belum** | Hanya local notification daily reminder |
| Offline support | ❌ **Belum** | Hanya SharedPreferences untuk draft |

### ❌ Phase 4 — Management (Belum Dimulai)
| Item | Status | Keterangan |
|------|--------|------------|
| Company OKR dashboard | 🔜 | Belum ada |
| Sales input & dashboard | ✅ | Sudah (via SharedPreferences) |
| Sales Firestore integration | 🔜 | Masih SharedPreferences |
| Total Emisi input & rekap | 🔜 | Belum ada |
| Shift Handover Report generator | 🔜 | Belum ada |
| Work Order mini | 🔜 | Belum ada |

---

## 11. Open Questions / Keputusan yang Perlu Dikonfirmasi

| # | Pertanyaan | Status / Impact |
|---|---|---|
| 1 | Google Sheets — 1 file per unit per bulan atau 1 file per shift? | ✅ **Terjawab:** 1 spreadsheet per unit per bulan, sheet tab per shift |
| 2 | Apakah data historical sensor RTDB diretain? (default: realtime only) | ❌ **Masih open** — Butuh InfluxDB/Firestore untuk historical chart jangka panjang |
| 3 | API cuaca: OpenWeatherMap sudah dipakai (1000 calls/hari). Cukup atau perlu migrasi? | ⚠️ **Perlu eval** — Pastikan tidak melebihi batas free tier |
| 4 | Apakah perlu Firestore atau cukup Google Sheets + SharedPreferences? | ❌ **Masih open** — Saat ini semua data non-RTDB pakai SharedPreferences & Google Sheets |
| 5 | Work Order: standalone atau perlu sync ke Maximo/D365? | ❌ **Masih open** — Scope jika Phase 4 dimulai |
| 6 | Bahasa app: Indonesia saja, atau bilingual ID/EN? | ❌ **Masih open** — Saat ini Indonesia saja |

---

*PRD v3.2 — Diupdate berdasarkan audit basis kode v1.0.2*
*Disiapkan oleh: M. Farhan Tandia (IC&IT Supervisor, MSW)*
*Tanggal: Juli 2026*
*Status: ✅ Diselaraskan dengan kode aktual — fitur ✅ = sudah jadi, ⚠️ = sebagian, 🔜 = rencana*
