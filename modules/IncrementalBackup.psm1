# Advanced Rollback System for Regional Settings Reset
# PowerShell Module for Incremental Backup and Restoration

function New-IncrementalBackup {
    param(
        [string]$BasePath,
        [string]$BackupName,
        [string]$PreviousBackupPath = ""
    )
    
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $backupPath = "$BasePath\IncrementalBackup_$BackupName_$timestamp"
    
    try {
        New-Item -ItemType Directory -Path $backupPath -Force | Out-Null
        
        # Registry paths to monitor
        $registryPaths = @(
            "HKCU:\Control Panel\International",
            "HKCU:\Control Panel\International\User Profile", 
            "HKCU:\Control Panel\International\Geo",
            "HKCU:\Software\Microsoft\Input\Settings"
        )
        
        $changeLog = @()
        
        foreach ($regPath in $registryPaths) {
            if (Test-Path $regPath) {
                $keyName = $regPath -replace ".*\\", ""
                $backupFile = "$backupPath\$keyName.reg"
                
                # Export current state
                $process = Start-Process -FilePath "reg" -ArgumentList "export", $regPath, $backupFile, "/y" -Wait -NoNewWindow -PassThru
                
                if ($process.ExitCode -eq 0) {
                    $changeLog += @{
                        "Path" = $regPath
                        "BackupFile" = $backupFile
                        "Timestamp" = $timestamp
                        "Size" = (Get-Item $backupFile).Length
                    }
                    
                    Write-Host "✅ Backed up: $regPath" -ForegroundColor Green
                } else {
                    Write-Warning "Failed to backup: $regPath"
                }
            }
        }
        
        # Save change log
        $changeLogPath = "$backupPath\changelog.json"
        $changeLog | ConvertTo-Json -Depth 3 | Out-File -FilePath $changeLogPath -Encoding UTF8
        
        # Create backup metadata
        $metadata = @{
            "BackupName" = $BackupName
            "Timestamp" = $timestamp
            "Type" = "Incremental" 
            "PreviousBackup" = $PreviousBackupPath
            "RegistryPaths" = $registryPaths
            "ChangeCount" = $changeLog.Count
            "TotalSize" = ($changeLog | Measure-Object -Property Size -Sum).Sum
        }
        
        $metadataPath = "$backupPath\metadata.json"
        $metadata | ConvertTo-Json -Depth 3 | Out-File -FilePath $metadataPath -Encoding UTF8
        
        Write-Host "📦 Incremental backup created: $backupPath" -ForegroundColor Cyan
        return $backupPath
    }
    catch {
        Write-Error "Failed to create incremental backup: $($_.Exception.Message)"
        return $null
    }
}

function Restore-IncrementalBackup {
    param(
        [string]$BackupPath,
        [switch]$DryRun,
        [switch]$Verbose
    )
    
    if (-not (Test-Path $BackupPath)) {
        Write-Error "Backup path not found: $BackupPath"
        return $false
    }
    
    try {
        # Load metadata
        $metadataPath = "$BackupPath\metadata.json"
        if (-not (Test-Path $metadataPath)) {
            Write-Error "Backup metadata not found: $metadataPath"
            return $false
        }
        
        $metadata = Get-Content $metadataPath | ConvertFrom-Json
        
        Write-Host "🔄 Restoring from incremental backup:" -ForegroundColor Yellow
        Write-Host "  Name: $($metadata.BackupName)" -ForegroundColor White
        Write-Host "  Timestamp: $($metadata.Timestamp)" -ForegroundColor White
        Write-Host "  Changes: $($metadata.ChangeCount)" -ForegroundColor White
        Write-Host "  Size: $([math]::Round($metadata.TotalSize / 1KB, 2)) KB" -ForegroundColor White
        
        if ($DryRun) {
            Write-Host "🧪 DRY RUN MODE - No changes will be made" -ForegroundColor Magenta
        }
        
        # Load change log
        $changeLogPath = "$BackupPath\changelog.json"
        if (Test-Path $changeLogPath) {
            $changeLog = Get-Content $changeLogPath | ConvertFrom-Json
            
            $restoredCount = 0
            $failedCount = 0
            
            foreach ($change in $changeLog) {
                if ($Verbose) {
                    Write-Host "  Restoring: $($change.Path)" -ForegroundColor Gray
                }
                
                if (-not $DryRun) {
                    $process = Start-Process -FilePath "reg" -ArgumentList "import", $change.BackupFile -Wait -NoNewWindow -PassThru
                    
                    if ($process.ExitCode -eq 0) {
                        $restoredCount++
                        if ($Verbose) {
                            Write-Host "    ✅ Success" -ForegroundColor Green
                        }
                    } else {
                        $failedCount++
                        Write-Warning "    ❌ Failed to restore: $($change.Path)"
                    }
                } else {
                    Write-Host "    📋 Would restore: $($change.BackupFile)" -ForegroundColor Blue
                    $restoredCount++
                }
            }
            
            Write-Host "📊 Restore Summary:" -ForegroundColor Cyan
            Write-Host "  Restored: $restoredCount" -ForegroundColor Green
            if ($failedCount -gt 0) {
                Write-Host "  Failed: $failedCount" -ForegroundColor Red
            }
            
            return $failedCount -eq 0
        } else {
            Write-Error "Change log not found: $changeLogPath"
            return $false
        }
    }
    catch {
        Write-Error "Failed to restore incremental backup: $($_.Exception.Message)"
        return $false
    }
}

function Get-BackupChain {
    param([string]$BackupPath)
    
    if (-not (Test-Path $BackupPath)) {
        Write-Error "Backup path not found: $BackupPath"
        return @()
    }
    
    try {
        $metadataPath = "$BackupPath\metadata.json"
        if (-not (Test-Path $metadataPath)) {
            return @($BackupPath)
        }
        
        $currentMetadata = Get-Content $metadataPath | ConvertFrom-Json
        $chain = @($BackupPath)
        
                # Follow the chain backwards\n        $currentBackup = $currentMetadata.PreviousBackup\n        while ($currentBackup -and (Test-Path $currentBackup)) {\n            $chain = @($currentBackup) + $chain\n            \n            $prevMetadataPath = \"$currentBackup\\metadata.json\"\n            if (Test-Path $prevMetadataPath) {\n                $prevMetadata = Get-Content $prevMetadataPath | ConvertFrom-Json\n                $currentBackup = $prevMetadata.PreviousBackup\n            } else {\n                break\n            }\n        }
        
        return $chain
    }
    catch {
        Write-Warning "Error building backup chain: $($_.Exception.Message)"
        return @($BackupPath)
    }
}

function Test-BackupIntegrity {
    param([string]$BackupPath)
    
    if (-not (Test-Path $BackupPath)) {
        Write-Error "Backup path not found: $BackupPath"
        return $false
    }
    
    try {
        # Check metadata
        $metadataPath = "$BackupPath\metadata.json"
        if (-not (Test-Path $metadataPath)) {
            Write-Warning "Missing metadata file: $metadataPath"
            return $false
        }
        
        $metadata = Get-Content $metadataPath | ConvertFrom-Json
        
        # Check change log
        $changeLogPath = "$BackupPath\changelog.json"
        if (-not (Test-Path $changeLogPath)) {
            Write-Warning "Missing change log: $changeLogPath"
            return $false
        }
        
        $changeLog = Get-Content $changeLogPath | ConvertFrom-Json
        
        # Verify backup files
        $missingFiles = @()
        $corruptFiles = @()
        
        foreach ($change in $changeLog) {
            if (-not (Test-Path $change.BackupFile)) {
                $missingFiles += $change.BackupFile
            } else {
                # Basic corruption check (file size)
                $actualSize = (Get-Item $change.BackupFile).Length
                if ($actualSize -ne $change.Size) {
                    $corruptFiles += $change.BackupFile
                }
            }
        }
        
        $isValid = ($missingFiles.Count -eq 0) -and ($corruptFiles.Count -eq 0)
        
        if ($isValid) {
            Write-Host "✅ Backup integrity check passed" -ForegroundColor Green
        } else {
            Write-Host "❌ Backup integrity check failed" -ForegroundColor Red
            if ($missingFiles.Count -gt 0) {
                Write-Host "  Missing files: $($missingFiles.Count)" -ForegroundColor Red
            }
            if ($corruptFiles.Count -gt 0) {
                Write-Host "  Corrupt files: $($corruptFiles.Count)" -ForegroundColor Red
            }
        }
        
        return $isValid
    }
    catch {
        Write-Error "Error during integrity check: $($_.Exception.Message)"
        return $false
    }
}

function Compare-BackupStates {
    param(
        [string]$BackupPath1,
        [string]$BackupPath2
    )
    
    try {
        $changes = @()
        
        # Load both change logs
        $changeLog1 = Get-Content "$BackupPath1\changelog.json" | ConvertFrom-Json
        $changeLog2 = Get-Content "$BackupPath2\changelog.json" | ConvertFrom-Json
        
        # Compare registry paths
        $paths1 = $changeLog1 | ForEach-Object { $_.Path }
        $paths2 = $changeLog2 | ForEach-Object { $_.Path }
        
        $allPaths = $paths1 + $paths2 | Sort-Object -Unique
        
        foreach ($path in $allPaths) {
            $file1 = ($changeLog1 | Where-Object { $_.Path -eq $path }).BackupFile
            $file2 = ($changeLog2 | Where-Object { $_.Path -eq $path }).BackupFile
            
            if ($file1 -and $file2) {
                # Compare file sizes as simple difference check
                $size1 = (Get-Item $file1).Length
                $size2 = (Get-Item $file2).Length
                
                if ($size1 -ne $size2) {
                    $changes += @{
                        "Path" = $path
                        "Type" = "Modified"
                        "SizeDiff" = $size2 - $size1
                    }
                }
            } elseif ($file2 -and -not $file1) {
                $changes += @{
                    "Path" = $path
                    "Type" = "Added"
                    "SizeDiff" = (Get-Item $file2).Length
                }
            } elseif ($file1 -and -not $file2) {
                $changes += @{
                    "Path" = $path
                    "Type" = "Removed"
                    "SizeDiff" = -(Get-Item $file1).Length
                }
            }
        }
        
        return $changes
    }
    catch {
        Write-Error "Error comparing backup states: $($_.Exception.Message)"
        return @()
    }
}

Export-ModuleMember -Function New-IncrementalBackup, Restore-IncrementalBackup, Get-BackupChain, Test-BackupIntegrity, Compare-BackupStates