# Product Requirements Document
## MSW ePlant Mobile Application — Version 4.1
**PT Makmur Sejahtera Wisesa (MSW) — Adaro Group**
**2×30 MW CFPP + Solar PV Plant**
**Codebase Aktual: v1.0.2 → Target: v2.0.0**

---

> **Status Legenda:**
> - ✅ Sudah diimplementasikan di v1.0.2
> - ⚠️ Sebagian selesai / ada gap
> - 🔜 Rencana pengembangan baru
> - 🆕 Keputusan baru dari sesi desain

---

## Changelog PRD

| Versi | Tanggal | Perubahan |
|---|---|---|
| v3.2 | Jun 2026 | Kondisi aktual codebase v1.0.2 |
| v4.0 | Jul 2026 | Homepage redesign, Login 3 role, Bottom nav dinamis, WO Report, MSW AI RAG, Warehouse QR, OKR dasar |
| **v4.1** | **Jul 2026** | **OKR CRUD (tambah/edit/hapus/ganti tahun/riwayat), Setting page redesign, Hierarki password 4 level, Set Password page, CEMS threshold baku mutu + threshold line chart + notifikasi** |

---

## Ringkasan Status Implementasi Aktual (v1.0.2)

| Fitur | Status | Keterangan |
|---|---|---|
| Bottom Navigation Bar (5 tabs) | ✅ | Home, Plant, Analytics, Logsheet, More |
| Dark Theme + Glass-morphism Cards | ✅ | Konsisten di semua halaman |
| Weather Widget (OpenWeatherMap) | ✅ | Suhu, kondisi, lokasi Tanjung |
| Total Generation PLTU | ✅ | Real-time dari RTDB |
| Solar PV Display | ⚠️ | Angka hardcoded 148 MWh |
| Unit Load Real-time (color-coded) | ✅ | Hijau/kuning/merah |
| Load Distribution PLN/AI | ✅ | Dari RTDB |
| NPHR Cards | ✅ | Unit 1 & 2 dengan target |
| Sales Progress Bar | ✅ | SharedPreferences |
| CEMS Dual Unit | ✅ | Bottom tab CEMS 1 & 2 |
| CEMS SO₂, NOx, Particulate, Hg | ✅ | Nilai real-time dari RTDB |
| CEMS Threshold Baku Mutu | 🆕🔜 | Threshold line di chart + notifikasi |
| CEMS Compliance Badge | 🆕🔜 | Check nilai vs baku mutu |
| Pull-to-Refresh | ✅ | Di homepage |
| Unit 1 & 2 Sensor Grid | ✅ | Color-coded + alarm |
| Trip/Shutdown Banner | ✅ | Load < 2 MW |
| Solar PV Dedicated Page | 🔜 | Belum ada |
| NPHR Curve Chart | ✅ | Polynomial curve 5–30 MW |
| NPHR Trend 7 Hari | 🔜 | Belum ada |
| Analytics Multi-Param (max 3) | ⚠️ | Target: 6 param + dual Y-axis |
| Logsheet Boiler (62 fields) | ✅ | Google Sheets via OAuth2 |
| Logsheet Steam Turbine (57 fields) | ✅ | Google Sheets via OAuth2 |
| Logsheet Auto-populate Sensor | 🔜 | Semua manual |
| Logsheet Approval Flow | 🔜 | Langsung sync tanpa approval |
| Sales Manual Input | ✅ | SharedPreferences |
| Hazard Report | ⚠️ | Hanya link Google Form |
| OKR Dashboard (view) | 🔜 | Belum ada |
| OKR CRUD (tambah/edit/hapus) | 🆕🔜 | Baru |
| OKR Ganti Tahun + Riwayat | 🆕🔜 | Baru |
| Emisi Manual Input | 🔜 | Belum ada |
| Login 3 Role + Password | 🆕🔜 | Baru |
| Setting Page Redesign | 🆕🔜 | Baru |
| Hierarki Password 4 Level | 🆕🔜 | Baru |
| Set Password Page | 🆕🔜 | Baru |
| Push Notification (FCM) | 🔜 | Hanya local notification |
| Firestore | 🔜 | Belum digunakan sama sekali |
| WO Progress Report | 🆕🔜 | Baru |
| MSW AI Assistant (RAG) | 🆕🔜 | Baru |
| Warehouse QR Material | 🆕🔜 | Baru |

---

## 1. Overview & Latar Belakang

### 1.1 Product Summary

MSW ePlant adalah aplikasi mobile internal berbasis Flutter untuk monitoring dan operasional PT Makmur Sejahtera Wisesa — PLTU 2×30 MW + Solar PV di Tanjung, Kalimantan Selatan. PRD v4.1 mendefinisikan target pengembangan v2.0.0 berdasarkan kondisi aktual codebase v1.0.2 ditambah seluruh keputusan desain dari sesi Juli 2026.

### 1.2 Masalah yang Diselesaikan

| Masalah | Solusi | Status |
|---|---|---|
| Navigasi side-panel tidak efisien | Bottom navigation bar | ✅ |
| Tidak ada ringkasan KPI di satu layar | Homepage dashboard | ✅ |
| NPHR tanpa konteks | NPHR + beban real-time | ✅ |
| Logsheet masih kertas | Digital Logsheet → Google Sheets | ✅ ⚠️ |
| App tidak punya identitas user/role | Login 3 role + bottom nav dinamis | 🆕🔜 |
| Homepage terlalu teknikal, tidak inklusif | Welcome page + grid menu departemen | 🆕🔜 |
| Laporan WO maintenance via WA tidak terstruktur | WO Progress Report + WA share | 🆕🔜 |
| Pengetahuan troubleshooting hilang saat resign | MSW AI Knowledge Base (RAG) | 🆕🔜 |
| Tidak ada visibilitas OKR | OKR Dashboard + CRUD | 🆕🔜 |
| OKR tidak bisa diedit/direvisi dari app | OKR Editor (tambah/edit/hapus/ganti tahun) | 🆕🔜 |
| Password tidak bisa diubah tanpa update app | Set Password page + Firestore config | 🆕🔜 |
| CEMS tidak ada indikator batas baku mutu | Threshold line chart + notifikasi | 🆕🔜 |
| Data emisi tidak ada di app | Emisi manual input | 🔜 |

---

## 2. Arsitektur & Tech Stack

### 2.1 Tech Stack

```
✅ Aktif  |  ⚠️ Sebagian  |  🔜 Rencana  |  🆕 Baru

Frontend:         Flutter (Dart) 3.x — Android ✅ iOS ✅
Realtime Data:    Firebase Realtime Database ✅
                  5 path: table1, table2, cems1, cems2, nphr
Database:         Cloud Firestore 🔜
                  (saat ini: SharedPreferences & Google Sheets)
Auth:             Role selector + password via Firestore 🆕🔜
                  (bukan Firebase Auth — 4 level password di Firestore)
Logsheet Sync:    Google Sheets API v4 (OAuth2 via google_sign_in) ✅
Weather:          OpenWeatherMap API ✅
Local Notif:      flutter_local_notifications ✅ (daily 08:00 WITA)
                  CEMS threshold alert 🆕🔜
Push Notif:       Firebase Cloud Messaging (FCM) 🔜
State Mgmt:       setState + StreamSubscription ✅
Charts:           fl_chart ^1.1.1 ✅
                  Threshold line (HorizontalLine) 🆕🔜
Local Storage:    shared_preferences ^2.2.3 ✅
Internet:         http ^1.2.1 ✅
URL Launcher:     url_launcher ^6.3.1 ✅
QR Code:          mobile_scanner 🆕🔜
WhatsApp Share:   share_plus 🆕🔜
AI/RAG:           Gemini 2.0 Flash API 🆕🔜
                  Google text-embedding-004 🆕🔜
                  Firestore Vector Search 🆕🔜
                  Tavily Search API (web fallback) 🆕🔜
```

### 2.2 Struktur Data Firebase

#### ✅ Firebase Realtime Database (Aktif)

```
/excel_data/
├── /table1/   → Boiler Unit 1
│   Array[]: [DATETIME, UNIT1_LOAD, TOTAL_LOAD, MAIN_STEAM_PRESS, ...]
├── /table2/   → Boiler Unit 2
├── /cems1/    → CEMS Unit 1 [SO2, NOX, PARTICULATE, HG, ...]
├── /cems2/    → CEMS Unit 2
└── /nphr/     → [unit1_value, unit2_value]
```

#### 🔜 Cloud Firestore (Rencana)

```
/config/
  ├── passwords/
  │     ├── operation:   { hash, last_changed, changed_by }
  │     ├── maintenance: { hash, last_changed, changed_by }
  │     ├── okr_editor:  { hash, last_changed, changed_by }
  │     └── master:      { hash, last_changed, changed_by }
  ├── cems_thresholds/          🆕 Baku mutu CEMS
  │     ├── pm:   { value: 50,   unit: "mg/Nm³", label: "Partikulat (PM)" }
  │     ├── so2:  { value: 550,  unit: "mg/Nm³", label: "Sulfur Dioksida (SO₂)" }
  │     ├── nox:  { value: 550,  unit: "mg/Nm³", label: "Nitrogen Oksida (NOx)" }
  │     └── hg:   { value: 0.03, unit: "mg/Nm³", label: "Merkuri (Hg)", periodic: true }
  └── logsheet_config/{unit}/spreadsheetId

/okr/{year}/                    🆕 OKR CRUD
  ├── meta: { created_at, created_by, is_active, copied_from? }
  ├── objectives/{obj_id}
  │     ├── title, color, order
  │     └── key_results/{kr_id}
  │           ├── label         ← auto dari order (a, b, c...)
  │           ├── description
  │           ├── type          ← numeric | qualitative | binary
  │           ├── target, target_unit
  │           ├── actual_value
  │           ├── progress_pct  ← auto-calc atau manual
  │           ├── status        ← on_track | at_risk | behind
  │           ├── notes
  │           ├── phase_options[] ← khusus kualitatif
  │           └── order
  └── changelog/{change_id}
        ├── timestamp, changed_by
        └── description         ← auto-generate

/wo_reports/{report_id}
  ├── wo_number, equipment_name, equipment_tag
  ├── location, date, start_time, end_time, duration_minutes
  ├── technician_name, supervisor_name
  ├── initial_status
  ├── symptoms[], description
  ├── checklist[{ item, done }]
  ├── findings[{ component, part_number, condition, measurement }]
  ├── solution, spare_parts[{ name, qty, unit }]
  ├── final_status, photos[], wa_text
  └── ai_indexed: false

/equipment_master/{id}
  ├── name, tag, type, location, unit, system

/cems_alerts/{id}               🆕 Log notifikasi CEMS
  ├── unit: "unit1" | "unit2"
  ├── parameter: "so2" | "nox" | "pm" | "hg"
  ├── value: float
  ├── threshold: float
  ├── exceeded_by: float        ← selisih vs threshold
  ├── timestamp: Timestamp
  └── acknowledged: bool

/sales/{month}
/emissions/{month}
/hazard_reports/{id}
/notifications/{id}
/ai_query_log/{id}
/ai_feedback/{id}
```

#### ✅ Google Sheets (Aktif — Logsheet)

```
Spreadsheet per unit per bulan:
  "Logsheet Unit 1 - Juni 2026"
  ├── Sheet "Pagi 07-15"
  ├── Sheet "Siang 15-23"
  └── Sheet "Malam 23-07"
```

---

## 3. Desain Navigasi & UI

### 3.1 Login Screen 🆕

```
┌─────────────────────────────────┐
│         [Logo MSW]              │
│         MSW ePlant              │
│   PT Makmur Sejahtera Wisesa    │
│   2×30 MW CFPP + Solar PV       │
│                                 │
│  Masuk sebagai:                 │
│  ┌─────────────────────────┐   │
│  │ ⚡ Operation        🔒  │   │ ← Password required
│  │ Plant monitoring+Logsheet│  │
│  └─────────────────────────┘   │
│  ┌─────────────────────────┐   │
│  │ 🔧 Maintenance      🔒  │   │ ← Password required
│  │ WO Report + MSW AI      │   │
│  └─────────────────────────┘   │
│  ┌─────────────────────────┐   │
│  │ 👁 General  [TANPA PW]  │   │ ← Langsung masuk
│  │ Monitoring + OKR        │   │
│  └─────────────────────────┘   │
│                                 │
│  [Field password — muncul jika  │
│   Operation/Maintenance dipilih]│
│  [Masuk sebagai {Role} →]       │
└─────────────────────────────────┘
```

**Behavior:**
- Tap role card → highlight border warna role
- Operation/Maintenance dipilih → field password muncul animasi slide-down
- General → field password hilang, tombol langsung aktif
- Password salah → shake animation + pesan error + counter percobaan
- Setelah 3× salah → lockout 5 menit
- Session tersimpan di SharedPreferences (< 12 jam)
- Role strip tampil di semua halaman setelah login

### 3.2 Bottom Navigation Bar — Dinamis per Role 🆕

**4 tab** (bukan 5), tab ke-3 berbeda per role:

| Slot | Operation | Maintenance | General |
|---|---|---|---|
| 1 | 🏠 Home | 🏠 Home | 🏠 Home |
| 2 | ⚡ Operation | ⚡ Operation | ⚡ Operation |
| 3 | 📋 Logsheet | 🔧 Maintenance | 🎯 OKR |
| 4 | ⚙️ Setting | ⚙️ Setting | ⚙️ Setting |

### 3.3 Homepage — Welcome Page + Menu Grid 🆕

**Layer struktur:**
1. Top bar (logo + notif)
2. Greeting + role strip
3. Plant status card ringkas (real-time)
4. Quick stats 3 kolom (MWh hari ini, Sales %, Availability %)
5. Weather strip
6. Menu grid (konten berbeda per role)

**Menu grid — konten per role:**

| Menu | Icon | Operation | Maintenance | General |
|---|---|---|---|---|
| Operation | ⚡ | ✅ | ✅ | ✅ |
| Maintenance | 🔧 | ❌ Hidden | ✅ | ❌ Hidden |
| HSE / Hazard | 🦺 | ✅ | ✅ | ✅ |
| Warehouse | 📦 | ✅ | ✅ | ✅ |
| OKR | 🎯 | ✅ | ✅ | ✅ |
| MSW AI | 🤖 | ❌ Hidden | ✅ | ❌ Hidden |
| Analytics | 📊 | ✅ | ✅ | ✅ |
| Logsheet | 📋 | ✅ | ❌ Hidden | ❌ Hidden |

> Menu hidden → **dihapus dari widget tree**, bukan di-grey.

### 3.4 Design System

```
Tema:         Dark
Background:   #090E1A
Surface:      #111827
Surface2:     #1C2539
Border:       #1F2D45
Primary:      #00C2FF  (Operation)
Maintenance:  #FFB020  (amber)
General/HSE:  #00E5A0  (hijau)
Warning:      #FFB020
Danger:       #FF4D6A
Purple:       #C084FC  (Admin/Master)
Text:         #F0F4FF
Text Sub:     #6B7FA3
```

---

## 4. Fitur Detail Per Halaman

### 4.1 LOGIN PAGE 🆕🔜
*(Lihat Section 3.1)*

**Tech notes:**
- Password di-hash (SHA-256) sebelum disimpan ke Firestore
- Compare: hash(input) == hash(stored)
- Session: SharedPreferences `{ role, login_timestamp }`
- Expired setelah 12 jam → kembali ke login page

---

### 4.2 HOME — Welcome Page 🆕🔜
*(Lihat Section 3.3)*

---

### 4.3 OPERATION — Sub-menu

#### 4.3.1 Plant Monitoring (Unit 1 & 2) ✅
- Sensor grid color-coded ✅
- Trip/shutdown banner ✅
- Tap parameter → chart detail ✅

#### 4.3.2 CEMS 🆕 (Major Update)

**Baku Mutu yang Berlaku (Peraturan PTBAE-PU / PermenLHK):**

| Parameter | Threshold | Satuan | Tipe Monitoring |
|---|---|---|---|
| Partikulat (PM) | **50** | mg/Nm³ | CEMS real-time |
| Sulfur Dioksida (SO₂) | **550** | mg/Nm³ | CEMS real-time |
| Nitrogen Oksida (NOx, sebagai NO₂) | **550** | mg/Nm³ | CEMS real-time |
| Merkuri (Hg) | **0.03** | mg/Nm³ | Uji berkala (bukan CEMS) |

**Tampilan CEMS (update):**

```
┌─────────────────────────────────┐
│  CEMS          UNIT 1  UNIT 2   │
├─────────────────────────────────┤
│  Partikulat    23      19       │
│  Batas: 50 mg/Nm³    ✅    ✅   │
│  ████░░░░░░ 46%  ███░░░░░░ 38% │
│                                 │
│  SO₂           142     138      │
│  Batas: 550 mg/Nm³   ✅    ✅   │
│  ████░░░░░░ 26%  ███░░░░░░ 25% │
│                                 │
│  NOx           91      87       │
│  Batas: 550 mg/Nm³   ✅    ✅   │
│  ██░░░░░░░░ 17%  ██░░░░░░░ 16% │
│                                 │
│  Hg            0.011   0.009    │
│  Batas: 0.03 mg/Nm³  ✅    ✅   │
│  ████░░░░░░ 37%  ███░░░░░░ 30% │
│  ⚠️ Uji berkala — bukan CEMS   │
└─────────────────────────────────┘
```

**Progress bar per parameter:**
- Bar warna hijau → nilai ≤ 80% threshold
- Bar warna amber → nilai 80%–100% threshold (warning zone)
- Bar warna merah → nilai > 100% threshold (exceeded)

**Threshold line di chart (fl_chart):**

```dart
// Implementasi di fl_chart
LineChartData(
  extraLinesData: ExtraLinesData(
    horizontalLines: [
      HorizontalLine(
        y: 550,          // threshold SO₂
        color: Colors.red.withOpacity(0.7),
        strokeWidth: 1.5,
        dashArray: [8, 4],   // garis putus-putus
        label: HorizontalLineLabel(
          show: true,
          labelResolver: (_) => 'Batas 550',
          style: TextStyle(
            color: Colors.red,
            fontSize: 9,
            fontWeight: FontWeight.bold,
          ),
          alignment: Alignment.topRight,
        ),
      ),
    ],
  ),
)
```

**Warning zone shading (opsional, tambahan visual):**
```dart
// Area 80%–100% threshold diberi background amber transparan
BetweenBarsData(
  fromIndex: 0,
  toIndex: 1,
  color: Colors.amber.withOpacity(0.08),
)
```

**Compliance badge di card:**
- ✅ **Compliant** — semua parameter kedua unit dalam batas
- ⚠️ **Warning** — ada parameter mendekati batas (> 80%)
- 🔴 **Exceeded** — ada parameter melebihi baku mutu

**Notifikasi CEMS (threshold alert):** *(lihat Section 6)*

#### 4.3.3 Solar PV 🔜
- Halaman dedicated (belum ada)
- Power output, irradiance, PR ratio
- Grafik produksi harian
- Produksi kWh hari ini

#### 4.3.4 NPHR ⚠️
- Curve chart polynomial ✅
- Real-time overlay Unit 1 & 2 ✅
- 🔜 Trend 7 hari historis

#### 4.3.5 Analytics ⚠️
- Single parameter chart ✅
- 🔜 Multi-parameter max 6 + dual Y-axis
- 🔜 Preset konfigurasi
- 🔜 Export PNG/CSV

#### 4.3.6 Logsheet Digital ⚠️
*(Role Operation only)*

- Form Boiler 62 fields + Steam Turbine 57 fields ✅
- Google Sheets sync via OAuth2 ✅
- Periode: 24 jam, 10:00 → 09:00, interval 1 jam ✅
- 🔜 Auto-populate dari sensor RTDB
- 🔜 Approval flow supervisor

---

### 4.4 MAINTENANCE — Sub-menu 🆕
*(Role Maintenance only)*

#### 4.4.1 WO Progress Report 🆕🔜

**Form 5 section:**
1. **Identitas** — No. WO, Equipment (dari master), Lokasi, Tanggal, Jam, Teknisi, Supervisor
2. **Kondisi Awal** — Status (Normal/Abnormal/Trip/Planned), Gejala (multi-select), Deskripsi
3. **Pekerjaan** — Checklist dinamis (drag reorder, tambah/hapus item)
4. **Temuan** — Per komponen: nama, part number, kondisi, pengukuran, foto
5. **Solusi & Hasil** — Tindakan, spare part used, status akhir, jam selesai

**Output WhatsApp (auto-generate via `share_plus`):**
```
━━━━━━━━━━━━━━━━━━━━━━
🔧 *WO PROGRESS REPORT*
━━━━━━━━━━━━━━━━━━━━━━
📋 *No. WO:* WO-2026-0847
⚙️ *Equipment:* BFP No.1 (P-001A)
📍 *Lokasi:* Pump House Unit 1
📅 *12 Jun 2026, 08:30*
👤 *Teknisi:* Agus Salim
━━━━━━━━━━━━━━━━━━━━━━
🚨 *KONDISI AWAL*
Trip — Vibrasi tinggi, Suara abnormal
━━━━━━━━━━━━━━━━━━━━━━
🔨 *PEKERJAAN*
✅ Isolasi & LOTO
✅ Cek alignment
✅ Buka bearing housing
━━━━━━━━━━━━━━━━━━━━━━
🔍 *TEMUAN*
• Bearing DE 6312-2RS: Aus, cage retak
  Clearance: 0.12mm (std: 0.03mm)
━━━━━━━━━━━━━━━━━━━━━━
✅ *HASIL*
Ganti bearing + mechanical seal
⏱️ Durasi: 3j 45m · Status: SELESAI
━━━━━━━━━━━━━━━━━━━━━━
_via MSW ePlant · RPT-20260612-0847_
```

**Storage:** Firestore `/wo_reports/{id}` → flag `ai_indexed: false` → Cloud Function trigger embed ke Vector DB.

#### 4.4.2 MSW AI Assistant 🆕🔜

**Arsitektur RAG (Hybrid):**
```
Query user
    ↓
Embed (Google text-embedding-004)
    ↓
Vector search Firestore (score threshold: 0.75)
    ↓ Score rendah? → Tavily web search (fallback)
    ↓
Build prompt + context
    ↓
Gemini 2.0 Flash API
    ↓
Jawaban + sumber (WO ID / dokumen / referensi umum)
```

**Fallback chain:** Gemini 2.0 Flash → Gemini 1.5 Pro → raw WO cards (jika API down)

**Tipe sumber jawaban:**
- `[WO-2026-0847]` → dari WO history MSW
- `[Manual Sulzer BFP]` → dari dokumen teknis yang di-upload
- `[Referensi teknis umum]` → dari web search fallback

**Feedback loop:** 👍 / 👎 / ⚠️ Kurang akurat → Firestore `/ai_feedback`

**Estimasi biaya:** ~$0.50–$1/bulan (50 query/hari, Gemini 2.0 Flash)

---

### 4.5 HSE 🔜
*(Semua role)*

- Saat ini: tombol link Google Form ⚠️
- Target: form built-in dengan foto, geolocation, kategori, status tracking

---

### 4.6 WAREHOUSE 🆕🔜
*(Semua role)*

- Scan QR code di rak/bin gudang → form permintaan material
- Data material dari Firestore `/equipment_master`
- Submit → pencatatan request dengan nama pemohon + WO/keperluan

---

### 4.7 OKR DASHBOARD 🆕🔜
*(Semua role — lihat + input progress dengan password OKR)*

#### 4.7.1 Tampilan OKR

**Header:** Nama perusahaan + tahun + overall progress bar (rata-rata semua KR)

**Per Objective:**
- Nomor urut + judul + persentase progress + warna kustom
- Progress bar objective (rata-rata KR di dalamnya)
- Garis warna di sisi kiri (border-left sesuai warna objective)

**Per Key Result:**
- Label huruf (a, b, c...) auto dari urutan
- Deskripsi lengkap
- Progress bar + persentase + nilai aktual vs target
- Status badge: ✅ On Track / ⚠️ At Risk / 🔴 Behind / ⬜ N/A
- Catatan/keterangan terbaru

**3 tipe KR:**

| Tipe | Input | Contoh |
|---|---|---|
| **Numerik** | Angka aktual, target, satuan | NPAT USD 7.80M, EAF 88%, Solar 746 MWh |
| **Kualitatif** | Pilihan fase + % manual + catatan | Optimus: Planning/Construction/Commissioning/Done |
| **Binary** | Counter angka per sub-item | Safety: 0 Fatality, 0 LTI, 0 MTC, 0 FAC, 0 Env |

**Timestamp:** "Terakhir diperbarui: {tanggal} · {jam} WIB · oleh Admin"

#### 4.7.2 OKR 2026 — Data Awal

**Objective 1: Deliver Reliable and Profitable Performance** (warna: #00C2FF)

| KR | Deskripsi | Tipe | Target | Satuan |
|---|---|---|---|---|
| a | Achieve NPAT | Numerik | 7.80 | USD M |
| b | Achieve EAF | Numerik | 88 | % |
| c | Achieve SAIDI ≤1.0 jam dan SAIFI ≤1.0 frekuensi | Kualitatif | ≤1.0 | jam/freq |
| d | Solar PV Kelanis production | Numerik | 746 | MWh |
| e | Initiate cost optimization initiatives | Numerik | 3 | inisiatif |

**Objective 2: Execute Value-Driven Project Development** (warna: #C084FC)

| KR | Deskripsi | Tipe | Target | Satuan |
|---|---|---|---|---|
| a | Optimus — Construction and implementation-stage | Kualitatif | Done | fase |
| b | Explore green initiatives & electrification projects | Numerik | 3 | proyek |

**Objective 3: Strengthen Sustainability and Compliance** (warna: #00E5A0)

| KR | Deskripsi | Tipe | Target | Satuan |
|---|---|---|---|---|
| a | Carbon emission intensity ≤1.297 ton CO₂e/MWh | Numerik | 1.297 | ton CO₂e/MWh |
| b | Carbon reduction 13.308 ton CO₂e via co-firing & Solar PV | Numerik | 13308 | ton CO₂e |
| c | Safety: 0 Fatality, 0 LTI, 0 MTC, 0 FAC, 0 Env. Incident | Binary | 0 | setiap kategori |
| d | FABA utilization | Numerik | 15000 | ton |
| e | Comprehensive assessment & comply all regulations | Numerik | 5 | regulasi |

#### 4.7.3 OKR CRUD — Editor 🆕

*Diakses dari Setting → OKR Editor → (password OKR)*

**Fitur editor:**

**A. Manajemen Tahun:**
- Navigasi ‹ › antar tahun yang sudah ada
- Chip tahun lama → bisa dilihat (read-only)
- Tombol "+ Tahun Baru" → pilih: salin struktur tahun sebelumnya (progress di-reset ke 0) atau mulai dari kosong
- OKR lama tetap tersimpan, tidak dihapus

**B. Edit Objective:**
- Drag reorder (ikon ⠿)
- Edit judul inline (text field)
- Pilih warna dari 6 opsi
- Hapus objective → konfirmasi bottom sheet modal (warning: semua KR dan progress terhapus permanen)

**C. Edit Key Result:**
- Drag reorder dalam objective
- Edit deskripsi (textarea)
- Pilih tipe: Numerik / Kualitatif / Binary
- Set nilai target dan satuan
- Untuk kualitatif: set pilihan fase (Planning, Construction, dll)
- Hapus KR → konfirmasi

**D. Tambah:**
- "+ Tambah Key Result" di bawah tiap objective
- "+ Tambah Objective Baru" di bawah semua objective

**E. Riwayat Perubahan (Changelog):**
- Auto-generate setiap kali struktur disimpan
- Mencatat: apa yang berubah, siapa, kapan
- Contoh: "Revisi target KR 1d: 800 MWh → 746 MWh · 14 Jul 2026 · Admin"
- Tersimpan di Firestore `/okr/{year}/changelog`

#### 4.7.4 Update Progress KR 🆕

*Diakses dari Setting → Update OKR Progress → (password OKR)*

Per KR, Admin bisa update:
- **Numerik:** nilai aktual (slider + angka), auto-hitung progress %
- **Kualitatif:** pilih fase aktif + % manual + catatan teks
- **Binary:** update counter per sub-item (Fatality, LTI, dll)
- Status: On Track / On Progress / Behind
- Catatan/keterangan

Semua perubahan langsung update Firestore → real-time ke semua user.

---

### 4.8 SETTING PAGE 🆕

*(Tab ke-4 bottom nav, semua role)*

**Struktur menu Setting:**

```
Setting
├── [Umum]
│   ├── Tema (Dark mode)
│   ├── Format Angka (decimal places)
│   └── Notifikasi (daily reminder)
│
├── [Manajemen 🔐 Terproteksi]
│   ├── OKR Editor          → password OKR
│   │   ├── Edit Struktur OKR (CRUD)
│   │   └── Update Progress KR
│   └── Set Password Login  → password Master
│       ├── Set Password Operation
│       ├── Set Password Maintenance
│       ├── Set Password OKR Editor
│       └── Set Password Master (diri sendiri)
│
├── [Tentang]
│   ├── Info App (versi, build)
│   ├── Panduan Pengguna
│   └── Kontak IT Support (IC&IT ext.)
│
└── [Keluar / Ganti Role]
```

**Session info strip di atas menu:** Menampilkan role aktif saat ini + sisa waktu session + tombol "Ganti" (kembali ke login page).

---

## 5. Sistem Password & Autentikasi 🆕

### 5.1 Hierarki Password (4 Level)

```
Level 4 — 🛡 Master Admin
  → Membuka halaman "Set Password Login"
  → Bisa ubah semua password termasuk dirinya sendiri
  → Hanya dipegang IC&IT Supervisor
  → Jika lupa: reset via Firestore Console

Level 3 — 🎯 OKR Editor
  → Membuka OKR Editor di Setting
  → Bisa edit struktur OKR + update progress
  → Dipegang Admin/Manager yang bertanggung jawab OKR

Level 2 — ⚡ Operation
  → Login role Operation
  → Akses Logsheet, Plant monitoring
  → Dipegang Kepala Shift & Operator

Level 1 — 🔧 Maintenance
  → Login role Maintenance
  → Akses WO Report, MSW AI
  → Dipegang tim Maintenance

[General — tanpa password]
  → Monitoring umum, OKR view, Warehouse, HSE
```

### 5.2 Password Gate Behavior

| Kondisi | Behavior |
|---|---|
| Password benar | Buka halaman tujuan, simpan unlock state sementara (30 menit) |
| Password salah | Shake animation + "Password salah. Sisa: N×" |
| 3× salah berturut | Lockout 5 menit + pesan "Coba lagi dalam 5 menit" |
| Lupa password | "Hubungi IC&IT untuk reset via Firestore Console" |

### 5.3 Set Password Flow

1. Buka Setting → Set Password Login
2. Gate: masukkan password Master
3. Jika benar → halaman Set Password muncul
4. 4 kartu password (Operation, Maintenance, OKR, Master)
5. Per kartu: input password baru + konfirmasi + strength indicator
6. Simpan → hash (SHA-256) → update Firestore `/config/passwords/{role}`
7. Perubahan langsung aktif, tidak perlu restart app

### 5.4 Login Flow

```
Buka app
    ↓
Cek SharedPreferences: session valid? (< 12 jam)
    ↓ Ya → Home sesuai role terakhir
    ↓ Tidak → Login Page
         ↓
    Pilih role card
         ↓
    Operation/Maintenance → field password muncul
    General → tombol langsung aktif
         ↓
    Submit → fetch hash dari Firestore /config/passwords/{role}
           → compare SHA-256(input) == stored_hash
         ↓
    Match → simpan session (role, timestamp) → Home
    No match → error + counter percobaan
```

### 5.5 Role Permission Matrix

| Fitur | Operation | Maintenance | General |
|---|---|---|---|
| Home (plant status + grid) | ✅ | ✅ | ✅ |
| Plant Monitoring (Unit 1 & 2) | ✅ | ✅ | ✅ |
| CEMS (view + chart) | ✅ | ✅ | ✅ |
| Solar PV | ✅ | ✅ | ✅ |
| NPHR | ✅ | ✅ | ✅ |
| Analytics | ✅ | ✅ | ✅ |
| **Logsheet (isi)** | ✅ | ❌ | ❌ |
| **WO Progress Report** | ❌ | ✅ | ❌ |
| **MSW AI Assistant** | ❌ | ✅ | ❌ |
| HSE / Hazard Report | ✅ | ✅ | ✅ |
| Warehouse QR | ✅ | ✅ | ✅ |
| OKR (lihat) | ✅ | ✅ | ✅ |
| OKR (edit struktur + progress) | Password OKR | Password OKR | Password OKR |
| Sales (lihat) | ✅ | ✅ | ✅ |
| Sales (input) | ✅ | ❌ | ❌ |
| Setting (umum) | ✅ | ✅ | ✅ |
| Setting OKR Editor | Password OKR | Password OKR | Password OKR |
| Setting Set Password | Password Master | Password Master | Password Master |

---

## 6. Notifikasi & Alarm

### 6.1 Sudah Ada ✅
- Daily reminder jam 08:00 WITA via `flutter_local_notifications`

### 6.2 CEMS Threshold Alert 🆕🔜

**Trigger:** Nilai CEMS dari RTDB melebihi baku mutu yang tersimpan di Firestore `/config/cems_thresholds`

**Implementasi:**
```dart
// Di RTDB stream listener
void _checkCemsThresholds(CemsData data, String unit) {
  final thresholds = {
    'pm':  50.0,
    'so2': 550.0,
    'nox': 550.0,
    'hg':  0.03,
  };
  
  thresholds.forEach((param, limit) {
    final value = data.getValue(param);
    if (value > limit) {
      // 1. Tampilkan local notification
      _showCemsAlert(unit, param, value, limit);
      // 2. Log ke Firestore /cems_alerts
      _logCemsAlert(unit, param, value, limit);
    } else if (value > limit * 0.8) {
      // Warning zone: > 80% threshold
      _showCemsWarning(unit, param, value, limit);
    }
  });
}
```

**Notifikasi yang muncul:**

| Kondisi | Level | Isi Notifikasi |
|---|---|---|
| Nilai > threshold | 🔴 EXCEEDED | "⚠️ CEMS Unit 1 — SO₂ melebihi baku mutu! Aktual: 612 mg/Nm³ (Batas: 550)" |
| Nilai 80–100% threshold | 🟡 WARNING | "⚠️ CEMS Unit 2 — NOx mendekati batas. Aktual: 462 mg/Nm³ (80% dari 550)" |
| Nilai kembali normal | ✅ RESOLVED | "✅ CEMS Unit 1 — SO₂ kembali normal. Aktual: 380 mg/Nm³" |

**Frekuensi:** Notifikasi tidak berulang-ulang jika masih exceeded — hanya trigger satu kali saat pertama melewati threshold, dan satu kali lagi saat kembali normal.

**Catatan Hg (Merkuri):** Karena Hg adalah uji berkala (bukan CEMS real-time), nilai Hg di app adalah **input manual** oleh Admin, bukan stream dari RTDB. Threshold check tetap dilakukan saat nilai di-input.

### 6.3 Notifikasi Lain 🔜

| Kategori | Trigger | Channel |
|---|---|---|
| CRITICAL | Parameter trip / alarm kritis | Push notif + sound (FCM) |
| MAJOR | Nilai sensor mendekati batas | Push notif (FCM) |
| LOGSHEET | Belum diisi H-1 jam shift end | Push notif |
| WO | WO baru dibuat | Notif in-app |

---

## 7. Offline Support ⚠️

| Halaman | Aktual | Target |
|---|---|---|
| Home | ❌ Data kosong | Cache terakhir + banner "Offline" |
| Plant/CEMS/NPHR | ❌ Bergantung RTDB stream | Data statis dari cache |
| Analytics | ❌ Chart kosong | Cache |
| Logsheet | ✅ Draft di SharedPreferences | Hive/SQLite lokal |
| Sales | ✅ SharedPreferences | — |
| WO Report | — | Draft lokal, sync saat online |

---

## 8. User Flow Utama

### 8.1 Operator Shift

```
1. Buka app → Login (Operation + password)
2. Home → cek beban unit + NPHR + cuaca
3. Tap CEMS → cek nilai + compliance badge + chart threshold line
4. Jika ada notif CEMS → buka, cek detail, acknowledge
5. Tap Plant → cek parameter sensor
6. Tab Logsheet → pilih shift → isi form per time slot
7. Submit → sync ke Google Sheets
```

### 8.2 Teknisi Maintenance

```
1. Buka app → Login (Maintenance + password)
2. Home → grid menu → Maintenance → WO Progress Report
3. Isi form 5 section + foto temuan
4. Preview WhatsApp text → Share ke grup WA
5. Submit → simpan ke Firestore → Cloud Function embed AI
6. MSW AI → tanya troubleshooting berbasis WO history
```

### 8.3 Admin — Update OKR

```
1. Login (role apapun)
2. Setting → OKR Editor → masukkan password OKR
3. Tab "Edit Struktur" → edit/tambah/hapus Objective & KR
4. Tab "Update Progress" → update nilai aktual + status + catatan
5. Simpan → update Firestore → real-time ke semua user
```

### 8.4 Admin — Ganti Password

```
1. Login (role apapun)
2. Setting → Set Password Login → masukkan password Master
3. Pilih kartu password yang ingin diubah
4. Input password baru + konfirmasi + cek strength
5. Simpan → hash → update Firestore → aktif langsung
```

### 8.5 General User

```
1. Buka app → Login (General — tanpa password)
2. Home → grid menu → OKR → lihat progress semua KR
3. Atau → Hazard Report → laporkan potensi bahaya
4. Atau → Warehouse → scan QR → request material
```

---

## 9. Milestone & Prioritas Pengembangan

### ✅ Phase 1 — Selesai (v1.0.2)
- Bottom nav 5 tab
- Home dashboard real-time
- Plant monitoring Unit 1 & 2
- NPHR curve
- CEMS dual unit (nilai real-time)
- Logsheet digital → Google Sheets
- Sales manual input
- Weather API
- Local notification daily

### 🔜 Phase 2 — Foundation Baru (Target v2.0.0)

| Item | Effort | Priority |
|---|---|---|
| Login page 3 role + password (Firestore) | S | P1 |
| Homepage redesign (welcome + grid menu) | M | P1 |
| Bottom nav 4 tab dinamis per role | S | P1 |
| Role strip indicator | S | P1 |
| Menu grid hide/show per role | S | P1 |
| Setting page redesign | S | P1 |
| Hierarki password 4 level | M | P1 |
| Set Password page | M | P1 |
| OKR Dashboard view (Firestore) | M | P1 |
| OKR CRUD Editor (tambah/edit/hapus) | L | P2 |
| OKR ganti tahun + salin struktur | M | P2 |
| OKR riwayat perubahan (changelog) | S | P2 |
| CEMS threshold line di chart | S | P1 |
| CEMS compliance badge + progress bar | S | P1 |
| CEMS threshold alert (local notif) | M | P1 |
| CEMS Hg input manual + threshold check | S | P2 |
| Solar PV dedicated page | M | P2 |
| Emisi manual input | S | P2 |

### 🔜 Phase 3 — Maintenance Module (Target v2.1.0)

| Item | Effort | Priority |
|---|---|---|
| Equipment master Firestore (seed) | S | P1 |
| WO Progress Report form (5 section) | L | P1 |
| WhatsApp share (share_plus) | S | P1 |
| WO history & search | M | P2 |
| Warehouse QR scan (mobile_scanner) | M | P2 |
| Hazard Report enhanced (foto, geolocation) | M | P3 |

### 🔜 Phase 4 — MSW AI (Target v2.2.0)

| Item | Effort | Priority |
|---|---|---|
| Firestore Vector Search config | M | P1 |
| Cloud Function: WO → embed pipeline | M | P1 |
| Gemini 2.0 Flash API integration | S | P1 |
| Tavily web search fallback | S | P2 |
| AI chat UI (chat widget + streaming) | M | P1 |
| Feedback loop 👍👎 | S | P2 |
| Document upload KB (PDF parse + chunk) | M | P3 |

### 🔜 Phase 5 — Polish (Target v2.3.0)
- NPHR trend 7 hari
- Analytics 6 param + dual Y-axis + preset + export
- Logsheet auto-populate dari sensor RTDB
- Logsheet approval flow supervisor
- Push notification FCM (CEMS + alarm)
- Offline cache (Hive + Firebase offline persistence)

---

## 10. Open Questions

| # | Pertanyaan | Status |
|---|---|---|
| 1 | Solar PV — apakah ada data sensor aktual di RTDB atau masih manual? | ❌ Open |
| 2 | Historical data RTDB — apakah ada retensi jangka panjang untuk Analytics? | ❌ Open |
| 3 | Equipment master Warehouse — dari mana seed data-nya? (Excel/CMMS) | ❌ Open |
| 4 | WO Nomor — dari CMMS existing (Maximo/D365) atau dibuat manual di app? | ❌ Open |
| 5 | MSW AI — apakah dokumen teknis (manual, SOP) sudah dalam format digital? | ❌ Open |
| 6 | CEMS stream RTDB — apakah Hg ikut di-stream atau hanya PM/SO₂/NOx? | ❌ Open |
| 7 | Threshold baku mutu CEMS — apakah bisa berubah (update regulasi)? Jika ya, perlu UI edit threshold di Setting | ❌ Open |
| 8 | Shift handover — perlu generate otomatis dari logsheet ke WA/email? | ❌ Open |

---

## 11. Referensi Teknis

| Dokumen | Keterangan |
|---|---|
| F-MSW-OPR-06-009 Rev.02 | Boiler Local Log Sheet Unit 1 (62 field, 24 time slot) |
| F-MSW-OPR-06-011 Rev.02 | Steam Turbine Local Log Sheet Unit 1 (57 field, 24 time slot) |
| PT MSW OKR 2026 | Company Objectives & Key Results (3 Objectives, 10 KR) |
| PermenLHK / PTBAE-PU | Baku mutu emisi PLTU: PM 50, SO₂ 550, NOx 550, Hg 0.03 mg/Nm³ |
| Gemini 2.0 Flash API | LLM untuk RAG MSW AI |
| Google text-embedding-004 | Embedding model untuk Firestore Vector Search |
| Tavily Search API | Web search fallback untuk RAG jika internal KB tidak cukup |

---

*PRD v4.1 — Update dari v4.0*
*Tambahan: OKR CRUD, Setting redesign, Hierarki password 4 level, CEMS threshold baku mutu*
*Disiapkan oleh: M. Farhan Tandia (IC&IT Supervisor, MSW)*
*Tanggal: Juli 2026 · Status: DRAFT — For Development*
