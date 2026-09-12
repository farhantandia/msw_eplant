# Huawei FusionSolar & SUN2000 Inverter Integration Invariants

## 1. Inverter State Classification (Table 3-1)
Never evaluate inverter health using naive numeric thresholds (e.g. `stateCode > 2`). Always map against official Huawei Table 3-1 specifications:
- **Normal Standby (Healthy, 0 Alarms)**: `0` (Initializing), `1` (Insulation Detecting), `2` (Irradiation Detecting), `3` (Grid Detecting), `40960` (Standby: No Irradiation), `40961` (Standby: No DC Input).
- **Normal Grid-Connected (Healthy, 0 Alarms)**: `256` (Start), `512` (Grid-Connected), `515` (Off-Grid), `1025..1029` (Grid Scheduling Curves).
- **Derated Operation (Warning)**: `513` (Power Limited), `514` (Self-Derating).
- **Shutdown / Fault (Major/Critical)**: `768` (On Fault), `770` (OVGR), `771` (Comm Interrupted), `773` (Manual Startup Req), `774` (DC Switch Disconnected), `777` (NS Protection), `45056` (SmartLogger Comm Interrupted).
- **Inspection & Testing**: `1280..2560`, `49152`.

## 2. Cache Sanitization Invariant
- Stale or historical synthetic alarms (such as `STATE-FAULT-40960` or alarms with code `40960` / `no irradiation`) must be filtered out inside `SolarInverter.fromJson` and `SolarInverter.activeAlarms`.
- This ensures cached Firebase RTDB payloads do not cause phantom alarms on client devices before new API syncs execute.

## 3. Huawei OpenAPI Communication Protocol
- **Pacing Delay (Anti-407)**: Apply a mandatory inter-request delay (minimum 2 seconds) to avoid Huawei HTTP 407 (`access frequency too high`).
- **Device Batching**: Always batch device IDs into comma-separated strings (`devIds: "id1,id2,id3"`) for `/getDevRealKpi` and `/getDevKpiDay`.
- **Session Handling**: If `failCode: 305` is returned, reset `xsrfToken` and re-authenticate immediately.
- **30-Minute Bucket Caching**: Do not make external API requests if a sync already succeeded in the current 30-minute bucket (`(hour * 2) + (minute >= 30 ? 1 : 0)`).
- **16-Hour Operational Window**: Only call the OpenAPI between 04:00 and 20:00 WITA. Outside this window, set inverters to Night Standby (0.0 kW) with 0 API requests.
