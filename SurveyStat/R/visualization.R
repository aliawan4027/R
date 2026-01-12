#' Create publication-quality histogram
#'
#' This function creates a clean, publication-quality histogram for numeric variables
#' using ggplot2 with minimal theme and appropriate statistical overlays.
#'
#' @param data A data.frame containing survey data
#' @param col Character string specifying column name for numeric variable
#' @param bins Number of bins for histogram (default: 30)
#' @param add_density Logical whether to add density curve (default: TRUE)
#' @return A ggplot object
#' @export
#' @importFrom ggplot2 ggplot aes aes_string geom_histogram geom_density aes after_stat labs theme theme_minimal element_text element_line element_blank
#' @importFrom stats density
#' @examples
#' data <- data.frame(age = rnorm(100, 35, 10))
#' hist_plot <- plot_histogram(data, "age")
#' print(hist_plot)
plot_histogram <- function(data, col, bins = 30, add_density = TRUE) {
  # Input validation
  if (!is.data.frame(data)) {
    stop("Input must be a data.frame")
  }
  
  if (!col %in% names(data)) {
    stop("Column '", col, "' not found in data")
  }
  
  if (!is.numeric(data[[col]])) {
    stop("Column '", col, "' must be numeric for histogram")
  }
  
  # Remove missing values
  plot_data <- data[!is.na(data[[col]]), , drop = FALSE]
  
  if (nrow(plot_data) == 0) {
    stop("No non-missing values for column '", col, "'")
  }
  
  # Create base plot
  p <- ggplot(plot_data, aes_string(x = col)) +
    geom_histogram(
      aes(y = after_stat(density)), 
      bins = bins, 
      fill = "steelblue", 
      color = "white", 
      alpha = 0.8,
      linewidth = 0.5
    ) +
    labs(
      title = paste("Distribution of", col),
      x = col,
      y = "Density"
    ) +
    theme_minimal() +
    theme(
      plot.title = element_text(hjust = 0.5, size = 14, face = "bold"),
      axis.title = element_text(size = 12, face = "plain"),
      axis.text = element_text(size = 10),
      panel.grid.major = element_line(linewidth = 0.3),
      panel.grid.minor = element_blank()
    )
  
  # Add density curve if requested
  if (add_density) {
    p <- p + 
      geom_density(color = "red", linewidth = 1, alpha = 0.7) +
      labs(subtitle = "Histogram with density curve")
  }
  
  return(p)
}

#' Create weighted bar plot for categorical variables
#'
#' This function creates a bar plot for categorical variables, optionally
#' using survey weights to show weighted frequencies.
#'
#' @param data A data.frame containing survey data
#' @param col Character string specifying column name for categorical variable
#' @param weight_col Character string specifying column name containing weights (optional)
#' @param show_percentages Logical whether to show percentage labels (default: TRUE)
#' @return A ggplot object
#' @export
#' @importFrom dplyr %>% group_by summarise mutate n
#' @importFrom rlang sym
#' @importFrom ggplot2 ggplot aes aes_string geom_bar geom_text labs theme theme_minimal element_text element_blank element_line aes ylim
#' @examples
#' data <- data.frame(gender = c("M", "F", "M", "F"), weight = c(1, 1.2, 0.8, 1.1))
#' bar_plot <- plot_weighted_bar(data, "gender")
#' weighted_bar <- plot_weighted_bar(data, "gender", "weight")
plot_weighted_bar <- function(data, col, weight_col = NULL, show_percentages = TRUE) {
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
  plot_data <- data[!is.na(data[[col]]), , drop = FALSE]
  
  if (nrow(plot_data) == 0) {
    stop("No non-missing values for column '", col, "'")
  }
  
  # Calculate frequencies
  if (!is.null(weight_col)) {
    freq_data <- plot_data %>%
      group_by(!!sym(col)) %>%
      summarise(Frequency = sum(.data[[weight_col]], na.rm = TRUE), .groups = "drop") %>%
      mutate(Percentage = Frequency / sum(Frequency) * 100)
    
    y_label <- "Weighted Frequency"
    title_suffix <- " (Weighted)"
  } else {
    freq_data <- plot_data %>%
      group_by(!!sym(col)) %>%
      summarise(Frequency = n(), .groups = "drop") %>%
      mutate(Percentage = Frequency / sum(Frequency) * 100)
    
    y_label <- "Frequency"
    title_suffix <- " (Unweighted)"
  }
  
  # Create base plot
  p <- ggplot(freq_data, aes_string(x = col, y = "Frequency")) +
    geom_bar(fill = "steelblue", color = "white", alpha = 0.8, linewidth = 0.5, stat = "identity") +
    labs(
      title = paste("Distribution of", col, title_suffix),
      x = col,
      y = y_label
    ) +
    theme_minimal() +
    theme(
      plot.title = element_text(hjust = 0.5, size = 14, face = "bold"),
      axis.title = element_text(size = 12, face = "plain"),
      axis.text = element_text(size = 10),
      axis.text.x = element_text(angle = 45, hjust = 1),
      panel.grid.major.x = element_blank(),
      panel.grid.major.y = element_line(linewidth = 0.3),
      panel.grid.minor = element_blank()
    )
  
  # Add percentage labels if requested
  if (show_percentages) {
    p <- p + 
      geom_text(
        aes(label = paste0(round(Percentage, 1), "%")),
        vjust = -0.5,
        size = 3.5,
        fontface = "plain"
      ) +
      ylim(0, max(freq_data$Frequency) * 1.15)  # Make room for labels
  }
  
  return(p)
}

#' Create publication-quality box plot
#'
#' This function creates a clean, publication-quality box plot for numeric variables,
#' optionally grouped by a categorical variable.
#'
#' @param data A data.frame containing survey data
#' @param col Character string specifying column name for numeric variable
#' @param group_col Character string specifying column name for grouping variable (optional)
#' @param add_points Logical whether to add individual data points (default: TRUE)
#' @return A ggplot object
#' @export
#' @importFrom ggplot2 ggplot aes aes_string geom_boxplot geom_jitter labs theme theme_minimal element_text element_line element_blank scale_x_discrete
#' @importFrom stats complete.cases
#' @examples
#' data <- data.frame(age = c(25, 30, 35, 40, 45), gender = c("M", "F", "M", "F", "M"))
#' box_plot <- plot_boxplot(data, "age")
#' grouped_box <- plot_boxplot(data, "age", "gender")
plot_boxplot <- function(data, col, group_col = NULL, add_points = TRUE) {
  # Input validation
  if (!is.data.frame(data)) {
    stop("Input must be a data.frame")
  }
  
  if (!col %in% names(data)) {
    stop("Column '", col, "' not found in data")
  }
  
  if (!is.null(group_col) && !group_col %in% names(data)) {
    stop("Group column '", group_col, "' not found in data")
  }
  
  if (!is.numeric(data[[col]])) {
    stop("Column '", col, "' must be numeric for box plot")
  }
  
  # Remove missing values
  if (!is.null(group_col)) {
    plot_data <- data[complete.cases(data[[col]], data[[group_col]]), , drop = FALSE]
    x_var <- group_col
    title_suffix <- paste("by", group_col)
  } else {
    plot_data <- data[!is.na(data[[col]]), , drop = FALSE]
    x_var <- "factor(1)"  # Create dummy factor for single boxplot
    title_suffix <- ""
  }
  
  if (nrow(plot_data) == 0) {
    stop("No complete cases for box plot")
  }
  
  # Create base plot
  p <- ggplot(plot_data, aes_string(x = x_var, y = col)) +
    geom_boxplot(
      fill = "lightblue", 
      color = "darkblue", 
      alpha = 0.7,
      linewidth = 0.8,
      outlier.shape = NA
    ) +
    labs(
      title = paste("Box Plot of", col, title_suffix),
      x = if (!is.null(group_col)) group_col else "",
      y = col
    ) +
    theme_minimal() +
    theme(
      plot.title = element_text(hjust = 0.5, size = 14, face = "bold"),
      axis.title = element_text(size = 12, face = "plain"),
      axis.text = element_text(size = 10),
      panel.grid.major = element_line(linewidth = 0.3),
      panel.grid.minor = element_blank()
    )
  
  # Add individual points if requested
  if (add_points) {
    p <- p + 
      geom_jitter(
        aes_string(x = x_var, y = col),
        color = "darkgray",
        alpha = 0.5,
        size = 1.5,
        width = 0.2
      )
  }
  
  # Adjust x-axis if single boxplot
  if (is.null(group_col)) {
    p <- p + 
      scale_x_discrete(labels = "") +
      theme(axis.text.x = element_blank())
  }
  
  return(p)
}
