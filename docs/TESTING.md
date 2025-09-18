# GitHub Actions Testing Guide

This document provides information about the automated testing infrastructure for the Windows Regional Settings Reset Toolkit.

## 🔄 Automated Workflows

### 1. PowerShell Windows Tests
**File**: `.github/workflows/powershell-windows-tests.yml`
**Triggers**: 
- Push to `main` or `develop` branches
- Pull requests to `main` or `develop` branches 
- Manual workflow dispatch with customizable parameters

**Test Matrix**:
- **Locales**: en-US, en-GB, de-DE, pl-PL
- **Profiles**: Standard, Corporate
- **Windows Version**: Latest

**Test Jobs**:
1. **Syntax Validation** - PowerShell script and module syntax checking
2. **Static Analysis** - PSScriptAnalyzer code quality analysis  
3. **Dry Run Tests** - Script execution testing with WhatIf parameter
4. **Module Tests** - PowerShell module import and functionality testing
5. **Configuration Tests** - JSON configuration file validation
6. **Comprehensive Tests** - Performance baseline and Python framework integration

### 2. Cross-Platform PowerShell Tests
**File**: `.github/workflows/cross-platform-powershell-tests.yml`
**Triggers**:
- Weekly schedule (Sundays at 2 AM UTC)
- Manual workflow dispatch with custom Windows/PowerShell versions

**Test Matrix**:
- **Windows Versions**: Windows Latest, 2019, 2022
- **PowerShell Versions**: 5.1 (Windows PowerShell), 7.x (PowerShell Core)
- **Compatibility Testing**: Cross-version PowerShell compatibility

## 🧪 Local Testing

### PowerShell Syntax Validation
Run the local syntax validation script before committing:

```powershell
# Basic syntax check
.\tests\Test-PowerShellSyntax.ps1

# Detailed output with token counts
.\tests\Test-PowerShellSyntax.ps1 -ShowDetails

# Return results as object for scripting
$results = .\tests\Test-PowerShellSyntax.ps1 -PassThru
```

### Python Test Framework
Run the comprehensive test suite:

```bash
cd tests
python test_framework.py --quick
python test_framework.py --enterprise --coverage --performance
```

## 📊 Test Coverage

### Files Tested
- **Scripts**: `scripts/Reset-RegionalSettings.ps1`, `group-policy/Deploy-RegionalSettings-GP.ps1`
- **Modules**: `modules/BackupCompression.psm1`, `modules/IncrementalBackup.psm1`
- **Configuration**: `config/config.json`, `config/config-gp-template.json`

### Test Types
- **Syntax Validation**: PowerShell parser validation
- **Static Analysis**: PSScriptAnalyzer code quality checks
- **Functional Testing**: Dry-run execution with multiple locales
- **Module Testing**: Import/export functionality validation
- **Configuration Testing**: JSON schema and structure validation
- **Performance Testing**: Baseline performance measurements

## 🚀 Continuous Integration

### Badge Status
The repository includes status badges for:
- **PowerShell Tests**: [![PowerShell Tests](https://github.com/jomardyan/win-reginnal-reset/actions/workflows/powershell-windows-tests.yml/badge.svg)](https://github.com/jomardyan/win-reginnal-reset/actions/workflows/powershell-windows-tests.yml)
- **Cross-Platform Tests**: [![Cross-Platform Tests](https://github.com/jomardyan/win-reginnal-reset/actions/workflows/cross-platform-powershell-tests.yml/badge.svg)](https://github.com/jomardyan/win-reginnal-reset/actions/workflows/cross-platform-powershell-tests.yml)

### Quality Gates
All tests must pass before merging:
- Syntax validation: 100% success rate required
- Static analysis: No critical issues allowed
- Dry run tests: All locale/profile combinations must succeed
- Module tests: All modules must import successfully
- Configuration tests: All JSON files must be valid

## 🔧 Troubleshooting

### Common Issues

#### PowerShell Execution Policy
The workflows automatically handle execution policy issues, but for local testing:
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

#### Parse Errors
If syntax validation fails:
1. Check the detailed error output
2. Verify PowerShell syntax using VS Code or PowerShell ISE
3. Run `.\tests\Test-PowerShellSyntax.ps1 -ShowDetails` for detailed analysis

#### Module Import Failures
For module testing issues:
1. Verify module structure and exports
2. Check for parameter conflicts or naming issues
3. Test manual import: `Import-Module .\modules\ModuleName.psm1 -Force`

### GitHub Actions Debugging
- Check the Actions tab for detailed logs
- Failed jobs provide step-by-step error information
- Use workflow dispatch for manual testing with custom parameters

## 📈 Performance Metrics

### Benchmarks
- **Script Loading**: < 5 seconds (Windows PowerShell), < 3 seconds (PowerShell 7)
- **Dry Run Execution**: < 30 seconds
- **Module Import**: < 2 seconds per module
- **Syntax Validation**: < 10 seconds for all files

### Success Targets
- **Overall Success Rate**: 99.9%
- **Syntax Validation**: 100%
- **Module Import Success**: 100%
- **Configuration Validity**: 100%

## 🔄 Workflow Customization

### Manual Workflow Dispatch
You can trigger workflows manually with custom parameters:

1. Go to the Actions tab in GitHub
2. Select the workflow to run
3. Click "Run workflow"
4. Customize parameters as needed:
   - Test level (quick, standard, comprehensive)
   - Target locale for testing
   - Windows versions (for cross-platform tests)
   - PowerShell versions (for cross-platform tests)

### Adding New Tests
To add new test scenarios:

1. **Update GitHub Actions workflows**: Modify the YAML files in `.github/workflows/`
2. **Update local test script**: Add new validations to `tests/Test-PowerShellSyntax.ps1`
3. **Update Python test framework**: Add new tests to `tests/test_framework.py`
4. **Update documentation**: Document new test types and coverage

This testing infrastructure ensures the Windows Regional Settings Reset Toolkit maintains high quality and reliability across different environments and use cases.