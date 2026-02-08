@echo off
setlocal enabledelayedexpansion

if "%~1"=="" (
    echo Usage: decompile_all.bat ^<directory^> [threads]
    echo Recursively decompiles all .xvmc files to .xvm
    echo Default threads: %NUMBER_OF_PROCESSORS%
    exit /b 1
)

set "DIR=%~1"
set "MAX_JOBS=%~2"
if "%MAX_JOBS%"=="" set "MAX_JOBS=%NUMBER_OF_PROCESSORS%"

set "TOOLDIR=%~dp0"
set "LOGDIR=%TEMP%\xvm_decompile_%RANDOM%"
mkdir "%LOGDIR%" 2>nul

echo Decompiling .xvmc files in: %DIR%
echo Threads: %MAX_JOBS%
echo.

set /a TOTAL=0
for /r "%DIR%" %%F in (*.xvmc) do set /a TOTAL+=1
echo Found %TOTAL% files.
echo.

set /a RUNNING=0
set /a LAUNCHED=0

for /r "%DIR%" %%F in (*.xvmc) do (
    set /a LAUNCHED+=1
    echo [!LAUNCHED!/%TOTAL%] %%F

    start /b "" cmd /c ""%TOOLDIR%Gibbed.MadMax.XvmDecompile.exe" "%%F" "%%~dpnF.xvm" >nul 2>&1 && echo OK>"!LOGDIR!\%%~nF.ok" || echo FAIL>"!LOGDIR!\%%~nF.fail""

    set /a RUNNING+=1
    if !RUNNING! geq %MAX_JOBS% (
        call :wait_any
    )
)

:wait_all
if !RUNNING! gtr 0 call :wait_any & goto wait_all

set /a OK=0
set /a ERRORS=0
for %%F in ("%LOGDIR%\*.ok") do set /a OK+=1
for %%F in ("%LOGDIR%\*.fail") do (
    set /a ERRORS+=1
    echo FAILED: %%~nF
)

rd /s /q "%LOGDIR%" 2>nul

echo.
echo Done. %OK% succeeded, %ERRORS% failed, %TOTAL% total.
exit /b 0

:wait_any
set /a DONE=0
for %%F in ("%LOGDIR%\*.ok" "%LOGDIR%\*.fail") do set /a DONE+=1
if !DONE! lss !LAUNCHED! (
    timeout /t 0 /nobreak >nul
    goto wait_any
)
set /a RUNNING=0
exit /b 0
