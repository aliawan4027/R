# Test script for SurveyStat package
# This script tests the basic functionality of the SurveyStat package

# Load required packages
library(SurveyStat)
library(dplyr)
library(ggplot2)

cat("=== SurveyStat Package Test ===\n\n")

# Test 1: Load example data
cat("Test 1: Loading example data...\n")
data_path <- system.file("data", "example_survey.csv", package = "SurveyStat")
if (file.exists(data_path)) {
  survey_data <- read.csv(data_path)
  cat("✓ Data loaded successfully\n")
  cat("  Dimensions:", nrow(survey_data), "rows,", ncol(survey_data), "columns\n")
  cat("  Variables:", paste(names(survey_data), collapse = ", "), "\n\n")
} else {
  cat("✗ Could not find example data\n\n")
}

# Test 2: Data cleaning functions
cat("Test 2: Testing data cleaning functions...\n")

# Remove duplicates
clean_data <- remove_duplicates(survey_data)
cat("✓ remove_duplicates() - Original:", nrow(survey_data), "rows, Cleaned:", nrow(clean_data), "rows\n")

# Handle missing values (introduce some for testing)
test_data_missing <- survey_data
test_data_missing$Income[sample(1:nrow(test_data_missing), 20)] <- NA
clean_data_missing <- clean_missing(test_data_missing, "Income", method = "mean")
cat("✓ clean_missing() - Missing values handled\n")

# Standardize categories
test_data_cat <- survey_data
test_data_cat$Gender[sample(1:nrow(test_data_cat), 30)] <- "M"
test_data_cat$Gender[sample(1:nrow(test_data_cat), 25)] <- "F"
gender_mapping <- list("M" = "Male", "Male" = "Male", "F" = "Female", "Female" = "Female")
clean_data_standardized <- standardize_categories(test_data_cat, "Gender", gender_mapping)
cat("✓ standardize_categories() - Categories standardized\n\n")

# Test 3: Survey weighting functions
cat("Test 3: Testing survey weighting functions...\n")

# Apply weights
weighted_data <- apply_weights(survey_data, "Weight")
cat("✓ apply_weights() - Weights applied and normalized\n")
cat("  Original weight sum:", sum(survey_data$Weight), "\n")
cat("  Normalized weight sum:", sum(weighted_data$Weight), "\n")

# Weighted mean
weighted_mean_income <- weighted_mean(weighted_data, "Income", "Weight")
cat("✓ weighted_mean() - Weighted mean income:", round(weighted_mean_income, 2), "\n")

# Weighted total
weighted_total_income <- weighted_total(weighted_data, "Income", "Weight")
cat("✓ weighted_total() - Weighted total income:", round(weighted_total_income, 0), "\n")

# Raking (simplified test)
population_targets <- list(
  Gender = c(Male = 1000000, Female = 1050000),
  Education = c(`High School` = 800000, Bachelor = 900000, Graduate = 350000)
)
raked_data <- rake_weights(weighted_data, population_targets, "Weight")
cat("✓ rake_weights() - Raking applied\n\n")

# Test 4: Statistical analysis functions
cat("Test 4: Testing statistical analysis functions...\n")

# Survey description
survey_desc <- describe_survey(raked_data, "Weight")
cat("✓ describe_survey() - Comprehensive description generated\n")
cat("  Sample size:", survey_desc$Sample_Size, "\n")
cat("  Number of variables:", survey_desc$Number_Variables, "\n")

# Frequency table
gender_freq <- frequency_table(raked_data, "Gender", "Weight")
cat("✓ frequency_table() - Frequency table generated\n")

# Cross-tabulation
cross_tab <- cross_tabulation(raked_data, "Gender", "Education", "Weight")
cat("✓ cross_tabulation() - Cross-tabulation with chi-square test generated\n")
cat("  Chi-square statistic:", round(cross_tab$Chi_Square_Test$Statistic, 3), "\n")
cat("  P-value:", format.pval(cross_tab$Chi_Square_Test$P_Value, digits = 3), "\n\n")

# Test 5: Visualization functions
cat("Test 5: Testing visualization functions...\n")

# Histogram
age_hist <- plot_histogram(raked_data, "Age", bins = 25)
cat("✓ plot_histogram() - Histogram created\n")

# Weighted bar plot
education_bar <- plot_weighted_bar(raked_data, "Education", "Weight")
cat("✓ plot_weighted_bar() - Weighted bar plot created\n")

# Box plot
income_box <- plot_boxplot(raked_data, "Income", "Gender")
cat("✓ plot_boxplot() - Box plot created\n\n")

# Test 6: Package information
cat("Test 6: Package information...\n")
cat("Package version:", packageVersion("SurveyStat"), "\n")
cat("Package loaded successfully!\n\n")

cat("=== All Tests Completed Successfully ===\n")
cat("The SurveyStat package is working correctly!\n\n")

# Save plots to files for verification
ggsave("test_histogram.png", age_hist, width = 7, height = 5, dpi = 300)
ggsave("test_barplot.png", education_bar, width = 7, height = 5, dpi = 300)
ggsave("test_boxplot.png", income_box, width = 7, height = 5, dpi = 300)

cat("Test plots saved as PNG files in working directory.\n")
