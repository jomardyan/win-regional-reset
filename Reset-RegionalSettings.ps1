#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Reset Windows Regional Settings Script
    
.DESCRIPTION
    This script resets all Windows regional settings to a specified locale,
    including Windows 11 registry memory slots. Defaults to Polish (pl-PL)
    but allows user customization.
    
.PARAMETER Locale
    Target locale code (e.g., 'pl-PL', 'en-US', 'de-DE')
    Default: 'pl-PL'
    
.PARAMETER Force
    Skip confirmation prompts
    
.EXAMPLE
    .\Reset-RegionalSettings.ps1
    Resets to Polish (pl-PL) with confirmation
    
.EXAMPLE
    .\Reset-RegionalSettings.ps1 -Locale "en-US" -Force
    Resets to English (US) without confirmation
    
.NOTES
    Requires Administrator privileges
    System restart may be required for full effect
#>

param(
    [Parameter(Mandatory=$false)]
    [string]$Locale = "pl-PL",
    
    [Parameter(Mandatory=$false)]
    [switch]$Force
)

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

# Function to write colored output
function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = "White"
    )
    Write-Host $Message -ForegroundColor $Color
}

# Function to backup registry
function Backup-Registry {
    param([string]$KeyPath, [string]$BackupName)
    
    try {
        $backupPath = "$env:TEMP\RegionalSettings_Backup_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
        if (-not (Test-Path $backupPath)) {
            New-Item -ItemType Directory -Path $backupPath -Force | Out-Null
        }
        
        $regFile = "$backupPath\$BackupName.reg"
        Start-Process -FilePath "reg" -ArgumentList "export", $KeyPath, $regFile, "/y" -Wait -NoNewWindow
        Write-ColorOutput "Backed up $KeyPath to $regFile" "Green"
        return $regFile
    }
    catch {
        Write-ColorOutput "Warning: Could not backup $KeyPath - $($_.Exception.Message)" "Yellow"
        return $null
    }
}

# Function to set registry value
function Set-RegistryValue {
    param(
        [string]$Path,
        [string]$Name,
        [string]$Value,
        [string]$Type = "String"
    )
    
    try {
        if (-not (Test-Path $Path)) {
            New-Item -Path $Path -Force | Out-Null
        }
        
        Set-ItemProperty -Path $Path -Name $Name -Value $Value -Type $Type
        Write-ColorOutput "Set ${Path}\${Name} = $Value" "Cyan"
    }
    catch {
        Write-ColorOutput "Error setting ${Path}\${Name}: $($_.Exception.Message)" "Red"
    }
}

# Function to remove registry value
function Remove-RegistryValue {
    param(
        [string]$Path,
        [string]$Name
    )
    
    try {
        if (Test-Path $Path) {
            $item = Get-ItemProperty -Path $Path -Name $Name -ErrorAction SilentlyContinue
            if ($item) {
                Remove-ItemProperty -Path $Path -Name $Name
                Write-ColorOutput "Removed ${Path}\${Name}" "Yellow"
            }
        }
    }
    catch {
        Write-ColorOutput "Could not remove ${Path}\${Name}: $($_.Exception.Message)" "Yellow"
    }
}

# Main script
Write-ColorOutput "========================================" "Magenta"
Write-ColorOutput "Windows Regional Settings Reset Script" "Magenta"
Write-ColorOutput "========================================" "Magenta"
Write-ColorOutput ""

Write-ColorOutput "Target Locale: $Locale ($($SupportedLocales[$Locale]))" "Green"

if (-not $Force) {
    Write-ColorOutput ""
    Write-Warning "This script will reset ALL regional settings and may require a restart."
    $confirm = Read-Host "Do you want to continue? (y/N)"
    if ($confirm -ne "y" -and $confirm -ne "Y") {
        Write-ColorOutput "Operation cancelled." "Yellow"
        exit 0
    }
}

Write-ColorOutput ""
Write-ColorOutput "Starting regional settings reset..." "Green"

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

# Backup current settings
Write-ColorOutput "Creating registry backups..." "Blue"
foreach ($category in $RegPaths.Keys) {
    foreach ($regPath in $RegPaths[$category]) {
        $keyName = $regPath -replace ".*\\", ""
        Backup-Registry -KeyPath $regPath -BackupName "${category}_${keyName}"
    }
}

# Reset International settings
Write-ColorOutput ""
Write-ColorOutput "Resetting International settings..." "Blue"

$intlPath = "HKCU:\Control Panel\International"

# Core locale settings
Set-RegistryValue -Path $intlPath -Name "Locale" -Value $Locale
Set-RegistryValue -Path $intlPath -Name "LocaleName" -Value $Locale

# Polish-specific settings (adjust based on selected locale)
switch ($Locale) {
    "pl-PL" {
        Set-RegistryValue -Path $intlPath -Name "sLanguage" -Value "PLK"
        Set-RegistryValue -Path $intlPath -Name "sCountry" -Value "Poland"
        Set-RegistryValue -Path $intlPath -Name "sShortDate" -Value "dd.MM.yyyy"
        Set-RegistryValue -Path $intlPath -Name "sLongDate" -Value "d MMMM yyyy"
        Set-RegistryValue -Path $intlPath -Name "sTimeFormat" -Value "HH:mm:ss"
        Set-RegistryValue -Path $intlPath -Name "sShortTime" -Value "HH:mm"
        Set-RegistryValue -Path $intlPath -Name "sCurrency" -Value "zł"
        Set-RegistryValue -Path $intlPath -Name "sMonDecimalSep" -Value ","
        Set-RegistryValue -Path $intlPath -Name "sMonThousandSep" -Value " "
        Set-RegistryValue -Path $intlPath -Name "sDecimal" -Value ","
        Set-RegistryValue -Path $intlPath -Name "sThousand" -Value " "
        Set-RegistryValue -Path $intlPath -Name "sList" -Value ";"
        Set-RegistryValue -Path $intlPath -Name "iCountry" -Value "48"
        Set-RegistryValue -Path $intlPath -Name "iCurrency" -Value "3"
        Set-RegistryValue -Path $intlPath -Name "iCurrDigits" -Value "2"
        Set-RegistryValue -Path $intlPath -Name "iDate" -Value "1"
        Set-RegistryValue -Path $intlPath -Name "iTime" -Value "1"
        Set-RegistryValue -Path $intlPath -Name "iTLZero" -Value "1"
        Set-RegistryValue -Path $intlPath -Name "s1159" -Value ""
        Set-RegistryValue -Path $intlPath -Name "s2359" -Value ""
    }
    "en-US" {
        Set-RegistryValue -Path $intlPath -Name "sLanguage" -Value "ENU"
        Set-RegistryValue -Path $intlPath -Name "sCountry" -Value "United States"
        Set-RegistryValue -Path $intlPath -Name "sShortDate" -Value "M/d/yyyy"
        Set-RegistryValue -Path $intlPath -Name "sLongDate" -Value "dddd, MMMM d, yyyy"
        Set-RegistryValue -Path $intlPath -Name "sTimeFormat" -Value "h:mm:ss tt"
        Set-RegistryValue -Path $intlPath -Name "sShortTime" -Value "h:mm tt"
        Set-RegistryValue -Path $intlPath -Name "sCurrency" -Value "$"
        Set-RegistryValue -Path $intlPath -Name "sMonDecimalSep" -Value "."
        Set-RegistryValue -Path $intlPath -Name "sMonThousandSep" -Value ","
        Set-RegistryValue -Path $intlPath -Name "sDecimal" -Value "."
        Set-RegistryValue -Path $intlPath -Name "sThousand" -Value ","
        Set-RegistryValue -Path $intlPath -Name "sList" -Value ","
        Set-RegistryValue -Path $intlPath -Name "iCountry" -Value "1"
        Set-RegistryValue -Path $intlPath -Name "iCurrency" -Value "0"
        Set-RegistryValue -Path $intlPath -Name "iCurrDigits" -Value "2"
        Set-RegistryValue -Path $intlPath -Name "iDate" -Value "0"
        Set-RegistryValue -Path $intlPath -Name "iTime" -Value "0"
        Set-RegistryValue -Path $intlPath -Name "iTLZero" -Value "0"
        Set-RegistryValue -Path $intlPath -Name "s1159" -Value "AM"
        Set-RegistryValue -Path $intlPath -Name "s2359" -Value "PM"
    }
    # Add more locales as needed
    default {
        Write-ColorOutput "Using generic settings for $Locale" "Yellow"
        Set-RegistryValue -Path $intlPath -Name "sLanguage" -Value $Locale.Split('-')[0].ToUpper()
        Set-RegistryValue -Path $intlPath -Name "sCountry" -Value $SupportedLocales[$Locale]
    }
}

# Reset Windows 11 specific memory slots
Write-ColorOutput ""
Write-ColorOutput "Resetting Windows 11 memory slots..." "Blue"

# Clear user profile settings
$userProfilePath = "HKCU:\Control Panel\International\User Profile"
if (Test-Path $userProfilePath) {
    Remove-Item -Path $userProfilePath -Recurse -Force -ErrorAction SilentlyContinue
    Write-ColorOutput "Cleared user profile regional settings" "Yellow"
}

# Reset geographic location
Set-RegistryValue -Path "HKCU:\Control Panel\International\Geo" -Name "Nation" -Value (if ($Locale -eq "pl-PL") { "191" } else { "244" })

# Clear input method settings
$inputSettingsPath = "HKCU:\Software\Microsoft\Input\Settings"
if (Test-Path $inputSettingsPath) {
    Get-ChildItem -Path $inputSettingsPath | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
    Write-ColorOutput "Cleared input method settings" "Yellow"
}

# Reset language bar settings
Set-RegistryValue -Path "HKCU:\Software\Microsoft\CTF\LangBar" -Name "ShowStatus" -Value "3" -Type "DWord"
Set-RegistryValue -Path "HKCU:\Software\Microsoft\CTF\LangBar" -Name "Label" -Value "1" -Type "DWord"

# Reset system locale (requires admin)
Write-ColorOutput ""
Write-ColorOutput "Setting system locale..." "Blue"

try {
    # Use PowerShell cmdlets for internationalization
    Set-WinSystemLocale -SystemLocale $Locale
    Set-WinUserLanguageList -LanguageList $Locale -Force
    Set-WinHomeLocation -GeoId (if ($Locale -eq "pl-PL") { 191 } else { 244 })
    Write-ColorOutput "System locale settings updated" "Green"
}
catch {
    Write-ColorOutput "Warning: Could not set system locale (may require different approach): $($_.Exception.Message)" "Yellow"
}

# Clear MRU (Most Recently Used) lists
Write-ColorOutput ""
Write-ColorOutput "Clearing MRU lists..." "Blue"

$mruPaths = @(
    "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\RunMRU",
    "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\TypedPaths"
)

foreach ($mruPath in $mruPaths) {
    if (Test-Path $mruPath) {
        Get-ItemProperty -Path $mruPath | ForEach-Object {
            $_.PSObject.Properties | Where-Object { $_.Name -ne "PSPath" -and $_.Name -ne "PSParentPath" -and $_.Name -ne "PSChildName" -and $_.Name -ne "PSDrive" -and $_.Name -ne "PSProvider" } | ForEach-Object {
                Remove-ItemProperty -Path $mruPath -Name $_.Name -ErrorAction SilentlyContinue
            }
        }
        Write-ColorOutput "Cleared MRU: $mruPath" "Yellow"
    }
}

Write-ColorOutput ""
Write-ColorOutput "========================================" "Magenta"
Write-ColorOutput "Regional Settings Reset Complete!" "Green"
Write-ColorOutput "========================================" "Magenta"
Write-ColorOutput ""
Write-ColorOutput "Target Locale: $Locale ($($SupportedLocales[$Locale]))" "Green"
Write-ColorOutput ""
Write-Warning "A system restart is recommended for all changes to take effect."
Write-ColorOutput ""

if (-not $Force) {
    $restart = Read-Host "Would you like to restart now? (y/N)"
    if ($restart -eq "y" -or $restart -eq "Y") {
        Write-ColorOutput "Restarting system in 10 seconds..." "Yellow"
        Start-Sleep -Seconds 10
        Restart-Computer -Force
    }
}

Write-ColorOutput "Script completed successfully." "Green"