@echo off
title MSW ePlant - Automation & Ingestion Tools
color 0B
cd /d "%~dp0"

:MENU
cls
echo ===============================================================================
echo                     MSW ePLANT - TOOL LAUNCHER (WINDOWS)
echo ===============================================================================
echo  Direktori: %~dp0
echo ===============================================================================
echo.
echo   [1] Test Koneksi Firebase RTDB (/solar_pv)
echo   [2] Sinkronisasi Data Solar PV 1x (Snapshot + Prune 7 Hari)
echo   [3] Jalankan Daemon Solar PV (Loop Otomatis Tiap 1 Jam di Background)
echo   [4] Jalankan Daemon Solar PV (Interval Kustom, misal tiap 10 Menit)
echo   [5] Inisialisasi Ulang / Seed Data Solar PV (7 Hari Historis)
echo.
echo   -----------------------------------------------------------------------------
echo   [6] Generate Ulang File Excel Inventaris Data (docs\msw_services_data_inventory.xlsx)
echo   [7] Buka File Excel Inventaris Data
echo.
echo   -----------------------------------------------------------------------------
echo   [8] Jalankan flutter test (Unit dan Widget Test Solar PV)
echo   [0] Keluar
echo.
echo ===============================================================================
set /p CHOICE="Pilih nomor menu [0-8]: "

if "%CHOICE%"=="1" goto TEST_CONN
if "%CHOICE%"=="2" goto SYNC_ONCE
if "%CHOICE%"=="3" goto RUN_DAEMON
if "%CHOICE%"=="4" goto RUN_DAEMON_CUSTOM
if "%CHOICE%"=="5" goto SEED_DATA
if "%CHOICE%"=="6" goto GEN_EXCEL
if "%CHOICE%"=="7" goto OPEN_EXCEL
if "%CHOICE%"=="8" goto RUN_TESTS
if "%CHOICE%"=="0" goto EXIT_PROMPT

echo.
echo [!] Pilihan tidak valid, silakan coba lagi.
timeout /t 2 >nul
goto MENU

:TEST_CONN
cls
echo ===============================================================================
echo   MENGUJI KONEKSI KE FIREBASE REALTIME DATABASE...
echo ===============================================================================
python scripts\solar_pv_sync.py --test
echo.
echo ===============================================================================
pause
goto MENU

:SYNC_ONCE
cls
echo ===============================================================================
echo   MENJALANKAN SINKRONISASI HOURLY SOLAR PV & PRUNING 7 HARI...
echo ===============================================================================
python scripts\solar_pv_sync.py --sync
echo.
echo ===============================================================================
pause
goto MENU

:RUN_DAEMON
cls
echo ===============================================================================
echo   MENJALANKAN DAEMON SOLAR PV (INTERVAL DEFAULT: 3600 DETIK / 1 JAM)...
echo   Tekan Ctrl + C untuk menghentikan proses kapan saja.
echo ===============================================================================
python scripts\solar_pv_sync.py --daemon
echo.
pause
goto MENU

:RUN_DAEMON_CUSTOM
cls
echo ===============================================================================
echo   MENJALANKAN DAEMON SOLAR PV DENGAN INTERVAL KUSTOM
echo ===============================================================================
set /p SECS="Masukkan interval sinkronisasi dalam detik (contoh: 600 untuk 10 menit): "
if "%SECS%"=="" set SECS=600
echo.
echo Menjalankan sinkronisasi setiap %SECS% detik...
echo Tekan Ctrl + C untuk menghentikan proses kapan saja.
echo.
python scripts\solar_pv_sync.py --daemon --interval %SECS%
echo.
pause
goto MENU

:SEED_DATA
cls
echo ===============================================================================
echo   PERINGATAN: INISIALISASI ULANG DATA 7 HARI (SEEDING)
echo ===============================================================================
echo Tindakan ini akan mengisi ulang data snapshot terbaru dan 7 hari bucket per jam
echo di node /solar_pv/latest dan /solar_pv/history.
echo.
set /p CONFIRM="Lanjutkan seeding? (Y/N): "
if /i not "%CONFIRM%"=="Y" (
    echo Dibatalkan.
    timeout /t 2 >nul
    goto MENU
)
python scripts\solar_pv_sync.py --seed
echo.
echo ===============================================================================
pause
goto MENU

:GEN_EXCEL
cls
echo ===============================================================================
echo   MEMBUAT ULANG DOKUMEN EXCEL INVENTARIS SERVICE...
echo ===============================================================================
python scripts\generate_service_inventory.py
echo.
echo ===============================================================================
pause
goto MENU

:OPEN_EXCEL
cls
if exist "docs\msw_services_data_inventory.xlsx" (
    echo Membuka docs\msw_services_data_inventory.xlsx ...
    start "" "docs\msw_services_data_inventory.xlsx"
) else (
    echo [!] File belum ditemukan. Membuat file terlebih dahulu...
    python scripts\generate_service_inventory.py
    start "" "docs\msw_services_data_inventory.xlsx"
)
timeout /t 2 >nul
goto MENU

:RUN_TESTS
cls
echo ===============================================================================
echo   MENJALANKAN FLUTTER TEST SOLAR PV & WIDGET SUITE...
echo ===============================================================================
C:\src\flutter\bin\flutter.bat test test/solar_trend_and_landscape_test.dart test/solar_detail_page_test.dart test/inverter_card_and_detail_test.dart test/fusion_solar_backend_test.dart
echo.
echo ===============================================================================
pause
goto MENU

:EXIT_PROMPT
cls
echo Terima kasih. Jendela ini dapat ditutup.
timeout /t 2 >nul
exit /b 0
