@echo off
setlocal enabledelayedexpansion
cd /d "%~dp0"

set "CACHE=working.txt"
set "TEST_URL=discord.com"

:: Находим прямой путь к Discord.exe (актуально для новых версий)
set "DISCORD_EXE="
for /d %%D in ("%LOCALAPPDATA%\Discord\app-*") do (
    if exist "%%D\Discord.exe" (
        set "DISCORD_EXE=%%D\Discord.exe"
        goto :found
    )
)
:: fallback на старый способ
if exist "%LOCALAPPDATA%\Discord\Update.exe" (
    set "DISCORD_EXE=%LOCALAPPDATA%\Discord\Update.exe --processStart Discord.exe"
) else if exist "%APPDATA%\Discord\Update.exe" (
    set "DISCORD_EXE=%APPDATA%\Discord\Update.exe --processStart Discord.exe"
) else (
    msg * "Discord не найден!"
    exit /b 1
)
:found

:: Используем ping вместо curl (надёжнее, всегда есть)
set "CHECK_CMD=ping -n 1 %TEST_URL%"

:: Если есть сохранённый рабочий конфиг
if exist "%CACHE%" (
    set /p LAST=<"%CACHE%"
    if exist "!LAST!" (
        call "!LAST!" >nul 2>&1
        timeout /t 7 /nobreak >nul
        %CHECK_CMD% >nul 2>&1
        if not errorlevel 1 goto :run
        taskkill /f /im winws.exe >nul 2>&1
        timeout /t 2 /nobreak >nul
    )
)

:: Поиск работающего конфига
for %%f in (general*.bat) do (
    call "%%f" >nul 2>&1
    timeout /t 7 /nobreak >nul
    %CHECK_CMD% >nul 2>&1
    if not errorlevel 1 (
        echo %%f > "%CACHE%"
        goto :run
    )
    taskkill /f /im winws.exe >nul 2>&1
    timeout /t 2 /nobreak >nul
)

:: Если ни один не подошёл – показываем ошибку и ждём
echo Нет рабочего конфига. Проверьте ваши general*.bat
pause
exit /b

:run
:: Запускаем Discord
start "" %DISCORD_EXE%

:: Ждём, пока процесс появится
timeout /t 5 /nobreak >nul

:: Понижаем приоритет
powershell -Command "Get-Process discord -ErrorAction SilentlyContinue | ForEach-Object { $_.PriorityClass = 'Idle' }"

exit
