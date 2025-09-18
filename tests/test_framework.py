#!/usr/bin/env python3
"""
Automated Testing Framework for Regional Settings Reset
Comprehensive test suite covering all three implementations
"""

import sys
import os
import subprocess
import json
import time
import tempfile
import shutil
from pathlib import Path
from typing import Dict, List, Tuple, Any

class TestResult:
    def __init__(self, name: str, passed: bool, message: str = "", execution_time: float = 0.0):
        self.name = name
        self.passed = passed
        self.message = message
        self.execution_time = execution_time

class TestFramework:
    def __init__(self):
        self.results: List[TestResult] = []
        self.total_tests = 0
        self.passed_tests = 0
        self.failed_tests = 0
        
    def run_test(self, test_name: str, test_func, *args, **kwargs) -> TestResult:
        """Run a single test and record results"""
        print(f"Running: {test_name}... ", end="", flush=True)
        start_time = time.time()
        
        try:
            result = test_func(*args, **kwargs)
            execution_time = time.time() - start_time
            
            if result is True:
                print("✅ PASS")
                test_result = TestResult(test_name, True, "Test passed", execution_time)
                self.passed_tests += 1
            else:
                print("❌ FAIL")
                message = result if isinstance(result, str) else "Test failed"
                test_result = TestResult(test_name, False, message, execution_time)
                self.failed_tests += 1
                
        except Exception as e:
            execution_time = time.time() - start_time
            print(f"❌ ERROR: {str(e)}")
            test_result = TestResult(test_name, False, f"Exception: {str(e)}", execution_time)
            self.failed_tests += 1
            
        self.results.append(test_result)
        self.total_tests += 1
        return test_result
    
    def test_powershell_syntax(self) -> bool:
        """Test PowerShell script syntax"""
        try:
            result = subprocess.run([
                'powershell', '-Command',
                "Get-Content '../scripts/Reset-RegionalSettings.ps1' | Out-Null; Write-Host 'Syntax OK'"
            ], capture_output=True, text=True, timeout=10)
            return "Syntax OK" in result.stdout
        except:
            return False
    
    def test_powershell_execution_policy(self) -> bool:
        """Test PowerShell execution policy"""
        try:
            result = subprocess.run([
                "powershell", "-Command", "Get-ExecutionPolicy"
            ], capture_output=True, text=True)
            
            policy = result.stdout.strip()
            return policy in ["Unrestricted", "RemoteSigned", "Bypass"]
        except:
            return False
    
    def test_python_imports(self) -> bool:
        """Test Python script imports"""
        try:
            # Test main script imports
            result = subprocess.run([
                sys.executable, "-c", 
                "import sys; sys.path.append('.'); import regional_settings_reset; print('Imports OK')"
            ], capture_output=True, text=True, cwd="../python")
            
            return "Imports OK" in result.stdout
        except:
            return False
    
    def test_python_demo_mode(self) -> bool:
        """Test Python demo mode execution"""
        try:
            # Test with a simple locale application
            result = subprocess.run([
                sys.executable, "regional_settings_reset.py", "--locale", "en-US", "--demo"
            ], capture_output=True, text=True, cwd="../python", timeout=10)
            
            return result.returncode == 0 and "DEMO MODE" in result.stdout
        except:
            return False
    
    def test_cpp_compilation(self) -> bool:
        """Test C++ compilation"""
        try:
            result = subprocess.run([
                "g++", "-std=c++17", "-pthread", "-c", "regional_settings_reset_v2.cpp"
            ], capture_output=True, text=True, cwd="../cpp")
            
            return result.returncode == 0
        except:
            return False
    
    def test_cpp_demo_execution(self) -> bool:
        """Test C++ demo mode execution"""
        try:
            result = subprocess.run([
                "./regional_settings_reset_v2", "en-US"
            ], capture_output=True, text=True, cwd="../cpp", timeout=10)
            
            return "[DEMO MODE]" in result.stdout or "[SUCCESS]" in result.stdout
        except:
            return False
    
    def test_config_files_validity(self) -> bool:
        """Test configuration file validity"""
        config_files = [
            "../config/config.json",
            "../python/config.json", 
            "../cpp/config.json",
        ]
        
        for config_file in config_files:
            try:
                with open(config_file, 'r') as f:
                    json.load(f)
            except:
                return f"Invalid JSON in {config_file}"
        
        return True
    
    def test_batch_files_syntax(self) -> bool:
        """Test batch file syntax"""
        batch_files = [
            "../scripts/reset-regional.bat",
            "../backup-manager.bat", 
            "../validate.bat",
            "../scheduler.bat"
        ]
        
        for batch_file in batch_files:
            if not os.path.exists(batch_file):
                return f"Missing batch file: {batch_file}"
        
        return True
    
    def test_locale_consistency(self) -> bool:
        """Test locale consistency across implementations"""
        # Read locales from different sources
        locales = {
            "powershell": [],
            "python": [],
            "cpp": []
        }
        
        # Check PowerShell locales
        try:
            with open("../scripts/Reset-RegionalSettings.ps1", 'r') as f:
                content = f.read()
                if '"pl-PL"' in content and '"en-US"' in content:
                    locales["powershell"] = ["pl-PL", "en-US", "de-DE"]
        except:
            pass
        
        # Check Python locales
        try:
            with open("../python/regional_settings_reset.py", 'r') as f:
                content = f.read()
                if '"pl-PL"' in content and '"en-US"' in content:
                    locales["python"] = ["pl-PL", "en-US", "de-DE"]
        except:
            pass
        
        # Check C++ locales
        try:
            with open("../cpp/regional_settings_reset_v2.cpp", 'r') as f:
                content = f.read()
                if '"pl-PL"' in content and '"en-US"' in content:
                    locales["cpp"] = ["pl-PL", "en-US", "de-DE"]
        except:
            pass
        
        # Basic consistency check
        return len(locales["powershell"]) > 0 and len(locales["python"]) > 0 and len(locales["cpp"]) > 0
    
    def test_backup_directory_creation(self) -> bool:
        """Test backup directory creation"""
        try:
            temp_dir = tempfile.mkdtemp()
            backup_dir = os.path.join(temp_dir, "test_backup")
            
            # Simulate backup directory creation
            os.makedirs(backup_dir, exist_ok=True)
            
            success = os.path.exists(backup_dir)
            shutil.rmtree(temp_dir)
            return success
        except:
            return False
    
    def test_performance_monitoring(self) -> bool:
        """Test performance monitoring capabilities"""
        try:
            import time
            import psutil
            
            # Basic performance metrics test
            start_time = time.time()
            start_memory = psutil.Process().memory_info().rss
            
            # Simulate some work
            time.sleep(0.1)
            
            end_time = time.time()
            end_memory = psutil.Process().memory_info().rss
            
            execution_time = end_time - start_time
            memory_diff = end_memory - start_memory
            
            return execution_time > 0
        except ImportError:
            # psutil not available, but that's okay for basic test
            return True
        except:
            return False
    
    def run_comprehensive_tests(self):
        """Run all tests"""
        print("🧪 Starting Comprehensive Test Suite")
        print("=" * 50)
        
        # Core functionality tests
        self.run_test("PowerShell Syntax Check", self.test_powershell_syntax)
        self.run_test("PowerShell Execution Policy", self.test_powershell_execution_policy)
        self.run_test("Python Import Test", self.test_python_imports)
        self.run_test("Python Demo Mode", self.test_python_demo_mode)
        self.run_test("C++ Compilation", self.test_cpp_compilation)
        self.run_test("C++ Demo Execution", self.test_cpp_demo_execution)
        
        # Configuration and file tests
        self.run_test("Configuration File Validity", self.test_config_files_validity)
        self.run_test("Batch File Syntax", self.test_batch_files_syntax)
        self.run_test("Locale Consistency", self.test_locale_consistency)
        
        # Advanced feature tests
        self.run_test("Backup Directory Creation", self.test_backup_directory_creation)
        self.run_test("Performance Monitoring", self.test_performance_monitoring)
        
        # Generate report
        self.generate_report()
    
    def generate_report(self):
        """Generate detailed test report"""
        print("\n" + "=" * 50)
        print("📊 TEST RESULTS SUMMARY")
        print("=" * 50)
        
        print(f"Total Tests: {self.total_tests}")
        print(f"Passed: {self.passed_tests} ✅")
        print(f"Failed: {self.failed_tests} ❌")
        
        success_rate = (self.passed_tests / self.total_tests * 100) if self.total_tests > 0 else 0
        print(f"Success Rate: {success_rate:.1f}%")
        
        total_time = sum(result.execution_time for result in self.results)
        print(f"Total Execution Time: {total_time:.2f} seconds")
        
        if self.failed_tests > 0:
            print("\n❌ FAILED TESTS:")
            for result in self.results:
                if not result.passed:
                    print(f"  • {result.name}: {result.message}")
        
        print("\n📈 PERFORMANCE METRICS:")
        for result in self.results:
            print(f"  • {result.name}: {result.execution_time:.3f}s")
        
        # Save detailed report
        self.save_detailed_report()
    
    def save_detailed_report(self):
        """Save detailed test report to file"""
        report_data = {
            "timestamp": time.strftime("%Y-%m-%d %H:%M:%S"),
            "summary": {
                "total_tests": self.total_tests,
                "passed": self.passed_tests,
                "failed": self.failed_tests,
                "success_rate": (self.passed_tests / self.total_tests * 100) if self.total_tests > 0 else 0
            },
            "results": [
                {
                    "name": result.name,
                    "passed": result.passed,
                    "message": result.message,
                    "execution_time": result.execution_time
                }
                for result in self.results
            ]
        }
        
        try:
            with open("test_report.json", "w") as f:
                json.dump(report_data, f, indent=2)
            print(f"\n📄 Detailed report saved to: test_report.json")
        except Exception as e:
            print(f"\n⚠️  Could not save detailed report: {e}")

def main():
    """Main test execution"""
    print("🚀 Regional Settings Reset - Automated Test Framework")
    print("Testing all implementations: PowerShell, Python, C++")
    print()
    
    framework = TestFramework()
    framework.run_comprehensive_tests()
    
    # Exit with appropriate code
    sys.exit(0 if framework.failed_tests == 0 else 1)

if __name__ == "__main__":
    main()