# Advanced Backup Manager with Compression and Encryption
# PowerShell Module for Enhanced Backup Operations

function New-CompressedBackup {
    param(
        [string]$SourcePath,
        [string]$DestinationPath,
        [SecureString]$Password,
        [switch]$Encrypt
    )
    
    try {
        if ($Encrypt -and $Password) {
            # Create encrypted compressed backup
            $passwordPlainText = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($Password))
            Compress-Archive -Path $SourcePath -DestinationPath "$DestinationPath.zip" -Force
            
            # Encrypt the zip file (simplified approach using built-in encryption)
            $encryptedPath = "$DestinationPath.encrypted"
            $bytes = [System.IO.File]::ReadAllBytes("$DestinationPath.zip")
            $encryptedBytes = [System.Security.Cryptography.ProtectedData]::Protect($bytes, $null, [System.Security.Cryptography.DataProtectionScope]::CurrentUser)
            [System.IO.File]::WriteAllBytes($encryptedPath, $encryptedBytes)
            
            Remove-Item "$DestinationPath.zip" -Force
            return $encryptedPath
        } else {
            # Create standard compressed backup
            Compress-Archive -Path $SourcePath -DestinationPath "$DestinationPath.zip" -Force
            return "$DestinationPath.zip"
        }
    }
    catch {
        Write-Error "Failed to create compressed backup: $($_.Exception.Message)"
        return $null
    }
}

function Restore-CompressedBackup {
    param(
        [string]$BackupPath,
        [string]$DestinationPath,
        [SecureString]$Password
    )
    
    try {
        if ($BackupPath -like "*.encrypted") {
            # Decrypt and extract
            $encryptedBytes = [System.IO.File]::ReadAllBytes($BackupPath)
            $decryptedBytes = [System.Security.Cryptography.ProtectedData]::Unprotect($encryptedBytes, $null, [System.Security.Cryptography.DataProtectionScope]::CurrentUser)
            
            $tempZip = "$env:TEMP\temp_backup.zip"
            [System.IO.File]::WriteAllBytes($tempZip, $decryptedBytes)
            
            Expand-Archive -Path $tempZip -DestinationPath $DestinationPath -Force
            Remove-Item $tempZip -Force
        } else {
            # Extract standard compressed backup
            Expand-Archive -Path $BackupPath -DestinationPath $DestinationPath -Force
        }
        
        return $true
    }
    catch {
        Write-Error "Failed to restore compressed backup: $($_.Exception.Message)"
        return $false
    }
}

function Get-BackupSize {
    param([string]$BackupPath)
    
    if (Test-Path $BackupPath) {
        $size = (Get-Item $BackupPath).Length
        return [math]::Round($size / 1MB, 2)
    }
    return 0
}

function Test-BackupIntegrity {
    param([string]$BackupPath)
    
    try {
        if ($BackupPath -like "*.encrypted") {
            # Test encrypted backup
            $encryptedBytes = [System.IO.File]::ReadAllBytes($BackupPath)
            $decryptedBytes = [System.Security.Cryptography.ProtectedData]::Unprotect($encryptedBytes, $null, [System.Security.Cryptography.DataProtectionScope]::CurrentUser)
            
            $tempZip = "$env:TEMP\temp_test.zip"
            [System.IO.File]::WriteAllBytes($tempZip, $decryptedBytes)
            
            $testResult = Test-Path $tempZip
            Remove-Item $tempZip -Force -ErrorAction SilentlyContinue
            return $testResult
        } else {
            # Test standard zip
            Add-Type -AssemblyName System.IO.Compression.FileSystem
            $archive = [System.IO.Compression.ZipFile]::OpenRead($BackupPath)
            $archive.Dispose()
            return $true
        }
    }
    catch {
        return $false
    }
}

Export-ModuleMember -Function New-CompressedBackup, Restore-CompressedBackup, Get-BackupSize, Test-BackupIntegrity