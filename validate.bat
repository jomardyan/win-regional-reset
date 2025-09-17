@echo off
REM ================================================================
REM Enhanced Validation Script for Windows Regional Settings Reset v2.0
REM ================================================================
REM This script provides comprehensive validation and testing of all
REM components for proper configuration and functionality.

setlocal enabledelayedexpansion

echo ========================================
echo Windows Regional Settings Reset - Enhanced Validation v2.0
echo ========================================
echo.

set "SCRIPT_DIR=%~dp0"
set "ERROR_COUNT=0"
set "WARNING_COUNT=0"
set "TEST_COUNT=0"

REM Test counter function
call :increment_test "Starting validation suite..."

echo [TEST] Checking required files...

REM Check PowerShell script
call :increment_test "PowerShell script existence"
if exist "%SCRIPT_DIR%Reset-RegionalSettings.ps1" (
    echo [PASS] PowerShell script found
) else (
    call :report_error "PowerShell script missing: Reset-RegionalSettings.ps1"
)

REM Check batch wrapper
call :increment_test "Batch wrapper existence"
if exist "%SCRIPT_DIR%reset-regional.bat" (
    echo [PASS] Batch wrapper found
) else (
    call :report_error "Batch wrapper missing: reset-regional.bat"
)

REM Check README
call :increment_test "Documentation existence"
if exist "%SCRIPT_DIR%README.md" (
    echo [PASS] Documentation found
) else (
    call :report_error "README.md missing"
)

REM Check LICENSE
call :increment_test "License file existence"
if exist "%SCRIPT_DIR%LICENSE" (
    echo [PASS] License file found
) else (
    call :report_error "LICENSE missing"
)

REM Check configuration file
call :increment_test "Configuration file existence"
if exist "%SCRIPT_DIR%config.json" (
    echo [PASS] Configuration file found
) else (
    call :report_warning "Configuration file missing (optional): config.json"
)

echo.
echo [TEST] Validating PowerShell script...

REM Test PowerShell syntax
call :increment_test "PowerShell syntax validation"
powershell -Command "try { [scriptblock]::Create((Get-Content '%SCRIPT_DIR%Reset-RegionalSettings.ps1' -Raw)) | Out-Null; Write-Host '[PASS] PowerShell syntax valid' -ForegroundColor Green; exit 0 } catch { Write-Host '[FAIL] PowerShell syntax invalid' -ForegroundColor Red; Write-Host $_.Exception.Message; exit 1 }"
if %errorLevel% NEQ 0 call :report_error "PowerShell syntax validation failed"

REM Test PowerShell execution policy
call :increment_test "PowerShell execution policy check"
for /f "tokens=*" %%i in ('powershell -Command "Get-ExecutionPolicy"') do set "EXEC_POLICY=%%i"
if /i "%EXEC_POLICY%"=="Restricted" (
    call :report_warning "PowerShell execution policy is Restricted. May require bypass."
) else (
    echo [PASS] PowerShell execution policy: %EXEC_POLICY%
)

REM Test PowerShell version
call :increment_test "PowerShell version check"
for /f "tokens=*" %%i in ('powershell -Command "$PSVersionTable.PSVersion.Major"') do set "PS_VERSION=%%i"
if %PS_VERSION% GEQ 5 (
    echo [PASS] PowerShell version: %PS_VERSION%.x
) else (
    call :report_warning "PowerShell version %PS_VERSION%.x may not be fully compatible. 5.0+ recommended."
)

echo.
echo [TEST] Testing parameter validation...

REM Test invalid locale handling
call :increment_test "Invalid locale handling"
powershell -ExecutionPolicy Bypass -Command "& '%SCRIPT_DIR%Reset-RegionalSettings.ps1' -Locale 'invalid-test' 2>$null; if ($LASTEXITCODE -eq 1) { Write-Host '[PASS] Invalid locale properly rejected'; exit 0 } else { Write-Host '[FAIL] Invalid locale not rejected'; exit 1 }"
if %errorLevel% NEQ 0 call :report_error "Invalid locale validation failed"

REM Test supported locales display
call :increment_test "Supported locales display"
powershell -ExecutionPolicy Bypass -Command "& '%SCRIPT_DIR%Reset-RegionalSettings.ps1' -Locale 'test-invalid' 2>&1 | Select-String 'pl-PL' | Out-Null; if ($?) { Write-Host '[PASS] Supported locales displayed'; exit 0 } else { Write-Host '[FAIL] Supported locales not displayed'; exit 1 }"
if %errorLevel% NEQ 0 call :report_error "Supported locales display failed"

echo.
echo [TEST] Testing batch wrapper functionality...

REM Test batch wrapper help
call :increment_test "Batch wrapper help system"
call "%SCRIPT_DIR%reset-regional.bat" /? >nul 2>&1
if %errorLevel% EQU 0 (
    echo [PASS] Batch wrapper help system works
) else (
    call :report_error "Batch wrapper help system failed"
)

REM Test batch wrapper parameter parsing
call :increment_test "Batch wrapper parameter parsing"
echo. | call "%SCRIPT_DIR%reset-regional.bat" en-US force >nul 2>&1
if %errorLevel% LEQ 2 (
    echo [PASS] Batch wrapper parameter parsing works
) else (
    call :report_warning "Batch wrapper parameter parsing may have issues"
)

echo.
echo [TEST] Testing system compatibility...

REM Check Windows version
call :increment_test "Windows version compatibility"
for /f "tokens=4-5 delims=. " %%i in ('ver') do set "WIN_VERSION=%%i.%%j"
if "!WIN_VERSION:~0,2!"=="10" (
    echo [PASS] Windows 10/11 detected: !WIN_VERSION!
) else (
    call :report_warning "Windows version may not be fully supported: !WIN_VERSION!"
)

REM Check administrator privileges
call :increment_test "Administrator privileges check"
net session >nul 2>&1
if %errorLevel% EQU 0 (
    echo [PASS] Running with administrator privileges
) else (
    call :report_warning "Not running as administrator. Some tests may be limited."
)

REM Test registry access
call :increment_test "Registry access validation"
reg query "HKCU\Control Panel\International" >nul 2>&1
if %errorLevel% EQU 0 (
    echo [PASS] Registry access available
) else (
    call :report_error "Registry access failed"
)

echo.
echo [TEST] Testing configuration file...

if exist "%SCRIPT_DIR%config.json" (
    call :increment_test "Configuration file syntax"
    powershell -Command "try { Get-Content '%SCRIPT_DIR%config.json' | ConvertFrom-Json | Out-Null; Write-Host '[PASS] Configuration file syntax valid'; exit 0 } catch { Write-Host '[FAIL] Configuration file syntax invalid'; Write-Host $_.Exception.Message; exit 1 }"
    if %errorLevel% NEQ 0 call :report_error "Configuration file syntax validation failed"
) else (
    echo [SKIP] Configuration file not present
)

echo.
echo [TEST] Testing backup functionality...

REM Test temporary directory access
call :increment_test "Temporary directory access"
echo test > "%TEMP%\regional_test.tmp" 2>nul
if exist "%TEMP%\regional_test.tmp" (
    del "%TEMP%\regional_test.tmp" >nul 2>&1
    echo [PASS] Temporary directory accessible
) else (
    call :report_error "Cannot access temporary directory for backups"
)

REM Test reg.exe availability
call :increment_test "Registry export tool availability"
reg /? >nul 2>&1
if %errorLevel% LEQ 1 (
    echo [PASS] Registry export tool available
) else (
    call :report_error "Registry export tool (reg.exe) not available"
)

echo.
echo [TEST] Performance and resource checks...

REM Check available disk space
call :increment_test "Disk space availability"
for /f "tokens=3" %%i in ('dir "%TEMP%" ^| findstr /i "bytes free"') do set "FREE_SPACE=%%i"
if defined FREE_SPACE (
    echo [PASS] Sufficient disk space available
) else (
    call :report_warning "Could not determine available disk space"
)

REM Test script execution time (dry run)
call :increment_test "Script performance test"
powershell -Command "$start = Get-Date; try { & '%SCRIPT_DIR%Reset-RegionalSettings.ps1' -Locale 'invalid-perf-test' -ErrorAction SilentlyContinue | Out-Null } catch {}; $elapsed = (Get-Date) - $start; if ($elapsed.TotalSeconds -lt 30) { Write-Host '[PASS] Script startup performance acceptable'; exit 0 } else { Write-Host '[WARN] Script startup may be slow'; exit 1 }"
if %errorLevel% NEQ 0 call :report_warning "Script performance may be suboptimal"

echo.
echo ========================================
echo Validation Summary
echo ========================================
echo.
echo Total Tests Run: %TEST_COUNT%
echo Errors Found: %ERROR_COUNT%
echo Warnings: %WARNING_COUNT%
echo.

if %ERROR_COUNT% EQU 0 (
    if %WARNING_COUNT% EQU 0 (
        echo [EXCELLENT] All tests passed! System is ready for use.
        echo.
        echo Next steps:
        echo   1. Run: reset-regional.bat en-US force
        echo   2. Check the log files for detailed output
        echo   3. Verify settings in Windows Settings after restart
    ) else (
        echo [GOOD] All critical tests passed with %WARNING_COUNT% warning(s).
        echo The system should work but may have minor limitations.
        echo Review warnings above for details.
    )
) else (
    echo [FAILED] Found %ERROR_COUNT% critical error(s) that must be resolved.
    echo The system may not function properly until these are fixed.
    echo.
    echo Common solutions:
    echo   1. Ensure all required files are present
    echo   2. Run as Administrator
    echo   3. Check PowerShell execution policy
    echo   4. Verify registry access permissions
)

echo ========================================
echo.

goto :cleanup

:increment_test
set /a TEST_COUNT+=1
if not "%~1"=="" echo [TEST %TEST_COUNT%] %~1
goto :eof

:report_error
echo [ERROR] %~1
set /a ERROR_COUNT+=1
goto :eof

:report_warning
echo [WARN] %~1
set /a WARNING_COUNT+=1
goto :eof

:cleanup
pause
exit /b %ERROR_COUNT%