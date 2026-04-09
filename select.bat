@echo off
setlocal enabledelayedexpansion
cd /d "%~dp0"

set "CACHE=working.txt"
set "TEST_URL=discord.com"

:: ------------------------------------------------------------------
:: 1. Находим рабочий конфиг zapret (general*.bat)
:: ------------------------------------------------------------------

:: Если есть сохранённый рабочий конфиг
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

:: Поиск работающего конфига среди всех general*.bat
for %%f in (general*.bat) do (
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

:: Если ничего не сработало
msg * "Не найден рабочий конфиг zapret!"
exit /b

:: ------------------------------------------------------------------
:: 2. Запускаем Discord и ставим низкий приоритет ВСЕМ процессам
:: ------------------------------------------------------------------
:run_discord

:: Находим путь к Discord.exe
set "DISCORD_EXE="
for /d %%D in ("%LOCALAPPDATA%\Discord\app-*") do (
    if exist "%%D\Discord.exe" (
        set "DISCORD_EXE=%%D\Discord.exe"
        goto :found
    )
)

:: Если не нашли — пробуем старый способ
if exist "%LOCALAPPDATA%\Discord\Update.exe" (
    set "DISCORD_EXE=%LOCALAPPDATA%\Discord\Update.exe --processStart Discord.exe"
) else if exist "%APPDATA%\Discord\Update.exe" (
    set "DISCORD_EXE=%APPDATA%\Discord\Update.exe --processStart Discord.exe"
) else (
    msg * "Discord.exe не найден!"
    exit /b 1
)
:found

:: Запускаем Discord (без окна CMD)
start /b "" "%DISCORD_EXE%" >nul 2>&1

:: Ждём появления всех процессов Discord
timeout /t 5 /nobreak >nul

:: Устанавливаем низкий приоритет ВСЕМ процессам Discord
powershell -Command "Get-Process -Name discord, Discord*, *Discord* -ErrorAction SilentlyContinue | ForEach-Object { $_.PriorityClass = 'Idle' }" >nul 2>&1

:: Запускаем фоновый мониторинг приоритетов (окно не показывается)
start /b powershell -WindowStyle Hidden -Command "while ($true) { Get-Process -Name discord, Discord*, *Discord* -ErrorAction SilentlyContinue | ForEach-Object { $_.PriorityClass = 'Idle' }; Start-Sleep -Seconds 10 }" >nul 2>&1

:: Закрываем ВСЕ окна CMD, включая это
taskkill /f /im cmd.exe >nul 2>&1
exit
