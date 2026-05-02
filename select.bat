@echo off
setlocal enabledelayedexpansion
cd /d "%~dp0"

set "CACHE=working.txt"
set "TEST_URL=discord.com"
if exist "%CACHE%" (
    set /p LAST=<"%CACHE%"
    if exist "!LAST!" (
        start /min "!LAST!" cmd /c "!LAST!" >nul 2>&1
        timeout /t 7 /nobreak >nul
        ping -n 1 %TEST_URL% >nul 2>&1
        if not errorlevel 1 goto :run_discord
        taskkill /f /im winws.exe >nul 2>&1
        timeout /t 2 /nobreak >nul
    )
)

setlocal enabledelayedexpansion
set "variants=general (ALT11).bat general (ALT10).bat general (ALT9).bat general (ALT8).bat general (ALT7).bat general (ALT6).bat general (ALT5).bat general (ALT4).bat general (ALT3).bat general (ALT2).bat general (ALT).bat general (FAKE TLS AUTO ALT3).bat general (FAKE TLS AUTO ALT2).bat general (FAKE TLS AUTO ALT).bat general (FAKE TLS AUTO).bat general (SIMPLE FAKE ALT2).bat general (SIMPLE FAKE ALT).bat general (SIMPLE FAKE).bat general.bat"

for %%f in (!variants!) do (
    if exist "%%f" (
        start /min "%%f" cmd /c "%%f" >nul 2>&1
        timeout /t 7 /nobreak >nul
        ping -n 1 %TEST_URL% >nul 2>&1
        if not errorlevel 1 (
            echo %%f > "%CACHE%"
            goto :run_discord
        )
        taskkill /f /im winws.exe >nul 2>&1
        timeout /t 2 /nobreak >nul
    )
)

msg * "No working variant found!"
exit /b

:run_discord
set "DISCORD_EXE="
for /d %%D in ("%LOCALAPPDATA%\Discord\app-*") do (
    if exist "%%D\Discord.exe" (
        set "DISCORD_EXE=%%D\Discord.exe"
        goto :found
    )
)

if exist "%LOCALAPPDATA%\Discord\Update.exe" (
    set "DISCORD_EXE=%LOCALAPPDATA%\Discord\Update.exe --processStart Discord.exe"
) else if exist "%APPDATA%\Discord\Update.exe" (
    set "DISCORD_EXE=%APPDATA%\Discord\Update.exe --processStart Discord.exe"
) else (
    msg * "Discord.exe not found!"
    exit /b 1
)
:found

start /b "" "%DISCORD_EXE%" >nul 2>&1

timeout /t 5 /nobreak >nul
powershell -Command "Get-Process -Name discord, Discord*, *Discord* -ErrorAction SilentlyContinue | ForEach-Object { $_.PriorityClass = 'Idle' }" >nul 2>&1

start /b powershell -WindowStyle Hidden -Command "while ($true) { Get-Process -Name discord, Discord*, *Discord* -ErrorAction SilentlyContinue | ForEach-Object { $_.PriorityClass = 'Idle' }; Start-Sleep -Seconds 10 }" >nul 2>&1
taskkill /f /im cmd.exe >nul 2>&1
exit
