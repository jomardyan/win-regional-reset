@echo off
REM ================================================================
REM Validation Script for Windows Regional Settings Reset
REM ================================================================
REM This script validates that all components are properly configured
REM and ready for use.

echo ========================================
echo Windows Regional Settings Reset - Validation
echo ========================================
echo.

set "SCRIPT_DIR=%~dp0"
set "ERROR_COUNT=0"

echo Checking required files...

REM Check PowerShell script
if exist "%SCRIPT_DIR%Reset-RegionalSettings.ps1" (
    echo [OK] PowerShell script found
) else (
    echo [ERROR] PowerShell script missing
    set /a ERROR_COUNT+=1
)

REM Check batch wrapper
if exist "%SCRIPT_DIR%reset-regional.bat" (
    echo [OK] Batch wrapper found
) else (
    echo [ERROR] Batch wrapper missing
    set /a ERROR_COUNT+=1
)

REM Check README
if exist "%SCRIPT_DIR%README.md" (
    echo [OK] Documentation found
) else (
    echo [ERROR] README.md missing
    set /a ERROR_COUNT+=1
)

REM Check LICENSE
if exist "%SCRIPT_DIR%LICENSE" (
    echo [OK] License file found
) else (
    echo [ERROR] LICENSE missing
    set /a ERROR_COUNT+=1
)

echo.
echo Validating PowerShell syntax...

powershell -Command "try { [scriptblock]::Create((Get-Content '%SCRIPT_DIR%Reset-RegionalSettings.ps1' -Raw)) | Out-Null; Write-Host '[OK] PowerShell syntax valid' -ForegroundColor Green } catch { Write-Host '[ERROR] PowerShell syntax invalid' -ForegroundColor Red; Write-Host $_.Exception.Message; exit 1 }"

if %errorLevel% NEQ 0 (
    set /a ERROR_COUNT+=1
)

echo.
echo Testing locale validation...

powershell -Command "& '%SCRIPT_DIR%Reset-RegionalSettings.ps1' -Locale 'invalid-test' 2>nul"
if %errorLevel% EQU 1 (
    echo [OK] Locale validation working
) else (
    echo [ERROR] Locale validation failed
    set /a ERROR_COUNT+=1
)

echo.
echo Testing supported locales display...

powershell -Command "& '%SCRIPT_DIR%Reset-RegionalSettings.ps1' -Locale 'test-invalid' 2>&1 | Select-String 'pl-PL' | Out-Null; if ($?) { Write-Host '[OK] Supported locales displayed' } else { Write-Host '[ERROR] Supported locales not displayed'; exit 1 }"

if %errorLevel% NEQ 0 (
    set /a ERROR_COUNT+=1
)

echo.
echo ========================================
if %ERROR_COUNT% EQU 0 (
    echo Validation Result: PASSED
    echo All components are ready for use.
) else (
    echo Validation Result: FAILED
    echo Found %ERROR_COUNT% error(s).
)
echo ========================================
echo.

pause
exit /b %ERROR_COUNT%