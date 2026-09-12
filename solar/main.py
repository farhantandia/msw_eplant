import requests
from datetime import datetime, timedelta
import openpyxl
from openpyxl import load_workbook
import configparser
import os
import sys
import time

MONTH_STR = {
    1: "Jan", 2: "Feb", 3: "Mar", 4: "Apr",
    5: "May", 6: "Jun", 7: "Jul", 8: "Aug",
    9: "Sep", 10: "Oct", 11: "Nov", 12: "Dec"
}

def load_root_env():
    """Membaca file .env jika tersedia untuk kredensial Huawei FusionSolar"""
    for candidate in [
        os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), ".env"),
        os.path.join(os.path.dirname(os.path.abspath(__file__)), ".env")
    ]:
        if os.path.exists(candidate):
            try:
                with open(candidate, "r", encoding="utf-8") as f:
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
            break

load_root_env()

# ── LOAD CONFIG.INI ───────────────────────────────────────
def load_config():
    base_dir    = os.path.dirname(os.path.abspath(__file__))
    config_path = os.path.join(base_dir, "config.ini")

    if not os.path.exists(config_path):
        example_path = os.path.join(base_dir, "config.ini.example")
        if os.path.exists(example_path):
            config_path = example_path
        else:
            print(f"❌ config.ini tidak ditemukan di: {config_path}")
            input("\nTekan Enter untuk keluar...")
            sys.exit(1)

    cfg = configparser.ConfigParser()
    cfg.read(config_path, encoding="utf-8")

    inverter_order = [
        line.strip()
        for line in cfg.get("inverter_order", "list").strip().splitlines()
        if line.strip() and not line.strip().startswith("#")
    ]
    inverter_468 = [
        line.strip()
        for line in cfg.get("inverter_468", "list").strip().splitlines()
        if line.strip() and not line.strip().startswith("#")
    ]

    day = cfg.getint("settings", "day", fallback=0)

    base_url = os.environ.get("FUSIONSOLAR_BASE_URL") or (
        cfg.get("fusionsolar", "base_url") if cfg.has_option("fusionsolar", "base_url") else "https://intl.fusionsolar.huawei.com/thirdData"
    )
    username = os.environ.get("FUSIONSOLAR_USERNAME") or (
        cfg.get("fusionsolar", "username") if cfg.has_option("fusionsolar", "username") else ""
    )
    system_code = os.environ.get("FUSIONSOLAR_SYSTEM_CODE") or (
        cfg.get("fusionsolar", "system_code") if cfg.has_option("fusionsolar", "system_code") else ""
    )

    return {
        "base_url":       base_url,
        "username":       username,
        "system_code":    system_code,
        "excel_file":     cfg.get("excel", "file", fallback="new_data.xlsx"),
        "sheet_name":     cfg.get("excel", "sheet_name", fallback="Sheet1"),
        "header_row":     cfg.getint("excel", "header_row", fallback=2),
        "inverter_order": inverter_order,
        "inverter_468":   inverter_468,
        "day":            day,
    }


# ── HITUNG DAFTAR TANGGAL ─────────────────────────────────
def get_target_dates(day):
    today = datetime.now().replace(hour=0, minute=0, second=0, microsecond=0)

    if day > 0:
        print(f"❌ day = {day} tidak valid. Tidak bisa ambil data masa depan.")
        input("\nTekan Enter untuk keluar...")
        sys.exit(1)

    if day == 0:
        return [today]
    else:
        return [today + timedelta(days=d) for d in range(day, 0)]

# ── LOGIN ─────────────────────────────────────────────────
def login(cfg):
    session = requests.Session()
    session.headers.update({"Content-Type": "application/json"})
    res = session.post(f"{cfg['base_url']}/login", json={
        "userName":   cfg["username"],
        "systemCode": cfg["system_code"]
    })
    token = res.headers.get("xsrf-token")
    if not token:
        raise RuntimeError(f"Login gagal: {res.json()}")
    session.headers.update({"xsrf-token": token})
    print("✅ Login sukses")
    return session

# ── LOGOUT ────────────────────────────────────────────────
def logout(session, cfg):
    try:
        session.post(f"{cfg['base_url']}/logout")
        print("👋 Logout sukses")
    except Exception:
        print("⚠️  Logout gagal (koneksi terputus)")

# ── POST DENGAN AUTO RETRY JIKA 407 ──────────────────────
def api_post(session, url, payload, retries=3):
    for attempt in range(retries):
        res = session.post(url, json=payload).json()
        if res.get("failCode") == 407:
            wait = (attempt + 1) * 10
            print(f"   ⏳ Rate limited (407), tunggu {wait} detik...")
            time.sleep(wait)
            continue
        return res
    raise RuntimeError(f"Gagal setelah {retries} percobaan: rate limit 407")

# ── AMBIL PLANT REPORT PER STATION ───────────────────────
def fetch_plant_report(session, cfg, stations, collect_time):
    # {station_code: {radiation_intensity, inverter_power, performance_ratio}}
    plant_data = {}

    for station in stations:
        station_code = station["stationCode"]
        station_name = station["stationName"]

        time.sleep(2)
        result = api_post(session, f"{cfg['base_url']}/getKpiStationDay", {
            "stationCodes": station_code,
            "collectTime":  collect_time
        })

        if not result.get("success") or not result.get("data"):
            print(f"   ⚠️  Plant report {station_name}: failCode {result.get('failCode')}")
            plant_data[station_code] = {}
            continue

        # Filter hanya record hari ini
        record = next(
            (item for item in result["data"] if item.get("collectTime") == collect_time),
            None
        )

        if record:
            kpi = record.get("dataItemMap", {})
            plant_data[station_code] = {
                "name":               station_name,
                "radiation_intensity": kpi.get("radiation_intensity", None),
                "inverter_power":      kpi.get("inverter_power",      None),
                "performance_ratio":   kpi.get("performance_ratio",   None),
            }
            print(f"   🌤️  {station_name}: "
                  f"Irr={kpi.get('radiation_intensity','-')} kWh/m², "
                  f"Pwr={kpi.get('inverter_power','-')} kWh, "
                  f"PR={kpi.get('performance_ratio','-')}%")
        else:
            plant_data[station_code] = {}

    return plant_data

# ── AMBIL YIELD & SPECIFIC ENERGY UNTUK 1 TANGGAL ────────
def fetch_yield_for_date(session, cfg, target_date):
    collect_time = int(target_date.timestamp() * 1000)

    stations_res = api_post(session, f"{cfg['base_url']}/getStationList",
                            {"pageNo": 1, "pageSize": 100})
    stations = stations_res.get("data", {}).get("list", [])

    yield_data  = {}
    se_data     = {}

    for station in stations:
        station_code = station["stationCode"]
        station_name = station["stationName"]

        time.sleep(2)
        devs_res = api_post(session, f"{cfg['base_url']}/getDevList",
                            {"stationCodes": station_code})
        all_devs = devs_res.get("data", [])

        if not all_devs or not isinstance(all_devs[0], dict):
            print(f"   ⚠️  {station_name}: response tidak valid, skip")
            continue

        inverters = [d for d in all_devs if d.get("devTypeId") == 1]
        if not inverters:
            continue

        dev_map = {d["id"]: d["devName"] for d in inverters}
        dev_ids = ",".join(str(k) for k in dev_map.keys())

        time.sleep(2)
        result = api_post(session, f"{cfg['base_url']}/getDevKpiDay", {
            "devIds":      dev_ids,
            "devTypeId":   1,
            "collectTime": collect_time
        })

        if not result.get("success") or not result.get("data"):
            print(f"   ⚠️  {station_name}: failCode {result.get('failCode')}")
            continue

        count = 0
        for item in result["data"]:
            if item.get("collectTime") != collect_time:
                continue
            dev_name = dev_map.get(item["devId"], str(item["devId"]))
            kwh      = item["dataItemMap"].get("product_power",  0)    or 0
            ratio    = item["dataItemMap"].get("perpower_ratio", None)
            yield_data[dev_name] = kwh
            if dev_name in cfg["inverter_468"]:
                se_data[dev_name] = ratio
            count += 1

        print(f"   📡 {station_name}: {count} inverter")

    # Ambil plant report untuk semua station
    print(f"   🌤️  Mengambil plant report...")
    plant_data = fetch_plant_report(session, cfg, stations, collect_time)

    return yield_data, se_data, plant_data, stations

# ── SETUP WORKBOOK & HEADER ───────────────────────────────
def setup_workbook(cfg, stations):
    se_headers    = [f"SE {inv}" for inv in cfg["inverter_468"]]

    # Plant report headers: per station
    plant_headers = []
    for s in stations:
        name = s["stationName"]
        plant_headers += [
            f"Irradiance {name} (kWh/m2)",
            f"Peak Power {name} (kWh)",
            f"PR {name} (%)",
        ]

    expected_headers = (
        ["Tahun", "Bulan", "Tanggal"]
        + cfg["inverter_order"]
        + se_headers
        + plant_headers
    )

    excel_file = cfg["excel_file"]
    sheet_name = cfg["sheet_name"]
    header_row = cfg["header_row"]

    if os.path.exists(excel_file):
        wb = load_workbook(excel_file)
    else:
        wb = openpyxl.Workbook()
        wb.active.title = sheet_name
        print(f"📄 File baru dibuat: {excel_file}")

    if sheet_name not in wb.sheetnames:
        wb.create_sheet(sheet_name)
        print(f"📋 Sheet '{sheet_name}' dibuat")

    ws = wb[sheet_name]

    existing_headers = [
        ws.cell(row=header_row, column=c).value
        for c in range(1, len(expected_headers) + 2)
    ]
    existing_headers = [h for h in existing_headers if h is not None]

    if not existing_headers:
        for col_idx, header in enumerate(expected_headers, start=1):
            ws.cell(row=header_row, column=col_idx, value=header)
        print(f"✅ Header inserted di baris {header_row}")
        existing_headers = expected_headers
    else:
        # Tambahkan header baru yang belum ada (misal plant headers baru)
        max_col = len(existing_headers)
        for header in expected_headers:
            if header not in existing_headers:
                max_col += 1
                ws.cell(row=header_row, column=max_col, value=header)
                existing_headers.append(header)
                print(f"   ➕ Header baru: {header}")

    header_col_map = {h: i for i, h in enumerate(existing_headers, start=1)}
    return wb, ws, header_col_map

# ── TULIS 1 ROW KE EXCEL ──────────────────────────────────
def write_row_to_excel(ws, yield_data, se_data, plant_data, stations,
                       target_date, cfg, header_col_map):
    header_row = cfg["header_row"]
    next_row   = None
    check_row  = header_row + 1

    while ws.cell(row=check_row, column=1).value is not None:
        r_tahun   = ws.cell(row=check_row, column=header_col_map["Tahun"]).value
        r_bulan   = ws.cell(row=check_row, column=header_col_map["Bulan"]).value
        r_tanggal = ws.cell(row=check_row, column=header_col_map["Tanggal"]).value

        if (r_tahun   == target_date.year and
            r_bulan   == MONTH_STR[target_date.month] and
            r_tanggal == target_date.day):
            next_row = check_row
            print(f"   🔄 {target_date.strftime('%Y-%m-%d')} sudah ada di baris {next_row}, di-replace")
            break
        check_row += 1

    if next_row is None:
        next_row = check_row
        print(f"   ➕ Append {target_date.strftime('%Y-%m-%d')} ke baris {next_row}")

    # Tulis tanggal
    ws.cell(row=next_row, column=header_col_map["Tahun"],   value=target_date.year)
    ws.cell(row=next_row, column=header_col_map["Bulan"],   value=MONTH_STR[target_date.month])
    ws.cell(row=next_row, column=header_col_map["Tanggal"], value=target_date.day)

    # Tulis yield inverter
    for inv_name in cfg["inverter_order"]:
        if inv_name in header_col_map:
            ws.cell(row=next_row, column=header_col_map[inv_name],
                    value=yield_data.get(inv_name, None))

    # Tulis specific energy 468 kWp
    for inv_name in cfg["inverter_468"]:
        col_key = f"SE {inv_name}"
        if col_key in header_col_map:
            ws.cell(row=next_row, column=header_col_map[col_key],
                    value=se_data.get(inv_name, None))

    # Tulis plant report per station
    for station in stations:
        station_code = station["stationCode"]
        station_name = station["stationName"]
        pd           = plant_data.get(station_code, {})

        irr_key = f"Irradiance {station_name} (kWh/m2)"
        pwr_key = f"Peak Power {station_name} (kWh)"
        pr_key  = f"PR {station_name} (%)"

        if irr_key in header_col_map:
            ws.cell(row=next_row, column=header_col_map[irr_key],
                    value=pd.get("radiation_intensity", None))
        if pwr_key in header_col_map:
            ws.cell(row=next_row, column=header_col_map[pwr_key],
                    value=pd.get("inverter_power", None))
        if pr_key in header_col_map:
            ws.cell(row=next_row, column=header_col_map[pr_key],
                    value=pd.get("performance_ratio", None))

    return next_row

# ── MAIN ──────────────────────────────────────────────────
def main():
    print("=" * 50)
    print("  FusionSolar Yield Logger")
    print("=" * 50)

    cfg          = load_config()
    target_dates = get_target_dates(cfg["day"])

    print(f"📅 Mode     : day = {cfg['day']}")
    if len(target_dates) == 1:
        print(f"   Tanggal  : {target_dates[0].strftime('%d %b %Y')}")
    else:
        print(f"   Range    : {target_dates[0].strftime('%d %b %Y')} → "
              f"{target_dates[-1].strftime('%d %b %Y')} ({len(target_dates)} hari)")
    print(f"📁 Excel    : {cfg['excel_file']}")
    print(f"📋 Sheet    : {cfg['sheet_name']}")
    print()

    session = None
    try:
        session = login(cfg)

        # Ambil daftar station sekali untuk setup header
        stations_res = api_post(session, f"{cfg['base_url']}/getStationList",
                                {"pageNo": 1, "pageSize": 100})
        stations = stations_res.get("data", {}).get("list", [])

        wb, ws, header_col_map = setup_workbook(cfg, stations)
        all_results = []

        for i, target_date in enumerate(target_dates, 1):
            if len(target_dates) > 1:
                print(f"\n[{i}/{len(target_dates)}] {target_date.strftime('%d %b %Y')}")
            else:
                print(f"\n📡 Mengambil data {target_date.strftime('%d %b %Y')}...")

            yield_data, se_data, plant_data, stations = fetch_yield_for_date(
                session, cfg, target_date)

            row = write_row_to_excel(
                ws, yield_data, se_data, plant_data, stations,
                target_date, cfg, header_col_map)

            all_results.append((target_date, yield_data, se_data, plant_data, row))

            # Simpan setiap hari berhasil
            wb.save(cfg["excel_file"])
            print(f"   💾 Tersimpan: {target_date.strftime('%d %b %Y')} → baris {row}")

            if i < len(target_dates):
                print(f"   ⏳ Loading...")
                time.sleep(5)

        # Summary
        for target_date, yield_data, se_data, plant_data, row in all_results:
            print(f"\n{'═'*55}")
            print(f"  📅 {target_date.strftime('%d %b %Y')} (baris {row})")
            print(f"{'─'*55}")

            # Yield summary
            print(f"  {'Inverter':<35} {'kWh':>8}")
            print(f"  {'─'*43}")
            total = 0
            for inv in cfg["inverter_order"]:
                kwh     = yield_data.get(inv, None)
                kwh_str = f"{kwh:.2f}" if kwh is not None else "-"
                total  += kwh if kwh else 0
                print(f"  {inv:<35} {kwh_str:>8}")
            print(f"  {'─'*43}")
            print(f"  {'⚡ TOTAL':<35} {total:>8.2f} kWh")

            # SE summary
            if se_data:
                print(f"\n  {'Specific Energy 468 kWp':<35} {'kWh/kWp':>8}")
                print(f"  {'─'*43}")
                for inv in cfg["inverter_468"]:
                    se     = se_data.get(inv, None)
                    se_str = f"{se:.3f}" if se is not None else "-"
                    print(f"  {inv:<35} {se_str:>8}")

            # Plant report summary
            print(f"\n  {'Station':<30} {'Irr':>8}  {'Power':>10}  {'PR':>7}")
            print(f"  {'─'*55}")
            for station in stations:
                sc   = station["stationCode"]
                sn   = station["stationName"]
                pd   = plant_data.get(sc, {})
                irr  = f"{pd.get('radiation_intensity', '-')}"
                pwr  = f"{pd.get('inverter_power', '-')}"
                pr   = f"{pd.get('performance_ratio', '-')}"
                print(f"  {sn:<30} {irr:>8}  {pwr:>10}  {pr:>7}")

    except Exception as e:
        print(f"\n❌ Error: {e}")
        import traceback
        traceback.print_exc()

    finally:
        if session is not None:
            logout(session, cfg)

if __name__ == "__main__":
    main()
    print("\nTekan Enter untuk keluar...")
    input()