#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Group Policy Deployment Script for Windows Regional Settings Reset
    
.DESCRIPTION
    This script provides Active Directory Group Policy compatible deployment
    of the Windows Regional Settings Reset toolkit. Designed for enterprise
    environments with network logging, silent execution, and compliance reporting.
    
.PARAMETER Locale
    Target locale code (e.g., 'pl-PL', 'en-US', 'de-DE')
    Default: 'en-US' (enterprise default)
    
.PARAMETER ConfigurationProfile
    Predefined configuration profile for enterprise deployment
    Options: 'Enterprise', 'Corporate', 'Standard', 'Minimal'
    Default: 'Enterprise'
    
.PARAMETER NetworkLogPath
    UNC path for centralized logging (e.g., '\\domain.com\logs\regional')
    If not provided, logs locally and attempts to copy to SYSVOL
    
.PARAMETER ComplianceMode
    Enable compliance reporting and audit trail
    Options: 'SOX', 'HIPAA', 'ISO27001', 'Standard'
    Default: 'Standard'
    
.PARAMETER DeploymentTarget
    Target deployment scope
    Options: 'User', 'Computer', 'Both'
    Default: 'Both'
    
.PARAMETER ReportingEnabled
    Enable detailed reporting for Group Policy management console
    
.PARAMETER DryRun
    Perform validation and planning without making changes
    
.EXAMPLE
    .\Deploy-RegionalSettings-GP.ps1
    Standard enterprise deployment with default settings
    
.EXAMPLE
    .\Deploy-RegionalSettings-GP.ps1 -Locale "de-DE" -ComplianceMode "SOX" -NetworkLogPath "\\corp.local\sysvol\logs"
    Enterprise deployment with SOX compliance and centralized logging
    
.EXAMPLE
    .\Deploy-RegionalSettings-GP.ps1 -DryRun -ConfigurationProfile "Minimal"
    Test deployment planning without making changes
    
.NOTES
    Designed for Active Directory Group Policy deployment
    Requires domain environment and appropriate permissions
    Compatible with SCCM, PDQ Deploy, and other enterprise tools
    
    Version: 1.0
    Author: Enterprise IT Team
    Last Modified: September 2024
#>

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("pl-PL", "en-US", "en-GB", "de-DE", "fr-FR", "es-ES", "it-IT", "pt-PT", "ru-RU", "zh-CN", "ja-JP", "ko-KR")]
    [string]$Locale = "en-US",
    
    [Parameter(Mandatory=$false)]
    [ValidateSet("Enterprise", "Corporate", "Standard", "Minimal")]
    [string]$ConfigurationProfile = "Enterprise",
    
    [Parameter(Mandatory=$false)]
    [string]$NetworkLogPath,
    
    [Parameter(Mandatory=$false)]
    [ValidateSet("SOX", "HIPAA", "ISO27001", "Standard")]
    [string]$ComplianceMode = "Standard",
    
    [Parameter(Mandatory=$false)]
    [ValidateSet("User", "Computer", "Both")]
    [string]$DeploymentTarget = "Both",
    
    [Parameter(Mandatory=$false)]
    [switch]$ReportingEnabled,
    
    [Parameter(Mandatory=$false)]
    [switch]$DryRun
)

# Script initialization
$script:ScriptVersion = "1.0"
$script:StartTime = Get-Date
$script:ScriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
$script:MainScript = Join-Path $script:ScriptPath "Reset-RegionalSettings.ps1"
$script:EventSource = "RegionalSettings-GP"
$script:DeploymentId = [System.Guid]::NewGuid().ToString("N")[0..7] -join ""

# Enterprise logging configuration
$script:LocalLogPath = "$env:TEMP\RegionalSettings-GP_$($script:DeploymentId)_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
$script:ComplianceLogPath = "$env:TEMP\RegionalSettings-Compliance_$($script:DeploymentId)_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
$script:ReportPath = "$env:TEMP\RegionalSettings-Report_$($script:DeploymentId)_$(Get-Date -Format 'yyyyMMdd_HHmmss').xml"

# Initialize counters
$script:TotalOperations = 0
$script:SuccessfulOperations = 0
$script:FailedOperations = 0
$script:WarningCount = 0

# Function to write enterprise logs
function Write-EnterpriseLog {
    param(
        [string]$Message,
        [ValidateSet("INFO", "WARN", "ERROR", "DEBUG", "AUDIT")]
        [string]$Level = "INFO",
        [string]$Component = "Main"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
    $logEntry = "[$timestamp] [$Level] [$Component] $Message"
    
    # Write to console with color coding
    $color = switch ($Level) {
        "INFO" { "Green" }
        "WARN" { "Yellow" }
        "ERROR" { "Red" }
        "DEBUG" { "Cyan" }
        "AUDIT" { "Magenta" }
        default { "White" }
    }
    
    Write-Host $logEntry -ForegroundColor $color
    
    # Write to local log
    try {
        $logEntry | Add-Content -Path $script:LocalLogPath -ErrorAction SilentlyContinue
        
        # Write compliance logs
        if ($Level -eq "AUDIT" -or $ComplianceMode -ne "Standard") {
            $complianceEntry = @{
                Timestamp = $timestamp
                Level = $Level
                Component = $Component
                Message = $Message
                User = $env:USERNAME
                Computer = $env:COMPUTERNAME
                Domain = $env:USERDOMAIN
                DeploymentId = $script:DeploymentId
                ComplianceMode = $ComplianceMode
            } | ConvertTo-Json -Compress
            
            $complianceEntry | Add-Content -Path $script:ComplianceLogPath -ErrorAction SilentlyContinue
        }
    }
    catch {
        # Silent fail for logging issues
    }
    
    # Write to Windows Event Log for enterprise monitoring
    try {
        if (-not [System.Diagnostics.EventLog]::SourceExists($script:EventSource)) {
            [System.Diagnostics.EventLog]::CreateEventSource($script:EventSource, "Application")
        }
        
        $eventType = switch ($Level) {
            "ERROR" { "Error" }
            "WARN" { "Warning" }
            default { "Information" }
        }
        
        Write-EventLog -LogName Application -Source $script:EventSource -EntryType $eventType -EventId 1000 -Message "$Component`: $Message"
    }
    catch {
        # Silent fail for event log issues
    }
}

# Function to detect domain environment
function Test-DomainEnvironment {
    try {
        $computerInfo = Get-ComputerInfo -Property CsDomain, CsDomainRole
        $isDomainJoined = $computerInfo.CsDomainRole -in @("MemberWorkstation", "MemberServer", "BackupDomainController", "PrimaryDomainController")
        
        if ($isDomainJoined) {
            Write-EnterpriseLog "Domain environment detected: $($computerInfo.CsDomain)" "INFO" "Environment"
            return @{
                IsDomainJoined = $true
                Domain = $computerInfo.CsDomain
                DomainRole = $computerInfo.CsDomainRole
            }
        } else {
            Write-EnterpriseLog "Standalone/workgroup environment detected" "WARN" "Environment"
            return @{
                IsDomainJoined = $false
                Domain = $null
                DomainRole = $computerInfo.CsDomainRole
            }
        }
    }
    catch {
        Write-EnterpriseLog "Failed to detect domain environment: $($_.Exception.Message)" "ERROR" "Environment"
        return @{
            IsDomainJoined = $false
            Domain = $null
            DomainRole = "Unknown"
        }
    }
}

# Function to get configuration profile settings
function Get-ConfigurationProfile {
    param([string]$Profile)
    
    $profiles = @{
        "Enterprise" = @{
            Force = $true
            BackupEnabled = $true
            PerformanceMonitoring = $true
            AuditLevel = "Detailed"
            RetryAttempts = 5
            TimeoutMinutes = 30
            NetworkBackup = $true
            EncryptionEnabled = $true
        }
        "Corporate" = @{
            Force = $true
            BackupEnabled = $true
            PerformanceMonitoring = $false
            AuditLevel = "Standard"
            RetryAttempts = 3
            TimeoutMinutes = 20
            NetworkBackup = $true
            EncryptionEnabled = $false
        }
        "Standard" = @{
            Force = $true
            BackupEnabled = $true
            PerformanceMonitoring = $false
            AuditLevel = "Basic"
            RetryAttempts = 2
            TimeoutMinutes = 15
            NetworkBackup = $false
            EncryptionEnabled = $false
        }
        "Minimal" = @{
            Force = $true
            BackupEnabled = $false
            PerformanceMonitoring = $false
            AuditLevel = "Basic"
            RetryAttempts = 1
            TimeoutMinutes = 10
            NetworkBackup = $false
            EncryptionEnabled = $false
        }
    }
    
    return $profiles[$Profile]
}

# Function to validate deployment prerequisites
function Test-DeploymentPrerequisites {
    Write-EnterpriseLog "Validating deployment prerequisites..." "INFO" "Validation"
    $script:TotalOperations++
    
    $validationResults = @{
        OverallStatus = $true
        Details = @()
    }
    
    # Check if main script exists
    if (-not (Test-Path $script:MainScript)) {
        $validationResults.OverallStatus = $false
        $validationResults.Details += "Main script not found: $script:MainScript"
        Write-EnterpriseLog "Main script not found: $script:MainScript" "ERROR" "Validation"
        $script:FailedOperations++
        return $validationResults
    }
    
    # Check PowerShell version
    if ($PSVersionTable.PSVersion.Major -lt 5) {
        $validationResults.OverallStatus = $false
        $validationResults.Details += "PowerShell 5.0 or higher required. Current version: $($PSVersionTable.PSVersion)"
        Write-EnterpriseLog "Insufficient PowerShell version: $($PSVersionTable.PSVersion)" "ERROR" "Validation"
    }
    
    # Check admin privileges
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    $isAdmin = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    
    if (-not $isAdmin) {
        $validationResults.OverallStatus = $false
        $validationResults.Details += "Administrator privileges required"
        Write-EnterpriseLog "Administrator privileges required" "ERROR" "Validation"
    }
    
    # Check network connectivity for centralized logging
    if ($NetworkLogPath) {
        $networkAvailable = Test-Path (Split-Path $NetworkLogPath -Parent) -ErrorAction SilentlyContinue
        if (-not $networkAvailable) {
            $validationResults.Details += "Network log path not accessible: $NetworkLogPath"
            Write-EnterpriseLog "Network log path not accessible: $NetworkLogPath" "WARN" "Validation"
            $script:WarningCount++
        }
    }
    
    # Check execution policy
    $executionPolicy = Get-ExecutionPolicy
    if ($executionPolicy -eq "Restricted") {
        $validationResults.Details += "PowerShell execution policy is Restricted"
        Write-EnterpriseLog "PowerShell execution policy is Restricted. Will attempt bypass." "WARN" "Validation"
        $script:WarningCount++
    }
    
    if ($validationResults.OverallStatus) {
        Write-EnterpriseLog "All prerequisites validated successfully" "INFO" "Validation"
        $script:SuccessfulOperations++
    } else {
        $script:FailedOperations++
    }
    
    return $validationResults
}

# Function to create deployment configuration
function New-DeploymentConfiguration {
    $config = Get-ConfigurationProfile -Profile $ConfigurationProfile
    
    # Create temporary configuration file
    $configPath = "$env:TEMP\RegionalSettings-GP-Config_$($script:DeploymentId).json"
    
    $deploymentConfig = @{
        Deployment = @{
            Id = $script:DeploymentId
            Timestamp = $script:StartTime.ToString("o")
            Profile = $ConfigurationProfile
            ComplianceMode = $ComplianceMode
            Target = $DeploymentTarget
            Locale = $Locale
        }
        Settings = $config
        Logging = @{
            LocalPath = $script:LocalLogPath
            NetworkPath = $NetworkLogPath
            CompliancePath = $script:ComplianceLogPath
            ReportPath = $script:ReportPath
            EventLogSource = $script:EventSource
        }
        Environment = Test-DomainEnvironment
    }
    
    try {
        $deploymentConfig | ConvertTo-Json -Depth 10 | Set-Content -Path $configPath
        Write-EnterpriseLog "Deployment configuration created: $configPath" "INFO" "Configuration"
        return $configPath
    }
    catch {
        Write-EnterpriseLog "Failed to create deployment configuration: $($_.Exception.Message)" "ERROR" "Configuration"
        return $null
    }
}

# Function to execute the main regional settings script
function Invoke-RegionalSettingsReset {
    param([string]$ConfigPath)
    
    Write-EnterpriseLog "Starting regional settings reset execution..." "AUDIT" "Execution"
    $script:TotalOperations++
    
    try {
        # Prepare execution parameters
        $params = @{
            Locale = $Locale
            Force = $true
            LogPath = $script:LocalLogPath
        }
        
        if ($ConfigPath) {
            $params.ConfigFile = $ConfigPath
        }
        
        # Set execution policy for this session if needed
        $currentPolicy = Get-ExecutionPolicy -Scope Process
        if ($currentPolicy -eq "Restricted") {
            Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force
            Write-EnterpriseLog "Execution policy bypassed for this session" "INFO" "Execution"
        }
        
        if ($DryRun) {
            Write-EnterpriseLog "DRY RUN: Would execute Reset-RegionalSettings.ps1 with parameters: $($params | ConvertTo-Json)" "INFO" "DryRun"
            $script:SuccessfulOperations++
            return @{ Success = $true; ExitCode = 0; Output = "DRY RUN - No changes made" }
        }
        
        # Execute the main script
        Write-EnterpriseLog "Executing: $script:MainScript" "INFO" "Execution"
        Write-EnterpriseLog "Parameters: $($params | ConvertTo-Json)" "DEBUG" "Execution"
        
        $job = Start-Job -ScriptBlock {
            param($ScriptPath, $Parameters)
            & $ScriptPath @Parameters
        } -ArgumentList $script:MainScript, $params
        
        # Wait for completion with timeout
        $config = Get-ConfigurationProfile -Profile $ConfigurationProfile
        $timeoutMinutes = $config.TimeoutMinutes
        $completed = Wait-Job -Job $job -Timeout ($timeoutMinutes * 60)
        
        if ($completed) {
            $output = Receive-Job -Job $job
            $exitCode = $job.State -eq "Completed" ? 0 : 1
            Remove-Job -Job $job
            
            Write-EnterpriseLog "Regional settings reset completed with exit code: $exitCode" "AUDIT" "Execution"
            $script:SuccessfulOperations++
            
            return @{
                Success = $exitCode -eq 0
                ExitCode = $exitCode
                Output = $output
            }
        }
        else {
            Stop-Job -Job $job
            Remove-Job -Job $job
            throw "Script execution timed out after $timeoutMinutes minutes"
        }
    }
    catch {
        Write-EnterpriseLog "Failed to execute regional settings reset: $($_.Exception.Message)" "ERROR" "Execution"
        $script:FailedOperations++
        return @{
            Success = $false
            ExitCode = 1
            Output = $_.Exception.Message
        }
    }
}

# Function to copy logs to network location
function Copy-LogsToNetwork {
    if (-not $NetworkLogPath) {
        return
    }
    
    try {
        # Ensure network directory exists
        $networkDir = Split-Path $NetworkLogPath -Parent
        if (-not (Test-Path $networkDir)) {
            New-Item -Path $networkDir -ItemType Directory -Force | Out-Null
        }
        
        # Copy logs with timestamp
        $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        $computerName = $env:COMPUTERNAME
        
        $networkLogFile = Join-Path $NetworkLogPath "RegionalSettings-GP_${computerName}_${timestamp}.log"
        $networkComplianceFile = Join-Path $NetworkLogPath "RegionalSettings-Compliance_${computerName}_${timestamp}.log"
        $networkReportFile = Join-Path $NetworkLogPath "RegionalSettings-Report_${computerName}_${timestamp}.xml"
        
        if (Test-Path $script:LocalLogPath) {
            Copy-Item $script:LocalLogPath $networkLogFile -ErrorAction Stop
            Write-EnterpriseLog "Log copied to network: $networkLogFile" "INFO" "Logging"
        }
        
        if (Test-Path $script:ComplianceLogPath) {
            Copy-Item $script:ComplianceLogPath $networkComplianceFile -ErrorAction Stop
            Write-EnterpriseLog "Compliance log copied to network: $networkComplianceFile" "AUDIT" "Logging"
        }
        
        if (Test-Path $script:ReportPath) {
            Copy-Item $script:ReportPath $networkReportFile -ErrorAction Stop
            Write-EnterpriseLog "Report copied to network: $networkReportFile" "INFO" "Logging"
        }
    }
    catch {
        Write-EnterpriseLog "Failed to copy logs to network: $($_.Exception.Message)" "WARN" "Logging"
        $script:WarningCount++
    }
}

# Function to generate deployment report
function New-DeploymentReport {
    param([hashtable]$ExecutionResult)
    
    $endTime = Get-Date
    $duration = $endTime - $script:StartTime
    
    $report = @{
        Deployment = @{
            Id = $script:DeploymentId
            StartTime = $script:StartTime.ToString("o")
            EndTime = $endTime.ToString("o")
            Duration = $duration.ToString()
            Status = if ($ExecutionResult.Success) { "Success" } else { "Failed" }
        }
        Configuration = @{
            Locale = $Locale
            Profile = $ConfigurationProfile
            ComplianceMode = $ComplianceMode
            Target = $DeploymentTarget
            DryRun = $DryRun.IsPresent
        }
        Environment = @{
            Computer = $env:COMPUTERNAME
            User = $env:USERNAME
            Domain = $env:USERDOMAIN
            PowerShellVersion = $PSVersionTable.PSVersion.ToString()
            OSVersion = [System.Environment]::OSVersion.Version.ToString()
        }
        Statistics = @{
            TotalOperations = $script:TotalOperations
            SuccessfulOperations = $script:SuccessfulOperations
            FailedOperations = $script:FailedOperations
            WarningCount = $script:WarningCount
            SuccessRate = if ($script:TotalOperations -gt 0) { 
                [math]::Round(($script:SuccessfulOperations / $script:TotalOperations) * 100, 2) 
            } else { 0 }
        }
        Execution = $ExecutionResult
        LogFiles = @{
            Local = $script:LocalLogPath
            Compliance = $script:ComplianceLogPath
            Network = $NetworkLogPath
        }
    }
    
    try {
        $report | ConvertTo-Json -Depth 10 | Set-Content -Path $script:ReportPath
        Write-EnterpriseLog "Deployment report generated: $script:ReportPath" "INFO" "Reporting"
        
        if ($ReportingEnabled) {
            # Output report summary to console for GP management
            Write-Host "`n=== GROUP POLICY DEPLOYMENT REPORT ===" -ForegroundColor Cyan
            Write-Host "Deployment ID: $($script:DeploymentId)" -ForegroundColor White
            Write-Host "Status: $($report.Deployment.Status)" -ForegroundColor $(if ($ExecutionResult.Success) { "Green" } else { "Red" })
            Write-Host "Duration: $($duration.ToString('hh\:mm\:ss'))" -ForegroundColor White
            Write-Host "Success Rate: $($report.Statistics.SuccessRate)%" -ForegroundColor White
            Write-Host "Locale Applied: $Locale" -ForegroundColor White
            Write-Host "Profile Used: $ConfigurationProfile" -ForegroundColor White
            
            if (-not $ExecutionResult.Success) {
                Write-Host "Error: $($ExecutionResult.Output)" -ForegroundColor Red
            }
            
            Write-Host "Report: $script:ReportPath" -ForegroundColor Cyan
            Write-Host "======================================`n" -ForegroundColor Cyan
        }
    }
    catch {
        Write-EnterpriseLog "Failed to generate deployment report: $($_.Exception.Message)" "ERROR" "Reporting"
    }
}

# Main execution function
function Start-GroupPolicyDeployment {
    Write-EnterpriseLog "=== Group Policy Regional Settings Deployment ===" "INFO" "Main"
    Write-EnterpriseLog "Version: $script:ScriptVersion" "INFO" "Main"
    Write-EnterpriseLog "Deployment ID: $script:DeploymentId" "AUDIT" "Main"
    Write-EnterpriseLog "Configuration Profile: $ConfigurationProfile" "INFO" "Main"
    Write-EnterpriseLog "Target Locale: $Locale" "INFO" "Main"
    Write-EnterpriseLog "Compliance Mode: $ComplianceMode" "AUDIT" "Main"
    Write-EnterpriseLog "Deployment Target: $DeploymentTarget" "INFO" "Main"
    
    if ($DryRun) {
        Write-EnterpriseLog "DRY RUN MODE - No changes will be made" "WARN" "Main"
    }
    
    try {
        # Step 1: Validate prerequisites
        $validation = Test-DeploymentPrerequisites
        if (-not $validation.OverallStatus) {
            throw "Prerequisite validation failed: $($validation.Details -join '; ')"
        }
        
        # Step 2: Create deployment configuration
        $configPath = New-DeploymentConfiguration
        if (-not $configPath) {
            throw "Failed to create deployment configuration"
        }
        
        # Step 3: Execute regional settings reset
        $executionResult = Invoke-RegionalSettingsReset -ConfigPath $configPath
        
        # Step 4: Copy logs to network if configured
        if ($NetworkLogPath) {
            Copy-LogsToNetwork
        }
        
        # Step 5: Generate deployment report
        New-DeploymentReport -ExecutionResult $executionResult
        
        # Final status
        if ($executionResult.Success) {
            Write-EnterpriseLog "Group Policy deployment completed successfully" "AUDIT" "Main"
            exit 0
        }
        else {
            Write-EnterpriseLog "Group Policy deployment failed" "ERROR" "Main"
            exit 1
        }
    }
    catch {
        Write-EnterpriseLog "Critical error in Group Policy deployment: $($_.Exception.Message)" "ERROR" "Main"
        
        # Generate error report
        $errorResult = @{
            Success = $false
            ExitCode = 1
            Output = $_.Exception.Message
        }
        New-DeploymentReport -ExecutionResult $errorResult
        
        exit 1
    }
    finally {
        # Cleanup temporary files
        try {
            if ($configPath -and (Test-Path $configPath)) {
                Remove-Item $configPath -Force -ErrorAction SilentlyContinue
            }
        }
        catch {
            # Silent cleanup
        }
    }
}

# Entry point
Start-GroupPolicyDeployment
