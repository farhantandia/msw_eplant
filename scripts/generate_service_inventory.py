#!/usr/bin/env python3
"""
MSW ePlant - Comprehensive Service, Database & Data Request Inventory Generator
================================================================================
Generates a multi-sheet, professionally-styled Microsoft Excel workbook (.xlsx)
documenting every service, database node, API request, payload, and data field
across the MSW ePlant Flutter & Python codebase.

Consolidates:
  - Central Plant CFPP RTDB Nodes (/excel_data/overview, table1, table2, cems1, cems2, nphr)
  - Huawei FusionSolar OpenAPI (Endpoints, Inverter Table 3-1, 12 Inverters, JSON Payloads)
  - Microsoft Dynamics 365 (D365) Maintenance & Inventory
  - OpenWeatherMap & Meteorological Algorithms
  - Google Sheets API v4 Shift Logsheet
  - Local Device Services (Auth, CEMS Thresholds, Notifications, OKRs)

Output:
    docs/msw_services_data_inventory.xlsx

Usage:
    python scripts/generate_service_inventory.py
"""

import os
import sys
import json
from openpyxl import Workbook
from openpyxl.styles import Font, PatternFill, Alignment, Border, Side
from openpyxl.utils import get_column_letter

# Ensure UTF-8 output
if hasattr(sys.stdout, 'reconfigure'):
    try:
        sys.stdout.reconfigure(encoding='utf-8')
    except Exception:
        pass

OUTPUT_DIR = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "docs")
OUTPUT_FILE = os.path.join(OUTPUT_DIR, "msw_services_data_inventory.xlsx")

# -----------------------------------------------------------------------------
# Color Palette & Styles (Industrial SCADA Palette)
# -----------------------------------------------------------------------------
HEADER_FILL = PatternFill(start_color="1B365D", end_color="1B365D", fill_type="solid") # Deep Navy
HEADER_FONT = Font(name="Segoe UI", size=10, bold=True, color="FFFFFF")

TITLE_FILL = PatternFill(start_color="0A192F", end_color="0A192F", fill_type="solid") # Dark Navy / Slate
TITLE_FONT = Font(name="Segoe UI", size=13, bold=True, color="FFFFFF")
SUBTITLE_FONT = Font(name="Segoe UI", size=9, italic=True, color="8892B0")

REGULAR_FONT = Font(name="Segoe UI", size=9, color="1F2937")
CODE_FONT = Font(name="Consolas", size=8.5, color="0F172A")
BOLD_FONT = Font(name="Segoe UI", size=9, bold=True, color="1F2937")

# Status Fills & Fonts
FILL_LIVE = PatternFill(start_color="E6F4EA", end_color="E6F4EA", fill_type="solid") # Green
FONT_LIVE = Font(name="Segoe UI", size=8.5, bold=True, color="137333")

FILL_HYBRID = PatternFill(start_color="FEF7E0", end_color="FEF7E0", fill_type="solid") # Amber
FONT_HYBRID = Font(name="Segoe UI", size=8.5, bold=True, color="B06000")

FILL_LOCAL = PatternFill(start_color="E8F0FE", end_color="E8F0FE", fill_type="solid") # Blue
FONT_LOCAL = Font(name="Segoe UI", size=8.5, bold=True, color="1A73E8")

FILL_ALERT = PatternFill(start_color="FCE8E6", end_color="FCE8E6", fill_type="solid") # Red
FONT_ALERT = Font(name="Segoe UI", size=8.5, bold=True, color="C5221F")

# Zebra Rows
ZEBRA_FILL = PatternFill(start_color="F8FAFC", end_color="F8FAFC", fill_type="solid")
WHITE_FILL = PatternFill(start_color="FFFFFF", end_color="FFFFFF", fill_type="solid")

THIN_BORDER = Border(
    left=Side(style='thin', color='E2E8F0'),
    right=Side(style='thin', color='E2E8F0'),
    top=Side(style='thin', color='E2E8F0'),
    bottom=Side(style='thin', color='E2E8F0')
)

HEADER_BORDER = Border(
    left=Side(style='thin', color='2A4365'),
    right=Side(style='thin', color='2A4365'),
    top=Side(style='medium', color='0A192F'),
    bottom=Side(style='medium', color='0A192F')
)

ALIGN_LEFT = Alignment(horizontal="left", vertical="center", wrap_text=True)
ALIGN_CENTER = Alignment(horizontal="center", vertical="center")
ALIGN_RIGHT = Alignment(horizontal="right", vertical="center")

# Standard Column Headers
STANDARD_HEADERS = [
    "No",
    "Category / Subsystem",
    "Service Class / Script",
    "File Code Path",
    "Function / Listener",
    "Endpoint / Database Path",
    "Method / Protocol",
    "Request Parameters / Body",
    "Data Key / Field Name",
    "Data Type & Unit",
    "Description & Usage in App",
    "Integration Status"
]

def apply_sheet_title(ws, title_text, subtitle_text, col_count=12):
    ws.merge_cells(start_row=1, start_column=1, end_row=1, end_column=col_count)
    ws.row_dimensions[1].height = 28
    title_cell = ws.cell(row=1, column=1, value=f"  {title_text}")
    title_cell.fill = TITLE_FILL
    title_cell.font = TITLE_FONT
    title_cell.alignment = Alignment(horizontal="left", vertical="center")

    ws.merge_cells(start_row=2, start_column=1, end_row=2, end_column=col_count)
    ws.row_dimensions[2].height = 18
    sub_cell = ws.cell(row=2, column=1, value=f"  {subtitle_text}")
    sub_cell.fill = TITLE_FILL
    sub_cell.font = SUBTITLE_FONT
    sub_cell.alignment = Alignment(horizontal="left", vertical="center")

    # Empty spacer row
    ws.row_dimensions[3].height = 8

def format_data_table(ws, headers, rows, start_row=4, wrap_cols=None):
    ws.views.sheetView[0].showGridLines = True
    ws.row_dimensions[start_row].height = 26
    for col_idx, header in enumerate(headers, 1):
        cell = ws.cell(row=start_row, column=col_idx, value=header)
        cell.fill = HEADER_FILL
        cell.font = HEADER_FONT
        cell.alignment = ALIGN_CENTER
        cell.border = HEADER_BORDER

    # Populate data rows
    for r_idx, row_data in enumerate(rows, start_row + 1):
        ws.row_dimensions[r_idx].height = 24
        is_even = (r_idx % 2 == 0)
        row_fill = ZEBRA_FILL if is_even else WHITE_FILL

        for c_idx, val in enumerate(row_data, 1):
            cell = ws.cell(row=r_idx, column=c_idx, value=val)
            cell.border = THIN_BORDER

            header_name = headers[c_idx - 1] if c_idx - 1 < len(headers) else ""

            if header_name == "No" or header_name == "Kode" or header_name == "Cluster / Unit":
                cell.alignment = ALIGN_CENTER
                cell.font = BOLD_FONT
                cell.fill = row_fill
            elif header_name in ["Integration Status", "Production Status", "Status", "Status di UI", "Klasifikasi Sistem", "Status Alarm"]:
                status_str = str(val).lower()
                if any(x in status_str for x in ["live", "aktif", "ditampilkan di ui", "healthy", "compliant"]):
                    cell.fill = FILL_LIVE
                    cell.font = FONT_LIVE
                elif any(x in status_str for x in ["hybrid", "derated", "warning", "standby"]):
                    cell.fill = FILL_HYBRID
                    cell.font = FONT_HYBRID
                elif any(x in status_str for x in ["fault", "critical", "major", "exceed", "shutdown", "stop"]):
                    cell.fill = FILL_ALERT
                    cell.font = FONT_ALERT
                else:
                    cell.fill = FILL_LOCAL
                    cell.font = FONT_LOCAL
                cell.alignment = ALIGN_CENTER
            elif header_name in ["File Code Path", "Endpoint / Database Path", "Method / Protocol", "Data Key / Field Name", "Request Parameters / Body", "Endpoint Sumber", "Field API"]:
                cell.font = CODE_FONT
                cell.alignment = ALIGN_LEFT
                cell.fill = row_fill
            else:
                cell.font = REGULAR_FONT
                cell.alignment = ALIGN_LEFT
                cell.fill = row_fill

    # Enable Auto-Filter
    last_col_letter = get_column_letter(len(headers))
    ws.auto_filter.ref = f"A{start_row}:{last_col_letter}{start_row + len(rows)}"

    # Auto-adjust column widths
    for col in ws.columns:
        col_letter = get_column_letter(col[0].column)
        max_len = 0
        for cell in col:
            if cell.row in [1, 2, 3]:
                continue
            if cell.value:
                lines = str(cell.value).split("\n")
                line_max = max(len(l) for l in lines)
                if line_max > max_len:
                    max_len = line_max
        ws.column_dimensions[col_letter].width = min(max(max_len + 3, 10), 60)

# =============================================================================
# SHEET 1: Overview & Architecture
# =============================================================================
def build_overview_sheet(wb):
    ws = wb.active
    ws.title = "Overview & Architecture"
    apply_sheet_title(
        ws,
        "MSW ePLANT - EXECUTIVE ARCHITECTURE & SERVICE INVENTORY",
        "Dokumen Resmi Inventaris Seluruh Service, Database Node, dan Protokol Komunikasi Data Mobile & Backend MSW ePlant (v4.7)",
        col_count=8
    )

    headers = [
        "No",
        "Service / Data Domain",
        "Primary File(s)",
        "Protocol / Transport",
        "Base URL / Host",
        "Authentication / Credential",
        "Total Fields / Keys",
        "Production Status"
    ]

    rows = [
        [
            1,
            "Firebase Realtime Database (RTDB) - CFPP Overview",
            "lib/models/plant_overview_models.dart\nlib/pages/plant/plant_overview_detail_page.dart\nlib/pages/home_page.dart",
            "WebSocket (WSS) Stream & REST API",
            "https://mswproject-bf2cd-default-rtdb.asia-southeast1.firebasedatabase.app",
            "Firebase Service Account / API Key (google-services.json)",
            "14 Central KPI Fields (Gross MW, TMGCR, BMCR, CF, EAF)",
            "Live RTDB Stream"
        ],
        [
            2,
            "Firebase RTDB - Boiler & Turbine (Unit 1 & Unit 2)",
            "lib/pages/unit_detail_page.dart\nlib/pages/plant_page.dart\nlib/pages/analytics_page.dart",
            "WebSocket (WSS) Stream & REST API",
            "https://mswproject-bf2cd-default-rtdb.asia-southeast1.firebasedatabase.app",
            "Firebase Service Account / API Key",
            "26 Fields per Unit (Main Steam, Feedwater, Air Flows, Feeders)",
            "Live RTDB Stream"
        ],
        [
            3,
            "Firebase RTDB - CEMS Cerobong (cems1 & cems2)",
            "lib/pages/cems_detail_page.dart\nlib/services/cems_threshold_service.dart\nlib/services/notification_service.dart",
            "WebSocket (WSS) Stream & REST API",
            "https://mswproject-bf2cd-default-rtdb.asia-southeast1.firebasedatabase.app",
            "Firebase Service Account / API Key",
            "13 Emisi & Baku Mutu Fields (SO2, NOx, PM, Hg, O2, Flow)",
            "Live RTDB Stream"
        ],
        [
            4,
            "Firebase RTDB - NPHR & Thermal Efficiency",
            "lib/pages/nphr_page.dart\nlib/pages/plant/plant_overview_detail_page.dart",
            "WebSocket (WSS) Stream & REST API",
            "https://mswproject-bf2cd-default-rtdb.asia-southeast1.firebasedatabase.app",
            "Firebase Service Account / API Key",
            "8 Fields + Polynomial 6th Degree Curves (5-30 MW)",
            "Live RTDB Stream"
        ],
        [
            5,
            "Huawei FusionSolar OpenAPI (v4.7 Safeguards)",
            "lib/services/fusion_solar_api_client.dart\nlib/services/fusion_solar_service.dart\nscripts/solar_pv_sync.py",
            "HTTPS REST (JSON POST)",
            "https://intl.fusionsolar.huawei.com/thirdData",
            "Configured via .env (FUSIONSOLAR_USERNAME, FUSIONSOLAR_SYSTEM_CODE); 407 2x stop rule, 30-min cron",
            "28 Telemetry Parameters (Purely Electrical, ESG Removed)",
            "Live API + Hybrid Cache"
        ],
        [
            6,
            "Solar PV Inverter Fleet Mapping",
            "lib/services/fusion_solar_api_client.dart\nlib/pages/solarpv/inverter_detail_page.dart",
            "Modbus over SmartLogger & Northbound API",
            "Cloud OpenAPI / Northbound ThirdData",
            "Inverter ESN & Station Codes (NE=54218158, NE=56226734)",
            "12 Inverter Units (868 kWp Total: MSW 400 kWp + Kelanis 468 kWp)",
            "Live Fleet Mapping"
        ],
        [
            7,
            "Simulasi Payload JSON FusionSolar",
            "lib/services/fusion_solar_api_client.dart\nsolar/generate_fusionsolar_excel.py",
            "JSON Request / Response Schemas",
            "Endpoints: login, devList, devRealKpi, devKpiDay, alarmList",
            "Configured via .env (FUSIONSOLAR_USERNAME, FUSIONSOLAR_SYSTEM_CODE)",
            "7 Core Request/Response Payloads & Diagnostics",
            "Standard OpenAPI Spec"
        ],
        [
            8,
            "Microsoft Dynamics 365 (D365) Maintenance",
            "lib/services/d365_service.dart\nlib/pages/maintenance/maintenance_page.dart",
            "HTTPS REST / OData & Local Storage",
            "Configured via .env (D365_API_BASE_URL) & SharedPreferences",
            "Employee Code Auth (6100xxxx) & Bearer Token",
            "28 Fields (19 Warehouses, 86 Activities, 39 Cost Centers)",
            "Hybrid (Live API + Seed Master)"
        ],
        [
            9,
            "OpenWeatherMap & Meteorologi",
            "lib/services/weather_service.dart\nlib/pages/weather_page.dart",
            "HTTPS REST (JSON GET)",
            "https://api.openweathermap.org/data/2.5",
            "Configured via .env (OPENWEATHER_API_KEY, OPENWEATHER_BASE_URL)",
            "22 Parameters (Weather, Forecast, Solar Potential, Operational Risks)",
            "Live API"
        ],
        [
            10,
            "Google Sheets API v4 (Shift Logsheet)",
            "lib/pages/logsheet/logsheet_service.dart\nlib/pages/logsheet/logsheet_page.dart",
            "HTTPS REST (JSON POST/GET/PUT)",
            "https://sheets.googleapis.com/v4/spreadsheets",
            "Google Sign-In OAuth2 (email, spreadsheets, drive scopes)",
            "60+ Logsheet Shift Operational Columns",
            "Live API + Firebase Config"
        ],
        [
            11,
            "Local & Device Services (Auth, CEMS, Notification, OKR)",
            "lib/services/auth_service.dart\nlib/services/cems_threshold_service.dart\nlib/services/notification_service.dart\nlib/services/okr_service.dart",
            "Local SharedPreferences, Android Notification Channel, Flutter Engine",
            "Local Device Storage & Android Notification Manager",
            "Configured via .env (DEFAULT_*_PASSWORD) & Role-based PINs",
            "18 Config, Compliance & Threshold Fields",
            "Local / Device Native"
        ]

    ]

    format_data_table(ws, headers, rows, start_row=4)

# =============================================================================
# SHEET 2: CFPP Overview (excel_data/overview)
# =============================================================================
def build_cfpp_overview_sheet(wb):
    ws = wb.create_sheet(title="CFPP Overview (excel_data)")
    apply_sheet_title(
        ws,
        "CFPP CENTRAL OVERVIEW TELEMETRY (/excel_data/overview)",
        "Inventaris 14 Parameter Utama Operasional Pembangkit PLTU MSW Tanjung: Beban Gross, Export PLN/AI, House Load, TMGCR, BMCR, Efisiensi, EAF, CF",
        col_count=len(STANDARD_HEADERS)
    )

    rows = [
        [1, "Overview Header", "PlantOverviewSnapshot", "lib/models/plant_overview_models.dart", "fromFirebase()", "excel_data/overview", "RTDB Stream / Array", "-", "DATETIME", "String (ISO / yyyy-MM-dd HH:mm)", "Waktu pencatatan logsheet agregasi overview pembangkit", "Live RTDB Stream"],
        [2, "Gross Generation", "PlantOverviewSnapshot", "lib/models/plant_overview_models.dart", "totalLoad", "excel_data/overview", "RTDB Stream / Array", "-", "TOTAL LOAD / TOTAL GENERATION", "double [MW]", "Total daya kotor yang dibangkitkan oleh generator Unit 1 + Unit 2", "Live RTDB Stream"],
        [3, "Grid Export", "PlantOverviewSnapshot", "lib/models/plant_overview_models.dart", "loadToPln", "excel_data/overview", "RTDB Stream / Array", "-", "LOAD TO PLN / PLN LOAD", "double [MW]", "Daya listrik netto yang diekspor ke sistem transmisi interkoneksi PLN 150 kV", "Live RTDB Stream"],
        [4, "Dedicated Load", "PlantOverviewSnapshot", "lib/models/plant_overview_models.dart", "loadToAi", "excel_data/overview", "RTDB Stream / Array", "-", "LOAD TO AI / AI LOAD", "double [MW]", "Daya listrik yang disalurkan ke beban dedicated Adaro / fasilitas khusus", "Live RTDB Stream"],
        [5, "Auxiliary Load", "PlantOverviewSnapshot", "lib/models/plant_overview_models.dart", "totalHouseLoad", "excel_data/overview", "RTDB Stream / Array", "-", "TOTAL HOUSE LOAD", "double [MW]", "Daya pemakaian sendiri (House Load) untuk peralatan auxiliary pembangkit", "Live RTDB Stream"],
        [6, "House Load Ratio", "PlantOverviewSnapshot", "lib/models/plant_overview_models.dart", "houseLoadPct", "Client Calculation", "Derived Metric", "-", "houseLoadPct", "double [%]", "Persentase pemakaian sendiri = (Total House Load / Total Load) * 100", "Live Derived"],
        [7, "Unit 1 Capability", "PlantOverviewSnapshot", "lib/models/plant_overview_models.dart", "unit1.tmgcr", "excel_data/overview", "RTDB Stream / Array", "-", "UNIT 1 TMGCR", "double [MW]", "Turbine Maximum Continuous Rating Unit 1 (kapasitas kontinu maks turbin 30 MW)", "Live RTDB Stream"],
        [8, "Unit 1 Boiler Rating", "PlantOverviewSnapshot", "lib/models/plant_overview_models.dart", "unit1.bmcr", "excel_data/overview", "RTDB Stream / Array", "-", "UNIT 1 BMCR", "double [Ton/h atau MW]", "Boiler Maximum Continuous Rating Unit 1 (kapasitas penguapan kontinu maks boiler)", "Live RTDB Stream"],
        [9, "Unit 1 Efficiency", "PlantOverviewSnapshot", "lib/models/plant_overview_models.dart", "unit1.boilerEfficiency", "excel_data/overview", "RTDB Stream / Array", "-", "UNIT 1 BOILER EFFICIENCY", "double [%]", "Efisiensi termal pembakaran dan perpindahan panas boiler Unit 1", "Live RTDB Stream"],
        [10, "Unit 1 Availability", "PlantOverviewSnapshot", "lib/models/plant_overview_models.dart", "unit1.eaf", "excel_data/overview", "RTDB Stream / Array", "-", "UNIT 1 EAF", "double [%]", "Equivalent Availability Factor (EAF) ketersediaan unit pembangkit Unit 1", "Live RTDB Stream"],
        [11, "Unit 1 Capacity Factor", "PlantOverviewSnapshot", "lib/models/plant_overview_models.dart", "unit1.capacityFactor", "excel_data/overview", "RTDB Stream / Array", "-", "UNIT 1 CAPACITY FACTOR", "double [%]", "Capacity Factor (CF) rasio pembangkitan riil terhadap kapasitas terpasang Unit 1", "Live RTDB Stream"],
        [12, "Unit 2 Capability", "PlantOverviewSnapshot", "lib/models/plant_overview_models.dart", "unit2.tmgcr", "excel_data/overview", "RTDB Stream / Array", "-", "UNIT 2 TMGCR", "double [MW]", "Turbine Maximum Continuous Rating Unit 2 (kapasitas kontinu maks turbin 30 MW)", "Live RTDB Stream"],
        [13, "Unit 2 Boiler Rating", "PlantOverviewSnapshot", "lib/models/plant_overview_models.dart", "unit2.bmcr", "excel_data/overview", "RTDB Stream / Array", "-", "UNIT 2 BMCR", "double [Ton/h atau MW]", "Boiler Maximum Continuous Rating Unit 2 (kapasitas penguapan kontinu maks boiler)", "Live RTDB Stream"],
        [14, "Unit 2 Efficiency", "PlantOverviewSnapshot", "lib/models/plant_overview_models.dart", "unit2.boilerEfficiency", "excel_data/overview", "RTDB Stream / Array", "-", "UNIT 2 BOILER EFFICIENCY", "double [%]", "Efisiensi termal pembakaran dan perpindahan panas boiler Unit 2", "Live RTDB Stream"],
        [15, "Unit 2 Availability", "PlantOverviewSnapshot", "lib/models/plant_overview_models.dart", "unit2.eaf", "excel_data/overview", "RTDB Stream / Array", "-", "UNIT 2 EAF", "double [%]", "Equivalent Availability Factor (EAF) ketersediaan unit pembangkit Unit 2", "Live RTDB Stream"],
        [16, "Unit 2 Capacity Factor", "PlantOverviewSnapshot", "lib/models/plant_overview_models.dart", "unit2.capacityFactor", "excel_data/overview", "RTDB Stream / Array", "-", "UNIT 2 CAPACITY FACTOR", "double [%]", "Capacity Factor (CF) rasio pembangkitan riil terhadap kapasitas terpasang Unit 2", "Live RTDB Stream"]
    ]

    format_data_table(ws, STANDARD_HEADERS, rows, start_row=4)

# =============================================================================
# SHEET 3: Boiler & Turbine (excel_data/table1 & table2)
# =============================================================================
def build_boiler_turbine_sheet(wb):
    ws = wb.create_sheet(title="Boiler & Turbine (table1 & 2)")
    apply_sheet_title(
        ws,
        "BOILER & TURBINE OPERATIONAL TELEMETRY (/excel_data/table1 & table2)",
        "Parameter Fisik dan Termal Boiler-Turbin-Generator CFPP Unit 1 (table1) dan Unit 2 (table2): Main Steam, Feedwater, Fans, Coal Feeders & Generator",
        col_count=len(STANDARD_HEADERS)
    )

    rows = [
        # Unit 1
        [1, "Unit 1 Timing", "UnitDetailPage", "lib/pages/unit_detail_page.dart", "_table1Ref.onValue", "excel_data/table1", "RTDB Stream", "-", "DATETIME", "String (Datetime)", "Waktu logging operasional boiler dan turbin Unit 1", "Live RTDB Stream"],
        [2, "Unit 1 Gross Load", "UnitDetailPage", "lib/pages/unit_detail_page.dart", "_table1Ref.onValue", "excel_data/table1", "RTDB Stream", "-", "UNIT 1 LOAD / LOAD", "double [MW]", "Beban generator kotor Unit 1 (Nominal 30 MW)", "Live RTDB Stream"],
        [3, "Unit 1 Main Steam", "UnitDetailPage", "lib/pages/unit_detail_page.dart", "_table1Ref.onValue", "excel_data/table1", "RTDB Stream", "-", "MAIN_STEAM_TEMP", "double [°C]", "Temperatur uap utama keluar superheater menuju turbin Unit 1 (Nominal 535 - 540 °C)", "Live RTDB Stream"],
        [4, "Unit 1 Main Steam", "UnitDetailPage", "lib/pages/unit_detail_page.dart", "_table1Ref.onValue", "excel_data/table1", "RTDB Stream", "-", "MAIN_STEAM_PRESS", "double [MPa / Bar]", "Tekanan uap utama keluar superheater Unit 1 (Nominal 9.8 MPa / 98 Bar)", "Live RTDB Stream"],
        [5, "Unit 1 Main Steam", "UnitDetailPage", "lib/pages/unit_detail_page.dart", "_table1Ref.onValue", "excel_data/table1", "RTDB Stream", "-", "STEAM_FLOW", "double [Ton/h]", "Laju aliran uap utama yang masuk ke high-pressure turbin Unit 1", "Live RTDB Stream"],
        [6, "Unit 1 Feedwater", "UnitDetailPage", "lib/pages/unit_detail_page.dart", "_table1Ref.onValue", "excel_data/table1", "RTDB Stream", "-", "FEEDWATER_TEMP", "double [°C]", "Temperatur air pengisi setelah high-pressure heater sebelum economizer", "Live RTDB Stream"],
        [7, "Unit 1 Feedwater", "UnitDetailPage", "lib/pages/unit_detail_page.dart", "_table1Ref.onValue", "excel_data/table1", "RTDB Stream", "-", "FEEDWATER_PRESS", "double [MPa]", "Tekanan air pengisi dari boiler feedwater pump (BFP)", "Live RTDB Stream"],
        [8, "Unit 1 Drum", "UnitDetailPage", "lib/pages/unit_detail_page.dart", "_table1Ref.onValue", "excel_data/table1", "RTDB Stream", "-", "DRUM_PRESSURE", "double [MPa]", "Tekanan jenuh uap di dalam steam drum boiler Unit 1", "Live RTDB Stream"],
        [9, "Unit 1 Drum", "UnitDetailPage", "lib/pages/unit_detail_page.dart", "_table1Ref.onValue", "excel_data/table1", "RTDB Stream", "-", "DRUM_LEVEL", "double [mm]", "Ketinggian level air pada steam drum boiler (Normal Range -50 mm s/d +50 mm)", "Live RTDB Stream"],
        [10, "Unit 1 Combustion", "UnitDetailPage", "lib/pages/unit_detail_page.dart", "_table1Ref.onValue", "excel_data/table1", "RTDB Stream", "-", "FURNACE_PRESSURE", "double [Pa]", "Tekanan ruang bakar (draft furnace) yang dikontrol ID Fan (Normal -50 s/d -100 Pa)", "Live RTDB Stream"],
        [11, "Unit 1 Air Supply", "UnitDetailPage", "lib/pages/unit_detail_page.dart", "_table1Ref.onValue", "excel_data/table1", "RTDB Stream", "-", "PRIMARY_AIR_FLOW", "double [m³/h]", "Aliran udara primer dari PA Fan untuk fluidisasi dan transportasi batubara", "Live RTDB Stream"],
        [12, "Unit 1 Air Supply", "UnitDetailPage", "lib/pages/unit_detail_page.dart", "_table1Ref.onValue", "excel_data/table1", "RTDB Stream", "-", "SECONDARY_AIR_FLOW", "double [m³/h]", "Aliran udara sekunder dari SA Fan untuk penyempurnaan pembakaran di furnace", "Live RTDB Stream"],
        [13, "Unit 1 Fuel Feed", "UnitDetailPage", "lib/pages/unit_detail_page.dart", "_table1Ref.onValue", "excel_data/table1", "RTDB Stream", "-", "COAL_FEEDER_TOTAL", "double [Ton/h]", "Total laju pengumpanan batubara ke pulverizer/furnace Unit 1", "Live RTDB Stream"],
        [14, "Unit 1 Flue Gas", "UnitDetailPage", "lib/pages/unit_detail_page.dart", "_table1Ref.onValue", "excel_data/table1", "RTDB Stream", "-", "FLUE_GAS_TEMP_OUTLET", "double [°C]", "Temperatur gas buang keluar air preheater sebelum masuk ESP / stack", "Live RTDB Stream"],
        [15, "Unit 1 Turbine & Gen", "UnitDetailPage", "lib/pages/unit_detail_page.dart", "_table1Ref.onValue", "excel_data/table1", "RTDB Stream", "-", "TURBINE_SPEED", "double [RPM]", "Kecepatan putaran rotor turbin uap (Nominal 3000 RPM sinkron 50 Hz)", "Live RTDB Stream"],
        [16, "Unit 1 Condenser", "UnitDetailPage", "lib/pages/unit_detail_page.dart", "_table1Ref.onValue", "excel_data/table1", "RTDB Stream", "-", "CONDENSER_VACUUM", "double [kPa]", "Tingkat kevakuman pada ruang kondensor untuk efisiensi ekspansi uap", "Live RTDB Stream"],

        # Unit 2
        [17, "Unit 2 Timing", "UnitDetailPage", "lib/pages/unit_detail_page.dart", "_table2Ref.onValue", "excel_data/table2", "RTDB Stream", "-", "DATETIME", "String (Datetime)", "Waktu logging operasional boiler dan turbin Unit 2", "Live RTDB Stream"],
        [18, "Unit 2 Gross Load", "UnitDetailPage", "lib/pages/unit_detail_page.dart", "_table2Ref.onValue", "excel_data/table2", "RTDB Stream", "-", "UNIT 2 LOAD / LOAD", "double [MW]", "Beban generator kotor Unit 2 (Nominal 30 MW)", "Live RTDB Stream"],
        [19, "Unit 2 Main Steam", "UnitDetailPage", "lib/pages/unit_detail_page.dart", "_table2Ref.onValue", "excel_data/table2", "RTDB Stream", "-", "MAIN_STEAM_TEMP", "double [°C]", "Temperatur uap utama keluar superheater menuju turbin Unit 2 (Nominal 535 - 540 °C)", "Live RTDB Stream"],
        [20, "Unit 2 Main Steam", "UnitDetailPage", "lib/pages/unit_detail_page.dart", "_table2Ref.onValue", "excel_data/table2", "RTDB Stream", "-", "MAIN_STEAM_PRESS", "double [MPa / Bar]", "Tekanan uap utama keluar superheater Unit 2 (Nominal 9.8 MPa / 98 Bar)", "Live RTDB Stream"],
        [21, "Unit 2 Main Steam", "UnitDetailPage", "lib/pages/unit_detail_page.dart", "_table2Ref.onValue", "excel_data/table2", "RTDB Stream", "-", "STEAM_FLOW", "double [Ton/h]", "Laju aliran uap utama yang masuk ke high-pressure turbin Unit 2", "Live RTDB Stream"],
        [22, "Unit 2 Feedwater", "UnitDetailPage", "lib/pages/unit_detail_page.dart", "_table2Ref.onValue", "excel_data/table2", "RTDB Stream", "-", "FEEDWATER_TEMP", "double [°C]", "Temperatur air pengisi setelah high-pressure heater sebelum economizer", "Live RTDB Stream"],
        [23, "Unit 2 Feedwater", "UnitDetailPage", "lib/pages/unit_detail_page.dart", "_table2Ref.onValue", "excel_data/table2", "RTDB Stream", "-", "FEEDWATER_PRESS", "double [MPa]", "Tekanan air pengisi dari boiler feedwater pump (BFP)", "Live RTDB Stream"],
        [24, "Unit 2 Drum", "UnitDetailPage", "lib/pages/unit_detail_page.dart", "_table2Ref.onValue", "excel_data/table2", "RTDB Stream", "-", "DRUM_PRESSURE", "double [MPa]", "Tekanan jenuh uap di dalam steam drum boiler Unit 2", "Live RTDB Stream"],
        [25, "Unit 2 Drum", "UnitDetailPage", "lib/pages/unit_detail_page.dart", "_table2Ref.onValue", "excel_data/table2", "RTDB Stream", "-", "DRUM_LEVEL", "double [mm]", "Ketinggian level air pada steam drum boiler (Normal Range -50 mm s/d +50 mm)", "Live RTDB Stream"],
        [26, "Unit 2 Combustion", "UnitDetailPage", "lib/pages/unit_detail_page.dart", "_table2Ref.onValue", "excel_data/table2", "RTDB Stream", "-", "FURNACE_PRESSURE", "double [Pa]", "Tekanan ruang bakar (draft furnace) yang dikontrol ID Fan (Normal -50 s/d -100 Pa)", "Live RTDB Stream"],
        [27, "Unit 2 Air Supply", "UnitDetailPage", "lib/pages/unit_detail_page.dart", "_table2Ref.onValue", "excel_data/table2", "RTDB Stream", "-", "PRIMARY_AIR_FLOW", "double [m³/h]", "Aliran udara primer dari PA Fan untuk fluidisasi dan transportasi batubara", "Live RTDB Stream"],
        [28, "Unit 2 Air Supply", "UnitDetailPage", "lib/pages/unit_detail_page.dart", "_table2Ref.onValue", "excel_data/table2", "RTDB Stream", "-", "SECONDARY_AIR_FLOW", "double [m³/h]", "Aliran udara sekunder dari SA Fan untuk penyempurnaan pembakaran di furnace", "Live RTDB Stream"],
        [29, "Unit 2 Fuel Feed", "UnitDetailPage", "lib/pages/unit_detail_page.dart", "_table2Ref.onValue", "excel_data/table2", "RTDB Stream", "-", "COAL_FEEDER_TOTAL", "double [Ton/h]", "Total laju pengumpanan batubara ke pulverizer/furnace Unit 2", "Live RTDB Stream"],
        [30, "Unit 2 Flue Gas", "UnitDetailPage", "lib/pages/unit_detail_page.dart", "_table2Ref.onValue", "excel_data/table2", "RTDB Stream", "-", "FLUE_GAS_TEMP_OUTLET", "double [°C]", "Temperatur gas buang keluar air preheater sebelum masuk ESP / stack", "Live RTDB Stream"],
        [31, "Unit 2 Turbine & Gen", "UnitDetailPage", "lib/pages/unit_detail_page.dart", "_table2Ref.onValue", "excel_data/table2", "RTDB Stream", "-", "TURBINE_SPEED", "double [RPM]", "Kecepatan putaran rotor turbin uap (Nominal 3000 RPM sinkron 50 Hz)", "Live RTDB Stream"],
        [32, "Unit 2 Condenser", "UnitDetailPage", "lib/pages/unit_detail_page.dart", "_table2Ref.onValue", "excel_data/table2", "RTDB Stream", "-", "CONDENSER_VACUUM", "double [kPa]", "Tingkat kevakuman pada ruang kondensor untuk efisiensi ekspansi uap", "Live RTDB Stream"]
    ]

    format_data_table(ws, STANDARD_HEADERS, rows, start_row=4)

# =============================================================================
# SHEET 4: CEMS Emisi (excel_data/cems1 & cems2)
# =============================================================================
def build_cems_sheet(wb):
    ws = wb.create_sheet(title="CEMS Emisi (cems1 & cems2)")
    apply_sheet_title(
        ws,
        "CONTINUOUS EMISSION MONITORING SYSTEM (CEMS) - STACK CEROBONG UNIT 1 & 2",
        "Inventaris Parameter Emisi Gas Buang Cerobong, Baku Mutu PermenLHK P.15/2019, Koreksi 7% O2, dan Alarm Exceed Notifikasi",
        col_count=len(STANDARD_HEADERS)
    )

    rows = [
        # Unit 1 CEMS
        [1, "CEMS Unit 1", "CemsDetailPage", "lib/pages/cems_detail_page.dart", "_cemsRef.onValue", "excel_data/cems1", "RTDB Stream", "-", "DATETIME", "String (ISO / Timestamp)", "Waktu logging pembacaan instrumen CEMS cerobong Unit 1", "Live RTDB Stream"],
        [2, "CEMS Unit 1", "CemsDetailPage & Threshold", "lib/pages/cems_detail_page.dart", "_cemsRef.onValue", "excel_data/cems1", "RTDB Stream", "-", "SO2 / SO2_COR", "double [mg/Nm³]", "Konsentrasi Sulfur Dioksida (Baku Mutu PermenLHK P.15/2019: Maks 550 mg/Nm³)", "Live RTDB Stream"],
        [3, "CEMS Unit 1", "CemsDetailPage & Threshold", "lib/pages/cems_detail_page.dart", "_cemsRef.onValue", "excel_data/cems1", "RTDB Stream", "-", "NOX / NOX_COR", "double [mg/Nm³]", "Konsentrasi Nitrogen Oksida (Baku Mutu PermenLHK P.15/2019: Maks 550 mg/Nm³)", "Live RTDB Stream"],
        [4, "CEMS Unit 1", "CemsDetailPage & Threshold", "lib/pages/cems_detail_page.dart", "_cemsRef.onValue", "excel_data/cems1", "RTDB Stream", "-", "PARTICULATE / DUST", "double [mg/Nm³]", "Konsentrasi Debu Partikulat (Baku Mutu PermenLHK P.15/2019: Maks 50 mg/Nm³)", "Live RTDB Stream"],
        [5, "CEMS Unit 1", "CemsDetailPage & Threshold", "lib/pages/cems_detail_page.dart", "_cemsRef.onValue", "excel_data/cems1", "RTDB Stream", "-", "HG / HG_COR", "double [mg/Nm³]", "Konsentrasi Merkuri Hg (Baku Mutu PermenLHK P.15/2019: Maks 0.03 mg/Nm³)", "Live RTDB Stream"],
        [6, "CEMS Unit 1", "CemsDetailPage", "lib/pages/cems_detail_page.dart", "_cemsRef.onValue", "excel_data/cems1", "RTDB Stream", "-", "CO / CO_CONC", "double [mg/Nm³]", "Konsentrasi Karbon Monoksida hasil pembakaran tidak sempurna", "Live RTDB Stream"],
        [7, "CEMS Unit 1", "CemsDetailPage", "lib/pages/cems_detail_page.dart", "_cemsRef.onValue", "excel_data/cems1", "RTDB Stream", "-", "CO2", "double [%]", "Kadar Karbon Dioksida pada gas buang cerobong Unit 1", "Live RTDB Stream"],
        [8, "CEMS Unit 1", "CemsDetailPage", "lib/pages/cems_detail_page.dart", "_cemsRef.onValue", "excel_data/cems1", "RTDB Stream", "-", "O2", "double [%]", "Kadar Oksigen gas buang untuk formula normalisasi koreksi 7% O2 standar KLHK", "Live RTDB Stream"],
        [9, "CEMS Unit 1", "CemsDetailPage", "lib/pages/cems_detail_page.dart", "_cemsRef.onValue", "excel_data/cems1", "RTDB Stream", "-", "FLOW / FLUE_GAS_FLOW", "double [m³/s]", "Laju alir gas buang cerobong untuk menghitung beban emisi total (ton/tahun)", "Live RTDB Stream"],
        [10, "CEMS Unit 1", "CemsDetailPage", "lib/pages/cems_detail_page.dart", "_cemsRef.onValue", "excel_data/cems1", "RTDB Stream", "-", "FLUE_GAS_TEMP", "double [°C]", "Temperatur gas buang pada titik pengukuran analyzer cerobong Unit 1", "Live RTDB Stream"],
        [11, "CEMS Unit 1", "CemsDetailPage", "lib/pages/cems_detail_page.dart", "_cemsRef.onValue", "excel_data/cems1", "RTDB Stream", "-", "OPACITY", "double [%]", "Tingkat kepekatan / opasitas asap cerobong (Batas alarm > 20%)", "Live RTDB Stream"],

        # Unit 2 CEMS
        [12, "CEMS Unit 2", "CemsDetailPage", "lib/pages/cems_detail_page.dart", "_cemsRef.onValue", "excel_data/cems2", "RTDB Stream", "-", "DATETIME", "String (ISO / Timestamp)", "Waktu logging pembacaan instrumen CEMS cerobong Unit 2", "Live RTDB Stream"],
        [13, "CEMS Unit 2", "CemsDetailPage & Threshold", "lib/pages/cems_detail_page.dart", "_cemsRef.onValue", "excel_data/cems2", "RTDB Stream", "-", "SO2 / SO2_COR", "double [mg/Nm³]", "Konsentrasi Sulfur Dioksida (Baku Mutu PermenLHK P.15/2019: Maks 550 mg/Nm³)", "Live RTDB Stream"],
        [14, "CEMS Unit 2", "CemsDetailPage & Threshold", "lib/pages/cems_detail_page.dart", "_cemsRef.onValue", "excel_data/cems2", "RTDB Stream", "-", "NOX / NOX_COR", "double [mg/Nm³]", "Konsentrasi Nitrogen Oksida (Baku Mutu PermenLHK P.15/2019: Maks 550 mg/Nm³)", "Live RTDB Stream"],
        [15, "CEMS Unit 2", "CemsDetailPage & Threshold", "lib/pages/cems_detail_page.dart", "_cemsRef.onValue", "excel_data/cems2", "RTDB Stream", "-", "PARTICULATE / DUST", "double [mg/Nm³]", "Konsentrasi Debu Partikulat (Baku Mutu PermenLHK P.15/2019: Maks 50 mg/Nm³)", "Live RTDB Stream"],
        [16, "CEMS Unit 2", "CemsDetailPage & Threshold", "lib/pages/cems_detail_page.dart", "_cemsRef.onValue", "excel_data/cems2", "RTDB Stream", "-", "HG / HG_COR", "double [mg/Nm³]", "Konsentrasi Merkuri Hg (Baku Mutu PermenLHK P.15/2019: Maks 0.03 mg/Nm³)", "Live RTDB Stream"],
        [17, "CEMS Unit 2", "CemsDetailPage", "lib/pages/cems_detail_page.dart", "_cemsRef.onValue", "excel_data/cems2", "RTDB Stream", "-", "CO / CO_CONC", "double [mg/Nm³]", "Konsentrasi Karbon Monoksida hasil pembakaran tidak sempurna", "Live RTDB Stream"],
        [18, "CEMS Unit 2", "CemsDetailPage", "lib/pages/cems_detail_page.dart", "_cemsRef.onValue", "excel_data/cems2", "RTDB Stream", "-", "CO2", "double [%]", "Kadar Karbon Dioksida pada gas buang cerobong Unit 2", "Live RTDB Stream"],
        [19, "CEMS Unit 2", "CemsDetailPage", "lib/pages/cems_detail_page.dart", "_cemsRef.onValue", "excel_data/cems2", "RTDB Stream", "-", "O2", "double [%]", "Kadar Oksigen gas buang untuk formula normalisasi koreksi 7% O2 standar KLHK", "Live RTDB Stream"],
        [20, "CEMS Unit 2", "CemsDetailPage", "lib/pages/cems_detail_page.dart", "_cemsRef.onValue", "excel_data/cems2", "RTDB Stream", "-", "FLOW / FLUE_GAS_FLOW", "double [m³/s]", "Laju alir gas buang cerobong untuk menghitung beban emisi total (ton/tahun)", "Live RTDB Stream"],
        [21, "CEMS Unit 2", "CemsDetailPage", "lib/pages/cems_detail_page.dart", "_cemsRef.onValue", "excel_data/cems2", "RTDB Stream", "-", "FLUE_GAS_TEMP", "double [°C]", "Temperatur gas buang pada titik pengukuran analyzer cerobong Unit 2", "Live RTDB Stream"],
        [22, "CEMS Unit 2", "CemsDetailPage", "lib/pages/cems_detail_page.dart", "_cemsRef.onValue", "excel_data/cems2", "RTDB Stream", "-", "OPACITY", "double [%]", "Tingkat kepekatan / opasitas asap cerobong (Batas alarm > 20%)", "Live RTDB Stream"]
    ]

    format_data_table(ws, STANDARD_HEADERS, rows, start_row=4)

# =============================================================================
# SHEET 5: NPHR & Thermal Heat Rate (excel_data/nphr)
# =============================================================================
def build_nphr_sheet(wb):
    ws = wb.create_sheet(title="NPHR & Thermal Heat Rate")
    apply_sheet_title(
        ws,
        "NET PLANT HEAT RATE (NPHR) & POLYNOMIAL EFFICIENCY CURVES",
        "Inventaris Nilai NPHR Unit 1 & Unit 2 (/excel_data/nphr), Persamaan Polinomial Derajat 6 (5-30 MW), Pembanding Target & Aktual",
        col_count=len(STANDARD_HEADERS)
    )

    rows = [
        [1, "NPHR Unit 1", "NphrPage & HomePage", "lib/pages/nphr_page.dart\nlib/pages/home_page.dart", "_nphrRef.onValue", "excel_data/nphr", "RTDB Stream", "-", "nphr1 / NPHR UNIT 1", "double [kCal/kWh]", "Net Plant Heat Rate Unit 1 seketika (Konsumsi panas batubara per kWh neto)", "Live RTDB Stream"],
        [2, "NPHR Unit 2", "NphrPage & HomePage", "lib/pages/nphr_page.dart\nlib/pages/home_page.dart", "_nphrRef.onValue", "excel_data/nphr", "RTDB Stream", "-", "nphr2 / NPHR UNIT 2", "double [kCal/kWh]", "Net Plant Heat Rate Unit 2 seketika (Konsumsi panas batubara per kWh neto)", "Live RTDB Stream"],
        [3, "Unit 1 Load Pairing", "NphrPage", "lib/pages/nphr_page.dart", "_boiler1Ref.onValue", "excel_data/table1", "RTDB Stream", "-", "load1 / LOAD", "double [MW]", "Beban generator Unit 1 saat pencatatan nilai heat rate (Sumbu X kurva NPHR)", "Live RTDB Stream"],
        [4, "Unit 2 Load Pairing", "NphrPage", "lib/pages/nphr_page.dart", "_boiler2Ref.onValue", "excel_data/table2", "RTDB Stream", "-", "load2 / LOAD", "double [MW]", "Beban generator Unit 2 saat pencatatan nilai heat rate (Sumbu X kurva NPHR)", "Live RTDB Stream"],
        [5, "Kurva Aktual Polinomial", "NphrPage", "lib/pages/nphr_page.dart", "calculatePolynomial(x)", "Formula Matematika Orde 6", "Client Computation", "x = Beban Gross MW (5 s/d 30 MW)", "calculatePolynomial(x)", "double [kCal/kWh]", "0.002091081*x^6 - 0.25509163*x^5 + 12.71453427*x^4 - 331.7789929*x^3 + 4795.876444*x^2 - 36715.63544*x + 122674.5032", "Polynomial Model"],
        [6, "Kurva Target Polinomial", "NphrPage", "lib/pages/nphr_page.dart", "calculateTarget(x)", "Formula Matematika Orde 6", "Client Computation", "x = Beban Gross MW (5 s/d 30 MW)", "calculateTarget(x)", "double [kCal/kWh]", "0.00196559505*x^6 - 0.239778826*x^5 + 11.9511090*x^4 - 311.854308*x^3 + 4507.83793*x^2 - 34510.5291*x + 115307.904", "Target Model"],
        [7, "Heat Rate Deviation", "NphrPage", "lib/pages/nphr_page.dart", "realtimePoints vs curve", "Comparison Logic", "Client Computation", "-", "heatRateDeviation", "double [kCal/kWh]", "Deviasi heat rate aktual terhadap kurva target pada pembebanan yang sama", "Derived Metric"],
        [8, "Thermal Efficiency Eq", "NphrPage", "lib/pages/nphr_page.dart", "Derived Efficiency", "Formula Termodinamika", "Client Computation", "860 / NPHR", "thermalEfficiency", "double [%]", "Efisiensi termal siklus pembangkit = (860 kCal/kWh / NPHR) * 100", "Derived Metric"]
    ]

    format_data_table(ws, STANDARD_HEADERS, rows, start_row=4)

# =============================================================================
# SHEET 6: Huawei FusionSolar OpenAPI
# =============================================================================
def build_fusionsolar_openapi_sheet(wb):
    ws = wb.create_sheet(title="Huawei FusionSolar OpenAPI")
    apply_sheet_title(
        ws,
        "HUAWEI FUSIONSOLAR OPENAPI - ENDPOINTS, PROTOCOL & INVERTER STATE (v4.7)",
        "Spesifikasi Lengkap REST API Northbound Huawei: Aturan 407 Rate Limit 2x Stop, 30-Min Cron, Telemetri Elektrik (ESG Dihapus) & Tabel 3-1",
        col_count=len(STANDARD_HEADERS)
    )

    rows = [
        # Endpoints
        [1, "Autentikasi Sesi", "FusionSolarApiClient", "lib/services/fusion_solar_api_client.dart", "login()", "/thirdData/login", "POST", '{"userName": "...", "systemCode": "..."}', "xsrf-token", "HTTP Header (Token)", "Autentikasi akun northbound dan perolehan token sesi xsrf-token (cached 25 min)", "Live API"],
        [2, "Autentikasi Sesi", "FusionSolarApiClient", "lib/services/fusion_solar_api_client.dart", "logout()", "/thirdData/logout", "POST", 'Header: xsrf-token', "success", "Boolean / Status", "Menutup sesi token secara aman saat service di-dispose", "Live API"],
        [3, "Struktur Stasiun", "FusionSolarApiClient", "lib/services/fusion_solar_api_client.dart", "getStationList()", "/thirdData/getStationList", "POST", '{"pageNo": 1, "pageSize": 100}', "stationCode, capacity", "String & double [kWp]", "Daftar stasiun aktif: PLTS MSW 400 kWp & PLTS Floating Kelanis 468 kWp", "Live API"],
        [4, "Daftar Inverter", "FusionSolarApiClient", "lib/services/fusion_solar_api_client.dart", "getInverters()", "/thirdData/getDevList", "POST", '{"stationCodes": "NE=..."}', "id, devName, esnCode, invType", "String / Int", "Mengambil 12 inverter aktif (devTypeId = 1). Dilengkapi safeguard 407 2x auto-abort", "Live API"],
        [5, "Telemetri Elektrik", "FusionSolarApiClient", "lib/services/fusion_solar_api_client.dart", "getRealtimeKpis()", "/thirdData/getDevRealKpi", "POST", '{"devIds": "...", "devTypeId": 1}', "active_power", "double [kW]", "Daya aktif output AC seketika per inverter (Batch 12 inverter sekaligus)", "Live API"],
        [6, "Telemetri Elektrik", "FusionSolarApiClient", "lib/services/fusion_solar_api_client.dart", "getRealtimeKpis()", "/thirdData/getDevRealKpi", "POST", '{"devIds": "...", "devTypeId": 1}', "temperature", "double [°C]", "Temperatur modul elektronik/IGBT internal inverter", "Live API"],
        [7, "Telemetri Elektrik", "FusionSolarApiClient", "lib/services/fusion_solar_api_client.dart", "getRealtimeKpis()", "/thirdData/getDevRealKpi", "POST", '{"devIds": "...", "devTypeId": 1}', "elec_freq", "double [Hz]", "Frekuensi jaringan AC inverter (Nominal 50.0 Hz)", "Live API"],
        [8, "Telemetri Elektrik", "FusionSolarApiClient", "lib/services/fusion_solar_api_client.dart", "getRealtimeKpis()", "/thirdData/getDevRealKpi", "POST", '{"devIds": "...", "devTypeId": 1}', "ab_u, bc_u, ca_u", "double [V]", "Tegangan fasa-fasa AC 3-Phase (Line-to-Line Voltage)", "Live API"],
        [9, "Telemetri Elektrik", "FusionSolarApiClient", "lib/services/fusion_solar_api_client.dart", "getRealtimeKpis()", "/thirdData/getDevRealKpi", "POST", '{"devIds": "...", "devTypeId": 1}', "a_i, b_i, c_i", "double [A]", "Arus keluaran AC 3-Phase per fasa (Phase Current)", "Live API"],
        [10, "Telemetri Elektrik", "FusionSolarApiClient", "lib/services/fusion_solar_api_client.dart", "getRealtimeKpis()", "/thirdData/getDevRealKpi", "POST", '{"devIds": "...", "devTypeId": 1}', "power_factor", "double [-1.0 .. 1.0]", "Faktor daya (cos φ) inverter terhadap grid", "Live API"],
        [11, "Telemetri Elektrik", "FusionSolarApiClient", "lib/services/fusion_solar_api_client.dart", "getRealtimeKpis()", "/thirdData/getDevRealKpi", "POST", '{"devIds": "...", "devTypeId": 1}', "efficiency", "double [%]", "Efisiensi konversi daya DC ke AC inverter (Standar Huawei > 98%)", "Live API"],
        [12, "Telemetri Elektrik", "FusionSolarApiClient", "lib/services/fusion_solar_api_client.dart", "getRealtimeKpis()", "/thirdData/getDevRealKpi", "POST", '{"devIds": "...", "devTypeId": 1}', "mppt_power", "double [kW]", "Total daya input DC dari array PV string ke MPPT inverter", "Live API"],
        [13, "Telemetri Elektrik", "FusionSolarApiClient", "lib/services/fusion_solar_api_client.dart", "getRealtimeKpis()", "/thirdData/getDevRealKpi", "POST", '{"devIds": "...", "devTypeId": 1}', "inverter_state / run_state", "int (Tabel 3-1)", "Kode status operasi inverter (0=Standby, 512=Grid-tied, 40960=No Irradiation)", "Live API"],
        [14, "Telemetri Elektrik", "FusionSolarApiClient", "lib/services/fusion_solar_api_client.dart", "getRealtimeKpis()", "/thirdData/getDevRealKpi", "POST", '{"devIds": "...", "devTypeId": 1}', "total_cap", "double [kWh]", "Total energi bangkitan seumur hidup (Lifetime Energy Generation)", "Live API"],
        [15, "Produksi Harian", "FusionSolarApiClient", "lib/services/fusion_solar_api_client.dart", "getDayKpi()", "/thirdData/getDevKpiDay", "POST", '{"devIds": "...", "devTypeId": 1, "collectTime": 00:00}', "product_power", "double [kWh]", "Akumulasi produksi energi harian resmi per unit inverter", "Live API"],
        [16, "Produksi Harian", "FusionSolarApiClient", "lib/services/fusion_solar_api_client.dart", "getDayKpi()", "/thirdData/getDevKpiDay", "POST", '{"devIds": "...", "devTypeId": 1, "collectTime": 00:00}', "perpower_ratio", "double [kWh/kWp]", "Specific Energy yield per kWp terpasang untuk perbandingan kinerja", "Live API"],
        [17, "Metrik Stasiun", "FusionSolarApiClient", "lib/services/fusion_solar_api_client.dart", "getStationDayKpis()", "/thirdData/getKpiStationDay", "POST", '{"stationCodes": "...", "collectTime": 00:00}', "radiation_intensity", "double [kWh/m²]", "Radiasi penyinaran matahari harian stasiun (MSW & Kelanis)", "Live API"],
        [18, "Metrik Stasiun", "FusionSolarApiClient", "lib/services/fusion_solar_api_client.dart", "getStationDayKpis()", "/thirdData/getKpiStationDay", "POST", '{"stationCodes": "...", "collectTime": 00:00}', "performance_ratio", "double [%]", "Performance Ratio stasiun (MSW & Kelanis PR terpisah di v4.7)", "Live API"],
        [19, "Kurva Profil Jam", "FusionSolarApiClient", "lib/services/fusion_solar_api_client.dart", "getStationHourKpis()", "/thirdData/getKpiStationHour", "POST", '{"stationCodes": "...", "collectTime": 00:00}', "radiation_intensity, power", "double [kWh/m² & kW]", "Profil radiasi dan daya per jam (04:00 - 20:00 WITA)", "Live API"],
        [20, "Daftar Alarm", "FusionSolarApiClient", "lib/services/fusion_solar_api_client.dart", "getAlarmList()", "/thirdData/getAlarmList", "POST", '{"stationCodes": "...", "beginTime": ..., "status": 1}', "alarmId, alarmName, lev, repairSuggestion", "String / Int", "Daftar gangguan aktif perangkat (Severity: 1=Critical, 2=Major, 3=Minor, 4=Warning)", "Live API"],

        # Safeguard & Policy Rows
        [21, "Rate Limit Safeguard", "FusionSolarApiClient", "lib/services/fusion_solar_api_client.dart", "_devListConsecutive407 >= 2", "Rate Limit Policy", "407 Handling", "HTTP Status 407", "407 Abort Stop", "Circuit Breaker", "Jika /getDevList terkena HTTP 407 dua kali beruntun, hentikan sync dan batalkan downstream loop", "Live Safeguard"],
        [22, "Empty Inverter Stop", "FusionSolarApiClient", "lib/services/fusion_solar_api_client.dart", "inverters.isEmpty", "Data Integrity Policy", "Pre-condition Check", "devIds == null", "Empty Dev Abort", "Early Exit", "Jika getInverters() menghasilkan list kosong (karena 407 atau network), langsung hentikan pipeline", "Live Safeguard"],
        [23, "Pacing Throttle", "FusionSolarApiClient", "lib/services/fusion_solar_api_client.dart", "throttleDelay = 2s", "Request Pacing", "Delay Injection", "Duration(seconds: 2)", "2s Sleep Between Calls", "Pacing Rule", "Wajib jeda minimal 2 detik antar pemanggilan endpoint Huawei untuk mencegah pemicu WAF rate limit", "Live Safeguard"],
        [24, "30-Min Cron & Window", "FusionSolarService", "lib/services/fusion_solar_service.dart", "fetchLiveKpis()", "Cron Scheduler", "Periodic Execution", "04:00 - 20:00 WITA", "Interval 30 Menit", "Execution Window", "Hanya berjalan 16 jam per hari (~256 call/hari = hanya 25% kuota 1.000 call/hari Huawei)", "Live Safeguard"],
        [25, "ESG Removal Notice", "FusionSolarService & Models", "lib/models/solar_models.dart", "ESG Metrics Purged", "v4.7 Refactor", "Code Architecture", "-", "ESG Metrics Removed", "Deprecation", "Semua pengambilan data ESG (CO2, batubara, pohon) dan komponen UI-nya telah dihapus penuh dari Solar PV", "Refactored v4.7"]
    ]

    format_data_table(ws, STANDARD_HEADERS, rows, start_row=4)

# =============================================================================
# SHEET 7: Solar PV Inverter Mapping (12 Inverters)
# =============================================================================
def build_solar_inverter_mapping_sheet(wb):
    ws = wb.create_sheet(title="Solar PV Inverter Mapping")
    apply_sheet_title(
        ws,
        "SOLAR PV FLEET - 12 INVERTER HARDWARE & NETWORK MAPPING",
        "Inventaris Lengkap 12 Unit Inverter Huawei SUN2000 pada 4 Kluster (PLTU MSW Rooftop, Ground, Fasilitas & PLTS Floating Kelanis 468 kWp)",
        col_count=11
    )

    headers = [
        "No",
        "Cluster / Plant Location",
        "Inverter Display Name",
        "Huawei Dev Name / ID",
        "Hardware Model",
        "Serial Number (ESN)",
        "Rated AC Power",
        "Firmware Version",
        "Grid Connection Point",
        "Telemetry Channel",
        "Integration Status"
    ]

    rows = [
        # Cluster 1: PLTU MSW Rooftop 4x 165kWp
        [1, "PLTU MSW Rooftop", "Inverter 165kWp-1", "Inverter(COM1-1) / 210107...", "SUN2000-40KTL-M3", "210107415410N1000001", "40 kW", "V500R023C00SPC156", "Main Building LV Switchboard A", "Batch /getDevRealKpi", "Live Inverter"],
        [2, "PLTU MSW Rooftop", "Inverter 165kWp-2", "Inverter(COM1-2) / 210107...", "SUN2000-40KTL-M3", "210107415410N1000002", "40 kW", "V500R023C00SPC156", "Main Building LV Switchboard A", "Batch /getDevRealKpi", "Live Inverter"],
        [3, "PLTU MSW Rooftop", "Inverter 165kWp-3", "Inverter(COM1-3) / 210107...", "SUN2000-40KTL-M3", "210107415410N1000003", "40 kW", "V500R023C00SPC156", "Main Building LV Switchboard B", "Batch /getDevRealKpi", "Live Inverter"],
        [4, "PLTU MSW Rooftop", "Inverter 165kWp-4", "Inverter(COM1-4) / 210107...", "SUN2000-40KTL-M3", "210107415410N1000004", "45 kW", "V500R023C00SPC156", "Main Building LV Switchboard B", "Batch /getDevRealKpi", "Live Inverter"],

        # Cluster 2: PLTU MSW Ground Mounted 2x 200kWp
        [5, "PLTU MSW Ground", "Inverter 200kWp-1", "INV_PLTS_200_KWP_1 / 210107...", "SUN2000-100KTL-M1", "210107415410N2000001", "100 kW", "V500R023C00SPC156", "Substation Outdoor Feeder 1", "Batch /getDevRealKpi", "Live Inverter"],
        [6, "PLTU MSW Ground", "Inverter 200kWp-2", "INV_PLTS_200_KWP_2 / 210107...", "SUN2000-100KTL-M1", "210107415410N2000002", "100 kW", "V500R023C00SPC156", "Substation Outdoor Feeder 2", "Batch /getDevRealKpi", "Live Inverter"],

        # Cluster 3: PLTU MSW Fasilitas Pendukung 2x 15/20kWp
        [7, "PLTU MSW Fasilitas", "Inverter 15kWp", "INV_FASILITAS_15KW / 210107...", "SUN2000-15KTL-M2", "210107415410N3000001", "15 kW", "V500R023C00SPC156", "Workshop Distribution Board", "Batch /getDevRealKpi", "Live Inverter"],
        [8, "PLTU MSW Fasilitas", "Inverter 20kWp", "INV_FASILITAS_20KW / 210107...", "SUN2000-20KTL-M2", "210107415410N3000002", "20 kW", "V500R023C00SPC156", "Warehouse Distribution Board", "Batch /getDevRealKpi", "Live Inverter"],

        # Cluster 4: PLTS Floating Adaro Kelanis 4x 468kWp
        [9, "Floating Kelanis", "Inverter 468kWp-01", "INV_KELANIS_FLOAT_01 / 210107...", "SUN2000-100KTL-M1", "210107415410N4000001", "117 kW", "V500R023C00SPC156", "Floating Substation Step-Up 1", "Batch /getDevRealKpi", "Live Inverter"],
        [10, "Floating Kelanis", "Inverter 468kWp-02", "INV_KELANIS_FLOAT_02 / 210107...", "SUN2000-100KTL-M1", "210107415410N4000002", "117 kW", "V500R023C00SPC156", "Floating Substation Step-Up 1", "Batch /getDevRealKpi", "Live Inverter"],
        [11, "Floating Kelanis", "Inverter 468kWp-03", "INV_KELANIS_FLOAT_03 / 210107...", "SUN2000-100KTL-M1", "210107415410N4000003", "117 kW", "V500R023C00SPC156", "Floating Substation Step-Up 2", "Batch /getDevRealKpi", "Live Inverter"],
        [12, "Floating Kelanis", "Inverter 468kWp-04", "INV_KELANIS_FLOAT_04 / 210107...", "SUN2000-100KTL-M1", "210107415410N4000004", "117 kW", "V500R023C00SPC156", "Floating Substation Step-Up 2", "Batch /getDevRealKpi", "Live Inverter"]
    ]

    format_data_table(ws, headers, rows, start_row=4)

# =============================================================================
# SHEET 8: Simulasi Payload FusionSolar (JSON Schemas)
# =============================================================================
def build_fusionsolar_payloads_sheet(wb):
    ws = wb.create_sheet(title="Simulasi Payload FusionSolar")
    apply_sheet_title(
        ws,
        "HUAWEI FUSIONSOLAR OPENAPI - JSON REQUEST & RESPONSE PAYLOAD SIMULATION",
        "Struktur Data Baku Pertukaran JSON Northbound ThirdData: Login, getDevList, getDevRealKpi, getDevKpiDay, getAlarmList",
        col_count=8
    )

    headers = [
        "No",
        "Endpoint Name",
        "HTTP Method",
        "Target URL Path",
        "Sample Request Payload (JSON)",
        "Sample Success Response (JSON)",
        "Rate Limit & Throttling Rules",
        "Status di App"
    ]

    rows = [
        [
            1,
            "Login API",
            "POST",
            "/thirdData/login",
            '{\n  "userName": "msw_fusionsolar_api",\n  "systemCode": "MSW_Plant_2026!"\n}',
            '{\n  "data": "xsrf-token-abc123xyz789",\n  "failCode": 0,\n  "message": "success",\n  "success": true\n}',
            "Dipanggil setiap 25 menit atau saat token kedaluwarsa. Token disimpan di in-memory cache.",
            "Live Production"
        ],
        [
            2,
            "Station List API",
            "POST",
            "/thirdData/getStationList",
            '{\n  "pageNo": 1,\n  "pageSize": 100\n}',
            '{\n  "data": {\n    "list": [\n      {"stationCode": "NE=54218158", "stationName": "PLTS MSW 400 kWp", "capacity": 400.0},\n      {"stationCode": "NE=56226734", "stationName": "PLTS Floating Kelanis 468 kWp", "capacity": 468.0}\n    ]\n  },\n  "failCode": 0,\n  "success": true\n}',
            "Dipanggil sekuensial setelah login. Output stasiun di-cache selama siklus sync.",
            "Live Production"
        ],
        [
            3,
            "Device List API",
            "POST",
            "/thirdData/getDevList",
            '{\n  "stationCodes": "NE=54218158,NE=56226734"\n}',
            '{\n  "data": [\n    {"id": 21010701, "devName": "Inverter 165kWp-1", "devTypeId": 1, "esnCode": "210107415410N1000001", "invType": "SUN2000-40KTL-M3"},\n    {"id": 21010702, "devName": "Inverter 165kWp-2", "devTypeId": 1, "esnCode": "210107415410N1000002", "invType": "SUN2000-40KTL-M3"}\n  ],\n  "failCode": 0,\n  "success": true\n}',
            "SAFEGUARD v4.7: Jika respon 407 dua kali beruntun (counter >= 2) ATAU list inverter kosong, abort downstream loop seketika.",
            "Live Production"
        ],
        [
            4,
            "Realtime Inverter KPI",
            "POST",
            "/thirdData/getDevRealKpi",
            '{\n  "devIds": "21010701,21010702,21010703,21010704,21010705,21010706,21010707,21010708,21010709,21010710,21010711,21010712",\n  "devTypeId": 1\n}',
            '{\n  "data": [\n    {\n      "devId": 21010701,\n      "dataItemMap": {\n        "active_power": 38.45,\n        "day_cap": 142.6,\n        "temperature": 52.8,\n        "elec_freq": 50.02,\n        "ab_u": 398.2,\n        "a_i": 55.8,\n        "inverter_state": 512\n      }\n    }\n  ],\n  "failCode": 0,\n  "success": true\n}',
            "BATCHING: Seluruh 12 unit inverter dipanggil dalam 1 request tunggal guna menghemat jatah kuota harian Huawei.",
            "Live Production"
        ],
        [
            5,
            "Daily Inverter KPI",
            "POST",
            "/thirdData/getDevKpiDay",
            '{\n  "devIds": "21010701,21010702,21010703,...",\n  "devTypeId": 1,\n  "collectTime": 1773417600000\n}',
            '{\n  "data": [\n    {\n      "devId": 21010701,\n      "dataItemMap": {\n        "product_power": 185.4,\n        "perpower_ratio": 4.63\n      }\n    }\n  ],\n  "failCode": 0,\n  "success": true\n}',
            "Batch request harian untuk memvalidasi energi resmi terverifikasi cloud Huawei.",
            "Live Production"
        ],
        [
            6,
            "Active Alarms API",
            "POST",
            "/thirdData/getAlarmList",
            '{\n  "stationCodes": "NE=54218158,NE=56226734",\n  "beginTime": 1773417600000,\n  "status": 1\n}',
            '{\n  "data": [\n    {\n      "alarmId": "ALM-99201",\n      "alarmName": "Grid Overvoltage",\n      "lev": 2,\n      "raiseTime": 1773421200000,\n      "repairSuggestion": "Check AC grid voltage tap and contact utility operator."\n    }\n  ],\n  "failCode": 0,\n  "success": true\n}',
            "Menyaring status normal Tabel 3-1 (40960: Standby no irradiation disaring agar tidak memicu alarm palsu).",
            "Live Production"
        ],
        [
            7,
            "Logout API",
            "POST",
            "/thirdData/logout",
            'Header: xsrf-token: xsrf-token-abc123xyz789',
            '{\n  "failCode": 0,\n  "message": "success",\n  "success": true\n}',
            "Membersihkan sesi aktif di gateway Huawei cloud untuk mencegah batas maksimum concurrent session.",
            "Live Production"
        ]
    ]

    format_data_table(ws, headers, rows, start_row=4)

# =============================================================================
# SHEET 9: Microsoft Dynamics 365 (D365)
# =============================================================================
def build_d365_sheet(wb):
    ws = wb.create_sheet(title="Microsoft Dynamics 365 (D365)")
    apply_sheet_title(
        ws,
        "MICROSOFT DYNAMICS 365 (D365) - ASSETS, INVENTORY & WORK ORDERS",
        "Inventaris Modul Integrasi D365 Maintenance: Pengambilan Sparepart, Transaksi Jurnal, Work Order Aktif, dan Master Data",
        col_count=len(STANDARD_HEADERS)
    )

    rows = [
        # Material Item Stock Check
        [1, "Inventory & Stock", "D365Service", "lib/services/d365_service.dart", "checkItemStock()", "{D365_API}/items/{itemNumber}", "GET", "itemNumber (XX.XXX.XXX.XXXX)", "itemNumber", "String", "Kode material unik terstandarisasi D365 (12 digit terformat)", "Hybrid (Live + Seed)"],
        [2, "Inventory & Stock", "D365Service", "lib/services/d365_service.dart", "checkItemStock()", "{D365_API}/items/{itemNumber}", "GET", "itemNumber", "itemName", "String", "Nama resmi sparepart / consumable (contoh: BEARING 6204-2RS C3 SKF)", "Hybrid (Live + Seed)"],
        [3, "Inventory & Stock", "D365Service", "lib/services/d365_service.dart", "checkItemStock()", "{D365_API}/items/{itemNumber}", "GET", "itemNumber", "description", "String", "Deskripsi spesifikasi teknis dimensi / kegunaan material", "Hybrid (Live + Seed)"],
        [4, "Inventory & Stock", "D365Service", "lib/services/d365_service.dart", "checkItemStock()", "{D365_API}/items/{itemNumber}", "GET", "itemNumber", "unitType", "String (PCS, SET, LTR, KG)", "Satuan unit pengukuran inventaris di gudang", "Hybrid (Live + Seed)"],
        [5, "Inventory & Stock", "D365Service", "lib/services/d365_service.dart", "checkItemStock()", "{D365_API}/items/{itemNumber}", "GET", "itemNumber", "availableStock", "double [Qty]", "Kuantitas stok fisik yang saat ini tersedia untuk diambil", "Hybrid (Live + Seed)"],
        [6, "Inventory & Stock", "D365Service", "lib/services/d365_service.dart", "checkItemStock()", "{D365_API}/items/{itemNumber}", "GET", "itemNumber", "defaultWarehouse", "String (e.g. MAINSTORE)", "Kode gudang penyimpanan utama barang", "Hybrid (Live + Seed)"],
        [7, "Inventory & Stock", "D365Service", "lib/services/d365_service.dart", "checkItemStock()", "{D365_API}/items/{itemNumber}", "GET", "itemNumber", "defaultLocation", "String (e.g. RAK-A2 / BIN-04)", "Kode rak dan bin posisi fisik barang di gudang", "Hybrid (Live + Seed)"],

        # Material Issue Submission
        [8, "Material Issue", "D365Service", "lib/services/d365_service.dart", "submitMaterialIssue()", "{D365_API}/material-issues", "POST", '{"transactionId": "...", "woNumber": "...", "items": [...]}', "transactionId", "String", "ID transaksi unik lokal untuk pelacakan voucher pengeluaran", "Hybrid (Live + Seed)"],
        [9, "Material Issue", "D365Service", "lib/services/d365_service.dart", "submitMaterialIssue()", "{D365_API}/material-issues", "POST", "Payload JSON", "woNumber", "String (WO-YYYY-xxxx)", "Nomor referensi Work Order pemeliharaan terkait", "Hybrid (Live + Seed)"],
        [10, "Material Issue", "D365Service", "lib/services/d365_service.dart", "submitMaterialIssue()", "{D365_API}/material-issues", "POST", "Payload JSON", "warehouseLocation", "String", "Gudang asal pengeluaran barang (MAINSTORE, OILSTORE, dll.)", "Hybrid (Live + Seed)"],
        [11, "Material Issue", "D365Service", "lib/services/d365_service.dart", "submitMaterialIssue()", "{D365_API}/material-issues", "POST", "Payload JSON", "activity", "String (6100ACxxxx)", "Dimensi finansial kode aktivitas akuntansi D365", "Hybrid (Live + Seed)"],
        [12, "Material Issue", "D365Service", "lib/services/d365_service.dart", "submitMaterialIssue()", "{D365_API}/material-issues", "POST", "Payload JSON", "costCenter", "String (6100DAxxx / DBxxx)", "Departemen pembebanan biaya pengeluaran sparepart", "Hybrid (Live + Seed)"],
        [13, "Material Issue", "D365Service", "lib/services/d365_service.dart", "submitMaterialIssue()", "{D365_API}/material-issues", "POST", "Payload JSON", "submittedBy", "String", "Nama teknisi / eksekutor pemohon barang", "Hybrid (Live + Seed)"],
        [14, "Material Issue", "D365Service", "lib/services/d365_service.dart", "submitMaterialIssue()", "{D365_API}/material-issues", "POST", "Payload JSON", "items", "List<LineItem>", "Daftar baris barang yang diambil beserta kuantitas pengurangannya", "Hybrid (Live + Seed)"],
        [15, "Material Issue", "D365Service", "lib/services/d365_service.dart", "submitMaterialIssue()", "{D365_API}/material-issues", "POST", "Response JSON", "journalNo / d365JournalNo", "String (JRN-D365-...)", "Nomor jurnal resmi posting ledger pembukuan D365", "Hybrid (Live + Seed)"],

        # Work Orders
        [16, "Work Orders", "D365Service", "lib/services/d365_service.dart", "getActiveWorkOrders()", "{D365_API}/work-orders?status=active", "GET", "status=active", "woNumber", "String (WO-YYYY-xxxx)", "Nomor identifikasi unik surat perintah kerja pemeliharaan", "Hybrid (Live + Cache)"],
        [17, "Work Orders", "D365Service", "lib/services/d365_service.dart", "getActiveWorkOrders()", "{D365_API}/work-orders?status=active", "GET", "status=active", "title", "String", "Judul pekerjaan overhaul / maintenance peralatan plant", "Hybrid (Live + Cache)"],
        [18, "Work Orders", "D365Service", "lib/services/d365_service.dart", "getActiveWorkOrders()", "{D365_API}/work-orders?status=active", "GET", "status=active", "equipment", "String (Tag / KKS)", "Tagging kode peralatan plant (contoh: 10-CWP-PMP-01A, 10-BLR-PT-025)", "Hybrid (Live + Cache)"],
        [19, "Work Orders", "D365Service", "lib/services/d365_service.dart", "getActiveWorkOrders()", "{D365_API}/work-orders?status=active", "GET", "status=active", "status", "String", "Status WO: Open, In Progress, Released, Closed", "Hybrid (Live + Cache)"],
        [20, "Work Orders", "D365Service", "lib/services/d365_service.dart", "getActiveWorkOrders()", "{D365_API}/work-orders?status=active", "GET", "status=active", "targetDate", "DateTime", "Batas waktu estimasi penyelesaian pekerjaan pemeliharaan", "Hybrid (Live + Cache)"],

        # Master Data Fixed Lists
        [21, "Master Data", "D365Service", "lib/services/d365_service.dart", "getWarehouseList()", "Local Master / Seed", "Memory / SharedPreferences", "-", "warehouseList", "List<String> (19 Warehouses)", "Daftar 19 gudang: MAINSTORE, CHEMSTORE, COALSTORE, OILSTORE, WTPSTORE, dll.", "Local Master Data"],
        [22, "Master Data", "D365Service", "lib/services/d365_service.dart", "getLocationList()", "Local Master / Seed", "Memory / SharedPreferences", "warehouse", "locationList", "List<String> (Bin / Rak)", "Daftar lokasi rak/bin spesifik per gudang (contoh: RAK-A1, LUBE-DRUM-01)", "Local Master Data"],
        [23, "Master Data", "D365Service", "lib/services/d365_service.dart", "getActivityList()", "Local Master / Seed", "Memory / SharedPreferences", "-", "activityList", "List<String> (86 Accounts)", "Daftar 86 dimensi finansial resmi D365 (6100ACxxxx: Sparepart, Pelumas, Jasa, dll.)", "Local Master Data"],
        [24, "Master Data", "D365Service", "lib/services/d365_service.dart", "getCostCenterList()", "Local Master / Seed", "Memory / SharedPreferences", "-", "costCenterList", "List<String> (39 Cost Centers)", "Daftar 39 cost center: Mechanical, Electrical, Instrument, WTP, Operation, PLTS", "Local Master Data"],

        # User Authentication & Sessions
        [25, "User Sessions", "D365Service", "lib/services/d365_service.dart", "loginD365()", "Local SharedPreferences", "Local Auth Session", "employeeCode", "employeeCode", "String (6100xxxx)", "Nomor induk karyawan resmi D365", "Local / Device Native"],
        [26, "User Sessions", "D365Service", "lib/services/d365_service.dart", "loginD365()", "Local SharedPreferences", "Local Auth Session", "employeeCode", "employeeName", "String", "Nama teknisi / eksekutor pemeliharaan", "Local / Device Native"],
        [27, "User Sessions", "D365Service", "lib/services/d365_service.dart", "loginD365()", "Local SharedPreferences", "Local Auth Session", "employeeCode", "department", "String", "Departemen penugasan kerja", "Local / Device Native"]
    ]

    format_data_table(ws, STANDARD_HEADERS, rows, start_row=4)

# =============================================================================
# SHEET 10: Weather & Meteorologi
# =============================================================================
def build_weather_sheet(wb):
    ws = wb.create_sheet(title="Weather & Meteorologi")
    apply_sheet_title(
        ws,
        "OPENWEATHERMAP API & METEOROLOGICAL EVALUATION",
        "Pemetaan Endpoint Cuaca untuk PLTU MSW Tanjung & Terminal Kelanis, Kalkulasi Potensi Solar PV, Navigasi WeatherPage, dan Matriks Risiko Operasi",
        col_count=len(STANDARD_HEADERS)
    )

    rows = [
        # Real-time Weather
        [1, "Current Weather", "WeatherService", "lib/services/weather_service.dart", "fetchWeather()", "https://api.openweathermap.org/data/2.5/weather", "GET", "lat=-2.1856, lon=115.3889, units=metric, appid=...", "main.temp", "double [°C]", "Temperatur udara ambient saat ini di area pembangkit", "Live API"],
        [2, "Current Weather", "WeatherService", "lib/services/weather_service.dart", "fetchWeather()", "https://api.openweathermap.org/data/2.5/weather", "GET", "lat, lon, units, appid", "main.feels_like", "double [°C]", "Temperatur yang dirasakan tubuh manusia (heat index)", "Live API"],
        [3, "Current Weather", "WeatherService", "lib/services/weather_service.dart", "fetchWeather()", "https://api.openweathermap.org/data/2.5/weather", "GET", "lat, lon, units, appid", "main.humidity", "int [%]", "Kelembapan relatif udara sekitar plant", "Live API"],
        [4, "Current Weather", "WeatherService", "lib/services/weather_service.dart", "fetchWeather()", "https://api.openweathermap.org/data/2.5/weather", "GET", "lat, lon, units, appid", "main.pressure", "int [hPa]", "Tekanan udara atmosfer di permukaan tanah", "Live API"],
        [5, "Current Weather", "WeatherService", "lib/services/weather_service.dart", "fetchWeather()", "https://api.openweathermap.org/data/2.5/weather", "GET", "lat, lon, units, appid", "wind.speed", "double [m/s]", "Kecepatan angin seketika (krusial untuk dermaga tongkang batubara)", "Live API"],
        [6, "Current Weather", "WeatherService", "lib/services/weather_service.dart", "fetchWeather()", "https://api.openweathermap.org/data/2.5/weather", "GET", "lat, lon, units, appid", "wind.deg", "int [Derajat °]", "Arah hembusan mata angin", "Live API"],
        [7, "Current Weather", "WeatherService", "lib/services/weather_service.dart", "fetchWeather()", "https://api.openweathermap.org/data/2.5/weather", "GET", "lat, lon, units, appid", "clouds.all", "int [%]", "Persentase tutupan awan di atas plant (Cloud Cover)", "Live API"],
        [8, "Current Weather", "WeatherService", "lib/services/weather_service.dart", "fetchWeather()", "https://api.openweathermap.org/data/2.5/weather", "GET", "lat, lon, units, appid", "rain.1h", "double [mm/jam]", "Intensitas curah hujan dalam 1 jam terakhir", "Live API"],
        [9, "Current Weather", "WeatherService", "lib/services/weather_service.dart", "fetchWeather()", "https://api.openweathermap.org/data/2.5/weather", "GET", "lat, lon, units, appid", "weather[0].description", "String", "Kondisi umum cuaca dalam teks bahasa (contoh: moderate rain, clear sky)", "Live API"],
        [10, "Current Weather", "WeatherService", "lib/services/weather_service.dart", "fetchWeather()", "https://api.openweathermap.org/data/2.5/weather", "GET", "lat, lon, units, appid", "sys.sunrise / sys.sunset", "int (Epoch Timestamp)", "Waktu matahari terbit dan terbenam lokal (WITA)", "Live API"],

        # Forecast
        [11, "Forecast 5-Day", "WeatherService", "lib/services/weather_service.dart", "fetchForecast()", "https://api.openweathermap.org/data/2.5/forecast", "GET", "lat, lon, units=metric, appid=...", "list[].dt_txt", "String (Datetime)", "Waktu prakiraan interval 3 jam ke depan", "Live API"],
        [12, "Forecast 5-Day", "WeatherService", "lib/services/weather_service.dart", "fetchForecast()", "https://api.openweathermap.org/data/2.5/forecast", "GET", "lat, lon, units=metric, appid=...", "list[].main.temp", "double [°C]", "Proyeksi temperatur udara untuk perencanaan beban pendingin", "Live API"],
        [13, "Forecast 5-Day", "WeatherService", "lib/services/weather_service.dart", "fetchForecast()", "https://api.openweathermap.org/data/2.5/forecast", "GET", "lat, lon, units=metric, appid=...", "list[].weather[0].icon", "String (Icon Code)", "Kode ikon visual kondisi cuaca mendatang", "Live API"],

        # Plant Risk & Solar Potential
        [14, "Plant Analytics", "WeatherService", "lib/services/weather_service.dart", "calculateSolarPvPotential()", "Algoritma Meteorologi", "Client-side Computation", "cloudPct, rainMm, hour", "solarPvScore", "double (0 - 100%)", "Indeks efektivitas potensi radiasi penyinaran untuk solar PV", "Client-side Computation"],
        [15, "Plant Analytics", "WeatherService", "lib/services/weather_service.dart", "calculateSolarPvPotential()", "Algoritma Meteorologi", "Client-side Computation", "cloudPct, rainMm, hour", "estimatedIrradiance", "double [W/m²]", "Estimasi radiasi global horisontal (GHI) dari model matematis sinus", "Client-side Computation"],
        [16, "Plant Analytics", "WeatherService", "lib/services/weather_service.dart", "evaluatePlantRisks()", "Matriks Risiko Operasional", "Client-side Computation", "windSpeed, rainMm, temp, humidity", "coalBargeRisk", "PlantRiskLevel", "Tingkat risiko keselamatan aktivitas sandar & muat tongkang batubara", "Client-side Computation"],
        [17, "Plant Analytics", "WeatherService", "lib/services/weather_service.dart", "evaluatePlantRisks()", "Matriks Risiko Operasional", "Client-side Computation", "windSpeed, rainMm, temp, humidity", "outdoorWorkRisk", "PlantRiskLevel", "Risiko keselamatan kerja pemeliharaan outdoor di ketinggian / boiler", "Client-side Computation"],
        [18, "Plant Analytics", "WeatherService", "lib/services/weather_service.dart", "evaluatePlantRisks()", "Matriks Risiko Operasional", "Client-side Computation", "windSpeed, rainMm, temp, humidity", "electricalSwitchyardRisk", "PlantRiskLevel", "Risiko kelembapan & hujan lebat pada gardu induk / switchyard 150kV", "Client-side Computation"],
        [19, "Plant Analytics", "WeatherService", "lib/services/weather_service.dart", "evaluatePlantRisks()", "Matriks Risiko Operasional", "Client-side Computation", "windSpeed, rainMm, temp, humidity", "highTempDerateRisk", "PlantRiskLevel", "Risiko penurunan efisiensi peralatan (thermal derating) saat suhu ekstrim", "Client-side Computation"],
        [20, "UI Navigation", "WeatherPage", "lib/pages/weather_page.dart", "MaterialPageRoute(builder: (_) => WeatherPage())", "Direct Route", "Screen Navigation", "-", "WeatherPage", "Widget Class", "Navigasi langsung dari SolarEnergyFlowWidget ke halaman evaluasi meteorologi lengkap", "Active UI Route"]
    ]

    format_data_table(ws, STANDARD_HEADERS, rows, start_row=4)

# =============================================================================
# SHEET 11: Google Sheets Logsheet
# =============================================================================
def build_googlesheets_sheet(wb):
    ws = wb.create_sheet(title="Google Sheets Logsheet")
    apply_sheet_title(
        ws,
        "GOOGLE SHEETS API V4 - SHIFT LOGSHEET & REPORT INTEGRATION",
        "Inventaris Kolom Logsheet Operasi Shift Pembangkit, Sinkronisasi Spreadsheet, dan Mekanisme OAuth2 Google Sign-In",
        col_count=len(STANDARD_HEADERS)
    )

    rows = [
        # Spreadsheet Management
        [1, "Sheet Management", "GoogleSheetsService", "lib/pages/logsheet/logsheet_service.dart", "signIn()", "GoogleSignIn (OAuth2)", "Google Sign-In Plugin", "scopes: email, spreadsheets, drive", "authHeaders", "Map<String, String>", "Bearer access token untuk Google Sheets API v4", "Live API"],
        [2, "Sheet Management", "GoogleSheetsService", "lib/pages/logsheet/logsheet_service.dart", "findOrCreateSpreadsheet()", "https://sheets.googleapis.com/v4/spreadsheets", "POST", '{"properties": {"title": "..."}}', "spreadsheetId", "String", "ID unik file spreadsheet Google Drive yang dibuat untuk logsheet plant", "Live API"],
        [3, "Sheet Management", "GoogleSheetsService", "lib/pages/logsheet/logsheet_service.dart", "readSheetData()", "https://sheets.googleapis.com/v4/spreadsheets/{id}/values/{range}", "GET", "A1 Range (%27encoded%27)", "values", "List<List<dynamic>>", "Seluruh baris dan kolom logsheet pada tanggal shift yang dipilih", "Live API"],
        [4, "Sheet Management", "GoogleSheetsService", "lib/pages/logsheet/logsheet_service.dart", "appendLogsheetRow()", "https://sheets.googleapis.com/v4/spreadsheets/{id}/values/{range}:append", "POST", "valueInputOption=USER_ENTERED", "updatedRows", "int", "Pencatatan data telemetry per jam oleh operator shift ke spreadsheet", "Live API"],

        # Standard Columns in Shift Logsheet
        [5, "Logsheet Columns", "GoogleSheetsService", "lib/pages/logsheet/logsheet_models.dart", "Column 0", "Spreadsheet Row / Col A", "Data Grid Column", "-", "TIMESTAMP / HOUR", "String (HH:00)", "Jam pencatatan logsheet operasional (00:00 - 23:00)", "Live Data Table"],
        [6, "Logsheet Columns", "GoogleSheetsService", "lib/pages/logsheet/logsheet_models.dart", "Column 1..2", "Spreadsheet Row / Col B..C", "Data Grid Column", "-", "MW_UNIT_1 & MW_UNIT_2", "double [MW]", "Beban daya listrik kotor Unit 1 & Unit 2", "Live Data Table"],
        [7, "Logsheet Columns", "GoogleSheetsService", "lib/pages/logsheet/logsheet_models.dart", "Column 3..6", "Spreadsheet Row / Col D..G", "Data Grid Column", "-", "STEAM_TEMP & STEAM_PRESS", "double [°C & MPa]", "Temperatur dan tekanan uap utama boiler Unit 1 & Unit 2", "Live Data Table"],
        [8, "Logsheet Columns", "GoogleSheetsService", "lib/pages/logsheet/logsheet_models.dart", "Column 7..10", "Spreadsheet Row / Col H..K", "Data Grid Column", "-", "COAL_FEEDER_FLOW", "double [Ton/h]", "Laju aliran batubara ke pulverizer / coal mill", "Live Data Table"],
        [9, "Logsheet Columns", "GoogleSheetsService", "lib/pages/logsheet/logsheet_models.dart", "Column 11..16", "Spreadsheet Row / Col L..Q", "Data Grid Column", "-", "FGD_CEMS_EMISSIONS", "double [mg/Nm³]", "Parameter emisi cerobong SO2, NOx, Partikulat per jam", "Live Data Table"],
        [10, "Logsheet Columns", "GoogleSheetsService", "lib/pages/logsheet/logsheet_models.dart", "Column 17..22", "Spreadsheet Row / Col R..W", "Data Grid Column", "-", "SOLAR_PV_GENERATION", "double [kW & kWh]", "Data daya aktif dan energi kumulatif bangkitan solar PV", "Live Data Table"],
        [11, "Logsheet Columns", "GoogleSheetsService", "lib/pages/logsheet/logsheet_models.dart", "Column 23..25", "Spreadsheet Row / Col X..Z", "Data Grid Column", "-", "SHIFT_OPERATOR_SIGN", "String (Nama & Paraf)", "Identitas operator kontrol room (Shift Supervisor & Boardman)", "Live Data Table"]
    ]

    format_data_table(ws, STANDARD_HEADERS, rows, start_row=4)

# =============================================================================
# SHEET 12: Local & Device Services
# =============================================================================
def build_local_services_sheet(wb):
    ws = wb.create_sheet(title="Local & Device Services")
    apply_sheet_title(
        ws,
        "LOCAL STORAGE, SECURITY, CEMS THRESHOLDS & OKR SERVICES",
        "Inventaris Layanan Internal: Autentikasi Role, Ambang Batas Lingkungan KLHK, Notifikasi Alarm Perangkat, dan Target OKR",
        col_count=len(STANDARD_HEADERS)
    )

    rows = [
        # AuthService
        [1, "Security & Auth", "AuthService", "lib/services/auth_service.dart", "saveSession() / getSavedRole()", "SharedPreferences", "Local Key-Value", "-", "session_role", "String (Enum)", "Role pengguna yang tersimpan: general, operation, maintenance, okr_editor, admin", "Local / Device Native"],
        [2, "Security & Auth", "AuthService", "lib/services/auth_service.dart", "hasValidSession()", "SharedPreferences", "Local Key-Value", "-", "session_timestamp", "int (Epoch ms)", "Waktu login untuk menghitung kedaluwarsa sesi (masa aktif 15 hari)", "Local / Device Native"],
        [3, "Security & Auth", "AuthService", "lib/services/auth_service.dart", "setPassword() / verifyPasswordScope()", "SharedPreferences", "Local Key-Value", "scope, password", "password_{scope}", "String (Hashed/Plain)", "Password akses proteksi per modul (admin, operation, maintenance, okr_editor)", "Local / Device Native"],

        # CemsThresholdService
        [4, "Environmental Compliance", "CemsThresholdService", "lib/services/cems_threshold_service.dart", "getThreshold('SO2')", "PermenLHK P.15/2019", "Static Configuration", "param='SO2'", "max: 550.0", "double [mg/Nm³]", "Baku mutu batas maksimum emisi Sulfur Dioksida PerMenLHK No. P.15/2019", "Local Configuration"],
        [5, "Environmental Compliance", "CemsThresholdService", "lib/services/cems_threshold_service.dart", "getThreshold('NOX')", "PermenLHK P.15/2019", "Static Configuration", "param='NOX'", "max: 550.0", "double [mg/Nm³]", "Baku mutu batas maksimum emisi Nitrogen Oksida PerMenLHK No. P.15/2019", "Local Configuration"],
        [6, "Environmental Compliance", "CemsThresholdService", "lib/services/cems_threshold_service.dart", "getThreshold('PARTICULATE')", "PermenLHK P.15/2019", "Static Configuration", "param='PARTICULATE'", "max: 50.0", "double [mg/Nm³]", "Baku mutu batas maksimum emisi debu partikulat PerMenLHK No. P.15/2019", "Local Configuration"],
        [7, "Environmental Compliance", "CemsThresholdService", "lib/services/cems_threshold_service.dart", "getThreshold('HG')", "PermenLHK P.15/2019", "Static Configuration", "param='HG'", "max: 0.03", "double [mg/Nm³]", "Baku mutu batas maksimum emisi Merkuri (Hg) PerMenLHK No. P.15/2019", "Local Configuration"],
        [8, "Environmental Compliance", "CemsThresholdService", "lib/services/cems_threshold_service.dart", "isDataCompliant()", "Threshold Engine", "Evaluation Function", "cemsData, fallbackData", "isCompliant", "Boolean", "Evaluasi otomatis apakah seluruh pembacaan CEMS berada di bawah ambang batas baku mutu", "Local Evaluation Engine"],

        # NotificationService
        [9, "System Notifications", "NotificationService", "lib/services/notification_service.dart", "init()", "flutter_local_notifications", "Android / iOS Native", "-", "Timezone: Asia/Makassar", "String", "Inisialisasi zona waktu WITA (Waktu Indonesia Tengah) untuk penjadwalan alarm", "Device Native"],
        [10, "System Notifications", "NotificationService", "lib/services/notification_service.dart", "showExceedNotification()", "flutter_local_notifications", "System Notification", "unitName, param, value, limit", "channel: cems_alert", "Notification Popup", "Peringatan darurat instan di status bar saat emisi CEMS melebihi baku mutu KLHK", "Device Native"],

        # OkrService
        [11, "Corporate OKRs", "OkrService", "lib/services/okr_service.dart", "currentObjectives", "Local In-Memory / SharedPreferences", "State Management", "-", "Objective[].title", "String", "Sasaran strategis perusahaan & plant tahunan (contoh: Kesiapan Operasi & Keandalan)", "Local / Seed State"],
        [12, "Corporate OKRs", "OkrService", "lib/services/okr_service.dart", "currentObjectives", "Local In-Memory / SharedPreferences", "State Management", "-", "KeyResult[].target", "double", "Nilai target kuantitatif (contoh: EAF 92%, NPHR 2450 kCal/kWh, Zero Accident)", "Local / Seed State"],
        [13, "Corporate OKRs", "OkrService", "lib/services/okr_service.dart", "saveObjective() / saveKeyResult()", "Local In-Memory / SharedPreferences", "State Management", "Objective / KeyResult", "changelog", "List<String>", "Riwayat perubahan (audit trail) pembaruan data pencapaian OKR", "Local / Seed State"]
    ]

    format_data_table(ws, STANDARD_HEADERS, rows, start_row=4)

# =============================================================================
# Main Execution
# =============================================================================
def main():
    print("[INFO] Initializing MSW ePlant Unified Service & Data Inventory Generator...")

    if not os.path.exists(OUTPUT_DIR):
        os.makedirs(OUTPUT_DIR, exist_ok=True)
        print(f"[INFO] Created directory: {OUTPUT_DIR}")

    wb = Workbook()

    print("[INFO] Building Sheet 1: Overview & Architecture...")
    build_overview_sheet(wb)

    print("[INFO] Building Sheet 2: CFPP Overview (excel_data)...")
    build_cfpp_overview_sheet(wb)

    print("[INFO] Building Sheet 3: Boiler & Turbine (table1 & 2)...")
    build_boiler_turbine_sheet(wb)

    print("[INFO] Building Sheet 4: CEMS Emisi (cems1 & cems2)...")
    build_cems_sheet(wb)

    print("[INFO] Building Sheet 5: NPHR & Thermal Heat Rate...")
    build_nphr_sheet(wb)

    print("[INFO] Building Sheet 6: Huawei FusionSolar OpenAPI...")
    build_fusionsolar_openapi_sheet(wb)

    print("[INFO] Building Sheet 7: Solar PV Inverter Mapping...")
    build_solar_inverter_mapping_sheet(wb)

    print("[INFO] Building Sheet 8: Simulasi Payload FusionSolar...")
    build_fusionsolar_payloads_sheet(wb)

    print("[INFO] Building Sheet 9: Microsoft Dynamics 365 (D365)...")
    build_d365_sheet(wb)

    print("[INFO] Building Sheet 10: Weather & Meteorologi...")
    build_weather_sheet(wb)

    print("[INFO] Building Sheet 11: Google Sheets Logsheet...")
    build_googlesheets_sheet(wb)

    print("[INFO] Building Sheet 12: Local & Device Services...")
    build_local_services_sheet(wb)

    print(f"[INFO] Saving master workbook to: {OUTPUT_FILE} ...")
    wb.save(OUTPUT_FILE)
    print(f"[OK] Successfully generated Master Excel inventory ({os.path.getsize(OUTPUT_FILE)} bytes) with 12 sheets!")

if __name__ == "__main__":
    main()
