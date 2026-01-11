library(testthat)
library(SurveyStat)

# Test Data Setup -------------------------------------------------------------
test_data <- data.frame(
  id = 1:10,
  age = c(25, 30, NA, 35, 40, 45, NA, 50, 55, 60),
  gender = c("M", "F", "M", "F", "M", "F", "M", "F", "M", "F"),
  income = c(50000, 60000, 70000, 80000, 90000, 100000, 110000, 120000, 130000, 140000),
  weight = c(1.0, 1.2, 0.8, 1.1, 0.9, 1.3, 0.7, 1.4, 0.6, 1.5)
)

# Test Data Cleaning Functions -------------------------------------------------

test_that("remove_duplicates works correctly", {
  # Create data with duplicates
  dup_data <- rbind(test_data, test_data[1:2, ])
  
  # Remove duplicates
  clean_data <- remove_duplicates(dup_data)
  
  # Check that duplicates are removed
  expect_equal(nrow(clean_data), nrow(test_data))
  expect_true(is.data.frame(clean_data))
})

test_that("clean_missing handles missing values correctly", {
  # Test mean imputation
  cleaned_mean <- clean_missing(test_data, "age", method = "mean")
  expect_false(any(is.na(cleaned_mean$age)))
  expect_equal(cleaned_mean$age[3], mean(test_data$age, na.rm = TRUE))
  
  # Test median imputation
  cleaned_median <- clean_missing(test_data, "age", method = "median")
  expect_equal(cleaned_median$age[3], median(test_data$age, na.rm = TRUE))
  
  # Test mode imputation for categorical variable
  cleaned_mode <- clean_missing(test_data, "gender", method = "mode")
  expect_true(is.data.frame(cleaned_mode))
  
  # Test error handling
  expect_error(clean_missing(test_data, "nonexistent_col", method = "mean"))
  expect_error(clean_missing("not_a_dataframe", "age", method = "mean"))
})

test_that("standardize_categories works correctly", {
  # Create data with inconsistent categories
  test_data_cat <- test_data
  test_data_cat$gender <- c("M", "Male", "F", "Female", "M", "Male", "F", "Female", "M", "Male")
  
  # Define mapping
  mapping <- list("M" = "Male", "Male" = "Male", "F" = "Female", "Female" = "Female")
  
  # Standardize
  standardized <- standardize_categories(test_data_cat, "gender", mapping)
  
  # Check that all categories are standardized
  expect_true(all(standardized$gender %in% c("Male", "Female")))
  expect_equal(length(unique(standardized$gender)), 2)
  
  # Test error handling
  expect_error(standardize_categories(test_data, "nonexistent_col", mapping))
  expect_error(standardize_categories("not_a_dataframe", "gender", mapping))
})

# Test Survey Weighting Functions ----------------------------------------------

test_that("apply_weights works correctly", {
  weighted_data <- apply_weights(test_data, "weight")
  
  # Check that weights are normalized
  expect_equal(sum(weighted_data$weight), nrow(weighted_data))
  expect_true(is.data.frame(weighted_data))
  
  # Test error handling
  expect_error(apply_weights(test_data, "nonexistent_col"))
  expect_error(apply_weights("not_a_dataframe", "weight"))
})

test_that("weighted_mean calculates correctly", {
  # Manual calculation for verification
  manual_weighted_mean <- sum(test_data$income * test_data$weight) / sum(test_data$weight)
  package_weighted_mean <- weighted_mean(test_data, "income", "weight")
  
  expect_equal(manual_weighted_mean, package_weighted_mean, tolerance = 1e-10)
  
  # Test with missing values
  test_data_na <- test_data
  test_data_na$income[3] <- NA
  weighted_mean_na <- weighted_mean(test_data_na, "income", "weight")
  
  # Should exclude missing values
  expect_equal(weighted_mean_na, 
               sum(test_data_na$income * test_data_na$weight, na.rm = TRUE) / 
               sum(test_data_na$weight, na.rm = TRUE))
  
  # Test error handling
  expect_error(weighted_mean(test_data, "nonexistent_col", "weight"))
  expect_error(weighted_mean("not_a_dataframe", "income", "weight"))
})

test_that("weighted_total calculates correctly", {
  # Manual calculation for verification
  manual_weighted_total <- sum(test_data$income * test_data$weight)
  package_weighted_total <- weighted_total(test_data, "income", "weight")
  
  expect_equal(manual_weighted_total, package_weighted_total, tolerance = 1e-10)
  
  # Test error handling
  expect_error(weighted_total(test_data, "nonexistent_col", "weight"))
  expect_error(weighted_total("not_a_dataframe", "income", "weight"))
})

test_that("rake_weights works correctly", {
  # Create population targets
  targets <- list(
    gender = c(Male = 100, Female = 150),
    age_group = c(Young = 80, Middle = 120, Old = 50)
  )
  
  # Create age groups
  test_data_rake <- test_data
  test_data_rake$age_group <- c(rep("Young", 3), rep("Middle", 4), rep("Old", 3))
  
  # Apply raking
  raked_data <- rake_weights(test_data_rake, targets, "weight")
  
  # Check that raked data has same structure
  expect_equal(nrow(raked_data), nrow(test_data_rake))
  expect_true("weight" %in% names(raked_data))
  
  # Test error handling
  expect_error(rake_weights(test_data, list(gender = c(Male = 100, Female = 100)), "weight"))
  expect_error(rake_weights("not_a_dataframe", targets, "weight"))
})

# Test Statistical Analysis Functions -----------------------------------------

test_that("describe_survey generates correct summary", {
  desc <- describe_survey(test_data, "weight")
  
  # Check structure
  expect_true(is.list(desc))
  expect_equal(desc$Sample_Size, nrow(test_data))
  expect_equal(desc$Number_Variables, ncol(test_data))
  expect_equal(desc$Weight_Column, "weight")
  expect_true(is.data.frame(desc$Variable_Summary))
  
  # Test without weights
  desc_unweighted <- describe_survey(test_data)
  expect_null(desc_unweighted$Weight_Column)
  
  # Test error handling
  expect_error(describe_survey("not_a_dataframe"))
  expect_error(describe_survey(test_data, "nonexistent_col"))
})

test_that("frequency_table works correctly", {
  freq_table <- frequency_table(test_data, "gender")
  
  # Check structure
  expect_true(is.data.frame(freq_table))
  expect_true("Category" %in% names(freq_table))
  expect_true("Frequency" %in% names(freq_table))
  expect_true("Percentage" %in% names(freq_table))
  
  # Check that percentages sum to 100
  expect_equal(sum(freq_table$Percentage), 100, tolerance = 0.01)
  
  # Test weighted frequency table
  freq_weighted <- frequency_table(test_data, "gender", "weight")
  expect_true("Weighted_Frequency" %in% names(freq_weighted))
  expect_true("Weighted_Percentage" %in% names(freq_weighted))
  
  # Test error handling
  expect_error(frequency_table(test_data, "nonexistent_col"))
  expect_error(frequency_table("not_a_dataframe", "gender"))
})

test_that("cross_tabulation works correctly", {
  # Create test data with categorical variables
  test_data_cross <- test_data
  test_data_cross$education <- sample(c("HS", "College", "Grad"), nrow(test_data), replace = TRUE)
  
  cross_tab <- cross_tabulation(test_data_cross, "gender", "education")
  
  # Check structure
  expect_true(is.list(cross_tab))
  expect_true(is.matrix(cross_tab$Cross_Table))
  expect_true(is.list(cross_tab$Chi_Square_Test))
  expect_true("Statistic" %in% names(cross_tab$Chi_Square_Test))
  expect_true("P_Value" %in% names(cross_tab$Chi_Square_Test))
  
  # Test weighted cross-tabulation
  cross_weighted <- cross_tabulation(test_data_cross, "gender", "education", "weight")
  expect_true(cross_weighted$Weighted)
  expect_true("Weighted_Cross_Table" %in% names(cross_weighted))
  
  # Test error handling
  expect_error(cross_tabulation(test_data, "nonexistent_col", "gender"))
  expect_error(cross_tabulation("not_a_dataframe", "gender", "education"))
})

# Test Visualization Functions --------------------------------------------------

test_that("plot_histogram returns ggplot object", {
  hist_plot <- plot_histogram(test_data, "age")
  
  expect_s3_class(hist_plot, "ggplot")
  
  # Test error handling
  expect_error(plot_histogram(test_data, "nonexistent_col"))
  expect_error(plot_histogram("not_a_dataframe", "age"))
})

test_that("plot_weighted_bar returns ggplot object", {
  bar_plot <- plot_weighted_bar(test_data, "gender")
  
  expect_s3_class(bar_plot, "ggplot")
  
  # Test weighted version
  bar_weighted <- plot_weighted_bar(test_data, "gender", "weight")
  expect_s3_class(bar_weighted, "ggplot")
  
  # Test error handling
  expect_error(plot_weighted_bar(test_data, "nonexistent_col"))
  expect_error(plot_weighted_bar("not_a_dataframe", "gender"))
})

test_that("plot_boxplot returns ggplot object", {
  box_plot <- plot_boxplot(test_data, "income")
  
  expect_s3_class(box_plot, "ggplot")
  
  # Test grouped version
  box_grouped <- plot_boxplot(test_data, "income", "gender")
  expect_s3_class(box_grouped, "ggplot")
  
  # Test error handling
  expect_error(plot_boxplot(test_data, "nonexistent_col"))
  expect_error(plot_boxplot("not_a_dataframe", "income"))
})

# Test Edge Cases and Error Handling -------------------------------------------

test_that("functions handle edge cases correctly", {
  # Test with empty data
  empty_data <- data.frame()
  
  # Test with single row
  single_row <- test_data[1, ]
  
  # Test with all missing values
  all_na <- test_data
  all_na$age[] <- NA
  
  # These should either work gracefully or give informative errors
  expect_error(remove_duplicates(empty_data))
  expect_error(clean_missing(all_na, "age", method = "mean"))
  
  # Single row should work for most functions
  expect_silent(remove_duplicates(single_row))
})

# Test Integration -------------------------------------------------------------

test_that("complete workflow works end-to-end", {
  # Start with raw data
  workflow_data <- test_data
  
  # Step 1: Remove duplicates
  workflow_data <- remove_duplicates(workflow_data)
  
  # Step 2: Clean missing values
  workflow_data <- clean_missing(workflow_data, "age", method = "mean")
  
  # Step 3: Apply weights
  workflow_data <- apply_weights(workflow_data, "weight")
  
  # Step 4: Generate statistics
  desc <- describe_survey(workflow_data, "weight")
  freq <- frequency_table(workflow_data, "gender", "weight")
  
  # Step 5: Create visualizations
  hist_plot <- plot_histogram(workflow_data, "age")
  bar_plot <- plot_weighted_bar(workflow_data, "gender", "weight")
  
  # Check that all steps completed successfully
  expect_true(is.data.frame(workflow_data))
  expect_true(is.list(desc))
  expect_true(is.data.frame(freq))
  expect_s3_class(hist_plot, "ggplot")
  expect_s3_class(bar_plot, "ggplot")
})
