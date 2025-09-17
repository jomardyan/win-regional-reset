# Windows Regional Settings Reset

A comprehensive PowerShell script and batch wrapper to reset all Windows regional settings, including Windows 11 registry memory slots. Defaults to Polish (pl-PL) locale but supports multiple languages with user customization.

## Features

- **Comprehensive Reset**: Resets all Windows regional settings including:
  - International settings (date, time, currency formats)
  - Geographic location
  - Input methods and language bar
  - Windows 11 specific registry memory slots
  - MRU (Most Recently Used) lists
  
- **Multi-Language Support**: Supports multiple locales with specific formatting
- **Safe Operation**: Creates automatic registry backups before making changes
- **Flexible Usage**: Command-line parameters for automation
- **Administrator Detection**: Ensures proper privileges for system changes

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

## Files

- `Reset-RegionalSettings.ps1` - Main PowerShell script
- `reset-regional.bat` - Batch wrapper for easy execution

## Usage

### Method 1: Batch File (Recommended)

**Right-click** `reset-regional.bat` and select **"Run as administrator"**

```batch
# Reset to Polish (default)
reset-regional.bat

# Reset to English (US)
reset-regional.bat en-US

# Reset to German without prompts
reset-regional.bat de-DE force

# Force mode with default locale
reset-regional.bat force
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

# Force mode with default locale
.\Reset-RegionalSettings.ps1 -Force
```

## What Gets Reset

### Core International Settings
- System locale and language
- Date and time formats
- Number and currency formats
- List and decimal separators
- Geographic location/country

### Windows 11 Specific
- User profile regional settings memory slots
- Input method configuration cache
- Language bar preferences
- Geographic location cache

### Additional Cleanup
- Windows Explorer MRU lists
- Registry backup creation
- System locale synchronization

## Requirements

- **Windows 10/11**: Tested on Windows 10 and Windows 11
- **Administrator Rights**: Required for system-level changes
- **PowerShell 5.0+**: Included in modern Windows versions
- **Execution Policy**: Script handles policy bypass automatically

## Safety Features

- **Automatic Backups**: Creates timestamped registry backups in `%TEMP%`
- **Validation**: Checks locale support before execution
- **Confirmation Prompts**: Asks for confirmation unless `-Force` is used
- **Error Handling**: Graceful handling of permission issues
- **Rollback Information**: Backup locations displayed for manual restoration

## Registry Areas Modified

### Current User (HKCU)
- `Control Panel\International` - Core regional settings
- `Control Panel\International\User Profile` - Windows 11 memory slots
- `Control Panel\International\Geo` - Geographic settings
- `Software\Microsoft\Input\Settings` - Input method cache
- `Software\Microsoft\CTF\LangBar` - Language bar settings

### Local Machine (HKLM) - System Level
- `SYSTEM\CurrentControlSet\Control\Nls\Language`
- `SYSTEM\CurrentControlSet\Control\Nls\Locale`
- `SYSTEM\CurrentControlSet\Control\Nls\CodePage`

## Examples

### Polish Business Environment
```batch
# Reset all workstations to Polish locale
reset-regional.bat pl-PL force
```

### International Office Setup
```powershell
# German workstations
.\Reset-RegionalSettings.ps1 -Locale "de-DE" -Force

# US workstations  
.\Reset-RegionalSettings.ps1 -Locale "en-US" -Force
```

### Troubleshooting Corrupted Settings
```batch
# Reset to default with confirmation
reset-regional.bat
```

## Post-Reset Recommendations

1. **Restart Required**: A system restart is recommended for all changes to take effect
2. **Verify Settings**: Check Windows Settings > Time & Language > Language & Region
3. **Test Applications**: Verify date/time formats in applications like Excel
4. **Input Methods**: Reconfigure keyboard layouts if needed

## Troubleshooting

### PowerShell Execution Policy
If you encounter execution policy errors:

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope Process
```

### Permission Issues
- Ensure running as Administrator
- Check User Account Control (UAC) settings
- Verify script files are not blocked (Right-click > Properties > Unblock)

### Registry Access Denied
- Some enterprise environments may restrict registry access
- Contact system administrator for group policy exceptions

## Technical Details

### Registry Backup Location
Backups are created in: `%TEMP%\RegionalSettings_Backup_YYYYMMDD_HHMMSS\`

### Locale-Specific Settings

**Polish (pl-PL)** formatting:
- Date: `dd.MM.yyyy`
- Time: `HH:mm:ss` (24-hour)
- Currency: `zł` (Polish Złoty)
- Decimal: `,` (comma)
- Thousands: ` ` (space)

**English (en-US)** formatting:
- Date: `M/d/yyyy`
- Time: `h:mm:ss tt` (12-hour with AM/PM)
- Currency: `$` (US Dollar)
- Decimal: `.` (period)
- Thousands: `,` (comma)

## Contributing

To add support for additional locales:

1. Add the locale to `$SupportedLocales` hashtable
2. Add locale-specific formatting in the switch statement
3. Test the locale settings
4. Update documentation

## License

This project is released under the MIT License. See LICENSE file for details.

## Disclaimer

This script modifies system registry settings. While it creates backups, use at your own risk. Test in a non-production environment first. The authors are not responsible for any system issues that may arise from using this script.