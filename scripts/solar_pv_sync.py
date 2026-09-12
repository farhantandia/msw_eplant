#!/usr/bin/env python3
"""
MSW ePlant - Solar PV Firebase RTDB Sync & Seed Script
======================================================
This standalone script communicates directly with Firebase Realtime Database
REST API (https://mswproject-bf2cd-default-rtdb.asia-southeast1.firebasedatabase.app/solar_pv).

Features:
- --seed: Immediately generates and seeds latest snapshot + 7-day rolling historical hourly records.
- --sync: Syncs current hourly snapshot and purges records older than 7 days.
- --test: Tests connection to Firebase Realtime Database.
- Zero heavy dependencies (uses standard Python library: urllib, json, datetime, math).
"""

import sys
import json
import math
import argparse
import urllib.request
import urllib.error
import os
from datetime import datetime, timedelta

# Ensure UTF-8 output on Windows consoles if supported
if hasattr(sys.stdout, 'reconfigure'):
    try:
        sys.stdout.reconfigure(encoding='utf-8')
    except Exception:
        pass

def load_env():
    """Lightweight .env loader without third-party dependencies"""
    env_path = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), ".env")
    if os.path.exists(env_path):
        try:
            with open(env_path, "r", encoding="utf-8") as f:
                for line in f:
                    line = line.strip()
                    if not line or line.startswith("#") or "=" not in line:
                        continue
                    k, v = line.split("=", 1)
                    k, v = k.strip(), v.strip().strip("'\"")
                    if k and k not in os.environ:
                        os.environ[k] = v
        except Exception:
            pass

load_env()

_rtdb_root = os.environ.get(
    "FIREBASE_RTDB_URL",
    ""
).rstrip("/")

DEFAULT_RTDB_BASE_URL = f"{_rtdb_root}/solar_pv" if _rtdb_root else ""

def format_date_key(dt: datetime) -> str:
    return dt.strftime("%Y-%m-%d")

def format_hour_key(dt: datetime) -> str:
    return dt.strftime("%H")

def get_cutoff_date(now: datetime, retention_days: int = 7) -> datetime:
    return now - timedelta(days=retention_days)

def http_put(url: str, data: dict) -> dict:
    req = urllib.request.Request(
        url,
        data=json.dumps(data).encode("utf-8"),
        headers={"Content-Type": "application/json"},
        method="PUT"
    )
    with urllib.request.urlopen(req, timeout=15) as resp:
        body = resp.read().decode("utf-8")
        return json.loads(body) if body else {}

def http_patch(url: str, data: dict) -> dict:
    req = urllib.request.Request(
        url,
        data=json.dumps(data).encode("utf-8"),
        headers={"Content-Type": "application/json"},
        method="PATCH"
    )
    with urllib.request.urlopen(req, timeout=15) as resp:
        body = resp.read().decode("utf-8")
        return json.loads(body) if body else {}

def http_delete(url: str) -> None:
    req = urllib.request.Request(url, method="DELETE")
    try:
        with urllib.request.urlopen(req, timeout=15) as resp:
            resp.read()
    except urllib.error.HTTPError as e:
        print(f"[WARN] Error during DELETE {url}: {e}")

def http_get(url: str) -> dict:
    req = urllib.request.Request(url, method="GET")
    with urllib.request.urlopen(req, timeout=15) as resp:
        body = resp.read().decode("utf-8")
        return json.loads(body) if body else {}

def generate_hourly_telemetry(dt: datetime) -> dict:
    hour = dt.hour + (dt.minute / 60.0)
    sun_factor = 0.0
    if 6.0 <= hour <= 18.5:
        norm = (hour - 6.0) / 12.5
        sun_factor = max(0.0, min(1.0, math.sin(norm * math.pi)))

    is_night = hour < 5.8 or hour > 18.5
    peak_system_power = 720.0 # kW for 868 kWp total capacity
    power_kw = 0.0 if is_night else round(peak_system_power * sun_factor * 0.96, 1)
    irradiance = 0.0 if is_night else round(sun_factor * 0.98, 2)
    pr = 0.0 if is_night else round(82.4 + (dt.hour % 3) * 0.4, 1)

    # Estimate cumulative daily yield up to this hour
    day_fraction = max(0.0, min(1.0, (hour - 6.0) / 12.0))
    daily_yield_kwh = 0.0 if hour < 6.0 else round(3400.0 * (day_fraction ** 1.3), 1)

    # Plant breakdown
    msw_power_kw = round(power_kw * 0.46, 1)
    msw_yield_kwh = round(daily_yield_kwh * 0.46, 1)
    kelanis_power_kw = round(power_kw * 0.54, 1)
    kelanis_yield_kwh = round(daily_yield_kwh * 0.54, 1)

    # 12 Inverters
    inverters = []
    # 4 units in 165kWp (MSW)
    for i in range(1, 5):
        inverters.append({
            "id": f"inv_165_{i}",
            "name": f"INV PLTS 165 kWp {i}",
            "cluster_id": "165kwp",
            "plant_id": "msw",
            "power_kw": 0.0 if is_night else round(msw_power_kw * 0.118, 1),
            "yield_today_kwh": round(msw_yield_kwh * 0.118, 1),
            "specific_energy": 0.0 if is_night else round(msw_yield_kwh * 0.118 / 41.25, 2),
            "temperature": 28.0 if is_night else round(42.0 + (dt.hour % 4) * 1.5, 1),
            "efficiency": 0.0 if is_night else round(98.2 + (i % 2) * 0.2, 1),
            "grid_frequency": 50.0,
            "line_voltage_ab": 380.0,
            "line_voltage_bc": 380.0,
            "line_voltage_ca": 380.0,
            "phase_current_a": 0.0 if is_night else round((msw_power_kw * 0.118 * 1000) / (1.732 * 380), 1),
            "phase_current_b": 0.0 if is_night else round((msw_power_kw * 0.118 * 1000) / (1.732 * 380), 1),
            "phase_current_c": 0.0 if is_night else round((msw_power_kw * 0.118 * 1000) / (1.732 * 380), 1),
            "power_factor": 0.99,
            "mppt_power_kw": 0.0 if is_night else round(msw_power_kw * 0.12, 1),
            "status": "standby" if is_night else "normal",
            "is_night_standby": is_night
        })
    # 4 units in 235kWp (MSW)
    for i in range(1, 5):
        inverters.append({
            "id": f"inv_235_{i}",
            "name": f"INV PLTS 235 kWp {i}",
            "cluster_id": "235kwp",
            "plant_id": "msw",
            "power_kw": 0.0 if is_night else round(msw_power_kw * 0.132, 1),
            "yield_today_kwh": round(msw_yield_kwh * 0.132, 1),
            "specific_energy": 0.0 if is_night else round(msw_yield_kwh * 0.132 / 58.75, 2),
            "temperature": 28.5 if is_night else round(44.0 + (dt.hour % 4) * 1.2, 1),
            "efficiency": 0.0 if is_night else round(98.4, 1),
            "grid_frequency": 50.0,
            "line_voltage_ab": 380.0,
            "line_voltage_bc": 380.0,
            "line_voltage_ca": 380.0,
            "phase_current_a": 0.0 if is_night else round((msw_power_kw * 0.132 * 1000) / (1.732 * 380), 1),
            "phase_current_b": 0.0 if is_night else round((msw_power_kw * 0.132 * 1000) / (1.732 * 380), 1),
            "phase_current_c": 0.0 if is_night else round((msw_power_kw * 0.132 * 1000) / (1.732 * 380), 1),
            "power_factor": 0.99,
            "mppt_power_kw": 0.0 if is_night else round(msw_power_kw * 0.135, 1),
            "status": "standby" if is_night else "normal",
            "is_night_standby": is_night
        })
    # 4 units in 468kWp (Kelanis)
    for i in range(1, 5):
        inverters.append({
            "id": f"inv_kelanis_{i}",
            "name": f"INV PLTS Kelanis {i}",
            "cluster_id": "kelanis_468",
            "plant_id": "kelanis",
            "power_kw": 0.0 if is_night else round(kelanis_power_kw * 0.25, 1),
            "yield_today_kwh": round(kelanis_yield_kwh * 0.25, 1),
            "specific_energy": 0.0 if is_night else round(kelanis_yield_kwh * 0.25 / 117.0, 2),
            "temperature": 28.0 if is_night else round(43.5 + (dt.hour % 4) * 1.4, 1),
            "efficiency": 0.0 if is_night else round(98.5, 1),
            "grid_frequency": 50.0,
            "line_voltage_ab": 380.0,
            "line_voltage_bc": 380.0,
            "line_voltage_ca": 380.0,
            "phase_current_a": 0.0 if is_night else round((kelanis_power_kw * 0.25 * 1000) / (1.732 * 380), 1),
            "phase_current_b": 0.0 if is_night else round((kelanis_power_kw * 0.25 * 1000) / (1.732 * 380), 1),
            "phase_current_c": 0.0 if is_night else round((kelanis_power_kw * 0.25 * 1000) / (1.732 * 380), 1),
            "power_factor": 0.99,
            "mppt_power_kw": 0.0 if is_night else round(kelanis_power_kw * 0.255, 1),
            "status": "standby" if is_night else "normal",
            "is_night_standby": is_night
        })

    online_inverters = 0 if is_night else 12

    return {
        "timestamp": dt.isoformat(),
        "hour": dt.hour,
        "total_power_kw": power_kw,
        "total_yield_kwh": daily_yield_kwh,
        "peak_power_kw": peak_system_power,
        "irradiance": irradiance,
        "pr": pr,
        "grid_export_kw": round(power_kw * 0.97, 1),
        "online_inverters": online_inverters,
        "total_inverters": 12,
        "plants": {
            "msw": {
                "power_kw": msw_power_kw,
                "yield_kwh": msw_yield_kwh,
                "irradiance": round(irradiance * 1.05, 2),
                "pr": round(pr + 1.2, 1),
                "peak_power_kw": 360.0,
                "online_inverters": 0 if is_night else 8,
                "total_inverters": 8
            },
            "kelanis": {
                "power_kw": kelanis_power_kw,
                "yield_kwh": kelanis_yield_kwh,
                "irradiance": round(irradiance * 0.94, 2),
                "pr": round(pr - 1.8, 1),
                "peak_power_kw": 410.0,
                "online_inverters": 0 if is_night else 4,
                "total_inverters": 4
            }
        },
        "inverters": inverters
    }

def seed_database(base_url: str) -> None:
    now = datetime.now()
    print(f"[START] Starting initial seed for Firebase RTDB root '/solar_pv'...")
    print(f"[INFO] Target: {base_url}.json")

    # 1. Seed latest snapshot
    latest_snapshot = generate_hourly_telemetry(now)
    latest_url = f"{base_url}/latest.json"
    print("[INFO] Pushing /solar_pv/latest ...")
    try:
        http_put(latest_url, latest_snapshot)
        print("[OK] /solar_pv/latest successfully updated!")
    except Exception as e:
        print(f"[ERROR] Failed to push /solar_pv/latest: {e}")
        print("[HINT] Ensure Firebase Realtime Database Security Rules allow write access to 'solar_pv':")
        print('       "solar_pv": { ".read": true, ".write": true }')
        return

    # 2. Seed 7-day historical records (hours 04 to 20 for past 6 days, and up to current hour today)
    print("[INFO] Seeding 7 days of historical records into /solar_pv/history ...")
    history_payload = {}
    for day_offset in range(6, -1, -1):
        target_date = now - timedelta(days=day_offset)
        date_key = format_date_key(target_date)
        max_hour = now.hour if day_offset == 0 else 20
        hours_map = {}
        for h in range(4, max_hour + 1):
            h_dt = target_date.replace(hour=h, minute=0, second=0, microsecond=0)
            hours_map[f"{h:02d}"] = generate_hourly_telemetry(h_dt)
        history_payload[date_key] = hours_map

    history_url = f"{base_url}/history.json"
    try:
        http_patch(history_url, history_payload)
        print(f"[OK] /solar_pv/history successfully populated with 7 days ({len(history_payload)} dates) of data!")
    except Exception as e:
        print(f"[ERROR] Failed to seed /solar_pv/history: {e}")

    print("[DONE] Seeding complete. You can now check the Firebase Console to see the '/solar_pv' node.")

def sync_hourly(base_url: str) -> None:
    now = datetime.now()
    date_key = format_date_key(now)
    hour_key = format_hour_key(now)

    print(f"[INFO] Running hourly sync at {now.isoformat()} (Bucket: {date_key}/{hour_key})")
    telemetry = generate_hourly_telemetry(now)

    # 1. Update /solar_pv/latest
    try:
        http_put(f"{base_url}/latest.json", telemetry)
        print("[OK] Updated /solar_pv/latest")
    except Exception as e:
        print(f"[ERROR] Failed to update latest: {e}")

    # 2. Append to /solar_pv/history/{date}/{hour}
    try:
        http_put(f"{base_url}/history/{date_key}/{hour_key}.json", telemetry)
        print(f"[OK] Appended to /solar_pv/history/{date_key}/{hour_key}")
    except Exception as e:
        print(f"[ERROR] Failed to append history: {e}")

    # 3. Prune records older than 7 days
    cutoff_date = get_cutoff_date(now, retention_days=7)
    cutoff_key = format_date_key(cutoff_date)
    print(f"[INFO] Pruning historical date records older than 7 days (< {cutoff_key}) ...")

    try:
        history_data = http_get(f"{base_url}/history.json")
        if isinstance(history_data, dict):
            for existing_date in history_data.keys():
                if existing_date < cutoff_key:
                    print(f"[INFO] Deleting expired date node: {existing_date}")
                    http_delete(f"{base_url}/history/{existing_date}.json")
            print("[OK] 7-day rolling window pruning complete.")
    except Exception as e:
        print(f"[WARN] Note on pruning: {e}")

def run_daemon(base_url: str, interval_seconds: int = 3600) -> None:
    import time
    print(f"[DAEMON] Starting continuous sync loop every {interval_seconds} seconds ({interval_seconds / 60:.1f} minutes)...")
    print("[DAEMON] Press Ctrl+C to terminate.")
    try:
        while True:
            sync_hourly(base_url)
            print(f"[DAEMON] Sleeping for {interval_seconds}s until next sync...")
            time.sleep(interval_seconds)
    except KeyboardInterrupt:
        print("\n[DAEMON] Terminated by user.")

def main():
    parser = argparse.ArgumentParser(description="MSW Solar PV Firebase RTDB Sync & Seed Tool")
    parser.add_argument("--seed", action="store_true", help="Perform initial seed of latest + 7-day history")
    parser.add_argument("--sync", action="store_true", help="Run hourly sync and prune records > 7 days")
    parser.add_argument("--daemon", action="store_true", help="Run continuous background sync loop")
    parser.add_argument("--interval", type=int, default=3600, help="Interval in seconds for daemon mode (default: 3600)")
    parser.add_argument("--test", action="store_true", help="Test Firebase RTDB connection")
    parser.add_argument("--url", default=DEFAULT_RTDB_BASE_URL, help=f"Base RTDB URL (default: {DEFAULT_RTDB_BASE_URL})")

    args = parser.parse_args()

    if args.seed:
        seed_database(args.url)
    elif args.sync:
        sync_hourly(args.url)
    elif args.daemon:
        run_daemon(args.url, interval_seconds=args.interval)
    elif args.test:
        print(f"[TEST] Testing connection to: {args.url}.json ...")
        try:
            data = http_get(f"{args.url}.json")
            print("[OK] Connection successful!")
            print(f"[INFO] Existing keys under /solar_pv: {list(data.keys()) if isinstance(data, dict) else 'None'}")
        except Exception as e:
            print(f"[ERROR] Connection error: {e}")
    else:
        parser.print_help()

if __name__ == "__main__":
    main()

