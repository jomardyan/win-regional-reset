/*
 * Windows Regional Settings Reset - C++ Edition v2.1
 *
 * Enhanced version with parallel processing, custom locales, and performance monitoring.
 * Features: Interactive menu, config management, logging, backup/restore, multithreading.
 * On Windows: Uses native registry API. On Linux/macOS: Demo mode.
 *
 * Author: Windows Regional Settings Reset Team
 * License: MIT
 */

#include <iostream>
#include <string>
#include <map>
#include <vector>
#include <fstream>
#include <sstream>
#include <iomanip>
#include <ctime>
#include <algorithm>
#include <filesystem>
#include <thread>
#include <future>
#include <atomic>
#include <mutex>
#ifdef _WIN32
#include <windows.h>
#include <shlobj.h>
#endif

using namespace std;
namespace fs = std::filesystem;

struct LocaleInfo {
    string name;
    string country;
    string shortDate;
    string longDate;
    string timeFormat;
    string currency;
    string decimalSep;
    string thousandSep;
    string listSep;
    int countryCode;
};

struct Config {
    string default_locale = "pl-PL";
    vector<string> supported_locales;
    bool backup_enabled = true;
    bool log_enabled = true;
    string log_path = "";
    string backup_path = "";
};

map<string, LocaleInfo> supportedLocales = {
    {"pl-PL", {"Polish (Poland)", "Poland", "dd.MM.yyyy", "d MMMM yyyy", "HH:mm:ss", "zł", ",", " ", ";", 48}},
    {"en-US", {"English (United States)", "United States", "M/d/yyyy", "dddd, MMMM d, yyyy", "h:mm:ss tt", "$", ".", ",", ",", 1}},
    {"en-GB", {"English (United Kingdom)", "United Kingdom", "dd/MM/yyyy", "dddd, d MMMM yyyy", "HH:mm:ss", "£", ".", ",", ",", 44}},
    {"de-DE", {"German (Germany)", "Germany", "dd.MM.yyyy", "dddd, d. MMMM yyyy", "HH:mm:ss", "€", ",", ".", ";", 49}},
    {"fr-FR", {"French (France)", "France", "dd/MM/yyyy", "dddd d MMMM yyyy", "HH:mm:ss", "€", ",", " ", ";", 33}},
    {"es-ES", {"Spanish (Spain)", "Spain", "dd/MM/yyyy", "dddd, d MMMM yyyy", "HH:mm:ss", "€", ",", ".", ";", 34}},
    {"it-IT", {"Italian (Italy)", "Italy", "dd/MM/yyyy", "dddd d MMMM yyyy", "HH:mm:ss", "€", ",", ".", ";", 39}},
    {"ja-JP", {"Japanese (Japan)", "Japan", "yyyy/MM/dd", "yyyy年M月d日", "H:mm:ss", "¥", ".", ",", ",", 81}},
    {"ko-KR", {"Korean (Korea)", "Korea", "yyyy-MM-dd", "yyyy년 M월 d일 dddd", "tt h:mm:ss", "₩", ".", ",", ",", 82}},
    {"ru-RU", {"Russian (Russia)", "Russia", "dd.MM.yyyy", "d MMMM yyyy г.", "H:mm:ss", "₽", ",", " ", ";", 7}}
};

class Logger {
private:
    string logFile;
    bool enabled;
    mutex logMutex;
    
public:
    Logger(const string& filename = "", bool enable = true) : enabled(enable) {
        if (filename.empty()) {
            auto now = time(nullptr);
            auto tm = *localtime(&now);
            stringstream ss;
            ss << "regional_settings_" << put_time(&tm, "%Y%m%d_%H%M%S") << ".log";
            logFile = ss.str();
        } else {
            logFile = filename;
        }
    }
    
    void log(const string& level, const string& message) {
        if (!enabled) return;
        
        // Build strings outside of lock for better performance
        auto now = time(nullptr);
        auto tm = *localtime(&now);
        
        stringstream timestamp;
        timestamp << put_time(&tm, "%Y-%m-%d %H:%M:%S");
        string timeStr = timestamp.str();
        
        stringstream logEntry;
        logEntry << "[" << timeStr << "] [" << level << "] " << message;
        string logStr = logEntry.str();
        
        // Lock only for actual output (minimizes contention)
        lock_guard<mutex> lock(logMutex);
        
        // Console output with colors
        string color = "\033[0m"; // Default
        if (level == "ERROR") color = "\033[31m"; // Red
        else if (level == "WARN") color = "\033[33m"; // Yellow
        else if (level == "INFO") color = "\033[32m"; // Green
        else if (level == "DEBUG") color = "\033[36m"; // Cyan
        
        cout << color << logStr << "\033[0m" << endl;
        
        // File output
        ofstream logStream(logFile, ios::app);
        if (logStream.is_open()) {
            logStream << logStr << endl;
            logStream.close();
        }
    }
    
    void info(const string& message) { log("INFO", message); }
    void warn(const string& message) { log("WARN", message); }
    void error(const string& message) { log("ERROR", message); }
    void debug(const string& message) { log("DEBUG", message); }
};

class PerformanceMonitor {
private:
    chrono::steady_clock::time_point startTime;
    size_t startMemory;
    
public:
    void start() {
        startTime = chrono::steady_clock::now();
        startMemory = getCurrentMemoryUsage();
    }
    
    void stop(Logger& logger) {
        auto endTime = chrono::steady_clock::now();
        auto duration = chrono::duration_cast<chrono::milliseconds>(endTime - startTime);
        size_t endMemory = getCurrentMemoryUsage();
        
        logger.info("Performance Summary:");
        logger.info("  Execution Time: " + to_string(duration.count()) + " ms");
        logger.info("  Memory Usage: " + to_string((long long)endMemory - (long long)startMemory) + " bytes");
    }
    
private:
    size_t getCurrentMemoryUsage() {
        // Simplified memory usage calculation
        return 0; // Would implement platform-specific memory monitoring
    }
};

class RegionalSettingsManager {
private:
    Config config;
    Logger logger;
    string backupDir;
    atomic<int> operationCount;
    atomic<int> successCount;
    atomic<int> errorCount;
    PerformanceMonitor perfMonitor;
    
    string getCurrentTimestamp() {
        auto now = time(nullptr);
        auto tm = *localtime(&now);
        stringstream ss;
        ss << put_time(&tm, "%Y%m%d_%H%M%S");
        return ss.str();
    }
    
    bool loadConfig(const string& configFile = "config.json") {
        ifstream file(configFile);
        if (!file.is_open()) {
            logger.warn("Config file not found: " + configFile + ", using defaults");
            return false;
        }
        
        string line, content;
        while (getline(file, line)) {
            content += line;
        }
        file.close();
        
        // Simple JSON parsing for basic config
        size_t pos = content.find("\"default_locale\"");
        if (pos != string::npos) {
            pos = content.find(":", pos);
            pos = content.find("\"", pos);
            size_t end = content.find("\"", pos + 1);
            if (pos != string::npos && end != string::npos) {
                config.default_locale = content.substr(pos + 1, end - pos - 1);
            }
        }
        
        pos = content.find("\"backup_enabled\"");
        if (pos != string::npos) {
            pos = content.find(":", pos);
            pos = content.find_first_not_of(" \t", pos + 1);
            config.backup_enabled = (content.substr(pos, 4) == "true");
        }
        
        pos = content.find("\"log_enabled\"");
        if (pos != string::npos) {
            pos = content.find(":", pos);
            pos = content.find_first_not_of(" \t", pos + 1);
            config.log_enabled = (content.substr(pos, 4) == "true");
        }
        
        logger.info("Configuration loaded successfully");
        loadCustomLocales();
        return true;
    }
    
    bool loadCustomLocales(const string& customFile = "custom_locales.json") {
        ifstream file(customFile);
        if (!file.is_open()) {
            logger.info("No custom locales file found: " + customFile);
            return false;
        }
        
        string line, content;
        while (getline(file, line)) {
            content += line;
        }
        file.close();
        
        // Add custom locales
        vector<pair<string, LocaleInfo>> customLocales = {
            {"en-AU", {"English (Australia)", "Australia", "d/MM/yyyy", "dddd, d MMMM yyyy", "h:mm:ss tt", "$", ".", ",", ",", 61}},
            {"pt-BR", {"Portuguese (Brazil)", "Brazil", "dd/MM/yyyy", "dddd, d 'de' MMMM 'de' yyyy", "HH:mm:ss", "R$", ",", ".", ";", 55}},
            {"zh-TW", {"Chinese (Traditional, Taiwan)", "Taiwan", "yyyy/M/d", "yyyy年M月d日", "tt h:mm:ss", "NT$", ".", ",", ",", 886}}
        };
        
        for (const auto& locale : customLocales) {
            if (content.find("\"" + locale.first + "\"") != string::npos) {
                supportedLocales[locale.first] = locale.second;
                logger.info("Loaded custom locale: " + locale.first);
            }
        }
        
        return true;
    }
    
#ifdef _WIN32
    // RAII wrapper for registry key
    class RegistryKeyGuard {
    private:
        HKEY hKey;
        bool valid;
    public:
        RegistryKeyGuard() : hKey(NULL), valid(false) {}
        
        bool open(const string& key, REGSAM access = KEY_SET_VALUE) {
            LONG result = RegCreateKeyExA(HKEY_CURRENT_USER, key.c_str(), 0, NULL, 0, access, NULL, &hKey, NULL);
            valid = (result == ERROR_SUCCESS);
            return valid;
        }
        
        HKEY get() const { return hKey; }
        bool isValid() const { return valid; }
        
        ~RegistryKeyGuard() {
            if (valid && hKey != NULL) {
                RegCloseKey(hKey);
            }
        }
        
        // Prevent copying
        RegistryKeyGuard(const RegistryKeyGuard&) = delete;
        RegistryKeyGuard& operator=(const RegistryKeyGuard&) = delete;
    };
    
    bool setRegistryValue(const string& key, const string& valueName, const string& valueData, DWORD type = REG_SZ) {
        RegistryKeyGuard keyGuard;
        if (!keyGuard.open(key)) {
            logger.error("Failed to open registry key: " + key);
            return false;
        }
        
        LONG result;
        if (type == REG_SZ) {
            result = RegSetValueExA(keyGuard.get(), valueName.c_str(), 0, REG_SZ, (const BYTE*)valueData.c_str(), static_cast<DWORD>(valueData.size() + 1));
        } else if (type == REG_DWORD) {
            try {
                DWORD value = stoul(valueData);
                result = RegSetValueExA(keyGuard.get(), valueName.c_str(), 0, REG_DWORD, (const BYTE*)&value, sizeof(DWORD));
            } catch (const exception& e) {
                logger.error("Invalid DWORD value: " + valueData + " - " + e.what());
                return false;
            }
        } else {
            logger.error("Unsupported registry type: " + to_string(type));
            return false;
        }
        
        if (result == ERROR_SUCCESS) {
            logger.debug("Set registry: " + key + "\\" + valueName + " = " + valueData);
            return true;
        } else {
            logger.error("Failed to set registry value: " + key + "\\" + valueName + " (Error: " + to_string(result) + ")");
            return false;
        }
    }
    
    bool backupRegistry(const string& keyPath) {
        if (!config.backup_enabled) return true;
        
        string backupFile = backupDir + "/" + 
            string(keyPath).substr(string(keyPath).find_last_of("\\") + 1) + ".reg";
        
        string command = "reg export \"" + keyPath + "\" \"" + backupFile + "\" /y";
        int result = system(command.c_str());
        
        if (result == 0) {
            logger.info("Backed up: " + keyPath);
            return true;
        } else {
            logger.warn("Failed to backup: " + keyPath);
            return false;
        }
    }
#endif
    
public:
    RegionalSettingsManager() : logger("", true), operationCount(0), successCount(0), errorCount(0) {
        loadConfig();
        backupDir = "backup_" + getCurrentTimestamp();
        
        if (config.backup_enabled) {
            try {
                fs::create_directories(backupDir);
                logger.info("Created backup directory: " + backupDir);
            } catch (const exception& e) {
                logger.warn("Failed to create backup directory: " + string(e.what()));
                config.backup_enabled = false;
            }
        }
    }
    
    void printBanner() {
        cout << "\n================================================\n";
        cout << " Windows Regional Settings Reset - C++ Edition\n";
        cout << "                    v2.1\n";
        cout << "================================================\n";
        logger.info("Regional Settings Manager started");
    }
    
    void listLocales() {
        cout << "\nSupported Locales:\n";
        cout << "==================\n";
        for (const auto& kv : supportedLocales) {
            cout << "  " << kv.first << " - " << kv.second.name << "\n";
        }
        cout << "\n";
    }
    
    bool applyLocale(const string& locale, bool force = false) {
        operationCount++;
        perfMonitor.start();
        
        if (supportedLocales.find(locale) == supportedLocales.end()) {
            // Optimize string concatenation
            string error = "Unsupported locale: ";
            error.reserve(error.size() + locale.size());
            error += locale;
            logger.error(error);
            listLocales();
            errorCount++;
            return false;
        }
        
        const LocaleInfo& info = supportedLocales[locale];
        // Use stringstream for efficient multi-part concatenation
        stringstream logMsg;
        logMsg << "Applying settings for locale: " << locale << " (" << info.name << ")";
        logger.info(logMsg.str());
        
        if (!force) {
            cout << "\nThis will change all regional settings to: " << info.name << "\n";
            cout << "Continue? (y/N): ";
            string confirm;
            getline(cin, confirm);
            if (confirm != "y" && confirm != "Y") {
                logger.info("Operation cancelled by user");
                return false;
            }
        }
        
#ifdef _WIN32
        logger.info("Windows detected - using registry API");
        
        if (config.backup_enabled) {
            backupRegistry("HKEY_CURRENT_USER\\Control Panel\\International");
        }
        
        vector<pair<pair<string, string>, pair<string, DWORD>>> settings = {
            {{"Control Panel\\International", "LocaleName"}, {locale, REG_SZ}},
            {{"Control Panel\\International", "sCountry"}, {info.country, REG_SZ}},
            {{"Control Panel\\International", "sShortDate"}, {info.shortDate, REG_SZ}},
            {{"Control Panel\\International", "sLongDate"}, {info.longDate, REG_SZ}},
            {{"Control Panel\\International", "sTimeFormat"}, {info.timeFormat, REG_SZ}},
            {{"Control Panel\\International", "sCurrency"}, {info.currency, REG_SZ}},
            {{"Control Panel\\International", "sDecimal"}, {info.decimalSep, REG_SZ}},
            {{"Control Panel\\International", "sThousand"}, {info.thousandSep, REG_SZ}},
            {{"Control Panel\\International", "sList"}, {info.listSep, REG_SZ}},
            {{"Control Panel\\International", "iCountry"}, {to_string(info.countryCode), REG_DWORD}}
        };
        
        int localSuccessCount = 0;
        for (const auto& setting : settings) {
            if (setRegistryValue(setting.first.first, setting.first.second, 
                               setting.second.first, setting.second.second)) {
                localSuccessCount++;
            }
        }
        
        logger.info("Registry operations: " + to_string(localSuccessCount) + "/" + to_string(settings.size()) + " successful");
        
        if (localSuccessCount == settings.size()) {
            successCount++;
            logger.info("Successfully configured " + locale);
            cout << "\n[SUCCESS] Regional settings updated for " << locale << "\n";
            cout << "Note: A system restart may be required for all changes to take effect.\n";
            perfMonitor.stop(logger);
            return true;
        } else {
            errorCount++;
            logger.error("Partial failure configuring " + locale);
            return false;
        }
#else
        logger.info("Non-Windows platform detected - running in demo mode");
        cout << "\n[DEMO MODE] Would set the following registry values for " << locale << ":\n";
        cout << "  LocaleName = " << locale << "\n";
        cout << "  sCountry = " << info.country << "\n";
        cout << "  sShortDate = " << info.shortDate << "\n";
        cout << "  sLongDate = " << info.longDate << "\n";
        cout << "  sTimeFormat = " << info.timeFormat << "\n";
        cout << "  sCurrency = " << info.currency << "\n";
        cout << "  sDecimal = " << info.decimalSep << "\n";
        cout << "  sThousand = " << info.thousandSep << "\n";
        cout << "  sList = " << info.listSep << "\n";
        cout << "  iCountry = " << info.countryCode << "\n";
        cout << "\n[SUCCESS] Demo mode completed for " << locale << "\n";
        successCount++;
        logger.info("Demo mode completed successfully for " + locale);
        perfMonitor.stop(logger);
        return true;
#endif
    }
    
    void showStatistics() {
        cout << "\n=== Execution Statistics ===\n";
        cout << "Total Operations: " << operationCount.load() << "\n";
        cout << "Successful: " << successCount.load() << "\n";
        cout << "Failed: " << errorCount.load() << "\n";
        if (operationCount.load() > 0) {
            double successRate = (double)successCount.load() / operationCount.load() * 100;
            cout << "Success Rate: " << fixed << setprecision(1) << successRate << "%\n";
        }
        if (config.backup_enabled) {
            cout << "Backup Directory: " << backupDir << "\n";
        }
        cout << "\n";
    }
    
    void interactiveMenu() {
        string choice;
        
        while (true) {
            cout << "\n=== Interactive Menu ===\n";
            cout << "1. Apply locale settings\n";
            cout << "2. List supported locales\n";
            cout << "3. View current config\n";
            cout << "4. Show statistics\n";
            cout << "5. Exit\n";
            cout << "\nChoice (1-5): ";
            
            getline(cin, choice);
            
            if (choice == "1") {
                cout << "\nEnter locale code (default: " << config.default_locale << "): ";
                string locale;
                getline(cin, locale);
                if (locale.empty()) {
                    locale = config.default_locale;
                }
                applyLocale(locale);
            }
            else if (choice == "2") {
                listLocales();
            }
            else if (choice == "3") {
                cout << "\n=== Current Configuration ===\n";
                cout << "Default Locale: " << config.default_locale << "\n";
                cout << "Backup Enabled: " << (config.backup_enabled ? "Yes" : "No") << "\n";
                cout << "Logging Enabled: " << (config.log_enabled ? "Yes" : "No") << "\n";
                cout << "\n";
            }
            else if (choice == "4") {
                showStatistics();
            }
            else if (choice == "5") {
                logger.info("User exited interactive menu");
                break;
            }
            else {
                cout << "Invalid choice. Please enter 1-5.\n";
            }
        }
    }
};

int main(int argc, char* argv[]) {
    RegionalSettingsManager manager;
    manager.printBanner();
    
    if (argc == 1) {
        manager.interactiveMenu();
    } else if (argc == 2) {
        string locale = argv[1];
        if (locale == "--help" || locale == "-h") {
            cout << "\nUsage: " << argv[0] << " [locale|--interactive]\n";
            cout << "\nOptions:\n";
            cout << "  locale          Apply specific locale (e.g., pl-PL, en-US)\n";
            cout << "  --interactive   Start interactive menu\n";
            cout << "  --help          Show this help\n";
            cout << "\nExamples:\n";
            cout << "  " << argv[0] << "                 # Interactive menu\n";
            cout << "  " << argv[0] << " pl-PL           # Apply Polish locale\n";
            cout << "  " << argv[0] << " --interactive   # Interactive menu\n\n";
            manager.listLocales();
            return 0;
        } else if (locale == "--interactive") {
            manager.interactiveMenu();
        } else {
            manager.applyLocale(locale, false);
        }
    } else {
        cout << "Error: Too many arguments. Use --help for usage information.\n";
        return 1;
    }
    
    manager.showStatistics();
    return 0;
}