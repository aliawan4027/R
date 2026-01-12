# Build SurveyStat Package for CRAN Submission
# Run this in R console after all checks pass

# Load devtools
if (!require("devtools", quietly = TRUE)) {
  install.packages("devtools")
}
library(devtools)

# Set working directory to package root
setwd(".")

cat("Building SurveyStat package...\n")

# Build source package
build_results <- build()

if (file.exists(build_results)) {
  cat("✅ Package built successfully!\n")
  cat("Package file:", build_results, "\n")
  cat("\nNext steps:\n")
  cat("1. Test the package: devtools::install()\n")
  cat("2. Upload to CRAN: https://cran.r-project.org/submit.html\n")
  cat("3. Wait for CRAN email confirmation\n")
} else {
  cat("❌ Package build failed\n")
}
