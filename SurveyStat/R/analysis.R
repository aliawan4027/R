#' Generate comprehensive survey description
#'
#' This function provides a comprehensive description of survey data including
#' sample size, variable types, missing value patterns, and basic statistics.
#' Can incorporate survey weights if provided.
#'
#' @param data A data.frame containing survey data
#' @param weight_col Character string specifying column name containing weights (optional)
#' @return A list containing descriptive statistics
#' @export
#' @importFrom stats median sd complete.cases
#' @examples
#' data <- data.frame(
#'   age = c(25, 30, 35),
#'   gender = c("M", "F", "M"),
#'   weight = c(1.2, 0.8, 1.0)
#' )
#' desc <- describe_survey(data)
#' desc_weighted <- describe_survey(data, "weight")
describe_survey <- function(data, weight_col = NULL) {
  # Input validation
  if (!is.data.frame(data)) {
    stop("Input must be a data.frame")
  }
  
  if (!is.null(weight_col) && !weight_col %in% names(data)) {
    stop("Weight column '", weight_col, "' not found in data")
  }
  
  # Basic information
  n_obs <- nrow(data)
  n_vars <- ncol(data)
  
  # Variable types
  var_types <- sapply(data, function(x) class(x)[1])
  var_summary <- data.frame(
    Variable = names(data),
    Type = var_types,
    Missing = sapply(data, function(x) sum(is.na(x))),
    Missing_Percent = round(sapply(data, function(x) mean(is.na(x))) * 100, 2)
  )
  
  # Numeric variable statistics
  numeric_vars <- names(data)[sapply(data, is.numeric)]
  numeric_stats <- NULL
  
  if (length(numeric_vars) > 0) {
    numeric_stats <- data.frame(
      Variable = numeric_vars,
      Mean = sapply(data[numeric_vars], function(x) mean(x, na.rm = TRUE)),
      SD = sapply(data[numeric_vars], function(x) sd(x, na.rm = TRUE)),
      Min = sapply(data[numeric_vars], function(x) min(x, na.rm = TRUE)),
      Max = sapply(data[numeric_vars], function(x) max(x, na.rm = TRUE)),
      Median = sapply(data[numeric_vars], function(x) median(x, na.rm = TRUE))
    )
    
    # Add weighted statistics if weights provided
    if (!is.null(weight_col)) {
      numeric_stats$Weighted_Mean <- sapply(numeric_vars, function(var) {
        weighted_mean(data, var, weight_col)
      })
    }
  }
  
  # Categorical variable statistics
  categorical_vars <- names(data)[!sapply(data, is.numeric)]
  categorical_stats <- NULL
  
  if (length(categorical_vars) > 0) {
    categorical_stats <- lapply(categorical_vars, function(var) {
      freq_table <- table(data[[var]], useNA = "no")
      prop_table <- prop.table(freq_table)
      
      result <- data.frame(
        Category = names(freq_table),
        Frequency = as.numeric(freq_table),
        Percentage = round(as.numeric(prop_table) * 100, 2)
      )
      
      # Add weighted frequencies if weights provided
      if (!is.null(weight_col)) {
        weighted_freq <- tapply(data[[weight_col]], data[[var]], sum, na.rm = TRUE)
        weighted_prop <- weighted_freq / sum(weighted_freq, na.rm = TRUE)
        
        result$Weighted_Frequency <- weighted_freq[as.character(result$Category)]
        result$Weighted_Percentage <- round(weighted_prop[as.character(result$Category)] * 100, 2)
      }
      
      return(result)
    })
    names(categorical_stats) <- categorical_vars
  }
  
  # Compile results
  result <- list(
    Sample_Size = n_obs,
    Number_Variables = n_vars,
    Weight_Column = weight_col,
    Variable_Summary = var_summary,
    Numeric_Statistics = numeric_stats,
    Categorical_Statistics = categorical_stats
  )
  
  return(result)
}

#' Generate frequency table for categorical variable
#'
#' This function creates a frequency table for a categorical variable,
#' optionally incorporating survey weights.
#'
#' @param data A data.frame containing survey data
#' @param col Character string specifying column name for categorical variable
#' @param weight_col Character string specifying column name containing weights (optional)
#' @return A data.frame with frequency statistics
#' @export
#' @examples
#' data <- data.frame(gender = c("M", "F", "M", "F"), weight = c(1, 1.2, 0.8, 1.1))
#' freq_table <- frequency_table(data, "gender")
#' weighted_freq <- frequency_table(data, "gender", "weight")
frequency_table <- function(data, col, weight_col = NULL) {
  # Input validation
  if (!is.data.frame(data)) {
    stop("Input must be a data.frame")
  }
  
  if (!col %in% names(data)) {
    stop("Column '", col, "' not found in data")
  }
  
  if (!is.null(weight_col) && !weight_col %in% names(data)) {
    stop("Weight column '", weight_col, "' not found in data")
  }
  
  # Remove missing values
  complete_data <- data[!is.na(data[[col]]), ]
  
  if (nrow(complete_data) == 0) {
    stop("No non-missing values for column '", col, "'")
  }
  
  # Calculate unweighted frequencies
  freq_table <- table(complete_data[[col]])
  prop_table <- prop.table(freq_table)
  
  result <- data.frame(
    Category = names(freq_table),
    Frequency = as.numeric(freq_table),
    Percentage = round(as.numeric(prop_table) * 100, 2),
    stringsAsFactors = FALSE
  )
  
  # Add weighted frequencies if weights provided
  if (!is.null(weight_col)) {
    weighted_freq <- tapply(complete_data[[weight_col]], complete_data[[col]], sum, na.rm = TRUE)
    weighted_prop <- weighted_freq / sum(weighted_freq, na.rm = TRUE)
    
    result$Weighted_Frequency <- weighted_freq[as.character(result$Category)]
    result$Weighted_Percentage <- round(weighted_prop[as.character(result$Category)] * 100, 2)
  }
  
  return(result)
}

#' Generate cross-tabulation table with chi-square test
#'
#' This function creates a cross-tabulation between two categorical variables
#' and performs a chi-square test of independence. Can incorporate survey weights.
#'
#' @param data A data.frame containing survey data
#' @param col1 Character string specifying first categorical variable
#' @param col2 Character string specifying second categorical variable
#' @param weight_col Character string specifying column name containing weights (optional)
#' @return A list containing cross-tabulation and chi-square test results
#' @export
#' @importFrom stats chisq.test complete.cases
#' @examples
#' data <- data.frame(gender = c("M", "F", "M", "F"), 
#'                    education = c("HS", "College", "HS", "College"))
#' cross_tab <- cross_tabulation(data, "gender", "education")
cross_tabulation <- function(data, col1, col2, weight_col = NULL) {
  # Input validation
  if (!is.data.frame(data)) {
    stop("Input must be a data.frame")
  }
  
  if (!col1 %in% names(data)) {
    stop("Column '", col1, "' not found in data")
  }
  
  if (!col2 %in% names(data)) {
    stop("Column '", col2, "' not found in data")
  }
  
  if (!is.null(weight_col) && !weight_col %in% names(data)) {
    stop("Weight column '", weight_col, "' not found in data")
  }
  
  # Remove missing values
  complete_data <- data[complete.cases(data[[col1]], data[[col2]]), ]
  
  if (nrow(complete_data) == 0) {
    stop("No complete cases for cross-tabulation")
  }
  
  # Create cross-tabulation table
  cross_table <- table(complete_data[[col1]], complete_data[[col2]])
  
  # Calculate row and column percentages
  row_percent <- round(prop.table(cross_table, 1) * 100, 2)
  col_percent <- round(prop.table(cross_table, 2) * 100, 2)
  
  # Perform chi-square test (unweighted)
  chi_test <- chisq.test(cross_table)
  
  # Compile unweighted results
  result <- list(
    Cross_Table = cross_table,
    Row_Percentages = row_percent,
    Column_Percentages = col_percent,
    Chi_Square_Test = list(
      Statistic = chi_test$statistic,
      DF = chi_test$parameter,
      P_Value = chi_test$p.value,
      Method = chi_test$method
    ),
    Weighted = FALSE
  )
  
  # Add weighted results if weights provided
  if (!is.null(weight_col)) {
    # Create weighted cross-tabulation
    weighted_table <- tapply(complete_data[[weight_col]], 
                           list(complete_data[[col1]], complete_data[[col2]]), 
                           sum, na.rm = TRUE)
    
    # Calculate weighted percentages
    weighted_row_percent <- round(prop.table(weighted_table, 1) * 100, 2)
    weighted_col_percent <- round(prop.table(weighted_table, 2) * 100, 2)
    
    # Note: Chi-square test with weights is more complex and requires specialized methods
    # For simplicity, we provide the weighted frequencies but not a weighted chi-square test
    
    result$Weighted_Cross_Table <- weighted_table
    result$Weighted_Row_Percentages <- weighted_row_percent
    result$Weighted_Column_Percentages <- weighted_col_percent
    result$Weighted <- TRUE
    
    warning("Weighted chi-square test not implemented. Use specialized survey packages for weighted tests.")
  }
  
  return(result)
}
