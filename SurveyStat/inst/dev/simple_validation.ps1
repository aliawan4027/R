Write-Host "=== SurveyStat Package Validation ===" -ForegroundColor Green
Write-Host ""

$packageDir = "c:\Users\HP Computers\OneDrive\Desktop\publication\SurveyStat"
Write-Host "Package directory: $packageDir"
Write-Host ""

# Check if package directory exists
if (Test-Path $packageDir) {
    Write-Host "Package directory exists" -ForegroundColor Green
} else {
    Write-Host "Package directory missing" -ForegroundColor Red
    exit
}

# Check required files
$requiredFiles = @(
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

Write-Host "Checking required files..." -ForegroundColor Yellow
$allPresent = $true

foreach ($file in $requiredFiles) {
    $path = Join-Path $packageDir $file
    if (Test-Path $path) {
        $item = Get-Item $path
        if ($item.PSIsContainer) {
            Write-Host "  ✓ $file (Directory)" -ForegroundColor Green
        } else {
            Write-Host "  ✓ $file ($($item.Length) bytes)" -ForegroundColor Green
        }
    } else {
        Write-Host "  ✗ $file (MISSING)" -ForegroundColor Red
        $allPresent = $false
    }
}

Write-Host ""

# Check DESCRIPTION file
$descPath = Join-Path $packageDir "DESCRIPTION"
if (Test-Path $descPath) {
    Write-Host "DESCRIPTION file validation:" -ForegroundColor Yellow
    $content = Get-Content $descPath
    if ($content -match "Package: SurveyStat") { Write-Host "  ✓ Package name correct" -ForegroundColor Green }
    if ($content -match "Version:") { Write-Host "  ✓ Version specified" -ForegroundColor Green }
    if ($content -match "License:") { Write-Host "  ✓ License specified" -ForegroundColor Green }
}

Write-Host ""

# Check data file
$dataPath = Join-Path $packageDir "data\example_survey.csv"
if (Test-Path $dataPath) {
    Write-Host "Data file validation:" -ForegroundColor Yellow
    $lines = Get-Content $dataPath
    $rowCount = $lines.Count - 1
    Write-Host "  ✓ $rowCount data rows" -ForegroundColor Green
    
    $header = $lines[0]
    if ($header -match "Age") { Write-Host "  ✓ Age column present" -ForegroundColor Green }
    if ($header -match "Gender") { Write-Host "  ✓ Gender column present" -ForegroundColor Green }
    if ($header -match "Income") { Write-Host "  ✓ Income column present" -ForegroundColor Green }
    if ($header -match "Weight") { Write-Host "  ✓ Weight column present" -ForegroundColor Green }
}

Write-Host ""

# Check R files
Write-Host "R files validation:" -ForegroundColor Yellow
$rFiles = @{
    "R\cleaning.R" = @("remove_duplicates", "clean_missing", "standardize_categories")
    "R\weighting.R" = @("apply_weights", "weighted_mean", "weighted_total", "rake_weights")
    "R\analysis.R" = @("describe_survey", "frequency_table", "cross_tabulation")
    "R\visualization.R" = @("plot_histogram", "plot_weighted_bar", "plot_boxplot")
}

foreach ($file in $rFiles.Keys) {
    $path = Join-Path $packageDir $file
    if (Test-Path $path) {
        Write-Host "  Checking $file:" -ForegroundColor Cyan
        $content = Get-Content $path
        foreach ($func in $rFiles[$file]) {
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

# Summary
Write-Host "=== Validation Summary ===" -ForegroundColor Green
if ($allPresent) {
    Write-Host "SUCCESS: All package components are present!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Package is ready for installation and testing." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor White
    Write-Host "1. Install R and RStudio" -ForegroundColor White
    Write-Host "2. Install required packages: dplyr, ggplot2, testthat, knitr, rmarkdown" -ForegroundColor White
    Write-Host "3. In R, navigate to package directory and run:" -ForegroundColor White
    Write-Host "   devtools::install('.')" -ForegroundColor White
    Write-Host "4. Test the package:" -ForegroundColor White
    Write-Host "   library(SurveyStat)" -ForegroundColor White
    Write-Host "   testthat::test_package('SurveyStat')" -ForegroundColor White
    Write-Host "5. Run the vignette:" -ForegroundColor White
    Write-Host "   vignette('SurveyStat_Reproducible')" -ForegroundColor White
} else {
    Write-Host "ERROR: Some components are missing!" -ForegroundColor Red
}

Write-Host ""
Write-Host "Validation completed." -ForegroundColor Green
