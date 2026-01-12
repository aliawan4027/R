#' Apply survey weights to data
#'
#' This function applies survey weights by creating a weighted version of the dataset.
#' The weights are normalized to sum to the sample size for computational stability.
#'
#' @param data A data.frame containing survey data
#' @param weight_col Character string specifying column name containing weights
#' @return A data.frame with normalized weights
#' @export
#' @examples
#' data <- data.frame(age = c(25, 30, 35), weight = c(1.2, 0.8, 1.0))
#' weighted_data <- apply_weights(data, "weight")
apply_weights <- function(data, weight_col) {
  # Input validation
  if (!is.data.frame(data)) {
    stop("Input must be a data.frame")
  }
  
  if (!weight_col %in% names(data)) {
    stop("Weight column '", weight_col, "' not found in data")
  }
  
  if (!is.numeric(data[[weight_col]])) {
    stop("Weight column must be numeric")
  }
  
  if (any(data[[weight_col]] <= 0, na.rm = TRUE)) {
    warning("Some weights are zero or negative. Consider checking your weights.")
  }
  
  # Make a copy to avoid modifying original data
  weighted_data <- data
  
  # Normalize weights to sum to sample size
  # This maintains the relative weight structure while improving numerical stability
  weight_sum <- sum(weighted_data[[weight_col]], na.rm = TRUE)
  if (weight_sum <= 0) {
    stop("Sum of weights must be positive")
  }
  
  normalized_weight <- weighted_data[[weight_col]] * nrow(weighted_data) / weight_sum
  weighted_data[[weight_col]] <- normalized_weight
  
  return(weighted_data)
}

#' Calculate weighted mean
#'
#' This function calculates the weighted mean of a numeric variable.
#' Uses standard weighted mean formula: sum(x * w) / sum(w)
#'
#' @param data A data.frame containing survey data
#' @param target_col Character string specifying column name for target variable
#' @param weight_col Character string specifying column name containing weights
#' @return Numeric weighted mean
#' @export
#' @importFrom stats complete.cases
#' @examples
#' data <- data.frame(income = c(50000, 75000, 100000), weight = c(1.2, 0.8, 1.0))
#' weighted_income <- weighted_mean(data, "income", "weight")
weighted_mean <- function(data, target_col, weight_col) {
  # Input validation
  if (!is.data.frame(data)) {
    stop("Input must be a data.frame")
  }
  
  if (!target_col %in% names(data)) {
    stop("Target column '", target_col, "' not found in data")
  }
  
  if (!weight_col %in% names(data)) {
    stop("Weight column '", weight_col, "' not found in data")
  }
  
  if (!is.numeric(data[[target_col]])) {
    stop("Target column must be numeric")
  }
  
  if (!is.numeric(data[[weight_col]])) {
    stop("Weight column must be numeric")
  }
  
  # Remove missing values
  complete_cases <- complete.cases(data[[target_col]], data[[weight_col]])
  if (sum(complete_cases) == 0) {
    stop("No complete cases for calculation")
  }
  
  x <- data[[target_col]][complete_cases]
  w <- data[[weight_col]][complete_cases]
  
  # Calculate weighted mean
  weighted_mean_value <- sum(x * w) / sum(w)
  
  return(weighted_mean_value)
}

#' Calculate weighted total
#'
#' This function calculates the weighted total of a numeric variable.
#' Useful for estimating population totals from survey data.
#'
#' @param data A data.frame containing survey data
#' @param target_col Character string specifying column name for target variable
#' @param weight_col Character string specifying column name containing weights
#' @return Numeric weighted total
#' @export
#' @importFrom stats complete.cases
#' @examples
#' data <- data.frame(income = c(50000, 75000, 100000), weight = c(1000, 800, 1200))
#' total_income <- weighted_total(data, "income", "weight")
weighted_total <- function(data, target_col, weight_col) {
  # Input validation
  if (!is.data.frame(data)) {
    stop("Input must be a data.frame")
  }
  
  if (!target_col %in% names(data)) {
    stop("Target column '", target_col, "' not found in data")
  }
  
  if (!weight_col %in% names(data)) {
    stop("Weight column '", weight_col, "' not found in data")
  }
  
  if (!is.numeric(data[[target_col]])) {
    stop("Target column must be numeric")
  }
  
  if (!is.numeric(data[[weight_col]])) {
    stop("Weight column must be numeric")
  }
  
  # Remove missing values
  complete_cases <- complete.cases(data[[target_col]], data[[weight_col]])
  if (sum(complete_cases) == 0) {
    stop("No complete cases for calculation")
  }
  
  x <- data[[target_col]][complete_cases]
  w <- data[[weight_col]][complete_cases]
  
  # Calculate weighted total
  weighted_total_value <- sum(x * w)
  
  return(weighted_total_value)
}

#' Rake survey weights to match population targets
#'
#' This function implements simple raking (iterative proportional fitting) to adjust
#' survey weights to match known population marginal totals. Assumes two-dimensional
#' raking for simplicity.
#'
#' @param data A data.frame containing survey data
#' @param population_targets Named list with population totals for each variable
#' @param weight_col Character string specifying initial weight column name
#' @return A data.frame with raked weights
#' @export
#' @examples
#' # Assuming we have gender and education population totals
#' targets <- list(
#'   gender = c(Male = 1000000, Female = 1050000),
#'   education = c(HighSchool = 800000, Bachelor = 900000, Graduate = 350000)
#' )
#' data <- data.frame(
#'   gender = c("Male", "Female", "Male", "Female", "Male"), 
#'   education = c("HighSchool", "Bachelor", "Bachelor", "HighSchool", "Graduate"),
#'   weight = c(1, 1, 1, 1, 1)
#' )
#' raked_data <- rake_weights(data, targets, "weight")
rake_weights <- function(data, population_targets, weight_col = "weight") {
  # Input validation
  if (!is.data.frame(data)) {
    stop("Input must be a data.frame")
  }
  
  if (!weight_col %in% names(data)) {
    stop("Weight column '", weight_col, "' not found in data")
  }
  
  if (!is.list(population_targets)) {
    stop("Population targets must be a named list")
  }
  
  # Make a copy to avoid modifying original data
  raked_data <- data
  
  # Initialize weights if not present
  if (!weight_col %in% names(raked_data)) {
    raked_data[[weight_col]] <- rep(1, nrow(raked_data))
  }
  
  # Get variable names for raking
  var_names <- names(population_targets)
  
  if (length(var_names) != 2) {
    stop("This implementation supports exactly 2 variables for raking")
  }
  
  if (!all(var_names %in% names(raked_data))) {
    stop("All target variables must be present in the data")
  }
  
  # Iterative raking algorithm
  max_iterations <- 50
  tolerance <- 1e-6
  
  for (iteration in 1:max_iterations) {
    old_weights <- raked_data[[weight_col]]
    
    # Rake on first variable
    var1 <- var_names[1]
    target1 <- population_targets[[var1]]
    
    # Calculate current weighted totals by category
    current_totals1 <- tapply(raked_data[[weight_col]], raked_data[[var1]], sum, na.rm = TRUE)
    
    # Calculate adjustment factors
    adjustment1 <- target1 / current_totals1
    adjustment1[is.infinite(adjustment1)] <- 1  # Handle missing categories
    adjustment1[is.na(adjustment1)] <- 1
    
    # Apply adjustments
    raked_data[[weight_col]] <- raked_data[[weight_col]] * adjustment1[as.character(raked_data[[var1]])]
    
    # Rake on second variable
    var2 <- var_names[2]
    target2 <- population_targets[[var2]]
    
    # Calculate current weighted totals by category
    current_totals2 <- tapply(raked_data[[weight_col]], raked_data[[var2]], sum, na.rm = TRUE)
    
    # Calculate adjustment factors
    adjustment2 <- target2 / current_totals2
    adjustment2[is.infinite(adjustment2)] <- 1  # Handle missing categories
    adjustment2[is.na(adjustment2)] <- 1
    
    # Apply adjustments
    raked_data[[weight_col]] <- raked_data[[weight_col]] * adjustment2[as.character(raked_data[[var2]])]
    
    # Check convergence
    weight_change <- max(abs(raked_data[[weight_col]] - old_weights) / old_weights, na.rm = TRUE)
    if (weight_change < tolerance) {
      break
    }
  }
  
  if (iteration == max_iterations) {
    warning("Raking did not converge after ", max_iterations, " iterations")
  }
  
  return(raked_data)
}
