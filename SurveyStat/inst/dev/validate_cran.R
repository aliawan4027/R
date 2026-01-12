# Comprehensive CRAN Validation Script
# Run this in R console before submission

# Load required packages
if (!require("devtools", quietly = TRUE)) install.packages("devtools")
if (!require("roxygen2", quietly = TRUE)) install.packages("roxygen2")
if (!require("lintr", quietly = TRUE)) install.packages("lintr")
if (!require("spell_check", quietly = TRUE)) install.packages("spell_check")

library(devtools)
library(roxygen2)
library(lintr)

cat("=== CRAN Validation for SurveyStat Package ===\n\n")

# 1. Check package structure
cat("1. Checking package structure...\n")
required_dirs <- c("R", "man", "DESCRIPTION", "NAMESPACE")
missing_dirs <- required_dirs[!file.exists(required_dirs)]
if (length(missing_dirs) > 0) {
  cat("❌ Missing required files/directories:", paste(missing_dirs, collapse = ", "), "\n")
} else {
  cat("✅ Package structure is complete\n")
}

# 2. Generate documentation
cat("\n2. Generating documentation...\n")
tryCatch({
  roxygenise()
  cat("✅ Documentation generated successfully\n")
}, error = function(e) {
  cat("❌ Documentation generation failed:", e$message, "\n")
})

# 3. Check DESCRIPTION file
cat("\n3. Checking DESCRIPTION file...\n")
desc <- read.dcf("DESCRIPTION")
title <- desc[1, "Title"]
if (nchar(title) > 65) {
  cat("❌ Title too long (", nchar(title), " characters, max 65)\n")
} else {
  cat("✅ Title length acceptable (", nchar(title), " characters)\n")
}

# 4. Check for common issues
cat("\n4. Checking for common CRAN issues...\n")

# Check for missing documentation
exported_functions <- c("apply_weights", "clean_missing", "describe_survey", 
                        "frequency_table", "plot_boxplot", "plot_histogram", 
                        "plot_weighted_bar", "rake_weights", "remove_duplicates", 
                        "standardize_categories", "weighted_mean", "weighted_total", 
                        "cross_tabulation")

missing_docs <- exported_functions[!file.exists(paste0("man/", exported_functions, ".Rd"))]
if (length(missing_docs) > 0) {
  cat("❌ Missing documentation for:", paste(missing_docs, collapse = ", "), "\n")
} else {
  cat("✅ All exported functions have documentation\n")
}

# 5. Run lintr
cat("\n5. Running code style checks...\n")
lint_results <- lint_package()
if (length(lint_results) > 0) {
  cat("❌ Found", length(lint_results), "linting issues:\n")
  print(lint_results[1:min(5, length(lint_results))])
  if (length(lint_results) > 5) cat("... and", length(lint_results) - 5, "more\n")
} else {
  cat("✅ No linting issues found\n")
}

# 6. Check for TODO/FIXME comments
cat("\n6. Checking for development comments...\n")
r_files <- list.files("R", pattern = "\\.R$", full.names = TRUE)
todo_comments <- c()
for (file in r_files) {
  content <- readLines(file, warn = FALSE)
  todo_lines <- grep("TODO|FIXME|XXX", content, ignore.case = TRUE)
  if (length(todo_lines) > 0) {
    todo_comments <- c(todo_comments, paste(basename(file), ":", paste(todo_lines, collapse = ", ")))
  }
}
if (length(todo_comments) > 0) {
  cat("❌ Found development comments:\n", paste(todo_comments, collapse = "\n"), "\n")
} else {
  cat("✅ No development comments found\n")
}

# 7. Final CRAN check
cat("\n7. Running final CRAN check...\n")
cat("Note: This will take several minutes...\n")
check_results <- check()

cat("\n=== FINAL RESULTS ===\n")
cat("Errors:", check_results$errors, "\n")
cat("Warnings:", check_results$warnings, "\n")
cat("Notes:", check_results$notes, "\n")

if (check_results$errors == 0 && check_results$warnings == 0) {
  cat("\n🎉 Package is ready for CRAN submission!\n")
  cat("Run devtools::build() to create the source package.\n")
} else {
  cat("\n⚠️  Please fix the above issues before submitting to CRAN.\n")
}
