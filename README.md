# MSW ePlant Mobile Application

<div align="center">

![MSW ePlant Banner](Picture1.png)

### **Enterprise Plant Monitoring & Warehouse Operations App**
**PT Makmur Sejahtera Wisesa (MSW) — Adaro Energy**  
*2×30 MW CFPP + 1.3 MWp Solar PV Plant — Tanjung, Tabalong, South Kalimantan, Indonesia*

[![Flutter Version](https://img.shields.io/badge/Flutter-3.x%20(Dart%203.9.2)-02569B?logo=flutter)](https://flutter.dev)
[![App Version](https://img.shields.io/badge/App%20Version-v1.0.2%2B1-00B4D8)](pubspec.yaml)
[![PRD Version](https://img.shields.io/badge/PRD%20Specification-v4.3-10B981)](plan/PRD_MSW_ePlant_v4.1.md)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS%20%7C%20Web-4CAF50)](android)
[![D365 Integration](https://img.shields.io/badge/ERP%20Integration-Microsoft%20Dynamics%20365-0078D4?logo=microsoft)](lib/services/d365_service.dart)

</div>

---

## 📌 1. Overview

**MSW ePlant** is an enterprise internal mobile application engineered for PT Makmur Sejahtera Wisesa (MSW). It empowers power plant operations with real-time performance telemetry, digital shift logsheet recording, corporate OKR/KPI tracking, and end-to-end warehouse material issuance integrated directly with **Microsoft Dynamics 365 Supply Chain Management (D365 SCM)** ERP.

The application is built with a modern **Dark Glassmorphism** design system over the plant background visual (`asset/msw.png`), featuring responsive layouts, Role-Based Access Control (RBAC), and high-throughput asynchronous data streams.

---

## 🚀 2. Key Features

### 🏭 1. Real-Time Plant & Generation Monitoring
- **Live Generation Streaming**: Real-time telemetry for gross generation (MW), net generation, auxiliary power consumption, and load distribution to both the national grid (PLN) and captive Adaro Indonesia (AI) networks.
- **Unit 1 & Unit 2 Critical Sensor Matrix**: Real-time monitoring of main steam temperature/pressure, reheat, boiler drum level, condenser vacuum, and generator electrical parameters (MW, MVAR, Hz).
- **Trip & Shutdown Alert Banner**: Automated detection and visual alert banner when unit load drops below 2 MW.
- **Live Weather Widget**: Real-time ambient temperature, humidity, wind speed, and weather conditions in Tanjung, Tabalong via OpenWeatherMap API.

### 🍃 2. CEMS (Continuous Emission Monitoring System)
- **Multi-Pollutant Telemetry**: Continuous streaming of Particulate Matter (PM), Sulfur Dioxide ($\text{SO}_2$), Nitrogen Oxides ($\text{NO}_x$), and Mercury ($\text{Hg}$) for Stacks 1 & 2.
- **Regulatory Threshold & Compliance Badge**: Dynamic compliance status indicators (*Compliant* vs. *Exceeded*) aligned with environmental regulations (PermenLHK / PTBAE-PU).
- **Interactive Threshold Charts**: Visual emission trends plotted with threshold limit lines (*HorizontalLine*) powered by `fl_chart`.
- **Local Threshold Alerts**: Automated notification triggers when emissions approach or exceed safety limits.

### 📈 3. NPHR & Thermal Efficiency Analytics
- **Polynomial NPHR Curve**: Thermal efficiency curve (5–30 MW) with real-time operating point overlay.
- **Target vs. Actual Deviation Indicator**: Energy consumption deviation metrics against benchmark heat rate targets.
- **Multi-Parameter Correlation Charting**: Simultaneous multi-sensor correlation analysis with Dual Y-Axis support.

### 📋 4. Digital Shift Logsheet
- **Boiler Local Logsheet**: 62 operational fields across 24 hourly time slots (07:00 – 19:00 WITA).
- **Steam Turbine Local Logsheet**: 57 operational parameters (bearing temperatures, vibration, lube oil pressure, condenser vacuum).
- **Cloud Master Sync**: Direct sync to corporate Google Sheets via Google Sheets API v4 (OAuth2).
- **Offline Draft Resilience**: Seamless local draft caching using `SharedPreferences` during network disconnects.

---

### 📦 5. Warehouse & Multi-Item Material Issuance (D365 SCM) — *NEW in v4.3*

A comprehensive warehouse module for field technicians and warehouse keepers, fully integrated with **Microsoft Dynamics 365**:

```
 ┌──────────────────────┐      ┌────────────────────────┐      ┌───────────────────────┐
 │   Warehouse Page     │ ───> │   Material Issue Form  │ ───> │  D365 ERP API Server  │
 │  - D365 Session      │      │  - Active WO Picker    │      │  - On-Demand Check    │
 │  - Search Item D365  │      │  - Multi-Item Cart     │      │  - Journal No Issue   │
 │  - Transaction Logs  │      │  - Stock vs Qty Guard  │      │  - Real-time Stock    │
 └──────────────────────┘      └────────────────────────┘      └───────────────────────┘
            │                              ▲
            ▼                              │
 ┌──────────────────────┐                  │
 │  QR / Barcode Camera │ ─────────────────┘
 │  - Laser Viewfinder  │   (Scan Barcode / Manual Input)
 │  - Torch & Flip Cam  │
 └──────────────────────┘
```

#### ✨ Warehouse Highlights & Capabilities:
1. **In-App D365 User Authentication (`D365UserSession`)**:
   - Direct D365 user login within the mobile application.
   - 1-Tap preset authentication for registered plant executors: `61000003 - Executor EIC`, `61000006 - Executor DG-PLTS`, and `61000002 - Executor MECH-W&F`.
   - Custom Employee ID + PIN login support for all plant staff.
   - Real-time session synchronization with quick action buttons (**`Login D365`**, **`Switch`**, and **`Logout`**) on the warehouse dashboard.
2. **Dynamic Work Order (WO) Picker**:
   - Active, uncompleted Work Order retrieval (`In Progress`, `Open`, `Released`) from D365.
   - Automated pre-population of Activity, Cost Center, and default Warehouse upon WO selection.
3. **Official D365 Master Dimension Values**:
   - **19 Warehouses**: `MAINSTORE`, `OILSTORE`, `CHEMSTORE`, `MAINWORK`, `COALSTORE`, `SAFETYSTORE`, etc.
   - **86 Activity Dimension Values**: `6100AC5403 - Equipment Tools`, `6100AC4042 - Inventory - Lubricant`, `6100AC0000 - NON`, etc.
   - **39 Cost Center Operating Units**: `6100DB401 - MSW_Maintenance - Mechanical`, `6100DB402 - EIC`, etc.
   - **Dynamic Unit Types**: Official unit types (`PCS`, `SET`, `LTR`, `KG`, `UNIT`) retrieved dynamically from D365.
4. **On-Demand Single Fetch Architecture**:
   - Instant validation per item number (`01.001.001.0004`) upon scanning or typing.
   - Ultra-fast response time (**< 200 ms**), lightweight payload (**< 1 KB**), and **100% real-time on-hand stock accuracy**.
5. **Search Item D365 (Contains Filter)**:
   - Search D365 master catalog by item name or part number (initial state is empty to conserve device memory).
6. **QR Code & Barcode Camera Scanner (`mobile_scanner` v6.0.11)**:
   - Modern camera viewfinder with animated laser scanning beam, torch/flashlight toggle, front/rear camera flip, and manual fallback modal with `XX.XXX.XXX.XXXX` auto-formatting.
7. **Multi-Item Material Cart & Posting**:
   - Batch multiple spare parts within a single Work Order issuance.
   - Stock guard prevents requesting quantities greater than real-time available inventory.
   - Review dialog and official payload generation with clean Cost Center dimension codes and Employee IDs.
   - Automatic generation of official **D365 Transaction Journal Numbers** (e.g., `JRN-D365-2026-4821`).

---

### 🎯 6. OKR (Objectives & Key Results) Dashboard
- **Corporate Strategy Tracking**: Real-time progress monitoring for 2026 corporate objectives.
- **In-App OKR Editor**: Secure CRUD operations for Objectives & Key Results protected by an administrative password gate.

### 🛡️ 7. HSE & Hazard Reporting
- Instant field reporting for Unsafe Actions, Unsafe Conditions, and Near-Miss incidents.

### 🔐 8. Role-Based Access Control & Security
- **3 User Roles**: *Operation*, *Maintenance*, and *General*.
- **Dynamic Bottom Navigation Bar**: Adaptive navigation tabs customized to the authenticated role.
- **Multi-Level Password Hierarchy**: Scoped security access protecting Admin Settings, Password Configuration, and OKR Editing.

---

## 🛠️ 3. Tech Stack & Dependencies

| Category | Technology / Library | Version | Description |
|---|---|---|---|
| **Framework** | Flutter / Dart SDK | `^3.9.2` | Cross-platform mobile UI (Android & iOS) |
| **Realtime DB** | `firebase_core`, `firebase_database` | `^4.1.1`, `^12.0.2` | Sensor telemetry streaming from plant RTDB |
| **ERP Integration**| `http`, `shared_preferences` | `^1.2.2`, `^2.2.3` | REST/OData D365 SCM API client & session storage |
| **Barcode Scanner**| `mobile_scanner` | `^6.0.11` | Camera-based Barcode and QR Code scanner |
| **Charts & Visuals**| `fl_chart` | `^1.1.1` | NPHR curves, emission trends, and analytics charts |
| **Localization**  | `intl` | `^0.19.0` | Number, currency, and date/time formatting |
| **Sheets Sync**    | `googleapis`, `google_sign_in` | `^13.2.0`, `^6.2.1` | Digital logsheet sync to corporate Google Sheets |
| **Local Notif**    | `flutter_local_notifications` | `^18.0.1` | Scheduled reminders and CEMS alert triggers |
| **Icons & Design** | `cupertino_icons` | `^1.0.8` | Consistent visual iconography |

---

## 📂 4. Project Directory Structure

```
msw_eplant/
├── android/                   # Native Android configuration & AndroidManifest (Camera Permission)
├── asset/                     # Visual assets (msw.png, logos, plant background)
├── lib/
│   ├── constants/             # Design tokens & AppColors (Dark Theme palette)
│   ├── models/                # Domain models
│   │   ├── d365_user_model.dart       # D365 user session (Employee code, department)
│   │   ├── material_issue_model.dart  # Multi-item issue request payload
│   │   ├── role.dart                  # UserRole definition (Operation, Maintenance, General)
│   │   ├── warehouse_item.dart        # D365 catalog item and on-hand stock model
│   │   └── work_order_model.dart      # Active D365 Work Order model
│   ├── pages/                 # UI pages and components
│   │   ├── analytics_page.dart        # Multi-parameter correlation analysis
│   │   ├── cems_detail_page.dart      # CEMS telemetry, compliance badges & threshold chart
│   │   ├── home_page.dart             # Main dashboard, unit load, weather, department grid
│   │   ├── logsheet_page.dart         # Digital Boiler & Turbine shift logsheets
│   │   ├── okr_page.dart              # OKR dashboard & structure editor
│   │   ├── setting_page.dart          # App settings, profile, and password gate
│   │   └── warehouse/                 # D365 Warehouse Module
│   │       ├── material_issue_page.dart # Multi-item material issue form
│   │       ├── qr_scanner_page.dart     # Barcode & QR camera scanner with laser beam
│   │       └── warehouse_page.dart      # Warehouse dashboard, Item Search, & Issue History
│   ├── services/              # Business logic & API clients
│   │   ├── d365_service.dart          # Microsoft Dynamics 365 API client & master data
│   │   ├── cems_threshold_service.dart# CEMS regulatory compliance monitoring
│   │   ├── notification_service.dart  # Local push notifications & alarm handlers
│   │   └── rtdb_service.dart          # Firebase Realtime Database stream listener
│   └── main.dart              # Application entry point and service initializers
├── plan/                      # PRD specifications, technical notes, and UI mockups
│   ├── PRD_MSW_ePlant_v4.1.md         # Master Product Requirements Document (PRD v4.3)
│   └── Logsheet_Detail_Implementation.md
├── pubspec.yaml               # Flutter package configuration and dependencies
└── README.md                  # Master repository documentation (English)
```

---

## 🧪 5. D365 Dummy Test Part Numbers (Ready for Simulation)

Use the following pre-configured part numbers for scanning or manual simulation:

| Item Number (Scan / Input) | Description | Unit Type (D365) | Available Stock | Default Location |
|:---|:---|:---:|:---:|:---|
| `01.001.001.0004` | **BEARING 6204-2RS C3 SKF** | `PCS` | **24.0** | MAINSTORE / `RAK-A2 / BIN-04` |
| `01.001.001.0005` | **BEARING 6309-2Z/C3 SKF** | `PCS` | **12.0** | MAINSTORE / `RAK-A2 / BIN-05` |
| `01.002.001.0012` | **MECHANICAL SEAL TYPE B-35MM** | `SET` | **6.0** | MAINSTORE / `RAK-B1 / BIN-02` |
| `01.003.001.0001` | **SYNTHETIC GEAR OIL ISO VG 320** | `LTR` | **150.0** | OILSTORE / `LUBE-DRUM-03` |
| `01.004.001.0020` | **HEX BOLT M16 X 70MM SS316** | `PCS` | **80.0** | MAINSTORE / `RAK-C3 / BIN-11` |
| `01.005.001.0008` | **SPIRAL WOUND GASKET 3 INCH 150#** | `PCS` | **35.0** | MAINSTORE / `RAK-C1 / BIN-08` |
| `01.006.001.0002` | **PRESSURE TRANSMITTER 0-25 BAR** | `UNIT` | **4.0** | MAINWORK / `RAK-E1 / BIN-01` |
| `01.007.001.0015` | **OIL FILTER ELEMENT 10 MICRON** | `PCS` | **18.0** | MAINSTORE / `RAK-D2 / BIN-03` |
| `01.008.001.0003` | **MCB 3 POLE 32A 10KA SCHNEIDER** | `PCS` | **10.0** | MAINWORK / `RAK-E2 / BIN-05` |
| `01.009.001.0001` | **HIGH TEMP GREASE EP2** | `KG` | **45.0** | OILSTORE / `RAK-L1 / BIN-01` |

> *Note: Any custom item number matching the format `XX.XXX.XXX.XXXX` is also dynamically supported with default mock inventory of 15 PCS.*

---

## 💻 6. Getting Started & Installation

### Prerequisites
- Flutter SDK `^3.9.2` or later
- Android SDK (API level 21+) / Android Studio
- Physical Android device with camera (for barcode/QR scanning) or an Android Emulator

### Run Instructions:
```bash
# 1. Clone the repository
git clone https://github.com/farhantandia/msw_eplant.git
cd msw_eplant

# 2. Install dependencies
flutter pub get

# 3. Verify static code analysis
flutter analyze

# 4. Launch on connected device
flutter run
```

---

## 📜 7. Changelog & Commit History

### **Latest Updates (August 30, 2026 — Since GitHub Commit `51fd434`)**
- ➕ **Integrated D365 Warehouse Module**: Built [warehouse_page.dart](file:///lib/pages/warehouse/warehouse_page.dart) with D365 connection status banner, quick actions, and transaction voucher logs.
- ➕ **Multi-Item Material Issuance**: Developed [material_issue_page.dart](file:///lib/pages/warehouse/material_issue_page.dart) supporting batch material issues per Work Order, confirmation review dialogs, and real-time inventory validation.
- ➕ **In-App D365 Authentication**: Introduced `D365UserSession` model and authentication modal with 1-tap presets (`61000003`, `61000006`, `61000002`) and manual employee code entry.
- ➕ **D365 Master Dimension Lists**: Integrated 19 Warehouses, 86 Activity Dimension Values, 39 Cost Center Operating Units, and dynamic unit types from D365.
- ➕ **QR & Barcode Camera Scanner**: Engineered [qr_scanner_page.dart](file:///lib/pages/warehouse/qr_scanner_page.dart) with `mobile_scanner` v6.0.11, animated laser beam viewfinder, flashlight toggle, and camera flip.
- ➕ **On-Demand Single Fetch Architecture**: Optimized catalog and inventory querying on-demand per item number for high responsiveness (< 200ms latency, < 1 KB payload).
- ➕ **Item Search Modal**: Added keyword-based catalog search with clean initial empty state.
- ➕ **Native Android Camera Permission**: Added `<uses-permission android:name="android.permission.CAMERA"/>` to `AndroidManifest.xml`.
- ➕ **Comprehensive Documentation**: Updated PRD specification to Version 4.3 and authored full English `README.md`.

---

<div align="center">
<b>© 2026 PT Makmur Sejahtera Wisesa (MSW) — Adaro Energy. All Rights Reserved.</b>
</div>

