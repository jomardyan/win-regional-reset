#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Test script to verify backup functionality
#>

# Test the backup path conversion
function Test-BackupPathConversion {
    $testPaths = @(
        "HKCU:\Control Panel\International",
        "HKLM:\SYSTEM\CurrentControlSet\Control\Nls\Language"
    )
    
    Write-Host "Testing registry path conversion:" -ForegroundColor Green
    foreach ($path in $testPaths) {
        $winRegPath = $path -replace "HKCU:", "HKEY_CURRENT_USER" -replace "HKLM:", "HKEY_LOCAL_MACHINE"
        Write-Host "  PowerShell: $path" -ForegroundColor Yellow
        Write-Host "  Windows:    $winRegPath" -ForegroundColor Cyan
        Write-Host ""
    }
}

# Test registry key existence
function Test-RegistryKeyExistence {
    $testPaths = @(
        "HKCU:\Control Panel\International",
        "HKCU:\Control Panel\International\Geo",
        "HKCU:\Control Panel\International\User Profile",
        "HKCU:\Software\Microsoft\Input\Settings",
        "HKLM:\SYSTEM\CurrentControlSet\Control\Nls\Language"
    )
    
    Write-Host "Testing registry key existence:" -ForegroundColor Green
    foreach ($path in $testPaths) {
        $exists = Test-Path $path
        $status = if ($exists) { "EXISTS" } else { "MISSING" }
        $color = if ($exists) { "Green" } else { "Red" }
        Write-Host "  $path : $status" -ForegroundColor $color
    }
}

# Run tests
Test-BackupPathConversion
Test-RegistryKeyExistence

Write-Host "Test completed. Review the output above to understand which keys exist." -ForegroundColor Magenta