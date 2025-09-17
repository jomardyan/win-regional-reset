# Windows Regional Settings Reset v2.0

A comprehensive PowerShell script and batch wrapper suite to reset all Windows regional settings, including Windows 11 registry memory slots. Features advanced error handling, configuration management, backup/restore capabilities, and comprehensive application support. Defaults to Polish (pl-PL) locale but supports multiple languages with extensive customization.

## 🚀 Quick Start

### Method 1: Batch Wrapper (Recommended)

**Right-click** `reset-regional.bat` and select **"Run as administrator"**

```batch
# Reset to Polish (default) with confirmation
reset-regional.bat

# Reset to English (US) with force mode
reset-regional.bat en-US force

# Silent execution for automation
reset-regional.bat de-DE silent

# Use custom configuration file
reset-regional.bat config=custom.json

# Custom log file location
reset-regional.bat en-GB log=C:\Logs\regional.log

# Skip backup creation (not recommended)
reset-regional.bat fr-FR nobackup

# Show comprehensive help
reset-regional.bat /?
```

### Method 2: PowerShell Direct

Open PowerShell as Administrator:

```powershell
# Reset to Polish (default) with confirmation
.\Reset-RegionalSettings.ps1

# Reset to English (US) with confirmation
.\Reset-RegionalSettings.ps1 -Locale "en-US"

# Reset to German without confirmation
.\Reset-RegionalSettings.ps1 -Locale "de-DE" -Force

# Use custom configuration
.\Reset-RegionalSettings.ps1 -ConfigFile "config.json"

# Custom log location
.\Reset-RegionalSettings.ps1 -LogPath "C:\Logs\regional.log"

# Restore from backup
.\Reset-RegionalSettings.ps1 -RestoreFromBackup "C:\Temp\RegionalSettings_Backup_20231201_143022"
```

### Method 3: Python Edition (Interactive)

Navigate to the Python directory and run the interactive application:

```bash
cd python
python regional_settings_reset.py
```

Or use the quick launcher:
```bash
cd python
python launcher.py
```

**Python Edition Features:**
- 🎮 Interactive menu system
- 🎨 Color-coded interface
- 📊 Real-time progress tracking
- 🔧 Built-in validation tools
- 📋 System information display
- ⚙️ Configuration management UI

### Method 4: Backup Management

```batch
# List available backups
backup-manager.bat list

# Restore from specific backup
backup-manager.bat restore RegionalSettings_Backup_20231201_143022

# Clean backups older than 30 days
backup-manager.bat cleanup 30

# Verify backup integrity
backup-manager.bat verify
```

## ✨ Key Features

- **🔧 Comprehensive Reset**: Resets all Windows regional settings including:
  - International settings (date, time, currency formats)
  - Geographic location and timezone settings
  - Input methods and language bar
  - Windows 11 specific registry memory slots
  - MRU (Most Recently Used) lists
  - Browser regional settings (Chrome, Firefox, Edge/IE)
  - Microsoft Office regional settings
  - .NET Framework culture settings
  
- **🛡️ Advanced Error Handling**: 
  - Retry mechanisms for registry operations
  - Comprehensive logging with multiple levels
  - Transaction-like backup and restore
  - Detailed error reporting and recovery
  
- **⚙️ Configuration Management**:
  - JSON configuration file support
  - Feature toggles for selective operations
  - Custom registry path support
  - Automated backup retention policies
  
- **💾 Backup & Restore System**:
  - Automatic timestamped backups
  - Backup verification and integrity checks
  - Point-in-time restore capabilities
  - Backup cleanup and management tools
  
- **🚀 Optimized User Experience**:
  - Silent mode for automation
  - Progress indicators and status reporting
  - Comprehensive validation and testing
  - Help system and usage guidance
  
- **🌍 Multi-Language Support**: Extended locale support with proper formatting
- **🔒 Safe Operation**: Multiple safety layers and rollback capabilities
- **📋 Flexible Usage**: Command-line parameters and configuration files
- **👤 Administrator Detection**: Ensures proper privileges for system changes

## Supported Locales

| Code  | Language/Country |
|-------|------------------|
| pl-PL | Polish (Poland) - **Default** |
| en-US | English (United States) |
| en-GB | English (United Kingdom) |
| de-DE | German (Germany) |
| fr-FR | French (France) |
| es-ES | Spanish (Spain) |
| it-IT | Italian (Italy) |
| pt-PT | Portuguese (Portugal) |
| ru-RU | Russian (Russia) |
| zh-CN | Chinese (Simplified, China) |
| ja-JP | Japanese (Japan) |
| ko-KR | Korean (Korea) |

## 📁 Files

### **Core Application**
- `Reset-RegionalSettings.ps1` - Main PowerShell script with advanced features
- `reset-regional.bat` - Batch wrapper with comprehensive options and examples
- `config.json` - Configuration file template

### **Management Tools**
- `validate.bat` - Comprehensive validation and testing script
- `backup-manager.bat` - Advanced backup management utility

### **Python Edition**
- `python/` - Complete Python port with interactive menu system
  - `regional_settings_reset.py` - Main Python application
  - `launcher.py` - Quick launcher with options
  - `config.json` - Python-specific configuration
  - `README.md` - Python edition documentation
  - `requirements.txt` - Python dependencies

### **Documentation**
- `README.md` - This documentation
- `LICENSE` - MIT license file

## ✨ Enhanced Features

- **🔧 Comprehensive Reset**: Resets all Windows regional settings including:
  - International settings (date, time, currency formats)
  - Geographic location and timezone settings
  - Input methods and language bar
  - Windows 11 specific registry memory slots
  - MRU (Most Recently Used) lists
  - Browser regional settings (Chrome, Firefox, Edge/IE)
  - Microsoft Office regional settings
  - .NET Framework culture settings

## 🔧 What Gets Reset

### Core International Settings
- System locale and language preferences
- Date and time formats with locale-specific patterns
- Number and currency formats with proper separators  
- List and decimal separators
- Geographic location/country settings
- Timezone and calendar preferences

### Windows 11 Specific Enhancements
- User profile regional settings memory slots
- Input method configuration cache and preferences
- Language bar settings and behavior
- Geographic location cache and MRU
- Windows 11 registry optimization paths

### Application-Specific Settings
- **Browser Settings**: Chrome, Firefox, Edge/Internet Explorer language preferences
- **Microsoft Office**: Word, Excel, PowerPoint, Outlook regional formats
- **.NET Framework**: Culture and regional settings for applications
- **Windows Explorer**: MRU lists and regional display preferences

### Advanced System Integration
- Registry backup creation with verification
- System locale synchronization across components
- Input method editor (IME) configuration reset
- Regional format consistency across all applications

## 📋 Requirements

- **Windows 10/11**: Tested extensively on Windows 10 and Windows 11
- **Administrator Rights**: Required for system-level registry changes
- **PowerShell 5.0+**: Included in modern Windows versions
- **Disk Space**: Minimum 50MB free space for backups
- **Registry Access**: Full registry read/write permissions

## 🛡️ Safety Features

- **Multi-Layer Backups**: Timestamped registry backups with integrity verification
- **Rollback Capability**: Complete restore from any backup point
- **Validation System**: Pre-execution compatibility and safety checks
- **Transaction Safety**: Atomic operations with failure recovery
- **Confirmation Prompts**: Multiple confirmation levels unless bypassed
- **Error Recovery**: Graceful handling of permission and access issues
- **Audit Trail**: Comprehensive logging with multiple detail levels
- **Backup Retention**: Automatic cleanup with configurable retention policies

## 📁 Registry Areas Modified

### Current User (HKCU)
- `Control Panel\International` - Core regional settings and formatting
- `Control Panel\International\User Profile` - Windows 11 memory slots
- `Control Panel\International\Geo` - Geographic and timezone settings
- `Software\Microsoft\Input\Settings` - Input method cache and preferences
- `Software\Microsoft\CTF\LangBar` - Language bar configuration
- `Software\Microsoft\Internet Explorer\International` - Browser settings
- `Software\Google\Chrome\PreferenceMACs\Default\intl` - Chrome settings

### Local Machine (HKLM) - System Level
- `SYSTEM\CurrentControlSet\Control\Nls\Language` - System language settings
- `SYSTEM\CurrentControlSet\Control\Nls\Locale` - System locale configuration
- `SYSTEM\CurrentControlSet\Control\Nls\CodePage` - Character encoding settings

### Office Applications (Version-Specific)
- `Software\Microsoft\Office\[Version]\[App]\Options` - Office regional settings

## ⚙️ Configuration Management

### Configuration File (config.json)
```json
{
  "defaultLocale": "pl-PL",
  "maxRetries": 3,
  "logLevel": "INFO",
  "features": {
    "resetBrowserSettings": true,
    "resetOfficeSettings": true,
    "resetMruLists": true,
    "resetSystemLocale": true,
    "resetWindows11Memory": true
  },
  "backup": {
    "retentionDays": 30,
    "compressionEnabled": false,
    "customBackupPath": ""
  }
}
```

### Feature Toggles
- **Browser Reset**: Control browser regional settings reset
- **Office Reset**: Enable/disable Office application settings
- **MRU Cleanup**: Configure Most Recently Used list clearing
- **System Locale**: Control system-wide locale changes
- **Memory Slots**: Windows 11 specific memory slot cleanup

### Backup Configuration
- **Retention Policy**: Automatic cleanup of old backups
- **Custom Paths**: Specify backup storage locations
- **Compression**: Optional backup compression (future feature)
- **Verification**: Automatic backup integrity checking

## 💡 Advanced Examples

### Enterprise Deployment
```batch
REM Corporate workstation setup with logging
reset-regional.bat en-US force log=\\server\logs\%COMPUTERNAME%_regional.log

REM Silent deployment with custom configuration
reset-regional.bat config=\\server\configs\corporate.json silent

REM Automated restoration after system updates
backup-manager.bat restore RegionalSettings_Backup_20231201_143022
```

### Development and Testing
```powershell
# Test configuration without making changes
.\Reset-RegionalSettings.ps1 -Locale "de-DE" -ConfigFile "test-config.json" -Force

# Create baseline backup before changes
.\Reset-RegionalSettings.ps1 -Locale "en-US"

# Restore to known good state
.\Reset-RegionalSettings.ps1 -RestoreFromBackup "C:\Backups\Baseline"
```

### Multilingual Environment Management
```batch
REM Set up German workstation with verification
reset-regional.bat de-DE force
validate.bat

REM Configure French environment with Office settings
reset-regional.bat fr-FR config=office-optimized.json

REM Quick locale switching with backup
backup-manager.bat list
reset-regional.bat ja-JP force
```

### Troubleshooting and Maintenance
```batch
REM Comprehensive system validation
validate.bat

REM Verify and clean old backups
backup-manager.bat verify
backup-manager.bat cleanup 14

REM Emergency restore from backup
backup-manager.bat restore [backup-folder]
```

## 🔧 Troubleshooting

### Common Issues and Solutions

#### PowerShell Execution Policy
```powershell
# Check current policy
Get-ExecutionPolicy

# Temporary bypass (automatic in script)
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process

# Permanent solution (if needed)
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

#### Permission Issues
- **Solution 1**: Ensure running as Administrator
- **Solution 2**: Check User Account Control (UAC) settings
- **Solution 3**: Verify script files are not blocked
  ```batch
  # Unblock files if downloaded from internet
  powershell -Command "Get-ChildItem -Path . -Recurse | Unblock-File"
  ```

#### Registry Access Denied
- **Enterprise Environment**: Contact system administrator for group policy exceptions
- **Antivirus Interference**: Temporarily disable real-time protection
- **Registry Permissions**: Verify current user has registry modification rights

#### Backup and Restore Issues
```batch
# Verify backup integrity
backup-manager.bat verify

# Manual backup location check
dir %TEMP%\RegionalSettings_Backup_*

# Force cleanup of corrupted backups
backup-manager.bat cleanup 0
```

#### Application-Specific Problems
- **Office Settings**: Restart Office applications after regional reset
- **Browser Settings**: Clear browser cache and restart browsers
- **System Integration**: Perform system restart for full effect

### Advanced Troubleshooting

#### Log Analysis
```powershell
# View recent log file
Get-Content -Path "$env:TEMP\RegionalSettings_*.log" -Tail 50

# Search for specific errors
Select-String -Path "$env:TEMP\RegionalSettings_*.log" -Pattern "ERROR"
```

#### Registry Verification
```batch
# Check current regional settings
reg query "HKCU\Control Panel\International"

# Verify backup files
reg export "HKCU\Control Panel\International" test-export.reg
```

#### System State Validation
```batch
# Run comprehensive validation
validate.bat

# Check Windows locale settings
powershell -Command "Get-WinSystemLocale; Get-WinUserLanguageList; Get-WinHomeLocation"
```

## 🔄 Post-Reset Recommendations

### Immediate Actions
1. **System Restart**: Recommended for all changes to take full effect
2. **Verify Settings**: Check Windows Settings > Time & Language > Language & Region
3. **Test Applications**: Verify date/time formats in applications like Excel, browsers
4. **Input Methods**: Reconfigure keyboard layouts and input methods if needed

### Validation Steps
1. **Date/Time Format**: Open Calculator or Clock app to verify formatting
2. **Currency Display**: Check currency symbols in Excel or shopping websites
3. **Browser Language**: Verify language preferences in browser settings
4. **Office Applications**: Test regional formatting in Word/Excel documents

### Long-term Maintenance
- **Monthly Backup Cleanup**: Use `backup-manager.bat cleanup 30`
- **Quarterly Validation**: Run `validate.bat` to ensure system health
- **Update Configuration**: Review and update `config.json` as needed
- **Monitor Log Files**: Check for recurring errors or warnings

## 📊 Technical Details

### Logging System
- **Log Levels**: ERROR, WARN, INFO, DEBUG
- **Automatic Timestamping**: All operations tracked with precise timestamps
- **Structured Format**: Machine-readable log format for automation
- **Location**: `%TEMP%\RegionalSettings_YYYYMMDD_HHMMSS.log`

### Backup System Architecture
- **Directory Structure**: `%TEMP%\RegionalSettings_Backup_YYYYMMDD_HHMMSS\`
- **File Naming**: `[Category]_[KeyName].reg` (e.g., `CurrentUser_International.reg`)
- **Integrity Verification**: Automatic validation of backup completeness
- **Compression Support**: Optional backup compression (configurable)

### Performance Optimization
- **Retry Logic**: Configurable retry attempts for registry operations
- **Batch Operations**: Grouped registry modifications for efficiency
- **Progress Tracking**: Real-time progress indicators for long operations
- **Resource Management**: Automatic cleanup and memory management

### Locale-Specific Formatting Details

**Polish (pl-PL)** - Default:
- Date: `dd.MM.yyyy` (e.g., 25.12.2023)
- Time: `HH:mm:ss` (24-hour format)
- Currency: `zł` (Polish Złoty) - postfix
- Decimal: `,` (comma separator)
- Thousands: ` ` (space separator)
- List separator: `;` (semicolon)

**English (en-US)**:
- Date: `M/d/yyyy` (e.g., 12/25/2023)
- Time: `h:mm:ss tt` (12-hour with AM/PM)
- Currency: `$` (US Dollar) - prefix
- Decimal: `.` (period)
- Thousands: `,` (comma)
- List separator: `,` (comma)

**German (de-DE)**:
- Date: `dd.MM.yyyy` (e.g., 25.12.2023)
- Time: `HH:mm:ss` (24-hour)
- Currency: `€` (Euro) - postfix
- Decimal: `,` (comma)
- Thousands: `.` (period)
- List separator: `;` (semicolon)

**French (fr-FR)**:
- Date: `dd/MM/yyyy` (e.g., 25/12/2023)  
- Time: `HH:mm:ss` (24-hour)
- Currency: `€` (Euro) - postfix
- Decimal: `,` (comma)
- Thousands: ` ` (space)
- List separator: `;` (semicolon)

### Error Handling Matrix

| Error Type | Retry Attempts | Recovery Action | User Impact |
|------------|----------------|-----------------|-------------|
| Registry Access Denied | 3 | Skip + Log | Warning only |
| Backup Creation Failed | 3 | Continue + Warn | Minimal |
| Invalid Locale | 0 | Exit immediately | Full stop |
| System Incompatibility | 0 | Exit with guidance | Full stop |
| Partial Registry Failure | 3 | Continue + Track | Tracked in logs |

## 🤝 Contributing

### Adding New Locales
1. **Update Supported Locales**: Add to `$SupportedLocales` hashtable in PowerShell script
2. **Add Locale Settings**: Include formatting rules in the locale switch statement  
3. **Geographic Mapping**: Add appropriate geographic ID mapping
4. **Test Coverage**: Verify with `validate.bat` and create test scenarios
5. **Documentation**: Update README.md with new locale information

### Feature Development
1. **Configuration**: Add new options to `config.json` schema
2. **Implementation**: Follow existing error handling and logging patterns
3. **Testing**: Add validation tests in `validate.bat`
4. **Documentation**: Update help systems and README
5. **Backwards Compatibility**: Ensure existing configurations still work

### Code Style Guidelines
- **PowerShell**: Follow PowerShell best practices and use approved verbs
- **Batch Files**: Use clear variable names and consistent formatting
- **Error Handling**: Always include try-catch blocks and meaningful error messages
- **Logging**: Use structured logging with appropriate levels
- **Comments**: Include detailed comments for complex operations

## 📜 Version History

### Version 2.0 (Current)
- ✅ Enhanced error handling with retry mechanisms
- ✅ Configuration file support (JSON)
- ✅ Advanced backup and restore system  
- ✅ Browser and Office application support
- ✅ Comprehensive validation and testing framework
- ✅ Silent mode and automation features
- ✅ Advanced batch wrapper with help system
- ✅ Backup management utility
- ✅ Progress tracking and detailed logging
- ✅ Extended locale support with proper formatting

### Version 1.0 (Legacy)
- Basic regional settings reset
- Polish locale focus
- Simple batch wrapper
- Basic backup functionality
- Windows 11 memory slot support

## License

This project is released under the MIT License. See LICENSE file for details.

## Disclaimer

This script modifies system registry settings. While it creates backups, use at your own risk. Test in a non-production environment first. The authors are not responsible for any system issues that may arise from using this script.