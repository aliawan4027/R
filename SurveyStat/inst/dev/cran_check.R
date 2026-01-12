# CRAN Check Script for SurveyStat Package
# Run this in R console to perform CRAN checks

# Install required packages if not already installed
if (!require("devtools", quietly = TRUE)) {
  install.packages("devtools")
}
if (!require("roxygen2", quietly = TRUE)) {
  install.packages("roxygen2")
}

# Load packages
library(devtools)
library(roxygen2)

# Set working directory to package root
setwd(".")

# Step 1: Generate documentation
cat("Generating documentation...\n")
roxygenise()

# Step 2: Run CRAN checks
cat("Running CRAN checks...\n")
check_results <- check()

# Step 3: Display results
cat("\n=== CRAN Check Results ===\n")
print(check_results)

# Step 4: Build source package if checks pass
if (check_results$errors == 0 && check_results$warnings == 0) {
  cat("\nBuilding source package...\n")
  build()
  cat("Package built successfully!\n")
} else {
  cat("\nPlease fix errors and warnings before building.\n")
}
