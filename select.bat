@echo off
setlocal enabledelayedexpansion
cd /d "%~dp0"

set "CACHE=working.txt"
set "TEST_URL=https://discord.com"

:: пути Discord
set "DC1=%LOCALAPPDATA%\Discord\Update.exe"
set "DC2=%APPDATA%\Discord\Update.exe"

:: функция понижения приоритета всех Discord процессов
set "LOWER_PS=powershell -Command "Get-Process discord -ErrorAction SilentlyContinue | ForEach-Object { $_.PriorityClass = 'Idle' }""

:: пробуем сохранённый вариант
if exist "%CACHE%" (
    set /p LAST=<"%CACHE%"
    if exist "!LAST!" (
        call "!LAST!" >nul 2>&1
        timeout /t 7 >nul

        curl -s --max-time 5 %TEST_URL% >nul 2>&1
        if not errorlevel 1 goto run_discord

        taskkill /f /im winws.exe >nul 2>&1
        timeout /t 2 >nul
    )
)

:: перебор
for %%f in (general*.bat) do (
    call "%%f" >nul 2>&1
    timeout /t 7 >nul

    curl -s --max-time 5 %TEST_URL% >nul 2>&1
    if not errorlevel 1 (
        echo %%f > "%CACHE%"
        goto run_discord
    )

    taskkill /f /im winws.exe >nul 2>&1
    timeout /t 2 >nul
)

exit

:run_discord
:: запуск Discord
if exist "%DC1%" (
    start "" "%DC1%" --processStart Discord.exe
) else if exist "%DC2%" (
    start "" "%DC2%" --processStart Discord.exe
)

:: ждём запуск процессов
timeout /t 5 >nul

:: понижаем приоритет ВСЕМ процессам Discord
%LOWER_PS%

exit