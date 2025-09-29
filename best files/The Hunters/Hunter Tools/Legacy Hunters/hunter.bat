@echo off
setlocal EnableExtensions EnableDelayedExpansion

rem =====================================================================
rem  Hunter Pack for Windows — report-first PC maintenance with safe fixes
rem  Modes:
rem    (no args)     -> REPORT ONLY
rem    /FIX          -> Safe fixes (temp, recycle bin, DNS cache, SSD TRIM, etc.)
rem    /DEEPFIX      -> Adds DISM StartComponentCleanup and SFC scan (longer)
rem    /RESTOREPOINT -> Create System Restore Point (needs admin & System Restore enabled)
rem    /SPEED        -> Switch to High Performance power plan (optional)
rem    /QUIET        -> Minimal console noise
rem =====================================================================

rem -------- Settings (you can tweak) ------------------------------------
set "LOG_DIR=%~dp0winhunter_reports"
set "TRACE_FILE=%~dp0winhunter_reports\hunt-events.ndjson"
set "TS="
for /f "tokens=1-3 delims=/- " %%a in ("%date%") do set "DATE=%%c-%%a-%%b"
for /f "tokens=1-2 delims=:." %%h in ("%time%") do set "TIME=%%h-%%i"
set "TS=%DATE%_%TIME%"

set "ALLOW_CLEAN_DIRS=%TEMP%;%LOCALAPPDATA%\Temp;C:\Windows\Temp;C:\Windows\SoftwareDistribution\Download"

rem -------- Args ---------------------------------------------------------
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

rem -------- Helpers ------------------------------------------------------
if not exist "%LOG_DIR%" mkdir "%LOG_DIR%"
set "MASTER_LOG=%LOG_DIR%\master_%TS%.log"
set "INSIGHTS=%LOG_DIR%\insights_%TS%.txt"

call :log "Hunter Pack — %MODE%  (RestorePoint=%MAKE_RP%  Speed=%SPEED%)"
call :log "Logs → %LOG_DIR%"
call :log "Trace → %TRACE_FILE%"

rem Admin check
net session >nul 2>&1 && (set "IS_ADMIN=1") || (set "IS_ADMIN=0")
if "%MODE%"=="REPORT" goto HUNT
if "%IS_ADMIN%"=="0" (
  call :log "Admin required for %MODE%. Relaunching elevated..."
  powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -ArgumentList '%*' -Verb RunAs"
  exit /b
)

:HUNT
rem -------- Hunters: each section reports; fix modes optionally act -------
call :hunter_storage
call :hunter_network
call :hunter_startup
call :hunter_health
call :hunter_power

if "%MODE%"=="FIX"     call :fix_safe
if "%MODE%"=="DEEPFIX" call :fix_safe & call :fix_deep

call :thinker

call :log ""
call :log "Done. Read: %INSIGHTS%"
exit /b 0

rem ============================ HUNTERS ===================================

:hunter_storage
set "MOD=storage"
call :section "%MOD%: disk & clutter"
call :trace "open" "%MOD%" "{\"topic\":\"storage\"}"

rem Free space per drive
for /f "tokens=1,3" %%D in ('wmic logicaldisk where "DriveType=3" get DeviceID^,FreeSpace /value ^| find "="') do (
  set "KV=%%D"
  set "VAL=%%E"
)
rem WMIC is deprecated but still present on many systems. Safer: use PowerShell for numbers.
powershell -NoProfile -Command ^
  "$d=Get-PSDrive -PSProvider FileSystem | Select Name,Used,Free; $d | ForEach-Object{ '{0}: Used={1:N0}MB Free={2:N0}MB' -f $_.Name, ($_.Used/1MB), ($_.Free/1MB)}" >> "%MASTER_LOG%"

rem Count temp files & recycle bin size
powershell -NoProfile -Command ^
  "$t1=(Get-ChildItem -Path $env:TEMP -Recurse -ErrorAction SilentlyContinue | Measure-Object Length -Sum).Sum;" ^
  "$t2=(Get-ChildItem -Path $env:LOCALAPPDATA\Temp -Recurse -ErrorAction SilentlyContinue | Measure-Object Length -Sum).Sum;" ^
  "$rb=(New-Object -ComObject Shell.Application).NameSpace(10).Items() | ForEach-Object{$_.Size} | Measure-Object -Sum | %% Sum;" ^
  "('{0} TEMP total ~ {1:N0} MB; Recycle Bin ~ {2:N0} MB' -f (Get-Date), (($t1+$t2)/1MB), ($rb/1MB))" >> "%MASTER_LOG%"

goto :eof

:hunter_network
set "MOD=network"
call :section "%MOD%: DNS & sockets"
call :trace "open" "%MOD%" "{\"topic\":\"network\"}"
ipconfig /displaydns | findstr /c":" >nul 2>&1 && (
  call :log "DNS cache present; flushing can help name-lookups after network changes."
) || (
  call :log "DNS cache view not available (policy or service)."
)
netstat -abno 2>nul | findstr LISTENING > "%LOG_DIR%\net_listening_%TS%.txt"
call :log "Listening sockets logged."
goto :eof

:hunter_startup
set "MOD=startup"
call :section "%MOD%: boot & autostart"
call :trace "open" "%MOD%" "{\"topic\":\"startup\"}"
call :log "Startup (registry):"
reg query HKCU\Software\Microsoft\Windows\CurrentVersion\Run > "%LOG_DIR%\startup_user_%TS%.txt" 2>nul
reg query HKLM\Software\Microsoft\Windows\CurrentVersion\Run > "%LOG_DIR%\startup_machine_%TS%.txt" 2>nul
call :log "Startup (scheduled tasks high impact):"
schtasks /query /fo csv | findstr /i "startup logon boot" > "%LOG_DIR%\startup_tasks_%TS%.csv" 2>nul
goto :eof

:hunter_health
set "MOD=health"
call :section "%MOD%: component store / file integrity (report)"
call :trace "open" "%MOD%" "{\"topic\":\"health\"}"
call :log "DISM /Online /Cleanup-Image /AnalyzeComponentStore (report-only):"
DISM /Online /Cleanup-Image /AnalyzeComponentStore >> "%MASTER_LOG%" 2>&1
call :log "SFC scan (verify-only, quick header):"
sfc /verifyonly >> "%MASTER_LOG%" 2>&1
goto :eof

:hunter_power
set "MOD=power"
call :section "%MOD%: power plan"
for /f "tokens=2 delims=:" %%a in ('powercfg /GETACTIVESCHEME ^| find ":"') do set "CURR_SCHEME=%%a"
call :log "Current scheme: !CURR_SCHEME!"
if "%SPEED%"=="1" (
  call :log "Request: switch to High performance (optional)"
) else (
  call :log "Tip: run with /SPEED to set High performance plan."
)
goto :eof

rem ============================ FIXERS ====================================

:fix_safe
call :section "FIX: safe cleanups"

if "%MAKE_RP%"=="1" (
  call :log "Creating restore point (Checkpoint-Computer)..."
  powershell -NoProfile -Command "Checkpoint-Computer -Description 'HunterPack' -RestorePointType 'MODIFY_SETTINGS'" >> "%MASTER_LOG%" 2>&1
)

call :log "Empty Recycle Bin..."
powershell -NoProfile -Command "Clear-RecycleBin -Force -ErrorAction SilentlyContinue" >> "%MASTER_LOG%" 2>&1

call :log "Flush DNS cache..."
ipconfig /flushdns >> "%MASTER_LOG%" 2>&1

call :log "Clean temp locations..."
for %%P in (%ALLOW_CLEAN_DIRS%) do call :clean_dir "%%~P"

call :log "SSD TRIM (retrim)..."
defrag C: /L /U >> "%MASTER_LOG%" 2>&1

if "%SPEED%"=="1" (
  call :log "Setting High performance power plan..."
  powercfg -setactive SCHEME_MIN >> "%MASTER_LOG%" 2>&1
)

goto :eof

:fix_deep
call :section "FIX: deep maintenance (can take a while)"

call :log "DISM StartComponentCleanup (without ResetBase)..."
DISM /Online /Cleanup-Image /StartComponentCleanup >> "%MASTER_LOG%" 2>&1

call :log "System File Checker (SFC /scannow)..."
sfc /scannow >> "%MASTER_LOG%" 2>&1

goto :eof

rem ============================ THINKER ===================================

:thinker
call :section "Thinker: Do-Next agenda"

rem Collect signals (very light)
set "BROKEN_LINKS=0"
set "TEMP_MB="
for /f "usebackq tokens=*" %%L in ("%MASTER_LOG%") do (
  echo %%L | findstr /i "broken link" >nul && set /a BROKEN_LINKS+=1
)

rem Pull TEMP size line produced earlier:
for /f "tokens=6 delims= " %%m in ('findstr /i "TEMP total" "%MASTER_LOG%"') do set "TEMP_MB=%%m"

> "%INSIGHTS%" (
  echo HUNTER DO-NEXT (report: %TS%)
  echo ------------------------------------------
  echo 1) Review startup entries:
  echo    - %LOG_DIR%\startup_user_%TS%.txt
  echo    - %LOG_DIR%\startup_machine_%TS%.txt
  echo    - %LOG_DIR%\startup_tasks_%TS%.csv
  echo.
  echo 2) Storage and clutter:
  if defined TEMP_MB (echo    - Temp estimate: !TEMP_MB! MB; run with /FIX to purge safely.)
  echo    - Check large downloads/videos; move to secondary drive if possible.
  echo.
  echo 3) Network:
  echo    - DNS flushed on /FIX; if app resolves slowly, try it.
  echo.
  echo 4) Health:
  echo    - DISM report and SFC verify recorded in master log.
  echo    - If corrupted files reported, run with /DEEPFIX (admin).
  echo.
  echo 5) Power:
  if "%SPEED%"=="1" (echo    - High performance set. Consider reverting to Balanced for battery life later.) else (echo    - Use /SPEED to switch to High performance during heavy work.)
  echo.
  echo Notes:
  echo    - This script is conservative by default. /DEEPFIX can take 10–30+ minutes.
  echo    - Always keep Windows Update current and GPU drivers up to date.
)

call :log "Wrote insights → %INSIGHTS%"
goto :eof

rem ============================ UTILITIES =================================

:section
if "%QUIET%"=="0" echo( & echo == %~1 ==
echo [SECTION] %~1 >> "%MASTER_LOG%"
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
>> "%TRACE_FILE%" echo {"t":"%DATE% %TIME%","module":"%MODULE%","op":"%OP%","data":%JSON%}
goto :eof

:clean_dir
set "TARGET=%~1"
if "%TARGET%"=="" goto :eof
if not exist "%TARGET%" (
  call :log "Skip (missing): %TARGET%"
  goto :eof
)
rem Guard: never allow root or drive roots
if "%TARGET:~1,1%"==":" if "%TARGET:~3%"=="" (
  call :log "Refusing to clean drive root: %TARGET%"
  goto :eof
)
call :log "Cleaning %TARGET% ..."
del /f /q /s "%TARGET%\*" >nul 2>&1
for /d %%D in ("%TARGET%\*") do rd /s /q "%%~fD" >nul 2>&1
goto :eof
