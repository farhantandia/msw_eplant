@echo off
title MSW ePlant - Solar PV Firebase Sync
color 0A
cd /d "%~dp0"

echo ===============================================================================
echo                MSW ePLANT - SOLAR PV FIREBASE RTDB SYNC
echo ===============================================================================
echo.
python scripts\solar_pv_sync.py --sync
echo.
echo ===============================================================================
echo Selesai. Tekan sembarang tombol untuk menutup jendela ini...
pause >nul
