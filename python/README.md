# Windows Regional Settings Reset - Python Edition v2.0

A comprehensive Python application to reset all Windows regional settings with an interactive menu system. This Python port provides the same functionality as the PowerShell/Batch version with additional interactive features and cross-platform compatibility testing.

## 🐍 Python Edition Features

### 🎯 **Interactive Menu System**
- **User-Friendly Interface**: Intuitive menu-driven navigation
- **Real-Time Status**: Live display of current settings and admin status
- **Color-Coded Output**: Visual feedback with ANSI color support
- **Progress Tracking**: Real-time operation monitoring

### 🔧 **Core Functionality**
- **Complete Regional Reset**: All Windows regional settings
- **Locale Support**: 12+ locales with proper formatting
- **Backup & Restore**: Comprehensive backup management
- **Error Handling**: Robust retry mechanisms and error recovery
- **Configuration Management**: JSON-based configuration system

### 🎮 **Menu Options**
1. **Quick Reset** - Immediate reset with current locale
2. **Configure Settings** - Interactive locale selection
3. **Backup Management** - Create, restore, and manage backups
4. **Validation Tools** - System compatibility and health checks
5. **System Information** - View current regional settings
6. **Configuration** - Manage configuration files
7. **Help & Examples** - Usage guidance and examples
8. **About** - Version and license information

## 🚀 **Quick Start**

### **Interactive Mode (Recommended)**
```bash
cd python
python regional_settings_reset.py
```

### **Command Line Mode**
```bash
# Reset to specific locale
python regional_settings_reset.py --locale en-US

# Force mode without confirmation
python regional_settings_reset.py --locale de-DE --force

# Use custom configuration
python regional_settings_reset.py --config custom.json

# Custom log file
python regional_settings_reset.py --locale fr-FR --log C:\\Logs\\regional.log
```

## 📋 **Requirements**

### **System Requirements**
- **OS**: Windows 10/11 (primary), Limited Linux/macOS support for testing
- **Python**: 3.6+ (3.8+ recommended)
- **Privileges**: Administrator rights for registry modifications
- **Dependencies**: Python standard library only (no external packages required)

### **Optional Enhancements**
```bash
# Install optional packages for enhanced features
pip install -r requirements.txt
```

## 🎨 **Interactive Menu Screenshots**

```
╔══════════════════════════════════════════════════════════╗
║     Windows Regional Settings Reset - Python Edition    ║
║                        v2.0                             ║
╚══════════════════════════════════════════════════════════╝

Current Locale: pl-PL
Admin Rights: Yes

1. Quick Reset          - Reset regional settings with current locale
2. Configure Settings   - Choose locale and advanced options
3. Backup Management    - Create, restore, and manage backups
4. Validation Tools     - System validation and testing
5. System Information   - View current regional settings
6. Configuration        - Manage configuration files
7. Help & Examples      - Usage examples and documentation
8. About               - Version and license information
9. Exit                - Quit the application

Enter your choice (1-9):
```

## ⚙️ **Configuration**

### **Python Configuration (config.json)**
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
    "resetWindows11Memory": true,
    "interactiveMode": true,
    "coloredOutput": true
  },
  "ui": {
    "showProgressBar": true,
    "enableColors": true,
    "confirmationRequired": true
  },
  "backup": {
    "retentionDays": 30,
    "autoBackup": true
  }
}
```

### **Feature Toggles**
- **Interactive Mode**: Enable/disable menu system
- **Colored Output**: ANSI color support
- **Auto Backup**: Automatic backup before changes
- **Progress Indicators**: Real-time operation tracking
- **System Notifications**: Desktop notification support

## 🛠️ **Development**

### **Code Structure**
```
python/
├── regional_settings_reset.py    # Main application
├── config.json                   # Configuration template
├── requirements.txt               # Dependencies
└── README.md                     # This documentation
```

### **Class Architecture**
- **`RegionalSettingsReset`**: Core functionality and registry operations
- **`RegionalSettingsConfig`**: Configuration management and locale definitions
- **`InteractiveMenu`**: Menu system and user interface
- **`Colors`**: ANSI color codes for terminal output

### **Key Methods**
- **`apply_locale_settings()`**: Apply locale-specific registry settings
- **`create_backup()`**: Create registry backups
- **`validate_locale()`**: Validate locale support
- **`reset_windows11_memory_slots()`**: Windows 11 specific cleanup
- **`generate_statistics_report()`**: Execution statistics

## 🔄 **Cross-Platform Compatibility**

### **Windows (Primary)**
- ✅ Full functionality with registry access
- ✅ Administrator privilege detection
- ✅ Native Windows API integration
- ✅ Registry backup/restore operations

### **Linux/macOS (Testing)**
- ⚠️ Limited functionality for development/testing
- ✅ Menu system and interface testing
- ✅ Configuration management
- ❌ Registry operations (Windows-specific)

## 🧪 **Testing and Validation**

### **Built-in Validation**
```python
# System compatibility check
python regional_settings_reset.py --validate

# Interactive validation through menu
# Option 4: Validation Tools
```

### **Test Scenarios**
- ✅ Locale validation and error handling
- ✅ Configuration file loading and parsing
- ✅ Registry access and permission checking
- ✅ Backup creation and verification
- ✅ Menu navigation and user input handling

## 📊 **Performance Features**

### **Optimizations**
- **Retry Logic**: Configurable retry attempts for registry operations
- **Batch Operations**: Grouped registry modifications
- **Memory Management**: Automatic resource cleanup
- **Progress Tracking**: Real-time operation monitoring

### **Statistics Reporting**
```
Execution Statistics:
  Total Operations: 45
  Successful: 43
  Failed: 2
  Success Rate: 95.6%
  
Files:
  Log File: C:\\Temp\\RegionalSettings_20231215_143022.log
  Backup Directory: C:\\Temp\\RegionalSettings_Backup_20231215_143022
```

## 🔐 **Security Features**

### **Safety Measures**
- **Administrator Verification**: Ensures proper privileges
- **Registry Backup**: Automatic backup before modifications
- **Input Validation**: Comprehensive parameter validation
- **Error Recovery**: Graceful handling of failures
- **Audit Trail**: Detailed logging of all operations

### **Best Practices**
- Always run as Administrator
- Create backups before making changes
- Test in non-production environment first
- Review logs after operations
- Keep configuration files secure

## 🆚 **Comparison with PowerShell Version**

| Feature | PowerShell | Python |
|---------|------------|--------|
| **Functionality** | ✅ Complete | ✅ Complete |
| **Interactive Menu** | ❌ No | ✅ Yes |
| **Color Output** | ✅ Yes | ✅ Enhanced |
| **Real-time Progress** | ⚠️ Limited | ✅ Full |
| **Cross-platform Testing** | ❌ No | ✅ Yes |
| **Configuration UI** | ❌ No | ✅ Yes |
| **System Validation** | ✅ Yes | ✅ Enhanced |
| **Error Recovery** | ✅ Yes | ✅ Improved |

## 🤝 **Contributing**

### **Development Setup**
```bash
# Clone repository
git clone <repository-url>

# Navigate to Python directory
cd python

# Run in development mode
python regional_settings_reset.py --menu
```

### **Code Style**
- Follow PEP 8 guidelines
- Use type hints where appropriate
- Comprehensive error handling
- Detailed logging and comments
- Unit tests for core functionality

## 📜 **License**

MIT License - See LICENSE file for details.

## 🆘 **Support**

### **Troubleshooting**
1. **Admin Rights**: Ensure running as Administrator
2. **Python Version**: Use Python 3.6+ (3.8+ recommended)
3. **Windows Compatibility**: Designed for Windows 10/11
4. **Registry Access**: Verify registry permissions

### **Common Issues**
- **Import Errors**: Check Python version and Windows platform
- **Registry Access Denied**: Run as Administrator
- **Configuration Errors**: Validate JSON syntax
- **Menu Display Issues**: Check terminal ANSI support

For additional support, refer to the main project documentation or open an issue in the repository.