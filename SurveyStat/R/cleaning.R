#' Remove duplicate rows from survey data
#'
#' This function identifies and removes duplicate rows based on all columns.
#' Preserves the first occurrence of each duplicate.
#'
#' @param data A data.frame containing survey data
#' @return A data.frame with duplicates removed
#' @export
#' @examples
#' data <- data.frame(id = c(1, 2, 2, 3), age = c(25, 30, 30, 35))
#' clean_data <- remove_duplicates(data)
remove_duplicates <- function(data) {
  # Input validation
  if (!is.data.frame(data)) {
    stop("Input must be a data.frame")
  }
  
  # Remove duplicates, keeping first occurrence
  clean_data <- unique(data)
  
  # Return cleaned data
  return(clean_data)
}

#' Clean missing values in specified column
#'
#' This function handles missing values using specified imputation method.
#' Supports mean, median, and mode imputation for numeric variables.
#'
#' @param data A data.frame containing survey data
#' @param col Character string specifying column name to clean
#' @param method Character string specifying imputation method ("mean", "median", or "mode")
#' @return A data.frame with missing values imputed
#' @export
#' @examples
#' data <- data.frame(age = c(25, NA, 30, NA, 35))
#' clean_data <- clean_missing(data, "age", method = "mean")
clean_missing <- function(data, col, method = c("mean", "median", "mode")) {
  # Input validation
  if (!is.data.frame(data)) {
    stop("Input must be a data.frame")
  }
  
  if (!col %in% names(data)) {
    stop("Column '", col, "' not found in data")
  }
  
  method <- match.arg(method)
  
  # Make a copy to avoid modifying original data
  clean_data <- data
  
  # Check if column is numeric for mean/median methods
  if (method %in% c("mean", "median") && !is.numeric(clean_data[[col]])) {
    stop("Mean and median imputation only work with numeric variables")
  }
  
  # Calculate imputation value
  if (method == "mean") {
    impute_value <- mean(clean_data[[col]], na.rm = TRUE)
  } else if (method == "median") {
    impute_value <- median(clean_data[[col]], na.rm = TRUE)
  } else if (method == "mode") {
    # Calculate mode for any type of variable
    freq_table <- table(clean_data[[col]], useNA = "no")
    impute_value <- names(freq_table)[which.max(freq_table)]
  }
  
  # Impute missing values
  clean_data[[col]][is.na(clean_data[[col]])] <- impute_value
  
  return(clean_data)
}

#' Standardize categorical values
#'
#' This function standardizes categorical variables by mapping values to standardized categories.
#' Useful for consolidating different representations of the same category.
#'
#' @param data A data.frame containing survey data
#' @param col Character string specifying column name to standardize
#' @param mapping Named list or vector mapping old values to new values
#' @return A data.frame with standardized categories
#' @export
#' @examples
#' data <- data.frame(gender = c("M", "Male", "F", "Female", "m"))
#' mapping <- list("M" = "Male", "Male" = "Male", "F" = "Female", "Female" = "Female", "m" = "Male")
#' clean_data <- standardize_categories(data, "gender", mapping)
standardize_categories <- function(data, col, mapping) {
  # Input validation
  if (!is.data.frame(data)) {
    stop("Input must be a data.frame")
  }
  
  if (!col %in% names(data)) {
    stop("Column '", col, "' not found in data")
  }
  
  if (!is.list(mapping) && !is.vector(mapping)) {
    stop("Mapping must be a named list or vector")
  }
  
  # Make a copy to avoid modifying original data
  clean_data <- data
  
  # Apply standardization
  clean_data[[col]] <- mapping[as.character(clean_data[[col]])]
  
  # Handle unmapped values (keep original)
  unmapped <- is.na(clean_data[[col]])
  clean_data[[col]][unmapped] <- as.character(data[[col]])[unmapped]
  
  return(clean_data)
}
