# Windows Regional Settings Reset Toolkit - Folder Structure

## 📁 Repository Organization

The Windows Regional Settings Reset Toolkit has been organized into a logical folder structure to improve maintainability, deployment, and development workflows.

```
win-reginnal-reset/
├── README.md                     # Main documentation
├── LICENSE                       # MIT License
│
├── scripts/                      # Core deployment scripts
│   ├── Reset-RegionalSettings.ps1    # Main PowerShell script
│   ├── reset-regional.bat           # Batch wrapper for easy execution
│   ├── backup-manager.bat           # Backup management utilities
│   └── scheduler.bat                # Task scheduling utilities
│
├── group-policy/                 # Active Directory Group Policy deployment
│   ├── Deploy-RegionalSettings-GP.ps1  # GP-compatible PowerShell script
│   └── deploy-regional-gp.bat         # GP-compatible batch wrapper
│
├── modules/                      # PowerShell modules and libraries
│   ├── BackupCompression.psm1       # Backup compression and encryption
│   └── IncrementalBackup.psm1       # Incremental backup functionality
│
├── config/                       # Configuration templates and files
│   ├── config.json                  # Standard configuration template
│   └── config-gp-template.json      # Group Policy configuration template
│
├── tests/                        # Testing framework and validation
│   ├── test_framework.py            # Multi-platform test suite
│   └── test_locales.sh              # C++ locale testing script
│
├── docs/                         # Documentation and guides
│   └── FOLDER_STRUCTURE.md          # This file
│
├── python/                       # Python implementation
│   ├── regional_settings_reset.py   # Main Python script
│   ├── launcher.py                  # Interactive launcher
│   ├── config.json                  # Python-specific configuration
│   ├── requirements.txt             # Python dependencies
│   └── README.md                    # Python implementation docs
│
└── cpp/                          # C++ implementation
    ├── regional_settings_reset.cpp  # Main C++ source
    ├── CMakeLists.txt               # CMake build configuration
    ├── Makefile                     # Make build configuration
    ├── config.json                  # C++ configuration
    ├── custom_locales.json          # Custom locale definitions
    └── README.md                    # C++ implementation docs
```

## 🎯 Folder Purposes

### `/scripts/` - Core Deployment Scripts
**Purpose**: Contains the main regional settings reset functionality and utility scripts.

**Key Files**:
- `Reset-RegionalSettings.ps1` - The primary PowerShell script for resetting regional settings
- `reset-regional.bat` - User-friendly batch wrapper with parameter parsing
- `backup-manager.bat` - Backup creation, restoration, and management utilities
- `scheduler.bat` - Task scheduling and automation utilities

**Usage**: These are the files end-users will primarily interact with for standard deployments.

### `/group-policy/` - Enterprise AD Deployment
**Purpose**: Specialized scripts designed for Active Directory Group Policy deployment in enterprise environments.

**Key Files**:
- `Deploy-RegionalSettings-GP.ps1` - GP-compatible PowerShell script with enterprise features
- `deploy-regional-gp.bat` - GP-compatible batch wrapper with compliance and logging

**Features**:
- Silent execution for automated deployment
- Centralized logging to network shares
- Compliance reporting (SOX, HIPAA, ISO27001)
- SCCM package compatibility
- Domain environment detection

### `/modules/` - PowerShell Modules
**Purpose**: Reusable PowerShell modules that extend functionality across scripts.

**Key Files**:
- `BackupCompression.psm1` - Provides backup compression and encryption capabilities
- `IncrementalBackup.psm1` - Enables incremental backup functionality with differential tracking

**Import Example**:
```powershell
Import-Module .\modules\BackupCompression.psm1
Import-Module .\modules\IncrementalBackup.psm1
```

### `/config/` - Configuration Templates
**Purpose**: Centralized location for all configuration files and templates.

**Key Files**:
- `config.json` - Standard configuration template for basic deployments
- `config-gp-template.json` - Enterprise Group Policy configuration with advanced settings

**Benefits**:
- Version-controlled configuration management
- Environment-specific settings
- Template-based deployment standardization

### `/tests/` - Testing and Validation
**Purpose**: Comprehensive testing framework for validation across all implementations.

**Key Files**:
- `test_framework.py` - Multi-platform test suite with syntax validation, compatibility testing, and performance benchmarking
- `test_locales.sh` - C++ locale testing script for cross-platform validation

**Test Coverage**:
- PowerShell syntax validation
- Python import testing
- C++ compilation testing
- Configuration file validation
- Cross-platform compatibility
- Performance benchmarking

### `/docs/` - Documentation
**Purpose**: Centralized documentation and guides.

**Current Files**:
- `FOLDER_STRUCTURE.md` - This folder structure guide

**Future Documentation**:
- API reference guides
- Deployment best practices
- Troubleshooting guides
- Architecture diagrams

### `/python/` - Python Implementation
**Purpose**: Cross-platform Python implementation with interactive UI.

**Features**:
- Interactive menu system
- Cross-platform compatibility (Windows, Linux, macOS demo mode)
- Color-coded user interface
- Configuration management UI

### `/cpp/` - C++ Implementation
**Purpose**: High-performance C++ implementation for resource-constrained environments.

**Features**:
- Maximum performance and minimal resource usage
- Cross-platform support
- CMake and Make build systems
- Custom locale support

## 🔄 Migration Guide

### Updating Existing Scripts

If you have existing scripts or documentation that reference the old file locations, update them as follows:

#### PowerShell Scripts
```powershell
# Old
.\Reset-RegionalSettings.ps1

# New
.\scripts\Reset-RegionalSettings.ps1
```

#### Batch Files
```batch
REM Old
reset-regional.bat en-US force

REM New
scripts\reset-regional.bat en-US force
```

#### Module Imports
```powershell
# Old
Import-Module .\BackupCompression.psm1

# New
Import-Module .\modules\BackupCompression.psm1
```

#### Configuration Files
```powershell
# Old
.\Reset-RegionalSettings.ps1 -ConfigFile "config.json"

# New
.\scripts\Reset-RegionalSettings.ps1 -ConfigFile "config\config.json"
```

#### Group Policy Deployment
```batch
REM Old
deploy-regional-gp.bat en-US Enterprise

REM New
group-policy\deploy-regional-gp.bat en-US Enterprise
```

### Testing the New Structure

Run the test framework to validate the new folder structure:

```bash
cd tests
python test_framework.py
```

## 🎯 Benefits of New Structure

### For Developers
- **Clear separation of concerns** - Each folder has a specific purpose
- **Improved maintainability** - Easier to locate and modify specific functionality
- **Better version control** - Cleaner commit history and easier code reviews
- **Modular architecture** - Components can be developed and tested independently

### For System Administrators
- **Easier deployment** - Clear distinction between user scripts and enterprise tools
- **Better organization** - Configuration files and scripts are logically grouped
- **Simplified automation** - Consistent paths for scripted deployments
- **Enhanced security** - Separate folders allow for granular permission management

### For End Users
- **Clearer documentation** - Folder structure makes it obvious what each component does
- **Easier navigation** - Logical organization reduces confusion
- **Better support** - Troubleshooting is easier with organized structure
- **Consistent experience** - Similar patterns across all implementations

## 📝 Best Practices

### When Adding New Files
1. **Follow the folder structure** - Place files in the most appropriate folder based on their purpose
2. **Update documentation** - Document any new files and their purposes
3. **Update tests** - Ensure new files are included in the test framework
4. **Check dependencies** - Update any file references in related scripts

### When Moving Files
1. **Update all references** - Search for and update all file path references
2. **Test thoroughly** - Run the complete test suite after making changes
3. **Update documentation** - Ensure all examples and guides reflect new paths
4. **Communicate changes** - Document breaking changes for users

### When Creating Symlinks or Aliases
For backward compatibility, you may create symlinks or wrapper scripts in the root directory that point to the new locations, but this should be temporary during migration periods.

## 🚀 Future Enhancements

### Planned Additions
- **`/examples/`** - Sample implementations and use cases
- **`/templates/`** - Additional configuration and deployment templates
- **`/tools/`** - Development and maintenance utilities
- **`/integrations/`** - Third-party system integrations (SCCM, Ansible, etc.)

### Documentation Expansion
- API reference documentation
- Architecture and design documents
- Deployment scenario guides
- Performance optimization guides

This folder structure provides a solid foundation for continued development and maintenance of the Windows Regional Settings Reset Toolkit while maintaining clear organization and ease of use.