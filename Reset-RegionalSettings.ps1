#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Reset Windows Regional Settings Script
    
.DESCRIPTION
    This script resets all Windows regional settings to a specified locale,
    including Windows 11 registry memory slots, timezone configuration, and
    time synchronization. Defaults to Polish (pl-PL) but allows user customization.
    
.PARAMETER Locale
    Target locale code (e.g., 'pl-PL', 'en-US', 'de-DE')
    Default: 'pl-PL'
    
.PARAMETER Force
    Skip confirmation prompts
    
.PARAMETER LogPath
    Custom path for log file (optional)
    
.PARAMETER RestoreFromBackup
    Path to backup directory to restore from
    
.PARAMETER ConfigFile
    Path to configuration file with custom settings
    
.EXAMPLE
    .\Reset-RegionalSettings.ps1
    Resets to Polish (pl-PL) with confirmation
    
.EXAMPLE
    .\Reset-RegionalSettings.ps1 -Locale "en-US" -Force
    Resets to English (US) without confirmation
    
.EXAMPLE
    .\Reset-RegionalSettings.ps1 -RestoreFromBackup "C:\Temp\RegionalSettings_Backup_20231201_143022"
    Restores settings from a backup
    
.NOTES
    Requires Administrator privileges
    System restart may be required for full effect
#>

param(
    [Parameter(Mandatory=$false)]
    [string]$Locale = "pl-PL",
    
    [Parameter(Mandatory=$false)]
    [switch]$Force,
    
    [Parameter(Mandatory=$false)]
    [string]$LogPath,
    
    [Parameter(Mandatory=$false)]
    [string]$RestoreFromBackup,
    
    [Parameter(Mandatory=$false)]
    [string]$ConfigFile
)

# Initialize error handling and logging
$ErrorActionPreference = "Stop"
$script:LogFile = if ($LogPath) { $LogPath } else { "$env:TEMP\RegionalSettings_$(Get-Date -Format 'yyyyMMdd_HHmmss').log" }
$script:BackupPath = "$env:TEMP\RegionalSettings_Backup_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
$script:OperationCount = 0
$script:SuccessCount = 0
$script:ErrorCount = 0

# Define supported locales
$SupportedLocales = @{
    "pl-PL" = "Polish (Poland)"
    "en-US" = "English (United States)"
    "en-GB" = "English (United Kingdom)"
    "de-DE" = "German (Germany)"
    "fr-FR" = "French (France)"
    "es-ES" = "Spanish (Spain)"
    "it-IT" = "Italian (Italy)"
    "pt-PT" = "Portuguese (Portugal)"
    "ru-RU" = "Russian (Russia)"
    "zh-CN" = "Chinese (Simplified, China)"
    "ja-JP" = "Japanese (Japan)"
    "ko-KR" = "Korean (Korea)"
}

# Validate locale
if (-not $SupportedLocales.ContainsKey($Locale)) {
    Write-Error "Unsupported locale: $Locale"
    Write-Host "Supported locales:"
    $SupportedLocales.GetEnumerator() | Sort-Object Key | ForEach-Object {
        Write-Host "  $($_.Key) - $($_.Value)"
    }
    exit 1
}

# Enhanced logging function
function Write-Log {
    param(
        [string]$Message,
        [string]$Level = "INFO",
        [string]$Color = "White"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    
    # Write to console with color
    Write-Host $logEntry -ForegroundColor $Color
    
    # Write to log file
    try {
        Add-Content -Path $script:LogFile -Value $logEntry -ErrorAction SilentlyContinue
    }
    catch {
        # Ignore log file errors to prevent cascading failures
    }
}

# Function to write colored output (legacy compatibility)
function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = "White"
    )
    Write-Log -Message $Message -Color $Color
}

# Enhanced function to validate system compatibility
function Test-SystemCompatibility {
    try {
        $osVersion = [System.Environment]::OSVersion.Version
        $isWindows10Plus = $osVersion.Major -ge 10
        
        if (-not $isWindows10Plus) {
            Write-Log "WARNING: This script is designed for Windows 10/11. Current version: $($osVersion.ToString())" "WARN" "Yellow"
            return $false
        }
        
        # Check PowerShell version
        $psVersion = $PSVersionTable.PSVersion
        if ($psVersion.Major -lt 5) {
            Write-Log "WARNING: PowerShell 5.0+ recommended. Current version: $($psVersion.ToString())" "WARN" "Yellow"
        }
        
        # Check admin privileges
        $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
        $isAdmin = $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
        
        if (-not $isAdmin) {
            Write-Log "ERROR: Administrator privileges required" "ERROR" "Red"
            return $false
        }
        
        Write-Log "System compatibility check passed" "INFO" "Green"
        return $true
    }
    catch {
        Write-Log "Error during compatibility check: $($_.Exception.Message)" "ERROR" "Red"
        return $false
    }
}

# Enhanced backup registry function with retry logic
function Backup-Registry {
    param(
        [string]$KeyPath, 
        [string]$BackupName,
        [int]$MaxRetries = 3
    )
    
    $retryCount = 0
    
    while ($retryCount -lt $MaxRetries) {
        try {
            $script:OperationCount++
            
            if (-not (Test-Path $script:BackupPath)) {
                New-Item -ItemType Directory -Path $script:BackupPath -Force | Out-Null
                Write-Log "Created backup directory: $script:BackupPath" "INFO" "Blue"
            }
            
            # Convert PowerShell registry path to Windows registry format
            $winRegPath = $KeyPath -replace "HKCU:", "HKEY_CURRENT_USER" -replace "HKLM:", "HKEY_LOCAL_MACHINE"
            
            # Check if the registry key exists before attempting backup
            if (-not (Test-Path $KeyPath)) {
                Write-Log "Registry key does not exist: $KeyPath (skipping backup)" "INFO" "Gray"
                $script:SuccessCount++
                return "SKIPPED"
            }
            
            $regFile = "$script:BackupPath\$BackupName.reg"
            $process = Start-Process -FilePath "reg" -ArgumentList "export", "`"$winRegPath`"", "`"$regFile`"", "/y" -Wait -NoNewWindow -PassThru
            
            if ($process.ExitCode -eq 0 -and (Test-Path $regFile)) {
                $script:SuccessCount++
                Write-Log "Successfully backed up $winRegPath to $regFile" "INFO" "Green"
                return $regFile
            } else {
                throw "Registry export failed with exit code: $($process.ExitCode)"
            }
        }
        catch {
            $retryCount++
            $script:ErrorCount++
            
            if ($retryCount -lt $MaxRetries) {
                Write-Log "Backup attempt $retryCount failed for $KeyPath. Retrying... Error: $($_.Exception.Message)" "WARN" "Yellow"
                Start-Sleep -Seconds 2
            } else {
                Write-Log "Failed to backup $KeyPath after $MaxRetries attempts: $($_.Exception.Message)" "ERROR" "Red"
                return $null
            }
        }
    }
    
    return $null
}

# Enhanced registry value setting with validation and retry
function Set-RegistryValue {
    param(
        [string]$Path,
        [string]$Name,
        [string]$Value,
        [string]$Type = "String",
        [int]$MaxRetries = 3
    )
    
    $retryCount = 0
    
    while ($retryCount -lt $MaxRetries) {
        try {
            $script:OperationCount++
            
            # Ensure the registry path exists
            if (-not (Test-Path $Path)) {
                New-Item -Path $Path -Force | Out-Null
                Write-Log "Created registry path: $Path" "INFO" "Blue"
            }
            
            # Set the registry value
            Set-ItemProperty -Path $Path -Name $Name -Value $Value -Type $Type -ErrorAction Stop
            
            # Verify the value was set correctly
            $verifyValue = Get-ItemProperty -Path $Path -Name $Name -ErrorAction Stop
            if ($verifyValue.$Name -eq $Value) {
                $script:SuccessCount++
                Write-Log "Successfully set ${Path}\${Name} = $Value" "INFO" "Cyan"
                return $true
            } else {
                throw "Value verification failed. Expected: $Value, Got: $($verifyValue.$Name)"
            }
        }
        catch {
            $retryCount++
            $script:ErrorCount++
            
            if ($retryCount -lt $MaxRetries) {
                Write-Log "Set registry attempt $retryCount failed for ${Path}\${Name}. Retrying... Error: $($_.Exception.Message)" "WARN" "Yellow"
                Start-Sleep -Seconds 1
            } else {
                Write-Log "Failed to set ${Path}\${Name} after $MaxRetries attempts: $($_.Exception.Message)" "ERROR" "Red"
                return $false
            }
        }
    }
    
    return $false
}

# Enhanced progress tracking function
function Show-Progress {
    param(
        [string]$Activity,
        [string]$Status,
        [int]$PercentComplete = 0,
        [int]$CurrentOperation = 0,
        [int]$TotalOperations = 0
    )
    
    if ($CurrentOperation -gt 0 -and $TotalOperations -gt 0) {
        $PercentComplete = [math]::Round(($CurrentOperation / $TotalOperations) * 100, 1)
        $Status = "$Status ($CurrentOperation/$TotalOperations)"
    }
    
    Write-Progress -Activity $Activity -Status $Status -PercentComplete $PercentComplete
    Write-Log "[Progress ${PercentComplete}%] ${Activity}: ${Status}" "INFO" "Cyan"
}

# Performance monitoring function
function Start-PerformanceMonitoring {
    $script:StartTime = Get-Date
    $script:StartMemory = [System.GC]::GetTotalMemory($false)
    $script:StartProcess = Get-Process -Id $PID
    Write-Log "Performance monitoring started" "INFO" "Blue"
}

function Stop-PerformanceMonitoring {
    $endTime = Get-Date
    $endMemory = [System.GC]::GetTotalMemory($false)
    $endProcess = Get-Process -Id $PID
    
    $executionTime = $endTime - $script:StartTime
    $memoryDiff = $endMemory - $script:StartMemory
    $cpuTime = $endProcess.TotalProcessorTime - $script:StartProcess.TotalProcessorTime
    
    Write-Log "Performance Summary:" "INFO" "Blue"
    Write-Log "  Execution Time: $($executionTime.TotalSeconds.ToString('F2')) seconds" "INFO" "Blue"
    Write-Log "  Memory Usage: $([math]::Round($memoryDiff / 1MB, 2)) MB" "INFO" "Blue"
    Write-Log "  CPU Time: $($cpuTime.TotalMilliseconds) ms" "INFO" "Blue"
}

# Function to remove registry values with retry logic
function Remove-RegValue {
    param(
        [string]$Path,
        [string]$Name,
        [int]$MaxRetries = 3
    )
    
    $retryCount = 0
    
    while ($retryCount -lt $MaxRetries) {
        try {
            $script:OperationCount++
            
            if (Test-Path $Path) {
                $item = Get-ItemProperty -Path $Path -Name $Name -ErrorAction SilentlyContinue
                if ($item) {
                    Remove-ItemProperty -Path $Path -Name $Name -ErrorAction Stop
                    $script:SuccessCount++
                    Write-Log "Successfully removed ${Path}\${Name}" "INFO" "Yellow"
                    return $true
                }
            }
            
            # Value doesn't exist, consider it successful
            Write-Log "Registry value ${Path}\${Name} does not exist (already removed)" "INFO" "Gray"
            return $true
        }
        catch {
            $retryCount++
            $script:ErrorCount++
            
            if ($retryCount -lt $MaxRetries) {
                Write-Log "Remove registry attempt $retryCount failed for ${Path}\${Name}. Retrying... Error: $($_.Exception.Message)" "WARN" "Yellow"
                Start-Sleep -Seconds 1
            } else {
                Write-Log "Failed to remove ${Path}\${Name} after $MaxRetries attempts: $($_.Exception.Message)" "ERROR" "Red"
                return $false
            }
        }
    }
    
    return $false
}

# Function to load configuration from file
function Import-Configuration {
    param([string]$ConfigPath)
    
    if (-not $ConfigPath -or -not (Test-Path $ConfigPath)) {
        Write-Log "No configuration file specified or found, using defaults" "INFO" "Blue"
        return @{}
    }
    
    try {
        $config = Get-Content $ConfigPath | ConvertFrom-Json
        Write-Log "Loaded configuration from: $ConfigPath" "INFO" "Green"
        return $config
    } catch {
        Write-Log "Failed to load configuration: $($_.Exception.Message)" "ERROR" "Red"
        return @{}
    }
}



# Function to restore from backup
function Restore-FromBackup {
    param([string]$BackupDirectory)
    
    if (-not (Test-Path $BackupDirectory)) {
        Write-Log "Backup directory not found: $BackupDirectory" "ERROR" "Red"
        return $false
    }
    
    try {
        $regFiles = Get-ChildItem -Path $BackupDirectory -Filter "*.reg"
        
        if ($regFiles.Count -eq 0) {
            Write-Log "No registry backup files found in: $BackupDirectory" "ERROR" "Red"
            return $false
        }
        
        Write-Log "Found $($regFiles.Count) backup files. Starting restore..." "INFO" "Blue"
        
        $restoredCount = 0
        $failedCount = 0
        
        foreach ($regFile in $regFiles) {
            # Skip files that were marked as SKIPPED during backup
            if ((Get-Content $regFile -TotalCount 1) -eq "SKIPPED") {
                Write-Log "Skipping restore of: $($regFile.Name) (was skipped during backup)" "INFO" "Gray"
                continue
            }
            
            Write-Log "Restoring: $($regFile.Name)" "INFO" "Cyan"
            $process = Start-Process -FilePath "reg" -ArgumentList "import", "`"$($regFile.FullName)`"" -Wait -NoNewWindow -PassThru
            
            if ($process.ExitCode -eq 0) {
                Write-Log "Successfully restored: $($regFile.Name)" "INFO" "Green"
                $restoredCount++
            } else {
                Write-Log "Failed to restore: $($regFile.Name) (Exit code: $($process.ExitCode))" "ERROR" "Red"
                $failedCount++
            }
        }
        
        Write-Log "Backup restore completed: $restoredCount successful, $failedCount failed" "INFO" "Green"
        return $true
    }
    catch {
        Write-Log "Error during backup restore: $($_.Exception.Message)" "ERROR" "Red"
        return $false
    }
}

# Initialize logging
try {
    $logDir = Split-Path $script:LogFile -Parent
    if (-not (Test-Path $logDir)) {
        New-Item -ItemType Directory -Path $logDir -Force | Out-Null
    }
    "Regional Settings Reset - Started $(Get-Date)" | Out-File -FilePath $script:LogFile -Encoding UTF8
}
catch {
    Write-Warning "Could not initialize log file: $($_.Exception.Message)"
}

# Main script execution with enhanced error handling
try {
    Write-Log "========================================" "INFO" "Magenta"
    Write-Log "Windows Regional Settings Reset Script" "INFO" "Magenta"
    Write-Log "========================================" "INFO" "Magenta"
    Write-Log ""
    
    # System compatibility check
    if (-not (Test-SystemCompatibility)) {
        Write-Log "System compatibility check failed. Exiting." "ERROR" "Red"
        exit 1
    }
    
    # Load configuration if specified
    $config = Import-Configuration -ConfigPath $ConfigFile
    
    # Handle restore mode
    if ($RestoreFromBackup) {
        Write-Log "Restore mode: $RestoreFromBackup" "INFO" "Blue"
        if (Restore-FromBackup -BackupDirectory $RestoreFromBackup) {
            Write-Log "Restore completed successfully. A restart may be required." "INFO" "Green"
            exit 0
        } else {
            Write-Log "Restore failed. Please check the backup directory and try again." "ERROR" "Red"
            exit 1
        }
    }
    
    # Validate locale
    if (-not $SupportedLocales.ContainsKey($Locale)) {
        Write-Log "Unsupported locale: $Locale" "ERROR" "Red"
        Write-Log "Supported locales:" "INFO" "White"
        $SupportedLocales.GetEnumerator() | Sort-Object Key | ForEach-Object {
            Write-Log "  $($_.Key) - $($_.Value)" "INFO" "White"
        }
        exit 1
    }
    
    Write-Log "Target Locale: $Locale ($($SupportedLocales[$Locale]))" "INFO" "Green"
    Write-Log "Log File: $script:LogFile" "INFO" "Blue"
    Write-Log "Backup Directory: $script:BackupPath" "INFO" "Blue"
    
    if (-not $Force) {
        Write-Log ""
        Write-Warning "This script will reset ALL regional settings and may require a restart."
        Write-Warning "Registry backups will be created before making changes."
        $confirm = Read-Host "Do you want to continue? (y/N)"
        if ($confirm -ne "y" -and $confirm -ne "Y") {
            Write-Log "Operation cancelled by user." "INFO" "Yellow"
            exit 0
        }
    }
    
    Write-Log ""
    Write-Log "Starting regional settings reset..." "INFO" "Green"
    $startTime = Get-Date
    Start-PerformanceMonitoring    # Validate write access to registry
    try {
        $testPath = "HKCU:\Software\RegionalSettingsTest"
        New-Item -Path $testPath -Force | Out-Null
        Remove-Item -Path $testPath -Force
        Write-Log "Registry write access validated" "INFO" "Green"
    }
    catch {
        Write-Log "Unable to write to registry. Please ensure you have proper permissions." "ERROR" "Red"
        exit 1
    }
}
catch {
    Write-Log "Critical error during initialization: $($_.Exception.Message)" "ERROR" "Red"
    Write-Log "Stack trace: $($_.ScriptStackTrace)" "ERROR" "Red"
    exit 1
}

    # Registry paths for regional settings
    $RegPaths = @{
        "CurrentUser" = @(
            "HKCU:\Control Panel\International",
            "HKCU:\Control Panel\Desktop",
            "HKCU:\Control Panel\Input Method"
        )
        "LocalMachine" = @(
            "HKLM:\SYSTEM\CurrentControlSet\Control\Nls\Language",
            "HKLM:\SYSTEM\CurrentControlSet\Control\Nls\Locale",
            "HKLM:\SYSTEM\CurrentControlSet\Control\Nls\CodePage"
        )
        "Windows11Memory" = @(
            "HKCU:\Control Panel\International\User Profile",
            "HKCU:\Control Panel\International\Geo",
            "HKCU:\Software\Microsoft\Input\Settings",
            "HKCU:\Software\Microsoft\CTF\LangBar"
        )
    }
    
    # Backup current settings with progress tracking and validation
    Write-Log "Creating registry backups..." "INFO" "Blue"
    
    # Pre-validate which registry keys actually exist
    $validPaths = @{}
    $totalValidPaths = 0
    
    foreach ($category in $RegPaths.Keys) {
        $validPaths[$category] = @()
        foreach ($regPath in $RegPaths[$category]) {
            if (Test-Path $regPath) {
                $validPaths[$category] += $regPath
                $totalValidPaths++
            } else {
                Write-Log "Registry key does not exist, skipping backup: $regPath" "INFO" "Gray"
            }
        }
    }
    
    Write-Log "Found $totalValidPaths valid registry keys to backup" "INFO" "Blue"
    $currentBackup = 0
    
    Show-Progress -Activity "Registry Backup" -Status "Initializing backup process" -PercentComplete 0
    
    try {
        foreach ($category in $validPaths.Keys) {
            if ($validPaths[$category].Count -gt 0) {
                Write-Log "Backing up $category settings..." "INFO" "Blue"
                foreach ($regPath in $validPaths[$category]) {
                    $currentBackup++
                    $keyName = ($regPath -split '\\')[-1] -replace '[\\/:*?"<>|]', '_'
                    
                    Show-Progress -Activity "Registry Backup" -Status "Backing up: $keyName" -CurrentOperation $currentBackup -TotalOperations $totalValidPaths
                    
                    $backupResult = Backup-Registry -KeyPath $regPath -BackupName "${category}_${keyName}"
                    if (-not $backupResult) {
                        Write-Log "Backup failed for $regPath, but continuing..." "WARN" "Yellow"
                    } elseif ($backupResult -eq "SKIPPED") {
                        Write-Log "Backup skipped for $regPath (key does not exist)" "INFO" "Gray"
                    }
                }
            } else {
                Write-Log "No valid registry keys found for $category category" "INFO" "Gray"
            }
        }
        Write-Log "Registry backup phase completed ($currentBackup/$totalValidPaths processed)" "INFO" "Green"
    }
    catch {
        Write-Log "Error during backup phase: $($_.Exception.Message)" "ERROR" "Red"
        Write-Log "Continuing with reset operation..." "WARN" "Yellow"
    }

    # Reset International settings with comprehensive locale support
    Write-Log ""
    Write-Log "Resetting International settings..." "INFO" "Blue"
    
    $intlPath = "HKCU:\Control Panel\International"
    $settingsApplied = 0
    $settingsFailed = 0
    
    try {
        # Core locale settings (universal)
        $coreSettings = @{
            "Locale" = $Locale
            "LocaleName" = $Locale
        }
        
        foreach ($setting in $coreSettings.GetEnumerator()) {
            if (Set-RegistryValue -Path $intlPath -Name $setting.Key -Value $setting.Value) {
                $settingsApplied++
            } else {
                $settingsFailed++
            }
        }
        
        # Locale-specific settings with enhanced coverage
        switch ($Locale) {
            "pl-PL" {
                $localeSettings = @{
                    "sLanguage" = "PLK"
                    "sCountry" = "Poland"
                    "sShortDate" = "dd.MM.yyyy"
                    "sLongDate" = "d MMMM yyyy"
                    "sTimeFormat" = "HH:mm:ss"
                    "sShortTime" = "HH:mm"
                    "sCurrency" = "zł"
                    "sMonDecimalSep" = ","
                    "sMonThousandSep" = " "
                    "sDecimal" = ","
                    "sThousand" = " "
                    "sList" = ";"
                    "iCountry" = "48"
                    "iCurrency" = "3"
                    "iCurrDigits" = "2"
                    "iDate" = "1"
                    "iTime" = "1"
                    "iTLZero" = "1"
                    "s1159" = ""
                    "s2359" = ""
                    "iNegCurr" = "8"
                    "iPaperSize" = "9"
                    "iMeasure" = "0"
                    "sTimeZoneKeyName" = "Central European Standard Time"
                }
            }
            "en-US" {
                $localeSettings = @{
                    "sLanguage" = "ENU"
                    "sCountry" = "United States"
                    "sShortDate" = "M/d/yyyy"
                    "sLongDate" = "dddd, MMMM d, yyyy"
                    "sTimeFormat" = "h:mm:ss tt"
                    "sShortTime" = "h:mm tt"
                    "sCurrency" = "$"
                    "sMonDecimalSep" = "."
                    "sMonThousandSep" = ","
                    "sDecimal" = "."
                    "sThousand" = ","
                    "sList" = ","
                    "iCountry" = "1"
                    "iCurrency" = "0"
                    "iCurrDigits" = "2"
                    "iDate" = "0"
                    "iTime" = "0"
                    "iTLZero" = "0"
                    "s1159" = "AM"
                    "s2359" = "PM"
                    "iNegCurr" = "0"
                    "iPaperSize" = "1"
                    "iMeasure" = "1"
                    "sTimeZoneKeyName" = "Eastern Standard Time"
                }
            }
            "en-GB" {
                $localeSettings = @{
                    "sLanguage" = "ENG"
                    "sCountry" = "United Kingdom"
                    "sShortDate" = "dd/MM/yyyy"
                    "sLongDate" = "dddd, d MMMM yyyy"
                    "sTimeFormat" = "HH:mm:ss"
                    "sShortTime" = "HH:mm"
                    "sCurrency" = "£"
                    "sMonDecimalSep" = "."
                    "sMonThousandSep" = ","
                    "sDecimal" = "."
                    "sThousand" = ","
                    "sList" = ","
                    "iCountry" = "44"
                    "iCurrency" = "0"
                    "iCurrDigits" = "2"
                    "iDate" = "1"
                    "iTime" = "1"
                    "iTLZero" = "1"
                    "s1159" = ""
                    "s2359" = ""
                    "iNegCurr" = "1"
                    "iPaperSize" = "9"
                    "iMeasure" = "0"
                    "sTimeZoneKeyName" = "GMT Standard Time"
                }
            }
            "de-DE" {
                $localeSettings = @{
                    "sLanguage" = "DEU"
                    "sCountry" = "Germany"
                    "sShortDate" = "dd.MM.yyyy"
                    "sLongDate" = "dddd, d. MMMM yyyy"
                    "sTimeFormat" = "HH:mm:ss"
                    "sShortTime" = "HH:mm"
                    "sCurrency" = "€"
                    "sMonDecimalSep" = ","
                    "sMonThousandSep" = "."
                    "sDecimal" = ","
                    "sThousand" = "."
                    "sList" = ";"
                    "iCountry" = "49"
                    "iCurrency" = "3"
                    "iCurrDigits" = "2"
                    "iDate" = "1"
                    "iTime" = "1"
                    "iTLZero" = "1"
                    "s1159" = ""
                    "s2359" = ""
                    "iNegCurr" = "8"
                    "iPaperSize" = "9"
                    "iMeasure" = "0"
                    "sTimeZoneKeyName" = "W. Europe Standard Time"
                }
            }
            "fr-FR" {
                $localeSettings = @{
                    "sLanguage" = "FRA"
                    "sCountry" = "France"
                    "sShortDate" = "dd/MM/yyyy"
                    "sLongDate" = "dddd d MMMM yyyy"
                    "sTimeFormat" = "HH:mm:ss"
                    "sShortTime" = "HH:mm"
                    "sCurrency" = "€"
                    "sMonDecimalSep" = ","
                    "sMonThousandSep" = " "
                    "sDecimal" = ","
                    "sThousand" = " "
                    "sList" = ";"
                    "iCountry" = "33"
                    "iCurrency" = "3"
                    "iCurrDigits" = "2"
                    "iDate" = "1"
                    "iTime" = "1"
                    "iTLZero" = "1"
                    "s1159" = ""
                    "s2359" = ""
                    "iNegCurr" = "8"
                    "iPaperSize" = "9"
                    "iMeasure" = "0"
                    "sTimeZoneKeyName" = "Romance Standard Time"
                }
            }
            default {
                Write-Log "Using generic settings for $Locale" "WARN" "Yellow"
                $localeSettings = @{
                    "sLanguage" = $Locale.Split('-')[0].ToUpper()
                    "sCountry" = $SupportedLocales[$Locale]
                    "sTimeZoneKeyName" = "Eastern Standard Time"
                }
            }
        }
        
        # Apply locale-specific settings
        foreach ($setting in $localeSettings.GetEnumerator()) {
            if (Set-RegistryValue -Path $intlPath -Name $setting.Key -Value $setting.Value) {
                $settingsApplied++
            } else {
                $settingsFailed++
            }
        }
        
        Write-Log "International settings: $settingsApplied applied, $settingsFailed failed" "INFO" "Green"
    }
    catch {
        Write-Log "Error in International settings section: $($_.Exception.Message)" "ERROR" "Red"
    }

    # Reset Windows 11 specific memory slots with enhanced error handling
    Write-Log ""
    Write-Log "Resetting Windows 11 memory slots..." "INFO" "Blue"
    
    try {
        # Clear user profile settings
        $userProfilePath = "HKCU:\Control Panel\International\User Profile"
        if (Test-Path $userProfilePath) {
            $profileItems = Get-ChildItem -Path $userProfilePath -ErrorAction SilentlyContinue
            if ($profileItems) {
                Remove-Item -Path $userProfilePath -Recurse -Force -ErrorAction Stop
                Write-Log "Cleared user profile regional settings ($($profileItems.Count) items)" "INFO" "Yellow"
            } else {
                Write-Log "User profile regional settings already empty" "INFO" "Gray"
            }
        } else {
            Write-Log "User profile path does not exist (already clean)" "INFO" "Gray"
        }
        
        # Reset geographic location with locale-specific values
        $geoId = switch ($Locale) {
            "pl-PL" { "191" }
            "en-US" { "244" }
            "en-GB" { "242" }
            "de-DE" { "94" }
            "fr-FR" { "84" }
            "es-ES" { "217" }
            "it-IT" { "118" }
            "pt-PT" { "193" }
            "ru-RU" { "203" }
            "zh-CN" { "45" }
            "ja-JP" { "122" }
            "ko-KR" { "134" }
            default { "244" }  # Default to US
        }
        
        if (Set-RegistryValue -Path "HKCU:\Control Panel\International\Geo" -Name "Nation" -Value $geoId) {
            Write-Log "Set geographic location to: $geoId (for $Locale)" "INFO" "Green"
        }
        
        # Clear input method settings with backup
        $inputSettingsPath = "HKCU:\Software\Microsoft\Input\Settings"
        if (Test-Path $inputSettingsPath) {
            $inputItems = Get-ChildItem -Path $inputSettingsPath -ErrorAction SilentlyContinue
            if ($inputItems) {
                foreach ($item in $inputItems) {
                    try {
                        Remove-Item -Path $item.PSPath -Recurse -Force -ErrorAction Stop
                        Write-Log "Cleared input setting: $($item.Name)" "INFO" "Yellow"
                    }
                    catch {
                        Write-Log "Could not clear input setting $($item.Name): $($_.Exception.Message)" "WARN" "Yellow"
                    }
                }
            }
        }
        
        # Reset language bar settings with validation
        $langBarPath = "HKCU:\Software\Microsoft\CTF\LangBar"
        $langBarSettings = @{
            "ShowStatus" = @{ Value = "3"; Type = "DWord" }
            "Label" = @{ Value = "1"; Type = "DWord" }
            "ExtraIconsOnMinimized" = @{ Value = "0"; Type = "DWord" }
            "Transparency" = @{ Value = "255"; Type = "DWord" }
        }
        
        foreach ($setting in $langBarSettings.GetEnumerator()) {
            $success = Set-RegistryValue -Path $langBarPath -Name $setting.Key -Value $setting.Value.Value -Type $setting.Value.Type
            if (-not $success) {
                Write-Log "Failed to set language bar setting: $($setting.Key)" "WARN" "Yellow"
            }
        }
        
        Write-Log "Windows 11 memory slots reset completed" "INFO" "Green"
    }
    catch {
        Write-Log "Error in Windows 11 memory slots section: $($_.Exception.Message)" "ERROR" "Red"
    }

    # Reset system locale with enhanced error handling
    Write-Log ""
    Write-Log "Setting system locale..." "INFO" "Blue"
    
    try {
        # Get the geographic ID and timezone for the locale
        $localeSettings = switch ($Locale) {
            "pl-PL" { @{ GeoId = 191; TimeZone = "Central European Standard Time" } }
            "en-US" { @{ GeoId = 244; TimeZone = "Eastern Standard Time" } }
            "en-GB" { @{ GeoId = 242; TimeZone = "GMT Standard Time" } }
            "de-DE" { @{ GeoId = 94; TimeZone = "W. Europe Standard Time" } }
            "fr-FR" { @{ GeoId = 84; TimeZone = "Romance Standard Time" } }
            "es-ES" { @{ GeoId = 217; TimeZone = "Romance Standard Time" } }
            "it-IT" { @{ GeoId = 118; TimeZone = "W. Europe Standard Time" } }
            "pt-PT" { @{ GeoId = 193; TimeZone = "GMT Standard Time" } }
            "ru-RU" { @{ GeoId = 203; TimeZone = "Russian Standard Time" } }
            "zh-CN" { @{ GeoId = 45; TimeZone = "China Standard Time" } }
            "ja-JP" { @{ GeoId = 122; TimeZone = "Tokyo Standard Time" } }
            "ko-KR" { @{ GeoId = 134; TimeZone = "Korea Standard Time" } }
            default { @{ GeoId = 244; TimeZone = "Eastern Standard Time" } }
        }
        
        $geoId = $localeSettings.GeoId
        $timeZone = $localeSettings.TimeZone
        
        # Use PowerShell cmdlets for internationalization with error handling
        $systemLocaleSuccess = $false
        $userLanguageSuccess = $false
        $homeLocationSuccess = $false
        $timeZoneSuccess = $false
        
        # Set system locale
        try {
            Set-WinSystemLocale -SystemLocale $Locale -ErrorAction Stop
            $systemLocaleSuccess = $true
            Write-Log "System locale set to: $Locale" "INFO" "Green"
        }
        catch {
            Write-Log "Could not set system locale: $($_.Exception.Message)" "WARN" "Yellow"
        }
        
        # Set user language list
        try {
            Set-WinUserLanguageList -LanguageList $Locale -Force -ErrorAction Stop
            $userLanguageSuccess = $true
            Write-Log "User language list set to: $Locale" "INFO" "Green"
        }
        catch {
            Write-Log "Could not set user language list: $($_.Exception.Message)" "WARN" "Yellow"
        }
        
        # Set home location
        try {
            Set-WinHomeLocation -GeoId $geoId -ErrorAction Stop
            $homeLocationSuccess = $true
            Write-Log "Home location set to: $geoId" "INFO" "Green"
        }
        catch {
            Write-Log "Could not set home location: $($_.Exception.Message)" "WARN" "Yellow"
        }
        
        # Set timezone
        try {
            Set-TimeZone -Id $timeZone -ErrorAction Stop
            $timeZoneSuccess = $true
            Write-Log "Timezone set to: $timeZone" "INFO" "Green"
        }
        catch {
            Write-Log "Could not set timezone: $($_.Exception.Message)" "WARN" "Yellow"
        }
        
        # Summary of system locale operations
        $successCount = @($systemLocaleSuccess, $userLanguageSuccess, $homeLocationSuccess, $timeZoneSuccess) | Where-Object { $_ } | Measure-Object | Select-Object -ExpandProperty Count
        Write-Log "System locale operations: $successCount/4 successful" "INFO" "Green"
        
        if ($successCount -eq 0) {
            Write-Log "All system locale operations failed. Manual configuration may be required." "WARN" "Yellow"
        }
    }
    catch {
        Write-Log "Error in system locale section: $($_.Exception.Message)" "ERROR" "Red"
    }

    # Reset and synchronize time settings
    Write-Log ""
    Write-Log "Configuring time synchronization..." "INFO" "Blue"
    
    try {
        # Stop Windows Time service if running
        $w32timeService = Get-Service -Name "w32time" -ErrorAction SilentlyContinue
        if ($w32timeService -and $w32timeService.Status -eq "Running") {
            Write-Log "Stopping Windows Time service..." "INFO" "Blue"
            Stop-Service -Name "w32time" -Force -ErrorAction SilentlyContinue
            Start-Sleep -Seconds 2
        }
        
        # Unregister and re-register Windows Time service
        try {
            Write-Log "Re-registering Windows Time service..." "INFO" "Blue"
            Start-Process -FilePath "w32tm" -ArgumentList "/unregister" -Wait -NoNewWindow -PassThru | Out-Null
            Start-Sleep -Seconds 2
            $regResult = Start-Process -FilePath "w32tm" -ArgumentList "/register" -Wait -NoNewWindow -PassThru
            
            if ($regResult.ExitCode -eq 0) {
                Write-Log "Windows Time service re-registered successfully" "INFO" "Green"
            } else {
                Write-Log "Windows Time service registration returned exit code: $($regResult.ExitCode)" "WARN" "Yellow"
            }
        }
        catch {
            Write-Log "Could not re-register Windows Time service: $($_.Exception.Message)" "WARN" "Yellow"
        }
        
        # Start Windows Time service
        try {
            Start-Service -Name "w32time" -ErrorAction Stop
            Write-Log "Windows Time service started" "INFO" "Green"
        }
        catch {
            Write-Log "Could not start Windows Time service: $($_.Exception.Message)" "WARN" "Yellow"
        }
        
        # Configure time server settings
        try {
            Write-Log "Configuring time server settings..." "INFO" "Blue"
            $configResult = Start-Process -FilePath "w32tm" -ArgumentList "/config", "/manualpeerlist:`"time.windows.com,0x1`"", "/syncfromflags:manual", "/reliable:yes", "/update" -Wait -NoNewWindow -PassThru
            
            if ($configResult.ExitCode -eq 0) {
                Write-Log "Time server configuration completed" "INFO" "Green"
            } else {
                Write-Log "Time server configuration returned exit code: $($configResult.ExitCode)" "WARN" "Yellow"
            }
        }
        catch {
            Write-Log "Could not configure time server: $($_.Exception.Message)" "WARN" "Yellow"
        }
        
        # Force immediate time synchronization
        try {
            Write-Log "Performing immediate time synchronization..." "INFO" "Blue"
            $syncResult = Start-Process -FilePath "w32tm" -ArgumentList "/resync", "/force" -Wait -NoNewWindow -PassThru
            
            if ($syncResult.ExitCode -eq 0) {
                Write-Log "Time synchronization completed successfully" "INFO" "Green"
            } else {
                Write-Log "Time synchronization returned exit code: $($syncResult.ExitCode)" "WARN" "Yellow"
            }
        }
        catch {
            Write-Log "Could not perform time synchronization: $($_.Exception.Message)" "WARN" "Yellow"
        }
        
        # Display current time information
        try {
            $currentTime = Get-Date
            $timeZoneInfo = Get-TimeZone
            Write-Log "Current system time: $($currentTime.ToString('yyyy-MM-dd HH:mm:ss'))" "INFO" "Cyan"
            Write-Log "Current timezone: $($timeZoneInfo.Id) ($($timeZoneInfo.DisplayName))" "INFO" "Cyan"
        }
        catch {
            Write-Log "Could not retrieve current time information: $($_.Exception.Message)" "WARN" "Yellow"
        }
        
        Write-Log "Time synchronization configuration completed" "INFO" "Green"
    }
    catch {
        Write-Log "Error in time synchronization section: $($_.Exception.Message)" "ERROR" "Red"
    }

    # Additional reset capabilities - Browser and Office settings
    Write-Log ""
    Write-Log "Resetting additional application settings..." "INFO" "Blue"
    
    try {
        # Reset Internet Explorer/Edge regional settings
        $ieSettingsApplied = 0
        $ieSettingsFailed = 0
        
        $iePaths = @(
            "HKCU:\Software\Microsoft\Internet Explorer\International",
            "HKCU:\Software\Microsoft\Internet Explorer\Main\International"
        )
        
        foreach ($iePath in $iePaths) {
            if (Set-RegistryValue -Path $iePath -Name "AcceptLanguage" -Value $Locale) {
                $ieSettingsApplied++
            } else {
                $ieSettingsFailed++
            }
        }
        
        # Reset Chrome regional settings (if Chrome is installed)
        $chromePath = "HKCU:\Software\Google\Chrome\PreferenceMACs\Default\intl"
        if (Test-Path "HKCU:\Software\Google\Chrome") {
            if (Set-RegistryValue -Path $chromePath -Name "accept_languages" -Value $Locale) {
                $ieSettingsApplied++
                Write-Log "Chrome language preference updated" "INFO" "Green"
            }
        }
        
        # Reset Firefox regional settings (if Firefox is installed)
        $firefoxProfiles = Get-ChildItem -Path "$env:APPDATA\Mozilla\Firefox\Profiles" -Directory -ErrorAction SilentlyContinue 2>$null
        
        if ($firefoxProfiles) {
            foreach ($firefoxProfile in $firefoxProfiles) {
                $prefsFile = Join-Path $firefoxProfile.FullName "prefs.js"
                if (Test-Path $prefsFile) {
                    try {
                        $prefsContent = Get-Content $prefsFile -ErrorAction Stop
                        $newPrefs = $prefsContent | Where-Object { $_ -notmatch 'intl\\.accept_languages' }
                        $newPrefs += "user_pref(`"intl.accept_languages`", `"$Locale`");"
                        $newPrefs | Set-Content $prefsFile -ErrorAction Stop
                        Write-Log "Firefox profile updated: $($firefoxProfile.Name)" "INFO" "Green"
                        $ieSettingsApplied++
                    }
                    catch {
                        Write-Log "Could not update Firefox profile $($firefoxProfile.Name): $($_.Exception.Message)" "WARN" "Yellow"
                        $ieSettingsFailed++
                    }
                }
            }
        }
        
        Write-Log "Browser settings: $ieSettingsApplied applied, $ieSettingsFailed failed" "INFO" "Green"
        
        # Reset Microsoft Office regional settings
        $officeSettingsApplied = 0
        $officeSettingsFailed = 0
        
        $officeVersions = @("15.0", "16.0")  # Office 2013, 2016/2019/365
        $officeApps = @("Word", "Excel", "PowerPoint", "Outlook")
        
        foreach ($version in $officeVersions) {
            foreach ($app in $officeApps) {
                $officePath = "HKCU:\Software\Microsoft\Office\$version\$app\Options"
                
                if (Test-Path $officePath) {
                    # Set locale for Office applications
                    if (Set-RegistryValue -Path $officePath -Name "LOCALE_IDEFAULTLANGUAGE" -Value ([System.Globalization.CultureInfo]::GetCultureInfo($Locale).LCID.ToString()) -Type "DWord") {
                        $officeSettingsApplied++
                    } else {
                        $officeSettingsFailed++
                    }
                    
                    # Set regional format
                    if (Set-RegistryValue -Path $officePath -Name "LOCALE_IDEFAULTLOCALE" -Value ([System.Globalization.CultureInfo]::GetCultureInfo($Locale).LCID.ToString()) -Type "DWord") {
                        $officeSettingsApplied++
                    } else {
                        $officeSettingsFailed++
                    }
                }
            }
        }
        
        if ($officeSettingsApplied -gt 0) {
            Write-Log "Office settings: $officeSettingsApplied applied, $officeSettingsFailed failed" "INFO" "Green"
        } else {
            Write-Log "No Office installations detected" "INFO" "Gray"
        }
        
        # Reset .NET Framework regional settings
        $dotnetPath = "HKCU:\Control Panel\International"
        $dotnetCulture = [System.Globalization.CultureInfo]::GetCultureInfo($Locale)
        
        $dotnetSettings = @{
            "LocaleName" = $Locale
            "sLanguage" = $dotnetCulture.ThreeLetterISOLanguageName.ToUpper()
        }
        
        $dotnetApplied = 0
        foreach ($setting in $dotnetSettings.GetEnumerator()) {
            if (Set-RegistryValue -Path $dotnetPath -Name $setting.Key -Value $setting.Value) {
                $dotnetApplied++
            }
        }
        
        Write-Log ".NET Framework settings applied: $dotnetApplied" "INFO" "Green"
        
    }
    catch {
        Write-Log "Error in additional application settings: $($_.Exception.Message)" "ERROR" "Red"
    }
    Write-Log ""
    Write-Log "Clearing MRU lists..." "INFO" "Blue"
    
    try {
        $mruPaths = @(
            "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\RunMRU",
            "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\TypedPaths",
            "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\WordWheelQuery",
            "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\RecentDocs"
        )
        
        $mruItemsCleared = 0
        
        foreach ($mruPath in $mruPaths) {
            if (Test-Path $mruPath) {
                try {
                    $properties = Get-ItemProperty -Path $mruPath -ErrorAction SilentlyContinue
                    if ($properties) {
                        $propertyNames = $properties.PSObject.Properties | Where-Object { 
                            $_.Name -notin @("PSPath", "PSParentPath", "PSChildName", "PSDrive", "PSProvider") 
                        } | Select-Object -ExpandProperty Name
                        
                        foreach ($propName in $propertyNames) {
                            try {
                                Remove-ItemProperty -Path $mruPath -Name $propName -ErrorAction Stop
                                $mruItemsCleared++
                            }
                            catch {
                                Write-Log "Could not remove MRU item ${mruPath}\${propName}: $($_.Exception.Message)" "WARN" "Yellow"
                            }
                        }
                        
                        if ($propertyNames.Count -gt 0) {
                            Write-Log "Cleared MRU: $mruPath ($($propertyNames.Count) items)" "INFO" "Yellow"
                        }
                    }
                }
                catch {
                    Write-Log "Error accessing MRU path ${mruPath}: $($_.Exception.Message)" "WARN" "Yellow"
                }
            } else {
                Write-Log "MRU path does not exist: $mruPath" "INFO" "Gray"
            }
        }
        
        Write-Log "MRU cleanup completed: $mruItemsCleared items cleared" "INFO" "Green"
    }
    catch {
        Write-Log "Error in MRU cleanup section: $($_.Exception.Message)" "ERROR" "Red"
    }
    
    # Calculate execution time and statistics
    $endTime = Get-Date
    $executionTime = $endTime - $startTime
    Stop-PerformanceMonitoring
    Write-Progress -Activity "Regional Settings Reset" -Completed
    
    Write-Log ""
    Write-Log "========================================" "INFO" "Magenta"
    Write-Log "Regional Settings Reset Complete!" "INFO" "Green"
    Write-Log "========================================" "INFO" "Magenta"
    Write-Log ""
    Write-Log "Execution Summary:" "INFO" "White"
    Write-Log "  Target Locale: $Locale ($($SupportedLocales[$Locale]))" "INFO" "Green"
    Write-Log "  Execution Time: $($executionTime.TotalSeconds.ToString('F2')) seconds" "INFO" "Blue"
    Write-Log "  Total Operations: $script:OperationCount" "INFO" "Blue"
    Write-Log "  Successful Operations: $script:SuccessCount" "INFO" "Green"
    Write-Log "  Failed Operations: $script:ErrorCount" "INFO" $(if ($script:ErrorCount -gt 0) { "Red" } else { "Green" })
    Write-Log "  Success Rate: $([math]::Round(($script:SuccessCount / [math]::Max($script:OperationCount, 1)) * 100, 1))%" "INFO" "Blue"
    Write-Log ""
    Write-Log "Configuration Applied:" "INFO" "White"
    Write-Log "  • International settings and formats" "INFO" "Cyan"
    Write-Log "  • Windows 11 memory slots cleared" "INFO" "Cyan"
    Write-Log "  • System locale and language preferences" "INFO" "Cyan"
    Write-Log "  • Timezone configuration" "INFO" "Cyan"
    Write-Log "  • Time synchronization with Windows Time" "INFO" "Cyan"
    Write-Log "  • Browser language preferences" "INFO" "Cyan"
    Write-Log "  • Office application locales" "INFO" "Cyan"
    Write-Log "  • MRU lists cleanup" "INFO" "Cyan"
    Write-Log ""
    Write-Log "Log File: $script:LogFile" "INFO" "Blue"
    Write-Log "Backup Directory: $script:BackupPath" "INFO" "Blue"
    Write-Log ""
    
    if ($script:ErrorCount -gt 0) {
        Write-Warning "Some operations failed. Check the log file for details."
        Write-Log "Review the log file for detailed error information: $script:LogFile" "WARN" "Yellow"
    } else {
        Write-Log "All operations completed successfully!" "INFO" "Green"
    }
    
    Write-Warning "A system restart is recommended for all changes to take effect."
    Write-Log ""
    
    # Restart prompt with enhanced options
    if (-not $Force) {
        Write-Host "Options:" -ForegroundColor White
        Write-Host "  [R] Restart now" -ForegroundColor Yellow
        Write-Host "  [S] Shutdown now" -ForegroundColor Yellow  
        Write-Host "  [N] Continue without restart (default)" -ForegroundColor White
        Write-Host ""
        
        $action = Read-Host "Choose an action (R/S/N)"
        
        switch ($action.ToUpper()) {
            "R" {
                Write-Log "User chose to restart system" "INFO" "Yellow"
                Write-Log "Restarting system in 10 seconds..." "INFO" "Yellow"
                Start-Sleep -Seconds 10
                try {
                    Restart-Computer -Force
                }
                catch {
                    Write-Log "Could not restart system: $($_.Exception.Message)" "ERROR" "Red"
                }
            }
            "S" {
                Write-Log "User chose to shutdown system" "INFO" "Yellow"
                Write-Log "Shutting down system in 10 seconds..." "INFO" "Yellow"
                Start-Sleep -Seconds 10
                try {
                    Stop-Computer -Force
                }
                catch {
                    Write-Log "Could not shutdown system: $($_.Exception.Message)" "ERROR" "Red"
                }
            }
            default {
                Write-Log "User chose to continue without restart" "INFO" "Blue"
            }
        }
    }
    
    Write-Log "Script completed successfully." "INFO" "Green"
    
    # Final log entry
    try {
        "Regional Settings Reset - Completed $(Get-Date) - Success Rate: $([math]::Round(($script:SuccessCount / [math]::Max($script:OperationCount, 1)) * 100, 1))%" | Add-Content -Path $script:LogFile
    }
    catch {
        # Ignore final log errors
    }
    
    # Set exit code based on error count
    if ($script:ErrorCount -gt 0) {
        exit 2  # Partial success
    } else {
        exit 0  # Complete success
    }
catch {
    Write-Log "Critical error during script execution: $($_.Exception.Message)" "ERROR" "Red"
    Write-Log "Stack trace: $($_.ScriptStackTrace)" "ERROR" "Red"
    
    try {
        "Regional Settings Reset - FAILED $(Get-Date) - Critical Error: $($_.Exception.Message)" | Add-Content -Path $script:LogFile
    }
    catch {
        # Ignore final log errors
    }
    
    exit 1  # Critical failure
}