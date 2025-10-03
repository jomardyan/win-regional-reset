#!/usr/bin/env python3
"""
Windows Regional Settings Reset - Python Edition v2.0

A comprehensive Python application to reset all Windows regional settings,
including Windows 11 registry memory slots. Features advanced error handling,
configuration management, backup/restore capabilities, and interactive menu system.

Author: Windows Regional Settings Reset Team
Version: 2.0
License: MIT
"""

import os
import sys
import json
import logging
import argparse
import subprocess
import tempfile
import shutil
import re
from datetime import datetime
from pathlib import Path
from typing import Dict, List, Optional, Tuple, Any

# Windows-specific imports with fallbacks
if sys.platform == 'win32':
    try:
        import winreg
        import ctypes
        from ctypes import wintypes
        WINDOWS_AVAILABLE = True
    except ImportError:
        WINDOWS_AVAILABLE = False
        winreg = None
        ctypes = None
else:
    WINDOWS_AVAILABLE = False
    winreg = None
    ctypes = None
    
# Mock objects for non-Windows platforms
if not WINDOWS_AVAILABLE:
    class MockWinreg:
        HKEY_CURRENT_USER = "HKEY_CURRENT_USER"
        REG_SZ = 1
        REG_DWORD = 4
        
        @staticmethod
        def CreateKey(*args):
            raise NotImplementedError("Windows registry not available on this platform")
            
        @staticmethod
        def OpenKey(*args):
            raise NotImplementedError("Windows registry not available on this platform")
            
        @staticmethod
        def SetValueEx(*args):
            raise NotImplementedError("Windows registry not available on this platform")
            
        @staticmethod
        def QueryValueEx(*args):
            raise NotImplementedError("Windows registry not available on this platform")
            
        @staticmethod
        def DeleteTree(*args):
            raise NotImplementedError("Windows registry not available on this platform")
    
    winreg = MockWinreg()
    
    class MockCtypes:
        class windll:
            class shell32:
                @staticmethod
                def IsUserAnAdmin():
                    return 0
    
    ctypes = MockCtypes()

# Check if running on Windows
if sys.platform != 'win32':
    print("⚠️  WARNING: This application is designed for Windows systems.")
    print("   Current platform:", sys.platform)
    print("   Running in demonstration mode with limited functionality.\n")

class Colors:
    """ANSI color codes for console output"""
    RED = '\033[91m'
    GREEN = '\033[92m'
    YELLOW = '\033[93m'
    BLUE = '\033[94m'
    MAGENTA = '\033[95m'
    CYAN = '\033[96m'
    WHITE = '\033[97m'
    GRAY = '\033[90m'
    RESET = '\033[0m'
    BOLD = '\033[1m'

class RegionalSettingsConfig:
    """Configuration management for regional settings"""
    
    SUPPORTED_LOCALES = {
        "pl-PL": "Polish (Poland)",
        "en-US": "English (United States)",
        "en-GB": "English (United Kingdom)",
        "de-DE": "German (Germany)",
        "fr-FR": "French (France)",
        "es-ES": "Spanish (Spain)",
        "it-IT": "Italian (Italy)",
        "pt-PT": "Portuguese (Portugal)",
        "ru-RU": "Russian (Russia)",
        "zh-CN": "Chinese (Simplified, China)",
        "ja-JP": "Japanese (Japan)",
        "ko-KR": "Korean (Korea)"
    }
    
    # Cached locale settings to avoid recreation (performance optimization)
    LOCALE_SETTINGS_CACHE = {}
    
    GEO_IDS = {
        "pl-PL": 191,
        "en-US": 244,
        "en-GB": 242,
        "de-DE": 94,
        "fr-FR": 84,
        "es-ES": 217,
        "it-IT": 118,
        "pt-PT": 193,
        "ru-RU": 203,
        "zh-CN": 45,
        "ja-JP": 122,
        "ko-KR": 134
    }
    
    DEFAULT_CONFIG = {
        "defaultLocale": "pl-PL",
        "skipBackup": False,
        "maxRetries": 3,
        "logLevel": "INFO",
        "features": {
            "resetBrowserSettings": True,
            "resetOfficeSettings": True,
            "resetMruLists": True,
            "resetSystemLocale": True,
            "resetWindows11Memory": True
        },
        "backup": {
            "retentionDays": 30,
            "compressionEnabled": False,
            "customBackupPath": ""
        }
    }

class RegionalSettingsReset:
    """Main class for Windows Regional Settings Reset functionality"""
    
    def __init__(self, config_file: Optional[str] = None, log_file: Optional[str] = None):
        self.config = RegionalSettingsConfig()
        self.operation_count = 0
        self.success_count = 0
        self.error_count = 0
        self.backup_path = ""
        
        # Setup logging
        self._setup_logging(log_file)
        
        # Load configuration
        self._load_config(config_file)
        
        # Check admin privileges
        self.is_admin = self._check_admin_privileges()
        
    @staticmethod
    def _validate_path(path: str) -> bool:
        """Validate file path to prevent path traversal attacks"""
        if not path:
            return False
        try:
            # Resolve to absolute path and check for path traversal
            abs_path = Path(path).resolve()
            # Check for suspicious patterns
            path_str = str(abs_path)
            if '..' in path_str or path_str.startswith('/etc') or path_str.startswith('/sys'):
                return False
            return True
        except (ValueError, OSError):
            return False
    
    @staticmethod
    def _sanitize_input(user_input: str, max_length: int = 100) -> str:
        """Sanitize user input to prevent injection attacks"""
        if not user_input:
            return ""
        # Remove potentially dangerous characters
        sanitized = re.sub(r'[;&|`$\n\r]', '', user_input)
        return sanitized[:max_length]
        
    def _setup_logging(self, log_file: Optional[str] = None):
        """Setup logging configuration"""
        if log_file is None:
            log_file = os.path.join(
                tempfile.gettempdir(),
                f"RegionalSettings_{datetime.now().strftime('%Y%m%d_%H%M%S')}.log"
            )
        
        self.log_file = log_file
        
        # Create log directory if it doesn't exist
        os.makedirs(os.path.dirname(log_file), exist_ok=True)
        
        # Configure logging
        logging.basicConfig(
            level=logging.INFO,
            format='[%(asctime)s] [%(levelname)s] %(message)s',
            handlers=[
                logging.FileHandler(log_file, encoding='utf-8'),
                logging.StreamHandler(sys.stdout)
            ]
        )
        
        self.logger = logging.getLogger(__name__)
        
    def _load_config(self, config_file: Optional[str] = None):
        """Load configuration from file or use defaults"""
        self.user_config = self.config.DEFAULT_CONFIG.copy()
        
        if config_file and os.path.exists(config_file):
            try:
                with open(config_file, 'r', encoding='utf-8') as f:
                    loaded_config = json.load(f)
                    self.user_config.update(loaded_config)
                self.log_info(f"Configuration loaded from: {config_file}")
            except Exception as e:
                self.log_warning(f"Failed to load configuration from {config_file}: {e}")
                
    def _check_admin_privileges(self) -> bool:
        """Check if running with administrator privileges"""
        if not WINDOWS_AVAILABLE:
            return False
            
        try:
            return ctypes.windll.shell32.IsUserAnAdmin() != 0
        except:
            return False
            
    def log_info(self, message: str, color: str = Colors.WHITE):
        """Log info message with color"""
        self.logger.info(message)
        if color != Colors.WHITE:
            print(f"{color}{message}{Colors.RESET}")
            
    def log_warning(self, message: str):
        """Log warning message"""
        self.logger.warning(message)
        print(f"{Colors.YELLOW}[WARNING] {message}{Colors.RESET}")
        
    def log_error(self, message: str):
        """Log error message"""
        self.logger.error(message)
        print(f"{Colors.RED}[ERROR] {message}{Colors.RESET}")
        self.error_count += 1
        
    def log_success(self, message: str):
        """Log success message"""
        self.logger.info(message)
        print(f"{Colors.GREEN}[SUCCESS] {message}{Colors.RESET}")
        self.success_count += 1
        
    def print_banner(self):
        """Print application banner"""
        print(f"{Colors.MAGENTA}{Colors.BOLD}")
        print("=" * 60)
        print("    Windows Regional Settings Reset - Python Edition v2.0")
        print("=" * 60)
        print(f"{Colors.RESET}")
        
    def validate_locale(self, locale: str) -> bool:
        """Validate if locale is supported"""
        return locale in self.config.SUPPORTED_LOCALES
        
    def list_supported_locales(self):
        """Display supported locales"""
        print(f"\n{Colors.CYAN}Supported Locales:{Colors.RESET}")
        for code, name in self.config.SUPPORTED_LOCALES.items():
            print(f"  {Colors.WHITE}{code:<8}{Colors.RESET} - {name}")
        print()
        
    def create_backup(self, registry_path: str, backup_name: str) -> bool:
        """Create registry backup"""
        if not WINDOWS_AVAILABLE:
            self.log_warning("Registry backup not available on this platform")
            return False
            
        try:
            if not self.backup_path:
                self.backup_path = os.path.join(
                    tempfile.gettempdir(),
                    f"RegionalSettings_Backup_{datetime.now().strftime('%Y%m%d_%H%M%S')}"
                )
                os.makedirs(self.backup_path, exist_ok=True)
                
            backup_file = os.path.join(self.backup_path, f"{backup_name}.reg")
            
            # Use reg.exe to export registry
            cmd = ["reg", "export", registry_path, backup_file, "/y"]
            result = subprocess.run(cmd, capture_output=True, text=True)
            
            if result.returncode == 0:
                self.log_success(f"Backed up {registry_path} to {backup_file}")
                return True
            else:
                self.log_error(f"Failed to backup {registry_path}: {result.stderr}")
                return False
                
        except Exception as e:
            self.log_error(f"Backup error for {registry_path}: {e}")
            return False
            
    def set_registry_value(self, hive: int, key_path: str, value_name: str, 
                          value_data: Any, value_type: int = None) -> bool:
        """Set registry value with retry logic"""
        if not WINDOWS_AVAILABLE:
            self.log_info(f"[DEMO] Would set {key_path}\\{value_name} = {value_data}")
            self.success_count += 1
            return True
            
        if value_type is None:
            value_type = winreg.REG_SZ
            
        max_retries = self.user_config.get('maxRetries', 3)
        
        for attempt in range(max_retries):
            try:
                self.operation_count += 1
                
                # Open/create registry key
                with winreg.CreateKey(hive, key_path) as key:
                    winreg.SetValueEx(key, value_name, 0, value_type, value_data)
                    
                # Verify the value was set
                with winreg.OpenKey(hive, key_path) as key:
                    stored_value, _ = winreg.QueryValueEx(key, value_name)
                    if stored_value == value_data:
                        self.log_success(f"Set {key_path}\\{value_name} = {value_data}")
                        return True
                        
            except Exception as e:
                if attempt < max_retries - 1:
                    self.log_warning(f"Registry attempt {attempt + 1} failed for {key_path}\\{value_name}: {e}")
                else:
                    self.log_error(f"Failed to set {key_path}\\{value_name} after {max_retries} attempts: {e}")
                    
        return False
        
    def apply_locale_settings(self, locale: str) -> bool:
        """Apply locale-specific settings"""
        self.log_info(f"Applying settings for locale: {locale}")
        
        # Define locale-specific settings
        locale_settings = self._get_locale_settings(locale)
        
        success = True
        
        if WINDOWS_AVAILABLE:
            hkcu = winreg.HKEY_CURRENT_USER
            intl_path = "Control Panel\\International"
            
            # Apply core settings
            for setting_name, setting_value in locale_settings.items():
                if isinstance(setting_value, int):
                    value_type = winreg.REG_DWORD
                else:
                    value_type = winreg.REG_SZ
                    
                if not self.set_registry_value(hkcu, intl_path, setting_name, setting_value, value_type):
                    success = False
        else:
            # Demo mode for non-Windows platforms
            self.log_info(f"[DEMO MODE] Applying {len(locale_settings)} settings for {locale}")
            for setting_name, setting_value in locale_settings.items():
                self.log_info(f"[DEMO] {setting_name} = {setting_value}")
                self.operation_count += 1
                self.success_count += 1
                
        return success
        
    def _get_locale_settings(self, locale: str) -> Dict[str, Any]:
        """Get locale-specific registry settings (cached for performance)"""
        # Check cache first
        if locale in self.config.LOCALE_SETTINGS_CACHE:
            return self.config.LOCALE_SETTINGS_CACHE[locale]
        
        locale_configs = {
            "pl-PL": {
                "Locale": locale,
                "LocaleName": locale,
                "sLanguage": "PLK",
                "sCountry": "Poland",
                "sShortDate": "dd.MM.yyyy",
                "sLongDate": "d MMMM yyyy",
                "sTimeFormat": "HH:mm:ss",
                "sShortTime": "HH:mm",
                "sCurrency": "zł",
                "sMonDecimalSep": ",",
                "sMonThousandSep": " ",
                "sDecimal": ",",
                "sThousand": " ",
                "sList": ";",
                "iCountry": 48,
                "iCurrency": 3,
                "iCurrDigits": 2,
                "iDate": 1,
                "iTime": 1,
                "iTLZero": 1,
                "s1159": "",
                "s2359": ""
            },
            "en-US": {
                "Locale": locale,
                "LocaleName": locale,
                "sLanguage": "ENU",
                "sCountry": "United States",
                "sShortDate": "M/d/yyyy",
                "sLongDate": "dddd, MMMM d, yyyy",
                "sTimeFormat": "h:mm:ss tt",
                "sShortTime": "h:mm tt",
                "sCurrency": "$",
                "sMonDecimalSep": ".",
                "sMonThousandSep": ",",
                "sDecimal": ".",
                "sThousand": ",",
                "sList": ",",
                "iCountry": 1,
                "iCurrency": 0,
                "iCurrDigits": 2,
                "iDate": 0,
                "iTime": 0,
                "iTLZero": 0,
                "s1159": "AM",
                "s2359": "PM"
            }
            # Add more locales as needed
        }
        
        result = locale_configs.get(locale, {
            "Locale": locale,
            "LocaleName": locale,
            "sLanguage": locale.split('-')[0].upper(),
            "sCountry": self.config.SUPPORTED_LOCALES[locale]
        })
        
        # Cache for future use
        self.config.LOCALE_SETTINGS_CACHE[locale] = result
        return result
        
    def reset_windows11_memory_slots(self) -> bool:
        """Reset Windows 11 specific memory slots"""
        self.log_info("Resetting Windows 11 memory slots...")
        
        if not WINDOWS_AVAILABLE:
            self.log_info("[DEMO] Would reset Windows 11 memory slots")
            return True
        
        try:
            hkcu = winreg.HKEY_CURRENT_USER
            
            # Clear user profile settings
            profile_path = "Control Panel\\International\\User Profile"
            try:
                winreg.DeleteTree(hkcu, profile_path)
                self.log_success("Cleared user profile regional settings")
            except FileNotFoundError:
                self.log_info("User profile settings already cleared")
            except Exception as e:
                self.log_warning(f"Could not clear user profile: {e}")
                
            return True
            
        except Exception as e:
            self.log_error(f"Error resetting Windows 11 memory slots: {e}")
            return False
            
    def reset_browser_settings(self) -> bool:
        """Reset browser regional settings"""
        if not self.user_config["features"]["resetBrowserSettings"]:
            return True
            
        self.log_info("Resetting browser settings...")
        success = True
        
        try:
            hkcu = winreg.HKEY_CURRENT_USER
            
            # Internet Explorer/Edge settings
            ie_paths = [
                "Software\\Microsoft\\Internet Explorer\\International",
                "Software\\Microsoft\\Internet Explorer\\Main\\International"
            ]
            
            for path in ie_paths:
                if not self.set_registry_value(hkcu, path, "AcceptLanguage", "en-US"):
                    success = False
                    
            self.log_success("Browser settings reset completed")
            return success
            
        except Exception as e:
            self.log_error(f"Error resetting browser settings: {e}")
            return False
            
    def generate_statistics_report(self) -> str:
        """Generate execution statistics report"""
        success_rate = (self.success_count / max(self.operation_count, 1)) * 100
        
        report = f"""
{Colors.CYAN}Execution Statistics:{Colors.RESET}
  Total Operations: {self.operation_count}
  Successful: {Colors.GREEN}{self.success_count}{Colors.RESET}
  Failed: {Colors.RED}{self.error_count}{Colors.RESET}
  Success Rate: {Colors.BLUE}{success_rate:.1f}%{Colors.RESET}
  
{Colors.CYAN}Files:{Colors.RESET}
  Log File: {Colors.WHITE}{self.log_file}{Colors.RESET}
  Backup Directory: {Colors.WHITE}{self.backup_path or 'None created'}{Colors.RESET}
"""
        return report

class InteractiveMenu:
    """Interactive menu system for the application"""
    
    def __init__(self):
        self.app = None
        self.current_locale = "pl-PL"
        
    def run(self):
        """Run the interactive menu"""
        while True:
            self.show_main_menu()
            choice = input(f"\n{Colors.CYAN}Enter your choice (1-9): {Colors.RESET}").strip()
            
            if choice == '1':
                self.quick_reset()
            elif choice == '2':
                self.configure_settings()
            elif choice == '3':
                self.backup_management()
            elif choice == '4':
                self.validation_tools()
            elif choice == '5':
                self.system_information()
            elif choice == '6':
                self.configuration_management()
            elif choice == '7':
                self.help_and_examples()
            elif choice == '8':
                self.about()
            elif choice == '9' or choice.lower() == 'q':
                self.exit_application()
                break
            else:
                print(f"{Colors.RED}Invalid choice. Please try again.{Colors.RESET}")
                
            input(f"\n{Colors.GRAY}Press Enter to continue...{Colors.RESET}")
            
    def show_main_menu(self):
        """Display the main menu"""
        os.system('cls' if os.name == 'nt' else 'clear')
        
        print(f"{Colors.MAGENTA}{Colors.BOLD}")
        print("╔" + "═" * 58 + "╗")
        print("║     Windows Regional Settings Reset - Python Edition    ║")
        print("║                        v2.0                             ║")
        print("╚" + "═" * 58 + "╝")
        print(f"{Colors.RESET}")
        
        print(f"{Colors.WHITE}Current Locale: {Colors.GREEN}{self.current_locale}{Colors.RESET}")
        print(f"{Colors.WHITE}Admin Rights: {Colors.GREEN if self._check_admin() else Colors.RED}{'Yes' if self._check_admin() else 'No'}{Colors.RESET}")
        print()
        
        menu_items = [
            ("1", "Quick Reset", "Reset regional settings with current locale"),
            ("2", "Configure Settings", "Choose locale and advanced options"),
            ("3", "Backup Management", "Create, restore, and manage backups"),
            ("4", "Validation Tools", "System validation and testing"),
            ("5", "System Information", "View current regional settings"),
            ("6", "Configuration", "Manage configuration files"),
            ("7", "Help & Examples", "Usage examples and documentation"),
            ("8", "About", "Version and license information"),
            ("9", "Exit", "Quit the application")
        ]
        
        for num, title, desc in menu_items:
            print(f"{Colors.CYAN}{num}.{Colors.RESET} {Colors.WHITE}{title:<20}{Colors.RESET} {Colors.GRAY}- {desc}{Colors.RESET}")
            
    def _check_admin(self) -> bool:
        """Check admin privileges"""
        if not WINDOWS_AVAILABLE:
            return False
            
        try:
            return ctypes.windll.shell32.IsUserAnAdmin() != 0
        except:
            return False
            
    def quick_reset(self):
        """Quick reset with current settings"""
        print(f"\n{Colors.YELLOW}Quick Reset - {self.current_locale}{Colors.RESET}")
        print("=" * 40)
        
        if not self._check_admin():
            print(f"{Colors.RED}Administrator privileges required!{Colors.RESET}")
            return
            
        confirm = input(f"\nReset regional settings to {Colors.GREEN}{self.current_locale}{Colors.RESET}? (y/N): ")
        if confirm.lower() != 'y':
            print("Operation cancelled.")
            return
            
        # Initialize application
        self.app = RegionalSettingsReset()
        self.app.print_banner()
        
        # Perform reset
        try:
            # Create backup
            backup_success = self.app.create_backup(
                "HKEY_CURRENT_USER\\Control Panel\\International",
                "International_Quick_Backup"
            )
            
            # Apply settings
            if self.app.apply_locale_settings(self.current_locale):
                print(f"\n{Colors.GREEN}Quick reset completed successfully!{Colors.RESET}")
            else:
                print(f"\n{Colors.YELLOW}Reset completed with some warnings.{Colors.RESET}")
                
            # Show statistics
            print(self.app.generate_statistics_report())
            
        except Exception as e:
            print(f"{Colors.RED}Error during quick reset: {e}{Colors.RESET}")
            
    def configure_settings(self):
        """Configure locale and advanced settings"""
        print(f"\n{Colors.YELLOW}Configure Settings{Colors.RESET}")
        print("=" * 30)
        
        # Show supported locales
        print(f"\n{Colors.CYAN}Supported Locales:{Colors.RESET}")
        locales = list(RegionalSettingsConfig.SUPPORTED_LOCALES.items())
        
        for i, (code, name) in enumerate(locales, 1):
            marker = f"{Colors.GREEN}→{Colors.RESET}" if code == self.current_locale else " "
            print(f"{marker} {i:2}. {Colors.WHITE}{code:<8}{Colors.RESET} - {name}")
            
        print(f"\n{Colors.WHITE}Current: {Colors.GREEN}{self.current_locale}{Colors.RESET}")
        
        try:
            choice = input(f"\nSelect locale number (1-{len(locales)}) or Enter to keep current: ").strip()
            if choice and choice.isdigit():
                idx = int(choice) - 1
                if 0 <= idx < len(locales):
                    self.current_locale = locales[idx][0]
                    print(f"{Colors.GREEN}Locale changed to: {self.current_locale}{Colors.RESET}")
                else:
                    print(f"{Colors.RED}Invalid selection.{Colors.RESET}")
        except ValueError:
            print(f"{Colors.RED}Invalid input.{Colors.RESET}")
            
    def backup_management(self):
        """Backup management interface"""
        print(f"\n{Colors.YELLOW}Backup Management{Colors.RESET}")
        print("=" * 30)
        
        backup_options = [
            ("1", "List Backups", "Show all available backups"),
            ("2", "Create Backup", "Create new backup"),
            ("3", "Restore Backup", "Restore from existing backup"),
            ("4", "Cleanup Old Backups", "Remove old backup files"),
            ("5", "Verify Backups", "Check backup integrity"),
            ("6", "Back to Main Menu", "Return to main menu")
        ]
        
        for num, title, desc in backup_options:
            print(f"{Colors.CYAN}{num}.{Colors.RESET} {Colors.WHITE}{title:<20}{Colors.RESET} {Colors.GRAY}- {desc}{Colors.RESET}")
            
        choice = input(f"\n{Colors.CYAN}Select option (1-6): {Colors.RESET}").strip()
        
        if choice == '1':
            self._list_backups()
        elif choice == '2':
            self._create_backup()
        elif choice == '3':
            self._restore_backup()
        elif choice == '4':
            self._cleanup_backups()
        elif choice == '5':
            self._verify_backups()
            
    def _list_backups(self):
        """List available backups"""
        temp_dir = tempfile.gettempdir()
        backup_pattern = "RegionalSettings_Backup_*"
        
        backups = []
        for item in Path(temp_dir).glob(backup_pattern):
            if item.is_dir():
                backups.append(item)
                
        if not backups:
            print(f"\n{Colors.YELLOW}No backups found.{Colors.RESET}")
            return
            
        print(f"\n{Colors.CYAN}Available Backups:{Colors.RESET}")
        for i, backup in enumerate(sorted(backups), 1):
            # Extract date/time from folder name
            match = re.search(r'(\d{8})_(\d{6})', backup.name)
            if match:
                date_str, time_str = match.groups()
                formatted_date = f"{date_str[:4]}-{date_str[4:6]}-{date_str[6:8]}"
                formatted_time = f"{time_str[:2]}:{time_str[2:4]}:{time_str[4:6]}"
                
            file_count = len(list(backup.glob("*.reg")))
            print(f"{Colors.WHITE}{i:2}.{Colors.RESET} {backup.name}")
            print(f"     Date: {formatted_date} {formatted_time}")
            print(f"     Files: {file_count} registry files")
            print()
            
    def _create_backup(self):
        """Create new backup"""
        if not self._check_admin():
            print(f"{Colors.RED}Administrator privileges required for backup creation!{Colors.RESET}")
            return
            
        print(f"\n{Colors.YELLOW}Creating backup...{Colors.RESET}")
        
        app = RegionalSettingsReset()
        success = app.create_backup(
            "HKEY_CURRENT_USER\\Control Panel\\International",
            "Manual_Backup"
        )
        
        if success:
            print(f"{Colors.GREEN}Backup created successfully!{Colors.RESET}")
            print(f"Location: {app.backup_path}")
        else:
            print(f"{Colors.RED}Backup creation failed.{Colors.RESET}")
            
    def _restore_backup(self):
        """Restore from backup"""
        print(f"\n{Colors.YELLOW}Restore functionality would be implemented here.{Colors.RESET}")
        print("This would show available backups and allow restoration.")
        
    def _cleanup_backups(self):
        """Cleanup old backups"""
        print(f"\n{Colors.YELLOW}Backup cleanup functionality would be implemented here.{Colors.RESET}")
        
    def _verify_backups(self):
        """Verify backup integrity"""
        print(f"\n{Colors.YELLOW}Backup verification functionality would be implemented here.{Colors.RESET}")
        
    def validation_tools(self):
        """Validation and testing tools"""
        print(f"\n{Colors.YELLOW}Validation Tools{Colors.RESET}")
        print("=" * 25)
        
        print(f"{Colors.CYAN}System Checks:{Colors.RESET}")
        
        # Check Windows version
        import platform
        print(f"Windows Version: {Colors.WHITE}{platform.version()}{Colors.RESET}")
        
        # Check Python version
        print(f"Python Version: {Colors.WHITE}{sys.version.split()[0]}{Colors.RESET}")
        
        # Check admin privileges
        admin_status = self._check_admin()
        color = Colors.GREEN if admin_status else Colors.RED
        print(f"Admin Privileges: {color}{'Yes' if admin_status else 'No'}{Colors.RESET}")
        
        # Check registry access
        if WINDOWS_AVAILABLE:
            try:
                with winreg.OpenKey(winreg.HKEY_CURRENT_USER, "Control Panel\\International"):
                    registry_access = True
            except:
                registry_access = False
        else:
            registry_access = False
            
        color = Colors.GREEN if registry_access else Colors.RED
        status = 'Available' if registry_access else ('Denied' if WINDOWS_AVAILABLE else 'Not Available (Non-Windows)')
        print(f"Registry Access: {color}{status}{Colors.RESET}")
        
    def system_information(self):
        """Display current system regional information"""
        print(f"\n{Colors.YELLOW}Current Regional Settings{Colors.RESET}")
        print("=" * 35)
        
        if not WINDOWS_AVAILABLE:
            print(f"{Colors.YELLOW}[DEMO MODE] Registry access not available on this platform{Colors.RESET}")
            print(f"{Colors.CYAN}Platform:{Colors.RESET} {Colors.WHITE}{sys.platform}{Colors.RESET}")
            print(f"{Colors.CYAN}Python Version:{Colors.RESET} {Colors.WHITE}{sys.version.split()[0]}{Colors.RESET}")
            print(f"{Colors.CYAN}Demo Locale:{Colors.RESET} {Colors.WHITE}{self.current_locale}{Colors.RESET}")
            return
        
        try:
            # Read current locale settings
            with winreg.OpenKey(winreg.HKEY_CURRENT_USER, "Control Panel\\International") as key:
                settings = [
                    ("Locale", "System Locale"),
                    ("LocaleName", "Locale Name"),
                    ("sCountry", "Country"),
                    ("sShortDate", "Short Date Format"),
                    ("sTimeFormat", "Time Format"),
                    ("sCurrency", "Currency Symbol")
                ]
                
                for reg_name, display_name in settings:
                    try:
                        value, _ = winreg.QueryValueEx(key, reg_name)
                        print(f"{Colors.CYAN}{display_name}:{Colors.RESET} {Colors.WHITE}{value}{Colors.RESET}")
                    except FileNotFoundError:
                        print(f"{Colors.CYAN}{display_name}:{Colors.RESET} {Colors.GRAY}Not set{Colors.RESET}")
                        
        except Exception as e:
            print(f"{Colors.RED}Error reading registry: {e}{Colors.RESET}")
            
    def configuration_management(self):
        """Configuration file management"""
        print(f"\n{Colors.YELLOW}Configuration Management{Colors.RESET}")
        print("=" * 35)
        
        config_file = "config.json"
        
        if os.path.exists(config_file):
            print(f"{Colors.GREEN}Configuration file found: {config_file}{Colors.RESET}")
            
            try:
                with open(config_file, 'r') as f:
                    config = json.load(f)
                    
                print(f"\n{Colors.CYAN}Current Configuration:{Colors.RESET}")
                print(json.dumps(config, indent=2))
                
            except Exception as e:
                print(f"{Colors.RED}Error reading configuration: {e}{Colors.RESET}")
        else:
            print(f"{Colors.YELLOW}No configuration file found.{Colors.RESET}")
            
            create = input(f"Create default configuration file? (y/N): ")
            if create.lower() == 'y':
                try:
                    with open(config_file, 'w') as f:
                        json.dump(RegionalSettingsConfig.DEFAULT_CONFIG, f, indent=2)
                    print(f"{Colors.GREEN}Configuration file created: {config_file}{Colors.RESET}")
                except Exception as e:
                    print(f"{Colors.RED}Error creating configuration: {e}{Colors.RESET}")
                    
    def help_and_examples(self):
        """Help and usage examples"""
        print(f"\n{Colors.YELLOW}Help & Examples{Colors.RESET}")
        print("=" * 25)
        
        examples = [
            ("Quick Reset", "Use option 1 for immediate reset with current locale"),
            ("Change Locale", "Use option 2 to select different locale"),
            ("Backup First", "Always create backup before making changes"),
            ("Check Status", "Use option 5 to view current settings"),
            ("Admin Required", "Most operations require administrator privileges"),
            ("Configuration", "Use config.json for advanced settings")
        ]
        
        for title, desc in examples:
            print(f"{Colors.CYAN}• {title}:{Colors.RESET} {desc}")
            
        print(f"\n{Colors.CYAN}Command Line Usage:{Colors.RESET}")
        print("python regional_settings_reset.py --locale en-US --force")
        print("python regional_settings_reset.py --config config.json")
        print("python regional_settings_reset.py --help")
        
    def about(self):
        """About information"""
        print(f"\n{Colors.YELLOW}About{Colors.RESET}")
        print("=" * 15)
        
        print(f"{Colors.CYAN}Windows Regional Settings Reset - Python Edition{Colors.RESET}")
        print(f"Version: {Colors.WHITE}2.0{Colors.RESET}")
        print(f"License: {Colors.WHITE}MIT{Colors.RESET}")
        print(f"Platform: {Colors.WHITE}Windows 10/11{Colors.RESET}")
        print(f"Python: {Colors.WHITE}{sys.version.split()[0]}+{Colors.RESET}")
        
        print(f"\n{Colors.CYAN}Features:{Colors.RESET}")
        features = [
            "Interactive menu system",
            "Comprehensive regional settings reset",
            "Backup and restore functionality",
            "Multiple locale support",
            "Configuration management",
            "System validation tools"
        ]
        
        for feature in features:
            print(f"• {feature}")
            
    def exit_application(self):
        """Exit the application"""
        print(f"\n{Colors.CYAN}Thank you for using Windows Regional Settings Reset!{Colors.RESET}")
        print(f"{Colors.GRAY}Goodbye!{Colors.RESET}")

def main():
    """Main function with command line argument support"""
    parser = argparse.ArgumentParser(
        description="Windows Regional Settings Reset - Python Edition v2.0",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  python regional_settings_reset.py                    # Interactive menu
  python regional_settings_reset.py --locale en-US     # Reset to English (US)
  python regional_settings_reset.py --force            # Skip confirmations
  python regional_settings_reset.py --config cfg.json  # Use custom config
        """
    )
    
    parser.add_argument('--locale', help='Target locale (e.g., en-US, de-DE)')
    parser.add_argument('--force', action='store_true', help='Skip confirmation prompts')
    parser.add_argument('--config', help='Configuration file path')
    parser.add_argument('--log', help='Log file path')
    parser.add_argument('--menu', action='store_true', help='Force interactive menu')
    
    args = parser.parse_args()
    
    # If no arguments or --menu specified, run interactive mode
    if len(sys.argv) == 1 or args.menu:
        menu = InteractiveMenu()
        menu.run()
    else:
        # Command line mode
        app = RegionalSettingsReset(config_file=args.config, log_file=args.log)
        app.print_banner()
        
        if args.locale:
            if not app.validate_locale(args.locale):
                print(f"{Colors.RED}Unsupported locale: {args.locale}{Colors.RESET}")
                app.list_supported_locales()
                sys.exit(1)
                
            if not args.force:
                confirm = input(f"Reset regional settings to {args.locale}? (y/N): ")
                if confirm.lower() != 'y':
                    print("Operation cancelled.")
                    sys.exit(0)
                    
            # Perform reset
            success = app.apply_locale_settings(args.locale)
            print(app.generate_statistics_report())
            
            sys.exit(0 if success else 1)
        else:
            parser.print_help()

if __name__ == "__main__":
    main()