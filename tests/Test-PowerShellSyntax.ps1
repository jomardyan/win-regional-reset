#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Local PowerShell syntax validation script for GitHub Actions testing
    
.DESCRIPTION
    This script validates PowerShell syntax for all scripts and modules
    in the repository. It mimics the GitHub Actions workflow validation
    to ensure consistency between local and CI/CD testing.
    
.PARAMETER ShowDetails
    Show additional details like token counts
    
.PARAMETER PassThru
    Return results as an object instead of exiting
    
.EXAMPLE
    .\Test-PowerShellSyntax.ps1
    
.EXAMPLE
    .\Test-PowerShellSyntax.ps1 -ShowDetails
    
.NOTES
    Run this script before committing to catch syntax errors early
#>

param(
    [Parameter(Mandatory=$false)]
    [switch]$ShowDetails,
    
    [Parameter(Mandatory=$false)]
    [switch]$PassThru
)

# Set error action preference
$ErrorActionPreference = "Stop"

# Initialize counters
$totalFiles = 0
$validFiles = 0
$allValid = $true

# Define file lists
$scriptFiles = @(
    "scripts/Reset-RegionalSettings.ps1",
    "group-policy/Deploy-RegionalSettings-GP.ps1"
)

$moduleFiles = @(
    "modules/BackupCompression.psm1",
    "modules/IncrementalBackup.psm1"
)

Write-Host "🔍 Validating PowerShell script syntax..." -ForegroundColor Cyan
Write-Host ""

# Test main scripts
Write-Host "📄 Testing Scripts:" -ForegroundColor Blue
foreach ($script in $scriptFiles) {
    $totalFiles++
    Write-Host "  Checking: $script" -ForegroundColor Yellow
    
    try {
        if (Test-Path $script) {
            $parseErrors = $null
            $tokens = [System.Management.Automation.PSParser]::Tokenize((Get-Content $script -Raw), [ref]$parseErrors)
            
            if ($parseErrors.Count -eq 0) {
                Write-Host "    ✅ Syntax OK" -ForegroundColor Green
                $validFiles++
                
                if ($ShowDetails) {
                    Write-Host "    📊 Tokens found: $($tokens.Count)" -ForegroundColor Cyan
                }
            } else {
                Write-Host "    ❌ Parse Errors Found:" -ForegroundColor Red
                foreach ($parseError in $parseErrors) {
                    Write-Host "      • $parseError" -ForegroundColor Red
                }
                $allValid = $false
            }
        } else {
            Write-Host "    ❌ File not found" -ForegroundColor Red
            $allValid = $false
        }
    }
    catch {
        Write-Host "    ❌ Syntax Error: $($_.Exception.Message)" -ForegroundColor Red
        $allValid = $false
    }
}

Write-Host ""

# Test module files
Write-Host "📦 Testing Modules:" -ForegroundColor Blue
foreach ($module in $moduleFiles) {
    $totalFiles++
    Write-Host "  Checking: $module" -ForegroundColor Yellow
    
    try {
        if (Test-Path $module) {
            $parseErrors = $null
            $tokens = [System.Management.Automation.PSParser]::Tokenize((Get-Content $module -Raw), [ref]$parseErrors)
            
            if ($parseErrors.Count -eq 0) {
                Write-Host "    ✅ Syntax OK" -ForegroundColor Green
                $validFiles++
                
                if ($ShowDetails) {
                    Write-Host "    📊 Tokens found: $($tokens.Count)" -ForegroundColor Cyan
                }
            } else {
                Write-Host "    ❌ Parse Errors Found:" -ForegroundColor Red
                foreach ($parseError in $parseErrors) {
                    Write-Host "      • $parseError" -ForegroundColor Red
                }
                $allValid = $false
            }
        } else {
            Write-Host "    ❌ File not found" -ForegroundColor Red
            $allValid = $false
        }
    }
    catch {
        Write-Host "    ❌ Syntax Error: $($_.Exception.Message)" -ForegroundColor Red
        $allValid = $false
    }
}

Write-Host ""

# Summary
Write-Host "📊 Syntax Validation Summary:" -ForegroundColor Cyan
Write-Host "  Total Files: $totalFiles" -ForegroundColor White
Write-Host "  Valid Files: $validFiles" -ForegroundColor Green

# Calculate success rate
if ($totalFiles -gt 0) {
    $successRate = [math]::Round(($validFiles / $totalFiles) * 100, 1)
    Write-Host "  Success Rate: $successRate%" -ForegroundColor White
} else {
    Write-Host "  Success Rate: N/A (No files found)" -ForegroundColor Yellow
    $allValid = $false
}

Write-Host ""

# Final result
if ($allValid) {
    Write-Host "✅ All PowerShell files have valid syntax!" -ForegroundColor Green
    Write-Host "🚀 Ready for GitHub Actions deployment!" -ForegroundColor Cyan
    
    if ($PassThru) {
        return @{
            Success = $true
            TotalFiles = $totalFiles
            ValidFiles = $validFiles
            SuccessRate = if ($totalFiles -gt 0) { [math]::Round(($validFiles / $totalFiles) * 100, 1) } else { 0 }
        }
    }
    
    exit 0
} else {
    Write-Host "❌ PowerShell syntax validation failed!" -ForegroundColor Red
    Write-Host "🔧 Please fix the syntax errors before committing." -ForegroundColor Yellow
    
    if ($PassThru) {
        return @{
            Success = $false
            TotalFiles = $totalFiles
            ValidFiles = $validFiles
            SuccessRate = if ($totalFiles -gt 0) { [math]::Round(($validFiles / $totalFiles) * 100, 1) } else { 0 }
        }
    }
    
    exit 1
}