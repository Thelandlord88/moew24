@echo off
setlocal EnableExtensions EnableDelayedExpansion

rem =====================================================================
rem  Hunter Pack for Windows 10 — report-first PC maintenance with safe fixes
rem  Modes:
rem    (no args)     -> REPORT ONLY
rem    /FIX          -> Safe fixes (temp, recycle bin, DNS cache, SSD TRIM, etc.)
rem    /DEEPFIX      -> Adds DISM StartComponentCleanup and SFC /scannow (longer)
rem    /RESTOREPOINT -> Create System Restore Point (needs admin & System Restore enabled)
rem    /SPEED        -> Switch to High Performance power plan (optional)
rem    /QUIET        -> Minimal console noise
rem =====================================================================

rem -------- Stable timestamp (locale-proof) --------------------------------
for /f %%t in ('powershell -NoProfile -Command "Get-Date -Format yyyy-MM-dd_HH-mm-ss"') do set "TS=%%t"

rem -------- Paths ----------------------------------------------------------
set "BASE=%~dp0"
set "LOG_DIR=%BASE%winhunter_reports"
set "TRACE_FILE=%LOG_DIR%\hunt-events.ndjson"
if not exist "%LOG_DIR%" mkdir "%LOG_DIR%"
set "MASTER_LOG=%LOG_DIR%\master_%TS%.log"
set "INSIGHTS=%LOG_DIR%\insights_%TS%.txt"

rem -------- Defaults & flags ----------------------------------------------
set "MODE=REPORT"
set "MAKE_RP=0"
set "SPEED=0"
set "QUIET=0"
for %%A in (%*) do (
  if /I "%%~A"=="/FIX"          set "MODE=FIX"
  if /I "%%~A"=="/DEEPFIX"      set "MODE=DEEPFIX"
  if /I "%%~A"=="/RESTOREPOINT" set "MAKE_RP=1"
  if /I "%%~A"=="/SPEED"        set "SPEED=1"
  if /I "%%~A"=="/QUIET"        set "QUIET=1"
)

rem -------- Clean targets (safe-only; edit to taste) -----------------------
set "ALLOW_CLEAN_DIRS=%TEMP%" "%LOCALAPPDATA%\Temp" "C:\Windows\Temp" "C:\Windows\SoftwareDistribution\Download"

rem -------- Header ---------------------------------------------------------
call :log "Hunter Pack - %MODE%  (RestorePoint=%MAKE_RP%  Speed=%SPEED%)"
call :log "Logs -> %LOG_DIR%"
call :log "Trace -> %TRACE_FILE%"

rem -------- Admin check & elevation for fix modes --------------------------
net session >nul 2>&1 && (set "IS_ADMIN=1") || (set "IS_ADMIN=0")
if not "%MODE%"=="REPORT" if "%IS_ADMIN%"=="0" (
  call :log "Admin required for %MODE%. Relaunching elevated..."
  powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -ArgumentList '%*' -Verb RunAs"
  exit /b
)

rem ============================== HUNTERS ==================================

call :hunter_storage
call :hunter_network
call :hunter_startup
call :hunter_health
call :hunter_power

if /I "%MODE%"=="FIX"     call :fix_safe
if /I "%MODE%"=="DEEPFIX" call :fix_safe & call :fix_deep

call :thinker
call :log ""
call :log "Done. See insights -> %INSIGHTS%"
exit /b 0

rem ============================ HUNTER: STORAGE ============================
:hunter_storage
set "MOD=storage"
call :section "%MOD%: disk + clutter"
call :trace "open" "%MOD%" "{\"topic\":\"storage\"}"

rem Drive usage (MB)
powershell -NoProfile -Command ^
  "$d=Get-PSDrive -PSProvider FileSystem | Select Name,Used,Free; " ^
  "$d | ForEach-Object{ '{0}: Used={1:N0}MB Free={2:N0}MB' -f $_.Name, ($_.Used/1MB), ($_.Free/1MB)}" >> "%MASTER_LOG%" 2>&1

rem Temp + Recycle Bin estimates
powershell -NoProfile -Command ^
  "$t1=(Get-ChildItem -Path $env:TEMP -Recurse -ErrorAction SilentlyContinue | Measure-Object Length -Sum).Sum; " ^
  "$t2=(Get-ChildItem -Path $env:LOCALAPPDATA\Temp -Recurse -ErrorAction SilentlyContinue | Measure-Object Length -Sum).Sum; " ^
  "$rbNS=(New-Object -ComObject Shell.Application).NameSpace(0xA); $rb=0; if($rbNS){$rbNS.Items()|%%{$rb+=$_.Size}}; " ^
  "Write-Output ('TEMP total ~ {0:N0} MB; Recycle Bin ~ {1:N0} MB' -f ((($t1+$t2)/1MB)), ($rb/1MB))" >> "%MASTER_LOG%" 2>&1
goto :eof

rem ============================ HUNTER: NETWORK ============================
:hunter_network
set "MOD=network"
call :section "%MOD%: DNS + sockets"
call :trace "open" "%MOD%" "{\"topic\":\"network\"}"

ipconfig /displaydns >nul 2>&1 && (
  call :log "DNS cache present; flushing can help after VPN/wifi changes."
) || (
  call :log "DNS cache view not available (service or policy)."
)

if "%IS_ADMIN%"=="1" (
  netstat -abno 2>nul | findstr /R /C:"LISTENING" > "%LOG_DIR%\net_listening_%TS%.txt"
) else (
  netstat -ano 2>nul | findstr /R /C:"LISTENING" > "%LOG_DIR%\net_listening_%TS%.txt"
)
call :log "Listening sockets logged -> %LOG_DIR%\net_listening_%TS%.txt"
goto :eof

rem ============================ HUNTER: STARTUP ===========================
:hunter_startup
set "MOD=startup"
call :section "%MOD%: boot + autostart"
call :trace "open" "%MOD%" "{\"topic\":\"startup\"}"

reg query HKCU\Software\Microsoft\Windows\CurrentVersion\Run > "%LOG_DIR%\startup_user_%TS%.txt" 2>nul
reg query HKLM\Software\Microsoft\Windows\CurrentVersion\Run > "%LOG_DIR%\startup_machine_%TS%.txt" 2>nul
schtasks /query /fo csv > "%LOG_DIR%\startup_tasks_%TS%.csv" 2>nul

call :log "Startup lists:"
call :log " - %LOG_DIR%\startup_user_%TS%.txt"
call :log " - %LOG_DIR%\startup_machine_%TS%.txt"
call :log " - %LOG_DIR%\startup_tasks_%TS%.csv"
goto :eof

rem ============================= HUNTER: HEALTH ===========================
:hunter_health
set "MOD=health"
call :section "%MOD%: component store + file integrity (report)"
call :trace "open" "%MOD%" "{\"topic\":\"health\"}"

DISM /Online /Cleanup-Image /AnalyzeComponentStore >> "%MASTER_LOG%" 2>&1
sfc /verifyonly >> "%MASTER_LOG%" 2>&1
goto :eof

rem ============================= HUNTER: POWER ============================
:hunter_power
set "MOD=power"
call :section "%MOD%: power plan"
for /f "tokens=2 delims=:" %%a in ('powercfg /GETACTIVESCHEME ^| find ":"') do set "CURR_SCHEME=%%a"
call :log "Current scheme:%CURR_SCHEME%"
if "%SPEED%"=="1" ( call :log "Request queued: High performance plan on /FIX" ) else ( call :log "Tip: add /SPEED with /FIX to set High performance temporarily." )
goto :eof

rem ================================ FIXERS ================================
:fix_safe
call :section "FIX: safe cleanups"

if "%MAKE_RP%"=="1" (
  call :log "Creating restore point..."
  powershell -NoProfile -Command "Checkpoint-Computer -Description 'HunterPack' -RestorePointType 'MODIFY_SETTINGS'" >> "%MASTER_LOG%" 2>&1
)

call :log "Emptying Recycle Bin..."
powershell -NoProfile -Command "Clear-RecycleBin -Force -ErrorAction SilentlyContinue" >> "%MASTER_LOG%" 2>&1

call :log "Flushing DNS cache..."
ipconfig /flushdns >> "%MASTER_LOG%" 2>&1

call :log "Cleaning temp locations..."
for %%P in (%ALLOW_CLEAN_DIRS%) do call :clean_dir %%~P

call :log "SSD TRIM (retrim C:)..."
defrag C: /L /U >> "%MASTER_LOG%" 2>&1

if "%SPEED%"=="1" (
  call :log "Setting High performance power plan..."
  powercfg -setactive SCHEME_MIN >> "%MASTER_LOG%" 2>&1
)
goto :eof

:fix_deep
call :section "FIX: deep maintenance (longer)"
call :log "DISM StartComponentCleanup (no ResetBase)..."
DISM /Online /Cleanup-Image /StartComponentCleanup >> "%MASTER_LOG%" 2>&1

call :log "System File Checker (SFC /scannow)..."
sfc /scannow >> "%MASTER_LOG%" 2>&1
goto :eof

rem =============================== THINKER ================================
:thinker
call :section "Thinker: Do-Next agenda"

rem quick pulls for insights
set "TEMP_LINE="
for /f "usebackq tokens=* delims=" %%L in ("%MASTER_LOG%") do (
  echo %%L | findstr /i "TEMP total ~" >nul && set "TEMP_LINE=%%L"
)

> "%INSIGHTS%" (
  echo HUNTER DO-NEXT  (%TS%)
  echo ------------------------------------------
  echo 1) Review startup entries:
  echo    - %LOG_DIR%\startup_user_%TS%.txt
  echo    - %LOG_DIR%\startup_machine_%TS%.txt
  echo    - %LOG_DIR%\startup_tasks_%TS%.csv
  echo.
  echo 2) Storage and clutter:
  if defined TEMP_LINE echo    - !TEMP_LINE!
  echo    - Consider moving large downloads/videos to another drive.
  echo.
  echo 3) Network:
  echo    - If lookups feel slow after VPN/wifi changes, run with /FIX to flush DNS.
  echo.
  echo 4) Health:
  echo    - DISM analyze and SFC verify recorded in master log.
  echo    - If corruption found, use /DEEPFIX (admin).
  echo.
  echo 5) Power:
  if "%SPEED%"=="1" (echo    - High performance will be set during /FIX.) else (echo    - Use /SPEED with /FIX to set High performance temporarily.)
  echo.
  echo Notes:
  echo    - /FIX performs safe cleanups only (temp, bin, DNS, TRIM).
  echo    - /DEEPFIX adds DISM cleanup + SFC repair; can take 10-30+ minutes.
)

call :log "Wrote insights -> %INSIGHTS%"
goto :eof

rem ============================== UTILITIES ===============================
:section
if "%QUIET%"=="0" echo( & echo == %~1 ==
echo [SECTION] %~1>> "%MASTER_LOG%"
goto :eof

:log
if "%QUIET%"=="0" echo %~1
echo %~1>> "%MASTER_LOG%"
goto :eof

:trace
rem :trace <op> <module> <json>
set "OP=%~1"
set "MODULE=%~2"
set "JSON=%~3"
>> "%TRACE_FILE%" echo {"t":"%TS%","module":"%MODULE%","op":"%OP%","data":%JSON%}
goto :eof

:clean_dir
set "TARGET=%~1"
if "%TARGET%"=="" goto :eof
if not exist "%TARGET%" (
  call :log "Skip (missing): %TARGET%"
  goto :eof
)
rem guard against drive root wipes
if "%TARGET:~1,1%"==":" if "%TARGET:~3%"=="" (
  call :log "Refusing to clean drive root: %TARGET%"
  goto :eof
)
call :log "Cleaning %TARGET% ..."
del /f /q /s "%TARGET%\*" >nul 2>&1
for /d %%D in ("%TARGET%\*") do rd /s /q "%%~fD" >nul 2>&1
goto :eof
