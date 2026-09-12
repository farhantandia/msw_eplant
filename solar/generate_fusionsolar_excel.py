import os
import openpyxl
from openpyxl.styles import Font, PatternFill, Alignment, Border, Side
from openpyxl.utils import get_column_letter

def create_fusionsolar_excel():
    wb = openpyxl.Workbook()
    # Remove default sheet
    wb.remove(wb.active)

    # Styles & Colors
    header_fill = PatternFill(start_color="1E293B", end_color="1E293B", fill_type="solid") # Dark Slate
    header_font = Font(name="Calibri", size=11, bold=True, color="FFFFFF")
    
    cat_fill = PatternFill(start_color="0F172A", end_color="0F172A", fill_type="solid")
    cat_font = Font(name="Calibri", size=12, bold=True, color="38BDF8")

    title_font = Font(name="Calibri", size=16, bold=True, color="0F172A")
    subtitle_font = Font(name="Calibri", size=11, italic=True, color="475569")

    ui_yes_fill = PatternFill(start_color="DCFCE7", end_color="DCFCE7", fill_type="solid") # Light Green
    ui_yes_font = Font(name="Calibri", size=10, bold=True, color="166534")

    ui_back_fill = PatternFill(start_color="FEF3C7", end_color="FEF3C7", fill_type="solid") # Light Amber
    ui_back_font = Font(name="Calibri", size=10, bold=True, color="92400E")

    ui_api_fill = PatternFill(start_color="F1F5F9", end_color="F1F5F9", fill_type="solid") # Light Gray
    ui_api_font = Font(name="Calibri", size=10, color="475569")

    thin_border = Border(
        left=Side(style='thin', color='CBD5E1'),
        right=Side(style='thin', color='CBD5E1'),
        top=Side(style='thin', color='CBD5E1'),
        bottom=Side(style='thin', color='CBD5E1')
    )

    # ─────────────────────────────────────────────────────────────
    # SHEET 1: RINGKASAN ARSITEKTUR & ENDPOINT
    # ─────────────────────────────────────────────────────────────
    ws1 = wb.create_sheet(title="Ringkasan Arsitektur")
    ws1.views.sheetView[0].showGridLines = True

    ws1["A1"] = "HUAWEI FUSIONSOLAR OPENAPI - DATA DICTIONARY & UI MAPPING"
    ws1["A1"].font = title_font
    ws1["A2"] = "Aplikasi MSW ePlant · PLTU MSW 400 kWp & PLTS Floating Kelanis 468 kWp"
    ws1["A2"].font = subtitle_font

    ws1["A4"] = "1. RINGKASAN ENDPOINT FUSIONSOLAR YANG DIGUNAKAN"
    ws1["A4"].font = Font(name="Calibri", size=12, bold=True, color="1E293B")

    endpoints_headers = ["No", "Endpoint Huawei OpenAPI", "Metode", "Fungsi Utama", "Pola Eksekusi", "Interval Sync", "Proteksi Quota & Rate Limit"]
    ws1.append([]) # row 5 empty
    ws1.append(endpoints_headers) # row 6
    
    for col_idx in range(1, len(endpoints_headers) + 1):
        cell = ws1.cell(row=6, column=col_idx)
        cell.fill = header_fill
        cell.font = header_font
        cell.alignment = Alignment(horizontal="center", vertical="center", wrap_text=True)

    endpoints_data = [
        [1, "/thirdData/login", "POST", "Autentikasi akun northbound 'msw_fusionsolar_api' dan perolehan token sesi xsrf-token", "Sekuensial Awal", "Per 25 menit / Saat expired", "Token di-cache, re-login otomatis bila failCode: 305"],
        [2, "/thirdData/getStationList", "POST", "Mengambil daftar stasiun/plant PV aktif beserta kapasitas terpasang dan kode stasiun", "Sekuensial Pipeline", "30 Menit sekali (04:00 - 20:00)", "Hasil stasiun di-cache di memori"],
        [3, "/thirdData/getDevList", "POST", "Mengambil daftar perangkat inverter aktif (devTypeId = 1) untuk setiap stasiun", "Sekuensial Pipeline", "30 Menit sekali (04:00 - 20:00)", "Jeda throttle 2s antar-request stasiun"],
        [4, "/thirdData/getDevRealKpi", "POST", "Telemetri elektrik real-time lengkap (Daya kW, Tegangan, Arus, Frekuensi, Suhu, Status)", "Batch 1 Request (12 Dev)", "30 Menit sekali (04:00 - 20:00)", "Batching 12 Device IDs ke 1 string comma-separated"],
        [5, "/thirdData/getDevKpiDay", "POST", "Akumulasi produksi energi harian resmi (product_power kWh) dan Specific Energy per inverter", "Batch 1 Request (12 Dev)", "30 Menit sekali (04:00 - 20:00)", "Batching 12 Device IDs; filter collectTime hari ini"],
        [6, "/thirdData/getKpiStationDay", "POST", "Metrik stasiun harian: Radiasi (kWh/m²), PR (%), Produksi kemarin, dan Pengurangan Emisi ESG", "Sekuensial Pipeline", "30 Menit sekali (04:00 - 20:00)", "Digunakan untuk card ringkasan & ESG banner"],
        [7, "/thirdData/getKpiStationHour", "POST", "Profil kurva per jam (Radiasi, Daya, PR) dari jam 04:00 hingga jam saat ini", "Sekuensial Pipeline", "30 Menit sekali (04:00 - 20:00)", "Hanya mengambil jam lewat (tidak mengisi jam masa depan)"],
        [8, "/thirdData/getAlarmList", "POST", "Daftar alarm aktif yang dilaporkan inverter ke cloud Huawei beserta rekomendasi perbaikan", "Sekuensial Pipeline", "30 Menit sekali (04:00 - 20:00)", "Auto-filter: menyaring kode normal 40960 / no irradiation"],
        [9, "/thirdData/logout", "POST", "Menutup sesi xsrf-token secara aman saat service di-dispose", "Saat Dispose", "Sesuai kebutuhan", "Mencegah penumpukan sesi aktif di server Huawei"]
    ]

    for row in endpoints_data:
        ws1.append(row)

    ws1.append([])
    ws1.append(["2. ATURAN PENGAMBILAN DATA (DATA FETCHING POLICY)"])
    r_idx = ws1.max_row
    ws1.cell(row=r_idx, column=1).font = Font(name="Calibri", size=12, bold=True, color="1E293B")

    policies = [
        ("Apakah diambil semua dalam satu waktu?", "TIDAK. Arsitektur API Huawei memisahkan endpoint stasiun, inverter, telemetri, dan alarm. Eksekusi dilakukan secara BERURUTAN (SEKUENSIAL PIPELINE), bukan serentak liar."),
        ("Pacing Delay (Anti 407)", "Setiap antar-request diberikan jeda wajib minimal 2 detik (throttleDelay). Ini menjamin Huawei WAF tidak memicu error 407 (access frequency too high)."),
        ("Device Batching", "Untuk menghemat kuota, telemetri 12 unit inverter dipanggil sekaligus dalam 1 request batch menggunakan parameter devIds: 'id1,id2,...'."),
        ("30-Minute Bucket Caching", "Sinkronisasi ke Huawei Cloud dilakukan setiap 30 menit. Request berulang dalam jendela 30 menit yang sama disajikan dari cache Firebase RTDB (~256 request/hari = hanya ~25% dari kuota Huawei 1.000)."),
        ("16-Hour Operational Window", "Hanya aktif antara jam 04:00 - 20:00 WITA. Di luar jam ini (malam hari), sistem langsung masuk Night Standby tanpa memanggil API (0 API calls).")
    ]

    ws1.append(["Mekanisme", "Penjelasan Teknis"])
    h_row = ws1.max_row
    for c in range(1, 3):
        cell = ws1.cell(row=h_row, column=c)
        cell.fill = header_fill
        cell.font = header_font

    for p in policies:
        ws1.append([p[0], p[1]])

    # ─────────────────────────────────────────────────────────────
    # SHEET 2: TELEMETRI ELEKTRIK INVERTER (DEV REAL KPI & DAY KPI)
    # ─────────────────────────────────────────────────────────────
    ws2 = wb.create_sheet(title="Telemetri Inverter")
    ws2.views.sheetView[0].showGridLines = True

    ws2["A1"] = "DATA TELEMETRI ELEKTRIK INVERTER (REAL-TIME & DAILY KPI)"
    ws2["A1"].font = title_font
    ws2["A2"] = "Sumber: Endpoint /getDevRealKpi dan /getDevKpiDay (Batch 12 Inverter)"
    ws2["A2"].font = subtitle_font

    inv_headers = [
        "No", "Parameter API (Key)", "Nama Deskriptif", "Satuan", "Tipe Data", 
        "Status di UI", "Lokasi Tampilan UI", "Endpoint Sumber", "Penjelasan Fungsi & Logika Pengolahan"
    ]
    ws2.append([])
    ws2.append(inv_headers)
    for col_idx in range(1, len(inv_headers) + 1):
        cell = ws2.cell(row=4, column=col_idx)
        cell.fill = header_fill
        cell.font = header_font
        cell.alignment = Alignment(horizontal="center", vertical="center", wrap_text=True)

    inv_fields = [
        [1, "active_power", "Daya Aktif Inverter", "kW", "Double", "Ditampilkan di UI", "PlantPage Card, Inverter Detail Hero, Solar Detail Header", "/getDevRealKpi", "Daya output AC saat ini yang dihasilkan inverter ke grid. Dijumlahkan untuk Total Power."],
        [2, "product_power", "Produksi Energi Hari Ini", "kWh", "Double", "Ditampilkan di UI", "PlantPage Card, Inverter Detail Hero, WhatsApp Report", "/getDevKpiDay", "Akumulasi kWh yang dihasilkan inverter per hari ini dari cloud Huawei."],
        [3, "inverter_state / run_state", "Kode Status Operasional", "Enum / Int", "Integer", "Ditampilkan di UI", "Inverter Detail Badge, Operating State Diagnostik", "/getDevRealKpi", "Kode status Huawei Tabel 3-1 (0=Standby, 512=Grid-Connected, 40960=Standby: No Irradiation)."],
        [4, "temperature", "Suhu Internal Inverter", "°C", "Double", "Ditampilkan di UI", "Inverter Detail Diagnostik & Numeric Trend Sheet", "/getDevRealKpi", "Suhu heatsink/IGBT internal. Status OK bila < 65°C. Dapat di-tap untuk grafik."],
        [5, "elec_freq", "Frekuensi Grid AC", "Hz", "Double", "Ditampilkan di UI", "Inverter Detail Diagnostik & Numeric Trend Sheet", "/getDevRealKpi", "Frekuensi jala-jala listrik PLN/Internal. Normal pada rentang 49.0 - 51.0 Hz."],
        [6, "ab_u", "Tegangan Saluran Uab", "V", "Double", "Ditampilkan di UI", "Inverter Detail Diagnostik (3-Phase Line Voltage)", "/getDevRealKpi", "Tegangan AC antar fasa A dan B. Mendukung grafik riwayat."],
        [7, "bc_u", "Tegangan Saluran Ubc", "V", "Double", "Ditampilkan di UI", "Inverter Detail Diagnostik (3-Phase Line Voltage)", "/getDevRealKpi", "Tegangan AC antar fasa B dan C."],
        [8, "ca_u", "Tegangan Saluran Uca", "V", "Double", "Ditampilkan di UI", "Inverter Detail Diagnostik (3-Phase Line Voltage)", "/getDevRealKpi", "Tegangan AC antar fasa C dan A."],
        [9, "a_i", "Arus Fasa Ia", "A", "Double", "Ditampilkan di UI", "Inverter Detail Diagnostik (AC Phase Current)", "/getDevRealKpi", "Arus keluaran AC pada fasa A. Mendukung grafik riwayat."],
        [10, "b_i", "Arus Fasa Ib", "A", "Double", "Ditampilkan di UI", "Inverter Detail Diagnostik (AC Phase Current)", "/getDevRealKpi", "Arus keluaran AC pada fasa B."],
        [11, "c_i", "Arus Fasa Ic", "A", "Double", "Ditampilkan di UI", "Inverter Detail Diagnostik (AC Phase Current)", "/getDevRealKpi", "Arus keluaran AC pada fasa C."],
        [12, "power_factor", "Faktor Daya (cos φ)", "—", "Double", "Ditampilkan di UI", "Inverter Detail Diagnostik", "/getDevRealKpi", "Nilai faktor daya inverter (ideal mendekati 1.000)."],
        [13, "efficiency", "Efisiensi Konversi", "%", "Double", "Ditampilkan di UI", "Inverter Detail Diagnostik & Numeric Trend Sheet", "/getDevRealKpi", "Efisiensi konversi daya DC ke AC (standar inverter Huawei > 98%)."],
        [14, "mppt_power", "Total Daya Input DC MPPT", "kW", "Double", "Ditampilkan di UI", "Inverter Detail Diagnostik & Numeric Trend Sheet", "/getDevRealKpi", "Total daya DC yang masuk dari string panel surya ke inverter."],
        [15, "total_cap", "Total Produksi Seumur Hidup", "MWh", "Double", "Ditampilkan di UI", "Inverter Detail Diagnostik (Lifetime Generation)", "/getDevRealKpi", "Kumulatif energi total sejak inverter pertama kali dioperasikan (dikonversi ke MWh)."],
        [16, "perpower_ratio", "Specific Energy / PR Unit", "kWh/kWp", "Double", "Ditampilkan di UI", "Inverter Detail Spec & WhatsApp Report (Kelanis)", "/getDevKpiDay", "Rasio kWh per kWp kapasitas inverter. Digunakan untuk evaluasi kinerja per unit."],
        [17, "day_cap / m_day_cap", "Produksi Harian Alternatif", "kWh", "Double", "Backend Only (Fallback)", "Tidak Tampil Langsung (Fallback jika dayKpi nol)", "/getDevRealKpi", "Register harian di real-time KPI. Digunakan sebagai fallback jika agregasi cloud terlambat."],
        [18, "reactive_power", "Daya Reaktif", "kVar", "Double", "Tersedia di API (Belum di UI)", "—", "/getDevRealKpi", "Daya reaktif AC keluaran inverter."],
        [19, "open_time", "Waktu Mulai Operasi Harian", "ms (Epoch)", "Integer", "Tersedia di API (Belum di UI)", "—", "/getDevRealKpi", "Timestamp saat inverter bangun dari standby dan mulai sinkron ke grid."],
        [20, "close_time", "Waktu Tutup Operasi Harian", "ms (Epoch)", "Integer", "Tersedia di API (Belum di UI)", "—", "/getDevRealKpi", "Timestamp saat inverter berhenti injeksi dan masuk standby sore/malam."],
        [21, "mppt_1_cap s/d mppt_4_cap", "Energi per String Tracker", "kWh", "Double", "Tersedia di API (Belum di UI)", "—", "/getDevRealKpi", "Energi yang dihasilkan oleh masing-masing pelacak MPPT individual."],
        [22, "pv1_u s/d pv8_u", "Tegangan DC per String PV", "V", "Double", "Tersedia di API (Belum di UI)", "—", "/getDevRealKpi", "Tegangan DC masing-masing string panel yang masuk ke terminal DC inverter."],
        [23, "pv1_i s/d pv8_i", "Arus DC per String PV", "A", "Double", "Tersedia di API (Belum di UI)", "—", "/getDevRealKpi", "Arus DC masing-masing string panel yang masuk ke terminal DC inverter."],
        [24, "insulation_resistance", "Tahanan Isolasi DC", "kΩ", "Double", "Tersedia di API (Status di UI)", "Inverter Detail (DC Isolation Resistance Normal)", "/getDevRealKpi", "Tahanan isolasi DC ke tanah. Bila di bawah ambang (<50 kΩ) memicu alarm isolasi."]
    ]

    for row in inv_fields:
        ws2.append(row)

    # ─────────────────────────────────────────────────────────────
    # SHEET 3: DATA STASIUN & ESG (STATION DAY & HOUR KPI)
    # ─────────────────────────────────────────────────────────────
    ws3 = wb.create_sheet(title="Data Stasiun & ESG")
    ws3.views.sheetView[0].showGridLines = True

    ws3["A1"] = "DATA STASIUN, KURVA JAM-JAMAN & PARAMETER ESG"
    ws3["A1"].font = title_font
    ws3["A2"] = "Sumber: Endpoint /getKpiStationDay dan /getKpiStationHour"
    ws3["A2"].font = subtitle_font

    st_headers = [
        "No", "Parameter API (Key)", "Nama Deskriptif", "Satuan", "Tipe Data", 
        "Status di UI", "Lokasi Tampilan UI", "Endpoint Sumber", "Penjelasan Fungsi & Logika Pengolahan"
    ]
    ws3.append([])
    ws3.append(st_headers)
    for col_idx in range(1, len(st_headers) + 1):
        cell = ws3.cell(row=4, column=col_idx)
        cell.fill = header_fill
        cell.font = header_font
        cell.alignment = Alignment(horizontal="center", vertical="center", wrap_text=True)

    st_fields = [
        [1, "radiation_intensity (Hari)", "Radiasi Matahari Total Hari Ini", "kWh/m²", "Double", "Ditampilkan di UI", "Solar Detail Card, Plant Card, Cuaca", "/getKpiStationDay", "Akumulasi insolasi matahari harian yang diterima sensor radiasi stasiun."],
        [2, "performance_ratio (Hari)", "Performance Ratio (PR) Stasiun", "%", "Double", "Ditampilkan di UI", "Solar Detail PR Card, WhatsApp Report", "/getKpiStationDay", "Efisiensi keseluruhan sistem pembangkit PLTS dibandingkan potensi radiasi teoritis."],
        [3, "reduction_total_co2", "Pengurangan Emisi CO₂", "Ton", "Double", "Ditampilkan di UI", "Solar Detail ESG Banner, Inverter Detail ESG", "/getKpiStationDay", "Total reduksi gas rumah kaca CO₂ yang dihasilkan oleh PLTS."],
        [4, "reduction_total_coal", "Penghematan Batubara Standar", "Ton", "Double", "Ditampilkan di UI", "Solar Detail ESG Banner, Inverter Detail ESG", "/getKpiStationDay", "Bahan bakar batubara ekuivalen yang dihemat dari pembangkitan energi surya."],
        [5, "reduction_total_tree", "Ekuivalen Penanaman Pohon", "Pohon", "Double", "Ditampilkan di UI", "Solar Detail ESG Banner, Inverter Detail ESG", "/getKpiStationDay", "Ekuivalen jumlah pohon yang ditanam berdasarkan kalkulasi resmi Huawei."],
        [6, "inverter_power (Kemarin)", "Produksi Energi Kemarin", "kWh", "Double", "Ditampilkan di UI", "Solar Detail Card (Yield Kemarin)", "/getKpiStationDay", "Produksi kemarin digunakan untuk pembanding tren harian (Yesterday vs Today)."],
        [7, "radiation_intensity (Jam)", "Radiasi Matahari per Jam", "kWh/m²", "Double", "Ditampilkan di UI", "Solar Detail Interactive Hourly Chart", "/getKpiStationHour", "Titik kurva radiasi jam-jaman (04:00 - 20:00) untuk grafik oranye di Solar Detail."],
        [8, "inverter_power (Jam)", "Produksi Energi per Jam", "kWh", "Double", "Ditampilkan di UI", "Solar Detail Interactive Hourly Chart", "/getKpiStationHour", "Titik kurva produksi energi jam-jaman untuk grafik hijau di Solar Detail."],
        [9, "performance_ratio (Jam)", "Performance Ratio per Jam", "%", "Double", "Ditampilkan di UI", "Solar Detail PR Trend Chart", "/getKpiStationHour", "PR stasiun pada jam tertentu."],
        [10, "power (Jam)", "Daya Output per Jam", "kW", "Double", "Ditampilkan di UI", "Solar Detail Hourly Power Curve", "/getKpiStationHour", "Rata-rata daya aktif pada slot jam tersebut."],
        [11, "revenue", "Pendapatan Moneter Listrik", "IDR / USD", "Double", "Tersedia di API (Belum di UI)", "—", "/getKpiStationDay", "Nilai moneter energi berdasarkan setting harga tarif listrik di FusionSolar web."],
        [12, "installed_capacity", "Kapasitas Nominal Terpasang", "kWp", "Double", "Ditampilkan di UI", "Solar Detail Subtitle & Hero Header", "/getKpiStationDay", "Kapasitas gabungan 868 kWp (400 kWp MSW + 468 kWp Kelanis)."]
    ]

    for row in st_fields:
        ws3.append(row)

    # ─────────────────────────────────────────────────────────────
    # SHEET 4: METADATA STASIUN & PERANGKAT
    # ─────────────────────────────────────────────────────────────
    ws4 = wb.create_sheet(title="Metadata Stasiun & Inverter")
    ws4.views.sheetView[0].showGridLines = True

    ws4["A1"] = "METADATA STASIUN & PERANGKAT INVERTER"
    ws4["A1"].font = title_font
    ws4["A2"] = "Sumber: Endpoint /getStationList dan /getDevList"
    ws4["A2"].font = subtitle_font

    meta_headers = [
        "No", "Parameter API (Key)", "Nama Deskriptif", "Tipe Data", 
        "Status di UI", "Lokasi Tampilan UI", "Endpoint Sumber", "Penjelasan Fungsi"
    ]
    ws4.append([])
    ws4.append(meta_headers)
    for col_idx in range(1, len(meta_headers) + 1):
        cell = ws4.cell(row=4, column=col_idx)
        cell.fill = header_fill
        cell.font = header_font
        cell.alignment = Alignment(horizontal="center", vertical="center", wrap_text=True)

    meta_fields = [
        [1, "stationCode", "Kode Unik Stasiun", "String", "Ditampilkan di UI (Filter)", "Filter Plant MSW vs Kelanis", "/getStationList", "Kode identifikasi stasiun (NE=56226734 untuk Kelanis, NE=54218158 untuk MSW)."],
        [2, "stationName", "Nama Resmi Stasiun", "String", "Ditampilkan di UI", "Label Tab Stasiun & Header", "/getStationList", "Nama stasiun di portal Huawei (PLTS Floating Adaro Kelanis 468 kWp & PLTS 400 kWp MSW)."],
        [3, "capacity", "Kapasitas Stasiun", "Double", "Ditampilkan di UI", "Header Plant (400 & 468 kWp)", "/getStationList", "Kapasitas peak rating stasiun surya."],
        [4, "id", "Device ID Huawei", "String / Long", "Backend Only", "Kunci Pemetaan Inverter", "/getDevList", "ID unik perangkat pada backend Huawei untuk menembak parameter telemetri."],
        [5, "devName", "Nama Perangkat Inverter", "String", "Ditampilkan di UI", "Judul Inverter Card & Detail Page", "/getDevList", "Nama unit inverter (Inverter(COM1-1), INV_PLTS_200_KWP_1, dsb.)."],
        [6, "devTypeId", "Tipe Perangkat", "Integer", "Backend Only", "Filter Inverter (devTypeId == 1)", "/getDevList", "Tipe device. Nilai 1 menandakan Inverter (disaring dari sensor cuaca/smartlogger)."],
        [7, "model / invType", "Tipe / Model Perangkat", "String", "Ditampilkan di UI", "Inverter Detail (Spesifikasi Teknis)", "/getDevList", "Model fisik inverter Huawei (misal SUN2000-100KTL-M1 atau seri SUN2000 terkait)."],
        [8, "softwareVersion", "Versi Firmware", "String", "Ditampilkan di UI", "Inverter Detail (Spesifikasi Teknis)", "/getDevList", "Versi perangkat lunak/firmware inverter (misal V500R023C00SPC156)."],
        [9, "esnCode", "Nomor Seri Hardware (ESN)", "String", "Ditampilkan di UI", "Inverter Detail (Spesifikasi Teknis)", "/getDevList", "Nomor seri pabrikan inverter dari Huawei."],
        [10, "stationAddr", "Alamat Fisik Stasiun", "String", "Tersedia di API (Belum di UI)", "—", "/getStationList", "Alamat lokasi proyek pembangkit."],
        [11, "latitude / longitude", "Koordinat Geografis", "Double", "Backend (Sinkronisasi Cuaca)", "Dipakai modul Open-Meteo Cuaca", "/getStationList", "Koordinat GPS Tanjung (-2.18) & Kelanis (-2.22) untuk mengambil data cuaca & matahari."],
        [12, "gridConnectionTime", "Tanggal Operasi Komersial", "String / ms", "Tersedia di API (Belum di UI)", "—", "/getStationList", "Tanggal awal stasiun diresmikan tersambung ke jaringan (COD)."],
        [13, "contactPerson / contactPhone", "Kontak Pengelola", "String", "Tersedia di API (Belum di UI)", "—", "/getStationList", "Nama dan nomor kontak penanggung jawab stasiun di Huawei."]
    ]

    for row in meta_fields:
        ws4.append(row)

    # ─────────────────────────────────────────────────────────────
    # SHEET 5: ALARM & KAMUS TABEL 3-1
    # ─────────────────────────────────────────────────────────────
    ws5 = wb.create_sheet(title="Alarm & Kamus Tabel 3-1")
    ws5.views.sheetView[0].showGridLines = True

    ws5["A1"] = "DATA ALARM FUSIONSOLAR & KAMUS INVERTER STATE (TABEL 3-1)"
    ws5["A1"].font = title_font
    ws5["A2"] = "Sumber: Endpoint /getAlarmList dan Pemetaan Status Huawei SUN2000 Modbus"
    ws5["A2"].font = subtitle_font

    ws5["A4"] = "1. STRUKTUR DATA ALARM (/getAlarmList)"
    ws5["A4"].font = Font(name="Calibri", size=12, bold=True, color="1E293B")

    alarm_headers = ["No", "Field API", "Nama Field", "Tipe Data", "Status di UI", "Lokasi Tampilan UI", "Fungsi"]
    ws5.append([])
    ws5.append(alarm_headers)
    for col_idx in range(1, len(alarm_headers) + 1):
        cell = ws5.cell(row=6, column=col_idx)
        cell.fill = header_fill
        cell.font = header_font

    alarm_fields = [
        [1, "alarmId", "ID Alarm", "String", "Ditampilkan di UI", "Modal Detail Alarm", "ID unik event alarm."],
        [2, "alarmName", "Nama Alarm / Gangguan", "String", "Ditampilkan di UI", "Kartu Alarm Inverter Detail", "Judul gangguan resmi Huawei."],
        [3, "alarmCode", "Kode Alarm", "Integer", "Ditampilkan di UI", "Modal Detail Alarm", "Kode numerik alarm."],
        [4, "lev", "Tingkat Keparahan (Severity)", "Integer", "Ditampilkan di UI", "Badge & Warna Alarm", "1=Critical (Merah), 2=Major (Orange), 3=Minor (Kuning), 4=Warning (Biru)."],
        [5, "raiseTime", "Waktu Terpicu", "Epoch ms", "Ditampilkan di UI", "Timestamp Kartu Alarm", "Waktu saat alarm pertama kali tercatat."],
        [6, "repairSuggestion", "Panduan Perbaikan", "String", "Ditampilkan di UI", "Modal Detail Rekomendasi", "Langkah investigasi dan troubleshooting teknis resmi dari Huawei."],
        [7, "devName / devId", "Nama / ID Perangkat", "String", "Ditampilkan di UI", "Label Inverter Terdampak", "Memetakan alarm ke unit inverter terkait."]
    ]
    for row in alarm_fields:
        ws5.append(row)

    ws5.append([])
    ws5.append(["2. KAMUS KODE STATUS INVERTER TABEL 3-1 HUAWEI (inverter_state)"])
    r_idx = ws5.max_row
    ws5.cell(row=r_idx, column=1).font = Font(name="Calibri", size=12, bold=True, color="1E293B")

    state_headers = ["Kode", "Deskripsi Resmi Huawei", "Klasifikasi Sistem", "Status Alarm", "Tampilan di UI", "Penjelasan Kondisi"]
    ws5.append([])
    ws5.append(state_headers)
    h_row2 = ws5.max_row
    for c in range(1, len(state_headers) + 1):
        cell = ws5.cell(row=h_row2, column=c)
        cell.fill = header_fill
        cell.font = header_font

    states_data = [
        [0, "Standby: initializing", "Standby", "0 Alarm (Healthy)", "Standby: Initializing", "Inverter sedang inisialisasi awal saat mulai dinyalakan."],
        [1, "Standby: insulation resistance detecting", "Standby", "0 Alarm (Healthy)", "Standby: Insulation Resistance Detecting", "Pemeriksaan tahanan isolasi string DC sebelum koneksi."],
        [2, "Standby: irradiation detecting", "Standby", "0 Alarm (Healthy)", "Standby: Irradiation Detecting", "Inverter mendeteksi kecukupan intensitas sinar matahari."],
        [3, "Standby: grid detecting", "Standby", "0 Alarm (Healthy)", "Standby: Grid Detecting", "Inverter mendeteksi sinkronisasi tegangan dan frekuensi grid."],
        [256, "Start", "Grid-Connected", "0 Alarm (Healthy)", "Start", "Inverter mulai proses injeksi daya ke grid."],
        [512, "Grid-connected", "Grid-Connected", "0 Alarm (Healthy)", "Grid-Connected", "Kondisi operasi normal penuh; inverter mengalirkan listrik ke beban/grid."],
        [513, "Grid-connected: power limited", "Derated", "Warning (Derated)", "Grid-Connected: Power Limited", "Inverter beroperasi dengan pembatasan daya dari dispatch jaringan."],
        [514, "Grid-connected: self-derating", "Derated", "Warning (Derated)", "Grid-Connected: Self-Derating", "Penurunan daya otomatis akibat suhu tinggi atau kondisi internal."],
        [515, "Off-grid operation", "Grid-Connected", "0 Alarm (Healthy)", "Off-Grid Operation", "Inverter beroperasi secara mandiri di luar jaringan."],
        [768, "Shutdown: on fault", "Fault", "Major Fault Alarm", "Shutdown: On Fault", "Inverter trip / mati akibat terjadi gangguan teknis."],
        [769, "Shutdown: on command", "Shutdown", "Minor Alarm", "Shutdown: On Command", "Inverter dimatikan secara manual melalui perintah SCADA/operator."],
        [770, "Shutdown: OVGR", "Fault", "Major Fault Alarm", "Shutdown: OVGR", "Shutdown akibat proteksi tegangan lebih grid."],
        [771, "Shutdown: communication interrupted", "Fault", "Major Fault Alarm", "Shutdown: Comm Interrupted", "Shutdown karena komunikasi dengan SmartLogger terputus."],
        [772, "Shutdown: power limited", "Shutdown", "Minor Alarm", "Shutdown: Power Limited", "Shutdown karena batasan daya nol dari grid."],
        [773, "Shutdown: manual startup required", "Fault", "Major Fault Alarm", "Shutdown: Manual Startup Required", "Inverter memerlukan restart manual di lapangan."],
        [774, "Shutdown: DC switch disconnected", "Fault", "Major Fault Alarm", "Shutdown: DC Switch Disconnected", "Saklar DC switch pada unit inverter terbuka/mati."],
        [775, "Shutdown: rapid shutdown", "Shutdown", "Minor Alarm", "Shutdown: Rapid Shutdown", "Inverter dimatikan lewat mekanisme emergency rapid shutdown."],
        [776, "Shutdown: input underpower", "Shutdown", "Minor Alarm", "Shutdown: Input Underpower", "Daya input DC terlalu rendah."],
        [777, "Shutdown: NS protection", "Fault", "Major Fault Alarm", "Shutdown: NS Protection", "Proteksi decoupling jaringan (NS) aktif."],
        [778, "Shutdown: commanded rapid shutdown", "Shutdown", "Minor Alarm", "Shutdown: Commanded Rapid", "Perintah rapid shutdown dari controller."],
        [1025, "Grid scheduling: cosψ-P curve", "Grid-Connected", "0 Alarm (Healthy)", "Grid Scheduling: cosψ-P", "Penjadwalan kurva faktor daya aktif."],
        [1026, "Grid scheduling: Q-U curve", "Grid-Connected", "0 Alarm (Healthy)", "Grid Scheduling: Q-U", "Penjadwalan kurva reaktif terhadap tegangan."],
        [1027, "Power grid scheduling: PF-U characteristic", "Grid-Connected", "0 Alarm (Healthy)", "Power Grid Scheduling", "Penjadwalan kurva karakteristik PF-U."],
        [1028, "Grid scheduling: dry contact", "Grid-Connected", "0 Alarm (Healthy)", "Grid Scheduling: Dry Contact", "Penjadwalan kontak relai kering."],
        [1029, "Power grid scheduling: Q-P characteristic", "Grid-Connected", "0 Alarm (Healthy)", "Power Grid Scheduling", "Penjadwalan kurva Q-P."],
        [1280, "Ready for terminal test", "Inspection", "0 Alarm (Healthy)", "Ready for Terminal Test", "Mode pengujian terminal."],
        [1281, "Terminal testing...", "Inspection", "0 Alarm (Healthy)", "Terminal Testing...", "Pengujian terminal sedang berlangsung."],
        [1536, "Inspection in progress", "Inspection", "0 Alarm (Healthy)", "Inspection in Progress", "Inpeksi rutin inverter sedang berjalan."],
        [1792, "AFCI self-check", "Inspection", "0 Alarm (Healthy)", "AFCI Self-Check", "Uji mandiri sensor proteksi busur api (Arc Fault)."],
        [2048, "I-V scanning", "Inspection", "0 Alarm (Healthy)", "I-V Scanning", "Pemindaian kurva arus-tegangan (I-V diagnosis) string panel."],
        [2304, "DC input detection", "Inspection", "0 Alarm (Healthy)", "DC Input Detection", "Deteksi kondisi rangkaian input DC."],
        [2560, "Off-grid charging", "Inspection", "0 Alarm (Healthy)", "Off-Grid Charging", "Mode pengisian daya off-grid."],
        [40960, "Standby: no irradiation", "Standby", "0 Alarm (Healthy) [FIXED]", "Standby: No Irradiation", "Standby normal saat malam/pagi hari tanpa radiasi matahari. BUKAN FAULT."],
        [40961, "Standby: no DC input", "Standby", "0 Alarm (Healthy)", "Standby: No DC Input", "Standby normal saat tidak ada input DC dari panel surya."],
        [45056, "Communication interrupted (SmartLogger)", "Fault", "Major Fault Alarm", "Comm Interrupted (SmartLogger)", "Komunikasi data antara inverter dan SmartLogger terputus."],
        [49152, "Loading... (SmartLogger)", "Inspection", "0 Alarm (Healthy)", "Loading... (SmartLogger)", "SmartLogger sedang memuat firmware atau konfigurasi."]
    ]

    for row in states_data:
        ws5.append(row)

    # ─────────────────────────────────────────────────────────────
    # FORMATTING STYLES, COLORS & COLUMN WIDTHS
    # ─────────────────────────────────────────────────────────────
    for ws in [ws1, ws2, ws3, ws4, ws5]:
        for row in ws.iter_rows(min_row=1, max_row=ws.max_row, min_col=1, max_col=ws.max_column):
            for cell in row:
                cell.border = thin_border
                val = str(cell.value or "")
                
                # Highlight status column in Sheets 2, 3, 4
                if "Ditampilkan di UI" in val:
                    cell.fill = ui_yes_fill
                    cell.font = ui_yes_font
                elif "Backend Only" in val:
                    cell.fill = ui_back_fill
                    cell.font = ui_back_font
                elif "Tersedia di API" in val:
                    cell.fill = ui_api_fill
                    cell.font = ui_api_font
                elif "0 Alarm (Healthy)" in val:
                    cell.fill = ui_yes_fill
                    cell.font = ui_yes_font
                elif "Major Fault Alarm" in val:
                    cell.fill = PatternFill(start_color="FEE2E2", end_color="FEE2E2", fill_type="solid") # Light Red
                    cell.font = Font(name="Calibri", size=10, bold=True, color="991B1B")
                elif "Warning (Derated)" in val:
                    cell.fill = ui_back_fill
                    cell.font = ui_back_font

        # Auto-adjust column widths
        for col in ws.columns:
            col_letter = get_column_letter(col[0].column)
            max_len = 0
            for cell in col:
                val_str = str(cell.value or "")
                if "\n" in val_str:
                    lines = val_str.split("\n")
                    max_len = max(max_len, max(len(l) for l in lines))
                else:
                    max_len = max(max_len, len(val_str))
            ws.column_dimensions[col_letter].width = min(max(max_len + 3, 10), 55)

    # Save workbook in workspace root
    out_path = "d:/msw/msw_eplant/FusionSolar_Data_Dictionary.xlsx"
    try:
        wb.save(out_path)
        print(f"SUCCESS: File Excel berhasil dibuat di {out_path}")
    except PermissionError:
        print(f"INFO: File {out_path} saat ini sedang dibuka di Microsoft Excel.")

if __name__ == "__main__":
    create_fusionsolar_excel()
