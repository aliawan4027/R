#' Declare global variables to suppress NOTES in CRAN checks
#'
#' This file declares variables that are used in non-standard evaluation
#' contexts (dplyr pipelines, ggplot aesthetics) to avoid "no visible binding"
#' notes during CRAN checks.
#'
#' @keywords internal
#' @name globalVariables
NULL

# Declare global variables to suppress NOTES in CRAN checks
utils::globalVariables(c(".data", "Frequency", "Percentage"))
