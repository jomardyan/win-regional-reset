# Windows Regional Settings Reset

A comprehensive multi-language toolkit for resetting regional and locale settings across Windows systems. Available in **PowerShell**, **Python**, and **C++** with unified functionality and cross-platform support.

## 🚀 Quick Start

### PowerShell (Windows Native)
```powershell
# Interactive menu with all features
.\reset-regional.bat

# Direct locale application
.\reset-regional.bat en-US

# Force mode (no confirmations)
.\reset-regional.bat pl-PL -Force
```

### Python (Cross-Platform)
```bash
cd python
python regional_settings_reset.py
# Interactive menu with backup/restore, config management
```

### C++ (High Performance)
```bash
cd cpp
# Build and run
make
./regional_settings_reset --interactive
```

## 📋 Unified Feature Matrix

| Feature | PowerShell | Python | C++ |
|---------|------------|--------|-----|
| **Interactive Menu** | ✅ | ✅ | ✅ |
| **Registry Operations** | ✅ | ✅ | ✅ |
| **Backup/Restore** | ✅ | ✅ | ✅ |
| **Configuration Files** | ✅ | ✅ | ✅ |
| **Comprehensive Logging** | ✅ | ✅ | ✅ |
| **Error Handling** | ✅ | ✅ | ✅ |
| **Demo Mode (Non-Windows)** | ❌ | ✅ | ✅ |
| **Windows 11 Memory Slots** | ✅ | ✅ | ✅ |
| **Browser Integration** | ✅ | ✅ | ✅ |
| **Office Integration** | ✅ | ✅ | ✅ |

## 🌍 Supported Locales (All Versions)

| Code | Language | Country | Date Format | Currency |
|------|----------|---------|-------------|----------|
| `pl-PL` | Polish | Poland | dd.MM.yyyy | zł |
| `en-US` | English | United States | M/d/yyyy | $ |
| `en-GB` | English | United Kingdom | dd/MM/yyyy | £ |
| `de-DE` | German | Germany | dd.MM.yyyy | € |
| `fr-FR` | French | France | dd/MM/yyyy | € |
| `es-ES` | Spanish | Spain | dd/MM/yyyy | € |
| `it-IT` | Italian | Italy | dd/MM/yyyy | € |
| `ja-JP` | Japanese | Japan | yyyy/MM/dd | ¥ |
| `ko-KR` | Korean | Korea | yyyy-MM-dd | ₩ |
| `ru-RU` | Russian | Russia | dd.MM.yyyy | ₽ |

## 🛠️ Installation & Requirements

### All Versions
- **Windows 10/11** (for registry operations)
- **Administrator privileges** required
- **Non-Windows**: Demo mode available (Python/C++)

### PowerShell
- PowerShell 5.0+
- No additional dependencies

### Python  
- Python 3.7+
- Automatic dependency detection

### C++
- GCC with C++17 support
- Filesystem library support

## 📖 Usage Examples

### PowerShell - Comprehensive Windows Tool
```powershell
# Interactive with validation
.\reset-regional.bat

# Batch mode with custom config
.\Reset-RegionalSettings.ps1 -ConfigFile "config.json" -Force

# Backup operations
.\backup-manager.bat create
.\backup-manager.bat restore "backup_20231201"

# System validation
.\validate.bat -Verbose
```

### Python - Cross-Platform Interactive
```bash
# Start interactive menu
python regional_settings_reset.py

# Command line usage
python regional_settings_reset.py --locale en-US --config config.json

# Demo mode (non-Windows)
python regional_settings_reset.py --demo
```

### C++ - High Performance Native
```bash
# Interactive menu
./regional_settings_reset

# Direct application
./regional_settings_reset pl-PL

# Help and options
./regional_settings_reset --help
```

## ⚙️ Configuration (config.json)

All versions support unified configuration:

```json
{
    "default_locale": "pl-PL",
    "supported_locales": ["pl-PL", "en-US", "de-DE", "fr-FR", "es-ES"],
    "backup_enabled": true,
    "log_enabled": true,
    "auto_restart": false,
    "confirmation_required": true
}
```

## 🔧 Advanced Operations

### Backup Management (All Versions)
- **Automatic**: Registry backup before changes
- **Manual**: Create/restore backups on demand  
- **Versioned**: Timestamped backup directories
- **Validation**: Backup integrity checking

### Logging System (Unified)
- **Timestamped entries**: Operation tracking
- **Multi-level logging**: INFO/WARN/ERROR/DEBUG
- **File + Console**: Dual output streams
- **Structured format**: Easy parsing and analysis

### Error Handling (Comprehensive)
- **Pre-flight checks**: System compatibility validation
- **Retry mechanisms**: Failed operation recovery
- **Graceful degradation**: Partial failure handling
- **Detailed reporting**: Error context and solutions

## 🎯 What Gets Reset (All Versions)

### Core Windows Settings
- ✅ **Display Language**: UI language preferences
- ✅ **Date/Time Formats**: Short/long date, time format
- ✅ **Number Formats**: Decimal separators, grouping
- ✅ **Currency**: Symbol, position, decimal places
- ✅ **Geographic Location**: Country/region settings

### Windows 11 Enhanced
- ✅ **Memory Slot Clearing**: Registry cache cleanup
- ✅ **User Profile Settings**: Profile-specific configurations  
- ✅ **Input Methods**: Keyboard and IME settings
- ✅ **Language Bar**: Display and behavior settings

### Application Integration
- ✅ **Browsers**: Chrome, Firefox, Edge language preferences
- ✅ **Microsoft Office**: Regional settings for Office apps
- ✅ **System Applications**: Explorer, Control Panel settings
- ✅ **.NET Framework**: Culture and formatting settings

## 🚨 Platform Compatibility

### Windows (Full Functionality)
- Registry operations with native APIs
- Administrative privilege validation
- System restart management
- Complete application integration

### Linux/macOS (Demo Mode)
- Configuration validation
- Locale information display
- Interactive menu simulation
- Cross-platform development testing

## 📊 Performance & Statistics

All versions provide execution statistics:
- **Operation Count**: Total operations attempted
- **Success Rate**: Percentage of successful operations
- **Execution Time**: Performance metrics
- **Resource Usage**: Memory and disk impact
- **Backup Size**: Storage requirements

## 🤝 Version Recommendations

| Use Case | Recommended Version | Reason |
|----------|-------------------|---------|
| **Production Windows** | PowerShell | Most comprehensive, native integration |
| **Development/Testing** | Python | Cross-platform, easy customization |
| **Performance Critical** | C++ | Fastest execution, minimal dependencies |
| **Automation/CI** | Any | All support command-line automation |
| **Learning/Education** | Python | Clear code, extensive documentation |

## 🔄 Migration Between Versions

All versions share:
- **Compatible config.json** format
- **Identical locale codes** and support
- **Unified backup** directory structure
- **Consistent command-line** interfaces

## 📄 License & Support

**MIT License** - Free for personal and commercial use.

**Community Support**:
- Issue tracking for all versions
- Feature requests and improvements
- Cross-platform compatibility testing
- Documentation contributions welcome

---

**⚠️ Important**: Always test on non-production systems first. Administrator privileges required for registry modifications on Windows.