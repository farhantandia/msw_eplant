# Logsheet Detail — Implementasi Flutter
## MSW ePlant Digital Logsheet
**Sumber: F-MSW-OPR-06-009 (Boiler) & F-MSW-OPR-06-011 (Steam Turbine)**
**Unit 1 — PT Makmur Sejahtera Wisesa**

---

## Struktur Umum Kedua Logsheet

| Atribut | Nilai |
|---|---|
| **Periode pencatatan** | 24 jam penuh: 10:00 → 23:00 → 00:00 → 09:00 (lintas tengah malam) |
| **Interval pencatatan** | **Setiap 1 jam** (24 baris data per hari) |
| **Tandatangan** | Field Operator (Shift 1/2/3) + Shift Supervisor (Shift 1/2/3) |
| **Dokumen Header** | PT Makmur Sejahtera Wisesa — Operation Department |
| **Catatan/Remarks** | 1 baris free-text di bawah tabel |

> **Catatan waktu:** Time slot dimulai dari 10:00 karena logsheet dibuat per hari kalender operasi (bukan per shift). Urutan: 10:00, 11:00, 12:00, ..., 23:00, 00:00, 01:00, ..., 09:00.

---


## LOGSHEET 1 — BOILER LOCAL LOG SHEET
**Kode Dokumen:** F-MSW-OPR-06-009 Rev.02

Boiler logsheet dibagi menjadi **2 section horizontal besar** yang masing-masing diisi di baris waktu yang sama (10:00–09:00).

---

### SECTION 1-A: PRIMARY AIR FAN (PAF) LOG SHEET

#### Group 1: PAF Lube Oil Pressure
| Field ID | Parameter | Unit | Target / Batas |
|---|---|---|---|
| `paf_lube_oil_press_1` | PAF No.1 Lube Oil Pressure | Bar | 1.0 – 1.2 |
| `paf_lube_oil_press_2` | PAF No.2 Lube Oil Pressure | Bar | 1.0 – 1.2 |

#### Group 2: PAF Bearing Motor Temperature
| Field ID | Parameter | Unit | Target / Batas |
|---|---|---|---|
| `paf1_motor_temp_de` | No.1 PAF Motor Bearing Temp — DE | °C | 35 – 80 |
| `paf1_motor_temp_nde` | No.1 PAF Motor Bearing Temp — NDE | °C | 35 – 80 |
| `paf2_motor_temp_de` | No.2 PAF Motor Bearing Temp — DE | °C | 35 – 80 |
| `paf2_motor_temp_nde` | No.2 PAF Motor Bearing Temp — NDE | °C | 35 – 80 |

#### Group 3: PAF Fan Bearing Temperature
| Field ID | Parameter | Unit | Target / Batas |
|---|---|---|---|
| `paf1_fan_bearing_temp_de` | No.1 PAF Fan Bearing Temp — DE | °C | 35 – 77 |
| `paf1_fan_bearing_temp_nde` | No.1 PAF Fan Bearing Temp — NDE | °C | 35 – 77 |
| `paf2_fan_bearing_temp_de` | No.2 PAF Fan Bearing Temp — DE | °C | 35 – 77 |
| `paf2_fan_bearing_temp_nde` | No.2 PAF Fan Bearing Temp — NDE | °C | 35 – 77 |

#### Group 4: PAF Oil Cooler Temperature
| Field ID | Parameter | Unit | Target / Batas |
|---|---|---|---|
| `paf1_oil_cooler_temp_inlet` | No.1 PAF Oil Cooler Temp — Inlet | °C | 25 – 35 |
| `paf1_oil_cooler_temp_outlet` | No.1 PAF Oil Cooler Temp — Outlet | °C | 25 – 45 |
| `paf2_oil_cooler_temp_inlet` | No.2 PAF Oil Cooler Temp — Inlet | °C | 25 – 35 |
| `paf2_oil_cooler_temp_outlet` | No.2 PAF Oil Cooler Temp — Outlet | °C | 25 – 45 |

#### Group 5: PAF Level Oil Tank & IGV Opening
| Field ID | Parameter | Unit | Target / Batas |
|---|---|---|---|
| `paf1_oil_tank_level` | No.1 PAF Level Oil Tank | % | 50 – 100 |
| `paf2_oil_tank_level` | No.2 PAF Level Oil Tank | % | 50 – 100 |
| `paf1_igv_opening` | No.1 PAF IGV Opening | % | 0 – 100 |
| `paf2_igv_opening` | No.2 PAF IGV Opening | % | 0 – 100 |

#### Group 6: PAF Differential Pressure
| Field ID | Parameter | Unit | Target / Batas |
|---|---|---|---|
| `paf1_diff_pressure` | No.1 PAF Differential Pressure | MBar | 0 – 0.5 |
| `paf2_diff_pressure` | No.2 PAF Differential Pressure | MBar | 0 – 0.5 |

---

### SECTION 1-B: INDUCED DRAFT FAN (IDF) LOG SHEET

#### Group 7: IDF Bearing Motor Temperature
| Field ID | Parameter | Unit | Target / Batas |
|---|---|---|---|
| `idf1_motor_temp_de` | No.1 IDF Motor Bearing Temp — DE | °C | 35 – 65 |
| `idf1_motor_temp_nde` | No.1 IDF Motor Bearing Temp — NDE | °C | 35 – 65 |
| `idf2_motor_temp_de` | No.2 IDF Motor Bearing Temp — DE | °C | 35 – 65 |
| `idf2_motor_temp_nde` | No.2 IDF Motor Bearing Temp — NDE | °C | 35 – 65 |

#### Group 8: IDF Fan Bearing Temperature
| Field ID | Parameter | Unit | Target / Batas |
|---|---|---|---|
| `idf1_fan_bearing_temp_de` | No.1 IDF Fan Bearing Temp — DE | °C | 35 – 60 |
| `idf1_fan_bearing_temp_nde` | No.1 IDF Fan Bearing Temp — NDE | °C | 35 – 60 |
| `idf2_fan_bearing_temp_de` | No.2 IDF Fan Bearing Temp — DE | °C | 35 – 60 |
| `idf2_fan_bearing_temp_nde` | No.2 IDF Fan Bearing Temp — NDE | °C | 35 – 60 |

#### Group 9: IDF Fan Bearing Oil Level
| Field ID | Parameter | Unit | Target / Batas |
|---|---|---|---|
| `idf1_bearing_oil_level_de` | No.1 IDF Fan Bearing Oil Level — DE | % | 40 – 100 |
| `idf1_bearing_oil_level_nde` | No.1 IDF Fan Bearing Oil Level — NDE | % | 40 – 100 |
| `idf2_bearing_oil_level_de` | No.2 IDF Fan Bearing Oil Level — DE | % | 40 – 100 |
| `idf2_bearing_oil_level_nde` | No.2 IDF Fan Bearing Oil Level — NDE | % | 40 – 100 |

#### Group 10: IDF IGV Opening & O2 Excess
| Field ID | Parameter | Unit | Target / Batas |
|---|---|---|---|
| `idf1_igv_opening` | No.1 IDF IGV Opening | % | 0 – 100 |
| `idf2_igv_opening` | No.2 IDF IGV Opening | % | 0 – 100 |
| `idf1_o2_excess` | No.1 IDF O2 Excess | % | — (monitor) |
| `idf2_o2_excess` | No.2 IDF O2 Excess | % | — (monitor) |

---

### SECTION 2-A: SECONDARY AIR FAN (SAF) LOG SHEET

#### Group 11: SAF Lube Oil Pressure
| Field ID | Parameter | Unit | Target / Batas |
|---|---|---|---|
| `saf_lube_oil_press_1` | SAF No.1 Lube Oil Pressure | Bar | 1.0 – 1.2 |
| `saf_lube_oil_press_2` | SAF No.2 Lube Oil Pressure | Bar | 1.0 – 1.2 |

#### Group 12: SAF Bearing Motor Temperature
| Field ID | Parameter | Unit | Target / Batas |
|---|---|---|---|
| `saf1_motor_temp_de` | No.1 SAF Motor Bearing Temp — DE | °C | 35 – 80 |
| `saf1_motor_temp_nde` | No.1 SAF Motor Bearing Temp — NDE | °C | 35 – 80 |
| `saf2_motor_temp_de` | No.2 SAF Motor Bearing Temp — DE | °C | 35 – 80 |
| `saf2_motor_temp_nde` | No.2 SAF Motor Bearing Temp — NDE | °C | 35 – 80 |

#### Group 13: SAF Fan Bearing Temperature
| Field ID | Parameter | Unit | Target / Batas |
|---|---|---|---|
| `saf1_fan_bearing_temp_de` | No.1 SAF Fan Bearing Temp — DE | °C | 35 – 77 |
| `saf1_fan_bearing_temp_nde` | No.1 SAF Fan Bearing Temp — NDE | °C | 35 – 77 |
| `saf2_fan_bearing_temp_de` | No.2 SAF Fan Bearing Temp — DE | °C | 35 – 77 |
| `saf2_fan_bearing_temp_nde` | No.2 SAF Fan Bearing Temp — NDE | °C | 35 – 77 |

#### Group 14: SAF Oil Cooler Temperature
| Field ID | Parameter | Unit | Target / Batas |
|---|---|---|---|
| `saf1_oil_cooler_temp_inlet` | No.1 SAF Oil Cooler Temp — Inlet | °C | 25 – 35 |
| `saf1_oil_cooler_temp_outlet` | No.1 SAF Oil Cooler Temp — Outlet | °C | 25 – 45 |
| `saf2_oil_cooler_temp_inlet` | No.2 SAF Oil Cooler Temp — Inlet | °C | 25 – 35 |
| `saf2_oil_cooler_temp_outlet` | No.2 SAF Oil Cooler Temp — Outlet | °C | 25 – 45 |

#### Group 15: SAF Level Oil Tank, IGV Opening & Diff Pressure
| Field ID | Parameter | Unit | Target / Batas |
|---|---|---|---|
| `saf1_oil_tank_level` | No.1 SAF Level Oil Tank | % | 50 – 100 |
| `saf2_oil_tank_level` | No.2 SAF Level Oil Tank | % | 50 – 100 |
| `saf1_igv_opening` | No.1 SAF IGV Opening | % | 0 – 100 |
| `saf2_igv_opening` | No.2 SAF IGV Opening | % | 0 – 100 |
| `saf1_diff_pressure` | No.1 SAF Differential Pressure | MBar | 0 – 0.5 |
| `saf2_diff_pressure` | No.2 SAF Differential Pressure | MBar | 0 – 0.5 |

---

### SECTION 2-B: P&S BLOWER & SEAL POT AIR BLOWER

| Field ID | Parameter | Unit | Target / Batas |
|---|---|---|---|
| `ps_blower1_diff_press` | P&S Blower No.1 Differential Pressure | MBar | 500 – 1500 |
| `ps_blower2_diff_press` | P&S Blower No.2 Differential Pressure | MBar | 500 – 1500 |
| `ps_blower1_oil_level` | P&S Blower No.1 Oil Level | — | > 50% |
| `seal_pot_blower1_diff_press` | Seal Pot Blower No.1 Differential Pressure | MBar | 0.2 – 0.6 |
| `seal_pot_blower2_diff_press` | Seal Pot Blower No.2 Differential Pressure | MBar | 0.2 – 0.6 |
| `seal_pot_blower1_oil_level` | Seal Pot Blower No.1 Oil Level | — | > 50% |

---

### SECTION 2-C: HP DOSING PUMP SYSTEM

| Field ID | Parameter | Unit | Target / Batas |
|---|---|---|---|
| `hp_dosing_stroke_pump_1` | HP Dosing Stroke Pump No.1 | % | 0 – 100 |
| `hp_dosing_stroke_pump_2` | HP Dosing Stroke Pump No.2 | % | 0 – 100 |
| `hp_dosing_discharge_press_1` | HP Dosing Discharge Pressure No.1 | MBar | Max 95 |
| `hp_dosing_discharge_press_2` | HP Dosing Discharge Pressure No.2 | MBar | Max 95 |
| `hp_dosing_tank_level` | HP Dosing Tank Level | CM | 30 – 80 |

---

### SECTION 2-D: STEAM DRUM

| Field ID | Parameter | Unit | Target / Batas |
|---|---|---|---|
| `steam_drum_pressure` | Steam Drum Pressure | Bar | Max 100 |
| `steam_drum_level_left` | Steam Drum Level — Left | mm | Normal water level |
| `steam_drum_level_right` | Steam Drum Level — Right | mm | Normal water level |

---

### BOILER — Metadata & Approval

| Field ID | Parameter | Tipe |
|---|---|---|
| `date` | Tanggal logsheet | Date |
| `remark` | Catatan/keterangan bebas | Text |
| `shift1_field_operator` | Nama Field Operator Shift I | Text |
| `shift2_field_operator` | Nama Field Operator Shift II | Text |
| `shift3_field_operator` | Nama Field Operator Shift III | Text |
| `shift1_supervisor` | Nama Supervisor Shift I | Text |
| `shift2_supervisor` | Nama Supervisor Shift II | Text |
| `shift3_supervisor` | Nama Supervisor Shift III | Text |

**Total parameter boiler (per time slot):** ~62 field numerik
**Total baris data per hari:** 24 baris (10:00 – 09:00)
**Total data point per hari (boiler):** ~1,488 nilai

---
---

## LOGSHEET 2 — STEAM TURBINE LOCAL LOG SHEET
**Kode Dokumen:** F-MSW-OPR-06-011 Rev.02

Steam Turbine logsheet juga dibagi **2 section** dengan 24 baris waktu masing-masing.

---

### SECTION 1-A: LP HEATER

#### Group 1: LP Heater Pressure & Level
| Field ID | Parameter | Unit | Target / Batas |
|---|---|---|---|
| `lp_heater1_pressure` | No.1 LP Heater Pressure | Bar | Max 1.2 |
| `lp_heater1_level` | No.1 LP Heater Level | mm | Max 350 |
| `lp_heater2_pressure` | No.2 LP Heater Pressure | Bar | Max 5.8 |
| `lp_heater2_level` | No.2 LP Heater Level | mm | Max 350 |

---

### SECTION 1-B: CONDENSER COOLING WATER

#### Group 2: Left Side
| Field ID | Parameter | Unit | Target / Batas |
|---|---|---|---|
| `cond_cw_left_inlet_temp` | Condenser CW Left Side — Inlet Temperature | °C | Max 33 |
| `cond_cw_left_outlet_temp` | Condenser CW Left Side — Outlet Temperature | °C | Max 49 |
| `cond_cw_left_pressure` | Condenser CW Left Side — Pressure | Bar | Max 3 |

#### Group 3: Right Side
| Field ID | Parameter | Unit | Target / Batas |
|---|---|---|---|
| `cond_cw_right_inlet_temp` | Condenser CW Right Side — Inlet Temperature | °C | Max 33 |
| `cond_cw_right_outlet_temp` | Condenser CW Right Side — Outlet Temperature | °C | Max 49 |
| `cond_cw_right_pressure` | Condenser CW Right Side — Pressure | Bar | Max 3 |

---

### SECTION 1-C: CONDENSER

| Field ID | Parameter | Unit | Target / Batas |
|---|---|---|---|
| `condenser_level` | Condenser Level (Hotwell) | mm | 100.0 (normal) |

---

### SECTION 1-D: CONDENSATE EXTRACTION PUMP (CEP)

#### Group 4: No.1 CEP
| Field ID | Parameter | Unit | Target / Batas |
|---|---|---|---|
| `cep1_inlet_pressure` | No.1 CEP Inlet Pressure | Bar | < –0.77 (vacuum) |
| `cep1_outlet_pressure` | No.1 CEP Outlet Pressure | Bar | Max 15 |

#### Group 5: No.2 CEP
| Field ID | Parameter | Unit | Target / Batas |
|---|---|---|---|
| `cep2_inlet_pressure` | No.2 CEP Inlet Pressure | Bar | < –0.77 (vacuum) |
| `cep2_outlet_pressure` | No.2 CEP Outlet Pressure | Bar | Max 15 |

---

### SECTION 1-E: CONDENSATE TEMPERATURE

| Field ID | Parameter | Unit | Target / Batas |
|---|---|---|---|
| `condensate_temp_inlet` | Condensate Temperature — Inlet | °C | Max 45 |
| `condensate_temp_outlet` | Condensate Temperature — Outlet | °C | Max 50 |

---

### SECTION 1-F: GLAND STEAM CONDENSER

| Field ID | Parameter | Unit | Target / Batas |
|---|---|---|---|
| `gland_steam_press_inlet` | Gland Steam Condenser — Seal Steam Pressure Inlet | Bar | Max 0.03 |
| `gland_steam_cond_inlet_temp` | Gland Steam Condenser — Cond. to GSC Inlet Temperature | °C | Max 45 |
| `gland_steam_cond_outlet_temp` | Gland Steam Condenser — Cond. to GSC Outlet Temperature | °C | Max 50 |

---

### SECTION 1-G: AIR REMOVAL COOLING SYSTEM

#### Group 6: No.1 Air Removal
| Field ID | Parameter | Unit | Target / Batas |
|---|---|---|---|
| `air_removal1_cw_inlet_temp` | No.1 Air Removal CW — Inlet Temperature | °C | < 33 |
| `air_removal1_pressure` | No.1 Air Removal — Pressure | Bar | < 3 |
| `air_removal1_cw_outlet_temp` | No.1 Air Removal CW — Outlet Temperature | °C | Max 50 |
| `air_removal1_outlet_cooler_temp` | No.1 Air Removal — Outlet Cooler Temperature | °C | Max 50 (via cooler press 3.0) |

#### Group 7: No.2 Air Removal
| Field ID | Parameter | Unit | Target / Batas |
|---|---|---|---|
| `air_removal2_cw_inlet_temp` | No.2 Air Removal CW — Inlet Temperature | °C | < 33 |
| `air_removal2_pressure` | No.2 Air Removal — Pressure | Bar | < 3 |
| `air_removal2_cw_outlet_temp` | No.2 Air Removal CW — Outlet Temperature | °C | Max 50 |
| `air_removal2_outlet_cooler_temp` | No.2 Air Removal — Outlet Cooler Temperature | °C | Max 50 |

---

### SECTION 1-H: AIR REMOVAL PRESSURE

| Field ID | Parameter | Unit | Target / Batas |
|---|---|---|---|
| `air_removal_pressure` | Air Removal Pressure | Bar | < –0.89 (vacuum) |

---

### SECTION 1-I: GENERATOR COOLING SYSTEM

| Field ID | Parameter | Unit | Target / Batas |
|---|---|---|---|
| `gen_cooling_cw_inlet_temp` | Generator Cooling Water — Inlet Temperature | °C | < 33 |
| `gen_cooling_cw_outlet_temp` | Generator Cooling Water — Outlet Temperature | °C | Max 55 |
| `gen_cooling_cw_pressure` | Generator Cooling Water — Pressure | Bar | Max 3 |

---

### SECTION 2-A: DEAERATOR

| Field ID | Parameter | Unit | Target / Batas |
|---|---|---|---|
| `deaerator_inlet_steam_press` | Deaerator — Inlet Steam Pressure | Bar | Max 7 |
| `deaerator_inlet_steam_temp` | Deaerator — Inlet Steam Temperature | °C | Max 155 |
| `deaerator_lp_heater2_steam_press` | Deaerator — From No.2 LP Heater Steam Pressure | Bar | Max 1.2 |
| `deaerator_lp_heater2_steam_temp` | Deaerator — From No.2 LP Heater Steam Temperature | °C | Max 150 |
| `deaerator_cycle_makeup_press` | Deaerator — From Cycle Makeup Pump Inlet Pressure | Bar | Max 15 |
| `deaerator_cycle_makeup_temp` | Deaerator — From Cycle Makeup Pump Inlet Temperature | °C | Max 36 |
| `deaerator_cycle_makeup_flow` | Deaerator — From Cycle Makeup Pump Inlet Flow | M³ | Max 15 |

---

### SECTION 2-B: FEED WATER STORAGE

| Field ID | Parameter | Unit | Target / Batas |
|---|---|---|---|
| `fw_storage_pressure` | Feed Water Storage — Pressure | Bar | Max 7 |
| `fw_storage_temp` | Feed Water Storage — Temperature | °C | Max 155 |
| `fw_storage_level` | Feed Water Storage — Level | mm | Max 1400 |

---

### SECTION 2-C: INLET STEAM TO STEAM TURBINE

| Field ID | Parameter | Unit | Target / Batas |
|---|---|---|---|
| `inlet_steam_to_turbine_press` | Inlet Steam to #1 Steam Turbine — Pressure | Bar | 78 – 84 |
| `inlet_steam_to_turbine_temp` | Inlet Steam to #1 Steam Turbine — Temperature | °C | 510 – 528 |

---

### SECTION 2-D: STEAM TURBINE EXTRACTION

| Field ID | Parameter | Unit | Target / Batas |
|---|---|---|---|
| `extraction_to_lp_heater1_press` | Extraction to #1 LP Heater — Pressure | Bar | Max 5.8 |
| `extraction_to_lp_heater1_temp` | Extraction to #1 LP Heater — Temperature | °C | Max 150 |
| `extraction_to_lp_heater2_press` | Extraction to #2 LP Heater — Pressure | Bar | Max 1.2 |
| `extraction_to_lp_heater2_temp` | Extraction to #2 LP Heater — Temperature | °C | Max 150 |
| `extraction_to_deaerator_press` | Extraction to Deaerator — Pressure | Bar | Max 7 |
| `extraction_to_deaerator_temp` | Extraction to Deaerator — Temperature | °C | Max 160 |

---

### SECTION 2-E: LP DOSING SYSTEM (Amoniak & Hydrazine)

| Field ID | Parameter | Unit | Target / Batas |
|---|---|---|---|
| `lp_dosing_stroke_pump_1` | LP Dosing Stroke Pump No.1 | % | Min 20 |
| `lp_dosing_stroke_pump_2` | LP Dosing Stroke Pump No.2 | % | Min 20 |
| `lp_dosing_tank_level` | LP Dosing Tank Level | % | Min 20 |

---

### SECTION 2-F: TURBINE GENERATOR LUBE OIL SYSTEM

#### Group 8: Lube Oil Temperature
| Field ID | Parameter | Unit | Target / Batas |
|---|---|---|---|
| `lube_oil_temp_before_cooler` | Lube Oil Temperature — Before Cooler | °C | Max 65 |
| `lube_oil_temp_after_cooler` | Lube Oil Temperature — After Cooler | °C | Max 65 |

#### Group 9: Bearing Pressures — Turbine Side
| Field ID | Parameter | Unit | Target / Batas |
|---|---|---|---|
| `turbine_bearing_press_de` | Turbine Bearing Pressure — DE | Bar | Min 1 |
| `turbine_bearing_press_nde` | Turbine Bearing Pressure — NDE | Bar | Min 1 |

#### Group 10: Bearing Pressures — Generator Side
| Field ID | Parameter | Unit | Target / Batas |
|---|---|---|---|
| `gen_bearing_press_de` | Generator Bearing Pressure — DE | Bar | Min 1 |
| `gen_bearing_press_nde` | Generator Bearing Pressure — NDE | Bar | Min 1 |

#### Group 11: Gear Box
| Field ID | Parameter | Unit | Target / Batas |
|---|---|---|---|
| `gearbox_pressure` | Gear Box Pressure | Bar | Min 1 |

---

### SECTION 2-G: JACKING OIL PUMP

| Field ID | Parameter | Unit | Target / Batas |
|---|---|---|---|
| `jacking_oil_pump_pressure` | Jacking Oil Pump — Pump Pressure | Bar | — (monitor) |
| `jacking_oil_gen_bearing_de` | Jacking Oil — DE Generator Bearing Pressure | Bar | — (monitor) |
| `jacking_oil_gen_bearing_nde` | Jacking Oil — NDE Generator Bearing Pressure | Bar | — (monitor) |

---

### SECTION 2-H: LUBE OIL COOLER & FILTER (Status)

| Field ID | Parameter | Tipe | Nilai |
|---|---|---|---|
| `lube_oil_cooler_in_service` | Lube Oil Cooler In Service | Dropdown/Radio | No.1 / No.2 |
| `lube_oil_filter_in_service` | Lube Oil Filter In Service | Dropdown/Radio | No.1 / No.2 |

---

### STEAM TURBINE — Metadata & Approval

| Field ID | Parameter | Tipe |
|---|---|---|
| `date` | Tanggal logsheet | Date |
| `note` | Catatan/keterangan bebas | Text |
| `shift1_field_operator` | Nama Field Operator Shift 1 | Text |
| `shift2_field_operator` | Nama Field Operator Shift 2 | Text |
| `shift3_field_operator` | Nama Field Operator Shift 3 | Text |
| `shift1_supervisor` | Nama Supervisor Shift 1 | Text |
| `shift2_supervisor` | Nama Supervisor Shift 2 | Text |
| `shift3_supervisor` | Nama Supervisor Shift 3 | Text |

**Total parameter steam turbine (per time slot):** ~55 field numerik + 2 field status
**Total baris data per hari:** 24 baris (10:00 – 09:00)
**Total data point per hari (turbine):** ~1,368 nilai

---
---

## Ringkasan untuk Implementasi Flutter

### Data Model — Firestore Document Structure

```
/logsheets/{YYYY-MM-DD}/
  ├── boiler/
  │     ├── metadata: { date, remark, signatures: { shift1_operator, shift1_supervisor, ... } }
  │     └── entries: [
  │           { time: "10:00", paf_lube_oil_press_1: 1.1, paf1_motor_temp_de: 48.5, ... },
  │           { time: "11:00", ... },
  │           ...24 entries total
  │         ]
  └── steam_turbine/
        ├── metadata: { date, note, signatures: { shift1_operator, shift1_supervisor, ... } }
        └── entries: [
              { time: "10:00", lp_heater1_pressure: 1.0, condenser_level: 100.2, ... },
              { time: "11:00", ... },
              ...24 entries total
            ]
```

### Google Sheets Mapping

Struktur sheet rekomendasi untuk sinkronisasi Google Sheets:

```
Sheet "Boiler_YYYY-MM" (1 sheet per bulan):
  Kolom A: Date
  Kolom B: Time
  Kolom C–BN: Parameter (sesuai urutan Field ID di atas)
  
Sheet "SteamTurbine_YYYY-MM":
  Kolom A: Date
  Kolom B: Time
  Kolom C–BE: Parameter (sesuai urutan Field ID di atas)
```

### Pengelompokan UI Flutter (Accordion/Card per Group)

**Boiler Logsheet — 10 Card Group:**
1. PAF Lube Oil Pressure (2 field)
2. PAF Bearing Motor Temperature (4 field)
3. PAF Fan Bearing Temperature (4 field)
4. PAF Oil Cooler Temperature (4 field)
5. PAF Oil Tank Level, IGV & Diff Pressure (6 field)
6. IDF Bearing Motor Temperature (4 field)
7. IDF Fan Bearing Temperature, Oil Level & IGV (8 field)
8. SAF (sama struktur dengan PAF — 16 field)
9. P&S Blower & Seal Pot (6 field)
10. HP Dosing + Steam Drum (8 field)

**Steam Turbine Logsheet — 11 Card Group:**
1. LP Heater (4 field)
2. Condenser Cooling Water (6 field)
3. Condenser Level + CEP (5 field)
4. Condensate Temperature + Gland Steam (5 field)
5. Air Removal Cooling System (8 field)
6. Generator Cooling System (3 field)
7. Deaerator (7 field)
8. Feed Water Storage + Inlet Steam (5 field)
9. Steam Turbine Extraction (6 field)
10. LP Dosing (3 field)
11. Lube Oil System + Jacking Oil Pump (9 field + 2 status)

### Validasi & Alarm di App

Setiap field numerik harus divalidasi saat input. Rekomendasi implementasi:

```dart
class LogsheetField {
  final String id;
  final String label;
  final String unit;
  final double? minNormal;
  final double? maxNormal;
  final bool isVacuum; // untuk nilai bertanda negatif (CEP inlet, air removal)
  final bool isStatus; // untuk field On/Off atau No.1/No.2
  
  bool isOutOfRange(double value) {
    if (minNormal != null && value < minNormal!) return true;
    if (maxNormal != null && value > maxNormal!) return true;
    return false;
  }
}
```

**Indikator warna:**
- ✅ Hijau — nilai dalam batas target
- ⚠️ Kuning — nilai mendekati batas (threshold 90% dari batas max, atau 110% dari batas min)
- 🔴 Merah — nilai melebihi batas target
- ⬜ Abu — belum diisi

### Shift Mapping untuk Approval Flow

Berdasarkan dokumen, ada **3 shift** per hari. Mapping waktu yang direkomendasikan:

| Shift | Jam Kerja | Baris Logsheet yang Diisi |
|---|---|---|
| Shift I | 07:00 – 15:00 | 10:00, 11:00, 12:00, 13:00, 14:00 |
| Shift II | 15:00 – 23:00 | 15:00, 16:00, 17:00, 18:00, 19:00, 20:00, 21:00, 22:00 |
| Shift III | 23:00 – 07:00 | 23:00, 00:00, 01:00, 02:00, 03:00, 04:00, 05:00, 06:00 |
| Shift I (berikutnya) | 07:00 – 10:00 | 07:00, 08:00, 09:00 |

> **Catatan:** Operator hanya mengisi baris sesuai jam shift-nya. Kolom 07:00–09:00 diisi oleh Shift I hari berikutnya (namun masih dalam dokumen yang sama karena logsheet adalah 1 dokumen per hari operasi).

### Auto-populate dari Firebase RTDB

Parameter berikut **dapat di-auto-fill** dari sensor DCS via Firebase Realtime Database, sehingga operator tidak perlu input manual:

**Dari Boiler (jika ada di DCS/ABB 800xA):**
- Steam Drum Pressure & Level (Left/Right)
- IDF O2 Excess
- PAF/SAF/IDF IGV Opening

**Dari Steam Turbine:**
- Inlet Steam Pressure & Temperature ke Turbine
- Condenser Level (Hotwell)
- LP Heater Pressure

> Fields yang **tidak** bisa auto-fill (harus manual patroli lapangan): bearing temperatures, oil levels, oil cooler temperatures, karena sensor-sensor ini umumnya bersifat lokal/non-networked di plant MSW.

---

## Rekapitulasi Total Field

| Logsheet | Field Numerik | Field Status | Field Teks | Total per Time Slot |
|---|---|---|---|---|
| Boiler | 62 | 0 | 0 | 62 |
| Steam Turbine | 55 | 2 | 0 | 57 |
| **Total** | **117** | **2** | **0** | **119** |

**Total data point per hari (kedua logsheet):** ~2,856 nilai numerik

---

*Dokumen ini dibuat dari analisis file:*
- *F-MSW-OPR-06-009_Unit_1_Boiler_Local_Log_Sheet_Rev_02.xls*
- *F-MSW-OPR-06-011_Unit_1_Steam_Turbine_Local_Log_Sheet_Rev_02.xls*

*Disiapkan untuk: Implementasi MSW ePlant Digital Logsheet v3.0 (Flutter)*
