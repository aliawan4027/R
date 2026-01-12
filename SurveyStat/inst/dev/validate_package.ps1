# PowerShell script to validate SurveyStat package structure
# This script checks if all required files and components are present

Write-Host "=== SurveyStat Package Validation ===" -ForegroundColor Green
Write-Host ""

# Check package structure
$packageDir = Get-Location
Write-Host "Package directory: $packageDir"
Write-Host ""

# Required files and directories
$requiredItems = @(
    "DESCRIPTION",
    "NAMESPACE", 
    "README.md",
    "R\cleaning.R",
    "R\weighting.R", 
    "R\analysis.R",
    "R\visualization.R",
    "data\example_survey.csv",
    "vignettes\SurveyStat_Reproducible.Rmd",
    "tests\testthat\test_core_functions.R"
)

Write-Host "Checking required files and directories..." -ForegroundColor Yellow
$allPresent = $true

foreach ($item in $requiredItems) {
    $path = Join-Path $packageDir $item
    if (Test-Path $path) {
        $size = if (Test-Path $path -PathType Leaf) { 
            (Get-Item $path).Length 
        } else { 
            "Directory" 
        }
        Write-Host "  ✓ $item ($size)" -ForegroundColor Green
    } else {
        Write-Host "  ✗ $item (MISSING)" -ForegroundColor Red
        $allPresent = $false
    }
}

Write-Host ""

# Check DESCRIPTION file content
Write-Host "Validating DESCRIPTION file..." -ForegroundColor Yellow
$descPath = Join-Path $packageDir "DESCRIPTION"
if (Test-Path $descPath) {
    $descContent = Get-Content $descPath
    $requiredFields = @("Package:", "Version:", "Title:", "Description:", "License:")
    
    foreach ($field in $requiredFields) {
        if ($descContent -match $field) {
            Write-Host "  ✓ $field found" -ForegroundColor Green
        } else {
            Write-Host "  ✗ $field missing" -ForegroundColor Red
            $allPresent = $false
        }
    }
}
Write-Host ""

# Check NAMESPACE file content
Write-Host "Validating NAMESPACE file..." -ForegroundColor Yellow
$nsPath = Join-Path $packageDir "NAMESPACE"
if (Test-Path $nsPath) {
    $nsContent = Get-Content $nsPath
    $exportCount = ($nsContent | Where-Object { $_ -match "^export" }).Count
    Write-Host "  ✓ $exportCount functions exported" -ForegroundColor Green
}
Write-Host ""

# Check R files for function definitions
Write-Host "Validating R files..." -ForegroundColor Yellow
$rFiles = @(
    @{File = "R\cleaning.R"; Functions = @("remove_duplicates", "clean_missing", "standardize_categories")},
    @{File = "R\weighting.R"; Functions = @("apply_weights", "weighted_mean", "weighted_total", "rake_weights")},
    @{File = "R\analysis.R"; Functions = @("describe_survey", "frequency_table", "cross_tabulation")},
    @{File = "R\visualization.R"; Functions = @("plot_histogram", "plot_weighted_bar", "plot_boxplot")}
)

foreach ($rFile in $rFiles) {
    $filePath = Join-Path $packageDir $rFile.File
    if (Test-Path $filePath) {
        $content = Get-Content $filePath
        Write-Host "  Checking $($rFile.File):" -ForegroundColor Cyan
        
        foreach ($func in $rFile.Functions) {
            if ($content -match $func) {
                Write-Host "    ✓ $func found" -ForegroundColor Green
            } else {
                Write-Host "    ✗ $func missing" -ForegroundColor Red
                $allPresent = $false
            }
        }
    }
}
Write-Host ""

# Check data file
Write-Host "Validating data file..." -ForegroundColor Yellow
$dataPath = Join-Path $packageDir "data\example_survey.csv"
if (Test-Path $dataPath) {
    $dataContent = Get-Content $dataPath
    $rowCount = $dataContent.Count - 1  # Subtract header
    $colCount = ($dataContent[0] -split ",").Count
    Write-Host "  ✓ $rowCount rows, $colCount columns" -ForegroundColor Green
    
    # Check for required columns
    $header = $dataContent[0]
    $requiredCols = @("Age", "Gender", "Education", "Income", "Weight")
    foreach ($col in $requiredCols) {
        if ($header -match $col) {
            Write-Host "    ✓ Column '$col' present" -ForegroundColor Green
        } else {
            Write-Host "    ✗ Column '$col' missing" -ForegroundColor Red
            $allPresent = $false
        }
    }
}
Write-Host ""

# Check vignette file
Write-Host "Validating vignette..." -ForegroundColor Yellow
$vignettePath = Join-Path $packageDir "vignettes\SurveyStat_Reproducible.Rmd"
if (Test-Path $vignettePath) {
    $vignetteContent = Get-Content $vignettePath
    $requiredSections = @("```{r setup", "Loading Data and Package", "Data Cleaning", 
                          "Survey Weighting", "Statistical Analysis", "Visualization")
    
    foreach ($section in $requiredSections) {
        if ($vignetteContent -match [regex]::Escape($section)) {
            Write-Host "    ✓ '$section' section found" -ForegroundColor Green
        } else {
            Write-Host "    ✗ '$section' section missing" -ForegroundColor Red
            $allPresent = $false
        }
    }
}
Write-Host ""

# Check test file
Write-Host "Validating test file..." -ForegroundColor Yellow
$testPath = Join-Path $packageDir "tests\testthat\test_core_functions.R"
if (Test-Path $testPath) {
    $testContent = Get-Content $testPath
    $testCount = ($testContent | Where-Object { $_ -match "test_that" }).Count
    Write-Host "  ✓ $testCount tests defined" -ForegroundColor Green
}
Write-Host ""

# Final summary
Write-Host "=== Validation Summary ===" -ForegroundColor Green
if ($allPresent) {
    Write-Host "✓ All package components are present and correctly structured!" -ForegroundColor Green
    Write-Host "✓ Package is ready for R installation and testing." -ForegroundColor Green
    Write-Host ""
    Write-Host "To install and test the package:" -ForegroundColor Yellow
    Write-Host "1. Install R (if not already installed)" -ForegroundColor White
    Write-Host "2. In R, run: devtools::install('.')" -ForegroundColor White
    Write-Host "3. Run: testthat::test_package('SurveyStat')" -ForegroundColor White
    Write-Host "4. Run: vignette('SurveyStat_Reproducible')" -ForegroundColor White
} else {
    Write-Host "✗ Some components are missing or incorrect." -ForegroundColor Red
    Write-Host "Please review the errors above and fix them before proceeding." -ForegroundColor Red
}

Write-Host ""
Write-Host "Package validation completed." -ForegroundColor Green
