# MSW ePlant — Comprehensive System Feature Documentation & Technical Roadmap
**PT Makmur Sejahtera Wisesa (MSW) — Adaro Energy Solutions**  
*2×30 MW Coal-Fired Power Plant (CFPP) + 868 kWp Solar PV Dual-Plant System*  
*Document Version: 4.6 | Date: September 2026 | Language: English (Professional Power Plant Engineering)*

---

## 📑 Executive Summary

**MSW ePlant** is an enterprise-grade mobile operational telemetry, digital plant operations, and warehouse material issuance platform specifically engineered for PT Makmur Sejahtera Wisesa (MSW) in Tanjung, Tabalong, South Kalimantan. The platform unifies real-time power plant generation monitoring, environmental emissions compliance (CEMS), thermodynamic efficiency analysis (NPHR), digital shift logsheet auditing, corporate OKRs, and supply chain material requests integrated directly with **Microsoft Dynamics 365 Supply Chain Management (D365 SCM)** ERP and **Huawei FusionSolar OpenAPI**.

This document serves as the master engineering reference detailing all currently implemented production features, electrical and digital architecture, data flows, and the explicit technical roadmap of pending capabilities (*"What is Not Yet Done"*).

---

## 🏛️ System Architecture & Data Flow

```
                                  ┌──────────────────────────────────────────────────────────┐
                                  │                MSW ePlant Mobile Client                  │
                                  │            (Flutter / Dark Glassmorphism)                │
                                  └────────────┬─────────────┬─────────────┬─────────────────┘
                                               │             │             │
                ┌──────────────────────────────┘             │             └──────────────────────────────┐
                ▼                                            ▼                                            ▼
┌───────────────────────────────┐            ┌───────────────────────────────┐            ┌───────────────────────────────┐
│     Firebase Realtime DB      │            │  Huawei FusionSolar OpenAPI   │            │   Microsoft Dynamics 365      │
│     (excel_data/ telemetry)   │            │  (Northbound REST API v1)     │            │   Supply Chain Management     │
├───────────────────────────────┤            ├───────────────────────────────┤            ├───────────────────────────────┤
│ • /overview (14 Plant Params) │            │ • PLTS MSW (400 kWp, 8 Inv)   │            │ • 19 Plant Warehouses         │
│ • /table1 (Unit 1 & Grid)     │            │ • PLTS Kelanis (468 kWp, 4 Inv│            │ • 86 Activity Dimensions      │
│ • /table2 (Unit 2 & Aux)      │            │ • 30-Min Cron Sync Engine     │            │ • 39 Cost Center Units        │
│ • /cems1 & /cems2 (Emissions) │            │ • Live `day_cap` Priority     │            │ • Multi-Item Material Request │
│ • /nphr (Heat Rate Curves)    │            │ • 2px AppBar Loading Line     │            │ • Real-time Stock Check       │
└───────────────────────────────┘            └───────────────────────────────┘            └───────────────────────────────┘
                ▲                                            ▲                                            ▲
                │ OPC / Modbus                               │ HTTPS TLS 1.3                              │ OData / REST
┌───────────────────────────────┐            ┌───────────────────────────────┐            ┌───────────────────────────────┐
│   CFPP DCS & SCADA System     │            │   Huawei Smart PV Inverters   │            │   Adaro Corporate ERP Cloud   │
│   (Yokogawa CENTUM VP / CEMS) │            │   (SUN2000-50KTL / 100KTL)    │            │   (Azure APIM / D365 SCM)     │
└───────────────────────────────┘            └───────────────────────────────┘            └───────────────────────────────┘
```

---

## ⚡ Section 1: Complete Inventory of Implemented Features

### 1. Plant Overview Detail & Animated SCADA Flow Diagram (`PlantOverviewDetailPage`)
- **Centralized Firebase Node (`/excel_data/overview`)**: Streams 14 general plant rating and operating parameters:
  - `UNIT 1 TMGCR` & `UNIT 2 TMGCR` (30.0 MW rated capacity).
  - `UNIT 1 BMCR` & `UNIT 2 BMCR` (130.0 t/h maximum continuous steam rating).
  - `UNIT 1 BOILER EFFICIENCY` & `UNIT 2 BOILER EFFICIENCY` (%).
  - `UNIT 1 EAF` & `UNIT 2 EAF` (Equivalent Availability Factor, %).
  - `UNIT 1 CAPACITY FACTOR` & `UNIT 2 CAPACITY FACTOR` (CF, %).
  - `LOAD TO PLN` (MW) — Commercial power delivered to the national 70 kV grid.
  - `LOAD TO AI` (MW) — Dedicated industrial power delivered to PT Adaro Indonesia 20 kV network.
  - `TOTAL LOAD` (MW) — Combined gross electrical generation.
  - `TOTAL HOUSE LOAD` (MW) — Auxiliary power consumed by plant balance-of-plant (BOP) systems.
- **Zero Hardcoded Data Guarantee**: 100% dynamic streaming with an elegant `" — "` placeholder if telemetry is unrecorded. Includes automated, seamless fallback to `table1` and `table2` fields.
- **Animated Single-Line SCADA Flow Diagram (`PlantEnergyFlowWidget`)**:
  - Vector-rendered via Flutter `CustomPainter` displaying the physical electrical evacuation topology:
    - **Unit 1 & Unit 2 Turbogenerators** (11 kV terminal voltage).
    - **Trafo 11kV / 6.6kV (Unit Auxiliary Transformer - UAT)** feeding internal plant **House Load (6.6 kV)**.
    - **Step-Up Substation & `BUSBAR 20kV / 70kV`** routing export power.
    - **PLN 70 kV Grid Transmission Line**.
    - **PT Adaro Indonesia (AI) 20 kV Industrial Dedicated Feeder**.
  - **Dynamic Particle Animation**: Animated particle pulses move across conductor paths at speeds proportional to actual electrical flow. Pulses automatically deactivate when a unit trips or shuts down.
  - **Interactive Node Modal Inspection**: Tapping any electrical bus, generator, or transformer node displays operational ratings, live megawatts, line voltages, and direct trend navigation.
- **Unit Operating Condition Evaluator**:
  - 🟢 **Normal Running** ($\ge 12.0\text{ MW}$): Full active generation.
  - 🟡 **Low Load** ($4.0 - 12.0\text{ MW}$): Advisory low-load flame stability state.
  - 🟣 **House Load** ($0.0 - 4.0\text{ MW}$): Islanded station power mode.
  - 🔴 **Shutdown / Trip** ($\le 0.0\text{ MW}$): Trip alert banner and particle halt.
  - Live capacity loading percentage against TMGCR (e.g., $28.5\text{ MW} / 30.0\text{ MW} = 95.0\%$).

### 2. CFPP Homepage Shortcut & Direct Navigation
- **Renamed Menu Button**: Updated from "Plant" to **"CFPP"** (*Coal-Fired Power Plant*) in [MenuGrid](file:///lib/widgets/menu_grid.dart).
- **Direct Navigation**: Tapping the CFPP icon routes directly to [PlantOverviewDetailPage](file:///lib/pages/plant/plant_overview_detail_page.dart), granting operators and managers instantaneous access to full plant balance, SCADA single-line flow, capability matrix, and emissions overview in 1 tap.

### 3. Interactive Historical Trend Chart (`ChartPage`) for All Telemetry Metrics
- **100% Tappable Metrics**: Every metric card, table cell, and SCADA node on the Plant Overview and Home pages is interactive:
  - Hero Balance Cards (Total Gross, PLN Export, AI Feeder, House Load).
  - Unit 1 & Unit 2 Gross Loads.
  - Capability Parameters (TMGCR, BMCR, Boiler Efficiency, EAF, Capacity Factor, NPHR).
  - CEMS 4 Environmental Indicators ($\text{SO}_2$, $\text{NO}_x$, PM, $\text{CO}$).
- **High-Performance Touch Interaction**: Powered by `fl_chart` with gradient area fills, dynamic horizontal threshold indicator lines, localized tooltips, and a **"Full Chart"** button launching landscape fullscreen inspection.

### 4. Executive HD Image Sharing (`DashboardShareService`)
- **1-Tap High-Definition PNG Capture**: Renders the complete, styled dashboard tree at 2.5× device pixel ratio.
- **Native Social Dispatch**: Exports directly to WhatsApp operational groups, Telegram, Email, or Slack via native OS share sheet using `share_plus` and `path_provider`, complete with active timestamps and status glows.
- **Available On**: Both the **Plant Overview Detail Page** and the **Solar PV Dedicated Portal**.

### 5. Solar PV Dual-Plant System (868 kWp Total) & Huawei FusionSolar OpenAPI
- **Dual-Plant Configuration**:
  - **PLTS MSW (400 kWp)**: 8 Huawei smart string inverters (Warehouse Roof, Mess Building, Ground-Mount, and Parking Canopy clusters).
  - **PLTS Kelanis (468 kWp)**: 4 high-capacity Huawei smart string inverters located at Kelanis Coal Terminal.
- **Direct OpenAPI Integration (`FusionSolarService` & `FusionSolarApiClient`)**:
  - Secure TLS HTTPS REST client with automated credential token acquisition and session renewal.
  - Station KPI endpoint (`/getKpiStationHour`, `/getKpiStationDay`, `/getStationRealKpi`).
  - Device Real-Time Telemetry endpoint (`/getDevRealKpi`, `/getDevHistoryKpi`).
  - Graceful fallback to persistent cache and realistic plant telemetry during network timeouts.
- **Dedicated Solar Portal (`SolarDetailPage`)**:
  - Dual-plant switcher tabs (*PLTS MSW 400 kWp* vs *PLTS Kelanis 468 kWp*).
  - Real-time solar active power (kW), daily yield (kWh), lifetime generation (MWh).
  - Insolation / Irradiance ($\text{W/m}^2$) and Performance Ratio ($\text{PR} \ge 80\%$).
  - Environmental ESG metrics: Avoided $\text{CO}_2$ emissions (Tons) and standard coal savings.
- **Inverter Array Grid & Unit Detail (`InverterDetailPage`)**:
  - Real-time LED status (Running, Warning, Fault, Disconnected).
  - String DC voltage/current, AC 3-phase voltages, operating efficiency %, heatsink temperatures, and derating risk analysis.
  - Tabular numeric sheet modal (`SolarNumericTrendSheet`) and landscape multi-interval trend visualizer (`SolarLandscapeTrendPage`).

### 6. 30-Minute Automatic Polling Schedule & Manual On-Demand Synchronization
- **Clock-Aligned Periodic Polling**: Automated background sync scheduled at exact half-hour intervals (e.g., 09:00, 09:30, 10:00, 10:30 WITA), preventing API throttling and quota exhaustion on Huawei FusionSolar servers.
- **Manual Synchronization**: Pull-to-refresh and AppBar refresh icon synchronize on-demand to the nearest active interval.
- **Concurrent Request Protection**: Atomic mutex locking (`_isSyncing` guard) guarantees that manual and automatic requests never collide or fire redundant HTTP payloads.

### 7. Ultra-Minimalist Single Linear Loading Indicator
- **Single Location**: Exactly ONE loading indicator across the application, positioned directly below the AppBar / fixed top header (height: 2.0 px, `AppColors.solar`).
- **Active Pages**:
  - [HomePage](file:///lib/pages/home_page.dart) (bottom edge of the fixed top header).
  - [PlantPage](file:///lib/pages/plant_page.dart) (`AppBar.bottom`).
  - [SolarDetailPage](file:///lib/pages/solarpv/solar_detail_page.dart) (`AppBar.bottom`).
  - [InverterDetailPage](file:///lib/pages/solarpv/inverter_detail_page.dart) (`AppBar.bottom`).
- **Zero Circular Loaders**: Removed all `CircularProgressIndicator` widgets from action buttons, header titles, and cards.
- **Zero Extra Text**: No distracting labels ("Menyinkronkan API...", "SYNCING...", or snackbar popups); the UI remains completely clean and stable during telemetry synchronization.

### 8. Accurate Real-Time Daily Yield Calculation Logic
- **Live Day Capacity Prioritization**: Prioritizes live `day_cap` from the station real-time API (e.g., MSW 384.3+ kWh) over delayed historical hourly accumulators.
- **Midnight Boundary Filtering**: Explicitly filters hourly timestamp collection to today's midnight (`00:00:00`), preventing yesterday's late evening production from bleeding into today's cumulative figure.

### 9. Real-Time Generation & Critical Sensor Matrix (Unit 1 & Unit 2)
- **Turbine-Generator Parameters**: Live gross power (MW), reactive power (MVAR), grid frequency (Hz), power factor ($\cos \phi$), excitation voltage/current.
- **Boiler Critical Parameters**: Main steam pressure (MPa), main steam temperature (°C), reheat steam parameters, drum water level, and furnace draft.
- **Trip & Shutdown Alert**: Prominent warning banner activated automatically whenever gross active power drops below 2.0 MW.

### 10. Continuous Emission Monitoring System (CEMS)
- **4 Main Pollutants**: Sulfur Dioxide ($\text{SO}_2$), Nitrogen Oxides ($\text{NO}_x$), Particulate Matter (PM / Opacity), and Carbon Monoxide ($\text{CO}$) for Stack 1 and Stack 2.
- **Permen LHK No. P.15/2019 Baku Mutu**: Real-time compliance assessment with dynamic badges (*COMPLIANT* vs *EXCEEDED*) and official threshold lines (*HorizontalLine*) rendered on trend charts.

### 11. Thermal Efficiency & Polynomial NPHR Curves
- **Operating Heat Rate**: Live calculation of Net Plant Heat Rate (NPHR, $\text{kCal/kWh}$) for Unit 1 and Unit 2.
- **Theoretical Benchmark Curve**: 5 MW to 30 MW polynomial heat rate curve overlaying actual operating points to identify combustion losses.

### 12. Digital Shift Logsheet & Google Sheets Integration
- **Boiler Local Logsheet**: 62 operational fields recorded across 24 hourly shift slots (07:00 to 19:00 WITA).
- **Steam Turbine Local Logsheet**: 57 parameters (bearing metal temperatures, shaft vibration, lube oil pressures, condenser vacuum).
- **Google Sheets API v4**: Direct automated push to corporate Google Sheets via OAuth2 service accounts with local offline draft preservation.

### 13. Warehouse & Multi-Item Material Issuance (Microsoft Dynamics 365 SCM)
- **In-App D365 Authentication (`D365UserSession`)**: 1-Tap preset login (`61000003 - Executor EIC`, `61000006 - Executor DG-PLTS`, `61000002 - Executor MECH`) plus custom Employee ID entry.
- **Camera Barcode & QR Scanner (`qr_scanner_page.dart`)**: Viewfinder with animated laser scanning beam, flashlight toggle, front/rear camera flip, and manual fallback dialog.
- **Dynamic Work Order (WO) Picker**: Retrieves active, uncompleted maintenance work orders from D365.
- **Master Dimension Lists**: Pre-loaded with 19 MSW Warehouses, 86 Activity Dimension Values, 39 Cost Center Operating Units, and official D365 Unit Types.
- **Multi-Item Material Cart**: Batch multiple spare parts into a single Work Order issuance with real-time stock availability guards.
- **Official Journal Voucher Number**: Generates D365 transaction reference vouchers (e.g., `JRN-D365-2026-XXXX`).

### 14. OKR (Objectives & Key Results) Strategic Dashboard
- **Corporate Alignment**: 2026 corporate objectives with interactive key result progress sliders.
- **In-App CRUD Editor**: Administrative modal with multi-level password gate for adding, editing, and archiving annual OKR targets.

### 15. Role-Based Access Control (RBAC) & Navigation
- **3 User Roles**: *Operation*, *Maintenance*, and *General*.
- **Adaptive Bottom Navigation**: Contextual navigation tabs customized per authenticated role with hidden restricted items.

---

## 🚧 Section 2: What is Not Yet Done / Technical Roadmap ("Apa Yang Belum")

While the core functionality of MSW ePlant is robust and live in the field, several enterprise integrations and advanced capabilities are planned for upcoming phases:

```
┌──────────────────────────────────────────────────────────────────────────────────────────────────┐
│                             MSW ePlant — Forward Technical Roadmap                               │
├────────────────────────────┬────────────────────────────┬────────────────────────────────────────┤
│ Phase / Priority           │ Module Area                │ Target Capability                      │
├────────────────────────────┼────────────────────────────┼────────────────────────────────────────┤
│ 🔴 High Priority (Phase 1) │ D365 ERP Production Gate   │ Direct Adaro Azure APIM & VPN Gateway   │
│ 🔴 High Priority (Phase 1) │ Cloud Messaging & Alerts   │ FCM Remote Push Notifications          │
│ 🟡 Medium Priority (Phase 2)│ Environmental Regulatory   │ Direct KLHK SISPEK CEMS API Bridge     │
│ 🟡 Medium Priority (Phase 2)│ Digital Shift Operations   │ Multi-Tier Logsheet Sign-Off Workflow  │
│ 🟢 Low Priority (Phase 3)  │ Telemetry Persistence      │ Local SQLite/Hive Offline Time-Series  │
│ 🟢 Low Priority (Phase 3)  │ Predictive Diagnostics     │ Boiler Tube Leak & Vibration ML Model  │
└────────────────────────────┴────────────────────────────┴────────────────────────────────────────┘
```

### 🔴 1. Production D365 ERP & Cloud Gateway Integration (Highest Priority)
*Current State: High-fidelity enterprise simulation engine (`d365_service.dart`) with official master dimension codes, realistic stock checks, and journal generation.*
- **Pending Implementation Requirements**:
  1. **Corporate Network Gateway / Reverse Proxy**: Establish secure mutual TLS (mTLS) or Azure API Management (APIM) gateway connecting the mobile client to Adaro Energy's internal D365 SCM production tenant.
  2. **Active Directory / OAuth2 Bearer Token Lifecycle**: Implement corporate Azure Active Directory (AAD) / Entra ID token acquisition and automated background refresh to replace preset employee PIN verification.
  3. **Direct OData / REST Journal Posting**: Transition journal generation from client-side generation to direct POST calls against the D365 `InventJournalTable` and `InventJournalTrans` entities.
  4. **Live Physical Stock Reconciliation**: Connect on-hand queries directly to live `InventOnhand` data entities across all 19 plant warehouses.

### 🔴 2. Remote Push Notifications via Firebase Cloud Messaging (FCM)
*Current State: Local notifications triggered client-side when the application is actively running in foreground or background.*
- **Pending Implementation Requirements**:
  1. **Serverless Alert Dispatcher (Firebase Cloud Functions)**: Listen directly to RTDB and FusionSolar stream nodes.
  2. **Critical Plant Trip Trigger**: Instantly dispatch high-priority push notifications to Operation and Maintenance personnel when Gross Load drops below 2.0 MW or an electrical bus trips.
  3. **CEMS Regulatory Exceedance Alert**: Immediate push alert when any of the 4 pollutants ($\text{SO}_2$, $\text{NO}_x$, PM, $\text{CO}$) exceed Permen LHK No. P.15/2019 limits continuously for $>15$ minutes.

### 🟡 3. Direct KLHK SISPEK CEMS Regulatory Integration
*Current State: Internal compliance evaluation based on Permen LHK limits.*
- **Pending Implementation Requirements**:
  1. **Direct API Bridge to KLHK SISPEK Server**: Automated JSON payload submission to the Ministry of Environment and Forestry (KLHK) central emissions server as mandated by Indonesian environmental regulations.
  2. **Data Availability Factor (DAF) Logging**: Tracking required 85% valid operating hours per quarter.

### 🟡 4. Digital Shift Logsheet Multi-Tier Approval Workflow
*Current State: Shift readings sync directly to corporate Google Sheets without sequential review.*
- **Pending Implementation Requirements**:
  1. **Digital Sign-Off Hierarchy**: Implement sequential in-app approvals:
     - Desk Operator (Submits draft).
     - Shift Supervisor / Chief Operator (Reviews and signs off).
     - Operation Superintendent (Final review and freeze).
  2. **Audit Trail & Timestamps**: Tamper-proof electronic signature logging stored in Firebase Firestore.

### 🟢 5. Local Offline Persistent Database (SQLite / Hive)
*Current State: In-memory state and SharedPreferences caching for active sessions.*
- **Pending Implementation Requirements**:
  1. **Local SQLite / Drift Engine**: Store up to 30 days of hourly telemetry on the device to enable zero-latency historical trend analysis even during complete network outages.
  2. **Delta Synchronization Engine**: Automated reconciliation of offline drafts once mobile network or plant Wi-Fi is restored.

### 🟢 6. Advanced Predictive Maintenance & Anomaly Detection
*Current State: Real-time threshold boundary alerts.*
- **Pending Implementation Requirements**:
  1. **Boiler Tube Leak Acoustic Anomaly Detection**: AI model analyzing temperature differentials between superheater headers to detect early pinhole tube leaks.
  2. **Turbine Bearing Vibration FFT Analysis**: Automated spectrum alerting for unbalance, misalignment, and bearing wear.

---

## 📊 Section 3: Data Dictionary & Engineering Inventory References

For detailed field-by-field parameter mappings and API schemas, refer to the following companion workbooks:
- [FusionSolar_Data_Dictionary.xlsx](file:///d:/msw/msw_eplant/docs/FusionSolar_Data_Dictionary.xlsx): Full inventory of station KPIs, inverter register addresses, measurement units, and OpenAPI schemas.
- [msw_services_data_inventory.xlsx](file:///d:/msw/msw_eplant/docs/msw_services_data_inventory.xlsx): Comprehensive cross-service mapping across Firebase RTDB, D365 SCM, CEMS, and Google Sheets.

---
*Authored by: Antigravity AI Engineering Assistant on behalf of PT Makmur Sejahtera Wisesa (MSW) Operation & Engineering Teams.*
