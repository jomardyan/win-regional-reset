@echo off
setlocal enabledelayedexpansion

REM ================================================================
REM Group Policy Regional Settings Deployment Wrapper v1.0
REM ================================================================
REM This batch file provides Group Policy compatible deployment
REM of the Windows Regional Settings Reset toolkit for enterprise
REM Active Directory environments.
REM
REM Usage:
REM   deploy-regional-gp.bat [locale] [profile] [options]
REM
REM Parameters:
REM   locale      - Target locale (e.g., pl-PL, en-US, de-DE)
REM   profile     - Configuration profile (Enterprise, Corporate, Standard, Minimal)
REM   options     - Additional options:
REM                 compliance=SOX|HIPAA|ISO27001|Standard
REM                 target=User|Computer|Both
REM                 networklog=\\server\path
REM                 dryrun
REM                 reporting
REM
REM Examples:
REM   deploy-regional-gp.bat                              - Enterprise deployment with defaults
REM   deploy-regional-gp.bat en-US Enterprise             - US English with Enterprise profile
REM   deploy-regional-gp.bat de-DE Corporate compliance=SOX - German with SOX compliance
REM   deploy-regional-gp.bat dryrun                       - Test run without changes
REM   deploy-regional-gp.bat /?                           - Show this help
REM ================================================================

set "VERSION=1.0"
set "SCRIPT_NAME=Group Policy Regional Settings Deployment"
set "ERROR_LEVEL=0"
set "EXIT_CODE=0"

REM Parse help request first
if "%~1"=="/?" goto :show_help
if "%~1"=="-h" goto :show_help
if "%~1"=="--help" goto :show_help
if "%~1"=="help" goto :show_help

REM Initialize variables with enterprise defaults
set "LOCALE=en-US"
set "PROFILE=Enterprise"
set "COMPLIANCE_MODE=Standard"
set "TARGET=Both"
set "NETWORK_LOG_PATH="
set "DRY_RUN=0"
set "REPORTING=0"
set "SILENT_MODE=1"
set "DEPLOYMENT_ID=%RANDOM%%RANDOM%"

REM Get script directory
set "SCRIPT_DIR=%~dp0"
set "PS_SCRIPT=%SCRIPT_DIR%Deploy-RegionalSettings-GP.ps1"

REM Show banner for interactive sessions
if defined SESSIONNAME (
    echo.
    echo ========================================
    echo %SCRIPT_NAME% v%VERSION%
    echo ========================================
    echo Deployment ID: %DEPLOYMENT_ID%
    echo.
)

REM Check if running in Group Policy context
if defined GP_MACHINE_EXTENSION_NAMES (
    echo [GP] Detected Group Policy Machine Extension context
    set "SILENT_MODE=1"
)

if defined GP_USER_EXTENSION_NAMES (
    echo [GP] Detected Group Policy User Extension context
    set "SILENT_MODE=1"
)

REM Check administrative privileges
net session >nul 2>&1
if %errorLevel% NEQ 0 (
    echo ERROR: Administrative privileges required for Group Policy deployment
    echo.
    echo This script must be run with elevated permissions in:
    echo - Computer Configuration\Policies\Windows Settings\Scripts\Startup
    echo - Computer Configuration\Policies\Windows Settings\Scripts\Shutdown
    echo - User Configuration\Policies\Windows Settings\Scripts\Logon
    echo - User Configuration\Policies\Windows Settings\Scripts\Logoff
    echo.
    exit /b 1
)

REM Check if PowerShell script exists
if not exist "%PS_SCRIPT%" (
    echo ERROR: Group Policy PowerShell script not found: %PS_SCRIPT%
    echo.
    echo Please ensure the following files are present:
    echo - Deploy-RegionalSettings-GP.ps1
    echo - ../scripts/Reset-RegionalSettings.ps1
    echo - ../config/config-gp-template.json
    echo.
    exit /b 1
)

REM Enhanced parameter parsing for Group Policy deployment
set "PARAM_COUNT=0"
for %%i in (%*) do set /a PARAM_COUNT+=1

REM Parse all parameters
set "PARAM_INDEX=1"
:parse_params
if %PARAM_INDEX% GTR %PARAM_COUNT% goto :params_done

REM Get current parameter
set "CURRENT_PARAM="
for /f "tokens=%PARAM_INDEX%" %%i in ("%*") do set "CURRENT_PARAM=%%i"

REM Check for dry run mode
echo %CURRENT_PARAM% | findstr /i "^dryrun$" >nul
if %errorLevel% EQU 0 (
    set "DRY_RUN=1"
    goto :next_param
)

REM Check for reporting mode
echo %CURRENT_PARAM% | findstr /i "^reporting$" >nul
if %errorLevel% EQU 0 (
    set "REPORTING=1"
    goto :next_param
)

REM Check for compliance mode
echo %CURRENT_PARAM% | findstr /i "^compliance=" >nul
if %errorLevel% EQU 0 (
    for /f "tokens=2 delims==" %%a in ("%CURRENT_PARAM%") do set "COMPLIANCE_MODE=%%a"
    goto :next_param
)

REM Check for target mode
echo %CURRENT_PARAM% | findstr /i "^target=" >nul
if %errorLevel% EQU 0 (
    for /f "tokens=2 delims==" %%a in ("%CURRENT_PARAM%") do set "TARGET=%%a"
    goto :next_param
)

REM Check for network log path
echo %CURRENT_PARAM% | findstr /i "^networklog=" >nul
if %errorLevel% EQU 0 (
    for /f "tokens=2 delims==" %%a in ("%CURRENT_PARAM%") do set "NETWORK_LOG_PATH=%%a"
    goto :next_param
)

REM Check for locale codes
echo %CURRENT_PARAM% | findstr /i "^[a-z][a-z]-[A-Z][A-Z]$" >nul
if %errorLevel% EQU 0 (
    set "LOCALE=%CURRENT_PARAM%"
    goto :next_param
)

REM Check for profile names
echo %CURRENT_PARAM% | findstr /i "^Enterprise$\|^Corporate$\|^Standard$\|^Minimal$" >nul
if %errorLevel% EQU 0 (
    set "PROFILE=%CURRENT_PARAM%"
    goto :next_param
)

REM Unknown parameter
echo WARNING: Unknown parameter ignored: %CURRENT_PARAM%

:next_param
set /a PARAM_INDEX+=1
goto :parse_params

:params_done

REM Validate configuration
echo [INFO] Validating Group Policy deployment configuration...
echo [INFO] Locale: %LOCALE%
echo [INFO] Profile: %PROFILE%
echo [INFO] Compliance Mode: %COMPLIANCE_MODE%
echo [INFO] Target: %TARGET%
if defined NETWORK_LOG_PATH echo [INFO] Network Log Path: %NETWORK_LOG_PATH%
if %DRY_RUN%==1 echo [INFO] Dry Run Mode: Enabled
if %REPORTING%==1 echo [INFO] Reporting Mode: Enabled

REM Validate locale
echo %LOCALE% | findstr /i "^pl-PL$\|^en-US$\|^en-GB$\|^de-DE$\|^fr-FR$\|^es-ES$\|^it-IT$\|^pt-PT$\|^ru-RU$\|^zh-CN$\|^ja-JP$\|^ko-KR$" >nul
if %errorLevel% NEQ 0 (
    echo ERROR: Unsupported locale: %LOCALE%
    echo.
    echo Supported locales for Group Policy deployment:
    echo   pl-PL  - Polish (Poland)
    echo   en-US  - English (United States) [Default]
    echo   en-GB  - English (United Kingdom)
    echo   de-DE  - German (Germany)
    echo   fr-FR  - French (France)
    echo   es-ES  - Spanish (Spain)
    echo   it-IT  - Italian (Italy)
    echo   pt-PT  - Portuguese (Portugal)
    echo   ru-RU  - Russian (Russia)
    echo   zh-CN  - Chinese (Simplified)
    echo   ja-JP  - Japanese (Japan)
    echo   ko-KR  - Korean (Korea)
    echo.
    exit /b 1
)

REM Check PowerShell version and execution policy
echo [INFO] Checking PowerShell environment...
for /f "tokens=*" %%i in ('powershell -Command "$PSVersionTable.PSVersion.Major"') do set "PS_VERSION=%%i"
if %PS_VERSION% LSS 5 (
    echo ERROR: PowerShell 5.0 or higher required for Group Policy deployment
    echo Current version: %PS_VERSION%
    echo.
    exit /b 1
)

REM Build PowerShell command with enterprise parameters
set "PS_COMMAND=powershell.exe -ExecutionPolicy Bypass -NonInteractive -NoProfile -WindowStyle Hidden"
set "PS_PARAMS=-Locale \"%LOCALE%\" -ConfigurationProfile \"%PROFILE%\" -ComplianceMode \"%COMPLIANCE_MODE%\" -DeploymentTarget \"%TARGET%\""

if defined NETWORK_LOG_PATH (
    set "PS_PARAMS=%PS_PARAMS% -NetworkLogPath \"%NETWORK_LOG_PATH%\""
)

if %DRY_RUN%==1 (
    set "PS_PARAMS=%PS_PARAMS% -DryRun"
)

if %REPORTING%==1 (
    set "PS_PARAMS=%PS_PARAMS% -ReportingEnabled"
)

REM Create deployment log entry
echo [%DATE% %TIME%] Starting Group Policy Regional Settings Deployment >> "%TEMP%\RegionalSettings-GP-Wrapper.log"
echo [%DATE% %TIME%] Deployment ID: %DEPLOYMENT_ID% >> "%TEMP%\RegionalSettings-GP-Wrapper.log"
echo [%DATE% %TIME%] Parameters: %PS_PARAMS% >> "%TEMP%\RegionalSettings-GP-Wrapper.log"

REM Execute Group Policy PowerShell script
echo [INFO] Executing Group Policy deployment script...
echo [DEBUG] Command: %PS_COMMAND% -File "%PS_SCRIPT%" %PS_PARAMS%

REM Create a temporary script to capture exit codes properly
set "TEMP_SCRIPT=%TEMP%\deploy-regional-gp-%DEPLOYMENT_ID%.ps1"
echo try { > "%TEMP_SCRIPT%"
echo   ^& "%PS_SCRIPT%" %PS_PARAMS% >> "%TEMP_SCRIPT%"
echo   exit $LASTEXITCODE >> "%TEMP_SCRIPT%"
echo } catch { >> "%TEMP_SCRIPT%"
echo   Write-Host "ERROR: $_" -ForegroundColor Red >> "%TEMP_SCRIPT%"
echo   exit 1 >> "%TEMP_SCRIPT%"
echo } >> "%TEMP_SCRIPT%"

%PS_COMMAND% -File "%TEMP_SCRIPT%"
set "PS_EXIT_CODE=%errorLevel%"

REM Clean up temporary script
if exist "%TEMP_SCRIPT%" del "%TEMP_SCRIPT%" >nul 2>&1

REM Log deployment result
echo [%DATE% %TIME%] Deployment completed with exit code: %PS_EXIT_CODE% >> "%TEMP%\RegionalSettings-GP-Wrapper.log"

REM Handle exit codes and reporting
if %PS_EXIT_CODE%==0 (
    echo [SUCCESS] Group Policy regional settings deployment completed successfully
    echo [INFO] Deployment ID: %DEPLOYMENT_ID%
    echo [INFO] Locale applied: %LOCALE%
    echo [INFO] Profile used: %PROFILE%
    
    REM Write success to Application Event Log
    powershell -Command "Write-EventLog -LogName Application -Source 'RegionalSettings-GP' -EntryType Information -EventId 1001 -Message 'Group Policy regional settings deployment completed successfully. Deployment ID: %DEPLOYMENT_ID%, Locale: %LOCALE%, Profile: %PROFILE%'" 2>nul
    
    set "EXIT_CODE=0"
) else (
    echo [ERROR] Group Policy regional settings deployment failed
    echo [ERROR] Exit code: %PS_EXIT_CODE%
    echo [ERROR] Deployment ID: %DEPLOYMENT_ID%
    echo [ERROR] Check logs for detailed error information
    
    REM Write error to Application Event Log
    powershell -Command "Write-EventLog -LogName Application -Source 'RegionalSettings-GP' -EntryType Error -EventId 1002 -Message 'Group Policy regional settings deployment failed. Deployment ID: %DEPLOYMENT_ID%, Exit Code: %PS_EXIT_CODE%'" 2>nul
    
    set "EXIT_CODE=%PS_EXIT_CODE%"
)

REM Group Policy deployment summary
if %SILENT_MODE%==0 (
    echo.
    echo ========================================
    echo Group Policy Deployment Summary
    echo ========================================
    echo Deployment ID: %DEPLOYMENT_ID%
    echo Locale: %LOCALE%
    echo Profile: %PROFILE%
    echo Compliance Mode: %COMPLIANCE_MODE%
    echo Target: %TARGET%
    echo Status: %EXIT_CODE%
    if %DRY_RUN%==1 echo Mode: Dry Run (No Changes Made)
    echo ========================================
    echo.
)

REM Exit with appropriate code for Group Policy processing
echo [INFO] Group Policy deployment wrapper exiting with code: %EXIT_CODE%
exit /b %EXIT_CODE%

:show_help
echo.
echo ========================================
echo %SCRIPT_NAME% v%VERSION%
echo ========================================
echo.
echo DESCRIPTION:
echo     Group Policy compatible deployment wrapper for Windows Regional Settings Reset.
echo     Designed for enterprise Active Directory environments with centralized logging,
echo     compliance reporting, and automated deployment capabilities.
echo.
echo USAGE:
echo     deploy-regional-gp.bat [locale] [profile] [options]
echo.
echo PARAMETERS:
echo     locale          Target locale code (default: en-US)
echo                     Supported: pl-PL, en-US, en-GB, de-DE, fr-FR, es-ES,
echo                               it-IT, pt-PT, ru-RU, zh-CN, ja-JP, ko-KR
echo.
echo     profile         Configuration profile (default: Enterprise)
echo                     Enterprise  - Full features with compliance and security
echo                     Corporate   - Standard features for business environments
echo                     Standard    - Basic features for workgroups
echo                     Minimal     - Lightweight deployment for testing
echo.
echo OPTIONS:
echo     compliance=MODE Compliance mode for audit requirements
echo                     SOX, HIPAA, ISO27001, Standard (default: Standard)
echo.
echo     target=SCOPE    Deployment target scope
echo                     User, Computer, Both (default: Both)
echo.
echo     networklog=PATH UNC path for centralized logging
echo                     Example: \\server\logs\regional
echo.
echo     dryrun          Perform validation without making changes
echo.
echo     reporting       Enable detailed reporting for GP management
echo.
echo EXAMPLES:
echo     REM Enterprise deployment with defaults
echo     deploy-regional-gp.bat
echo.
echo     REM German locale with SOX compliance
echo     deploy-regional-gp.bat de-DE Enterprise compliance=SOX
echo.
echo     REM Test deployment without changes
echo     deploy-regional-gp.bat en-US Standard dryrun
echo.
echo     REM Corporate deployment with centralized logging
echo     deploy-regional-gp.bat en-GB Corporate networklog=\\corp\logs reporting
echo.
echo GROUP POLICY INTEGRATION:
echo     This script is designed to be called from Group Policy in the following contexts:
echo     - Computer Configuration\Policies\Windows Settings\Scripts\Startup
echo     - Computer Configuration\Policies\Windows Settings\Scripts\Shutdown
echo     - User Configuration\Policies\Windows Settings\Scripts\Logon
echo     - User Configuration\Policies\Windows Settings\Scripts\Logoff
echo.
echo     For SCCM deployment, use as a package with administrative rights.
echo.
echo EXIT CODES:
echo     0   Success - Regional settings applied successfully
echo     1   Error   - Deployment failed, check logs for details
echo     2   Warning - Partial success, some operations failed
echo.
echo LOGS:
echo     Local: %%TEMP%%\RegionalSettings-GP-Wrapper.log
echo     Detailed: %%TEMP%%\RegionalSettings-GP_[ID]_[timestamp].log
echo     Event Log: Application\RegionalSettings-GP
echo.
echo For additional help and documentation, see README.md
echo ========================================
echo.
exit /b 0