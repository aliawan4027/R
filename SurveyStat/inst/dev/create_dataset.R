# Create example_survey dataset for SurveyStat package
example_survey <- data.frame(
  Age = c(25, 34, 45, 28, 52, 31, 38, 29, 47, 33),
  Gender = c("Male", "Female", "Male", "Female", "Male", "Female", "Male", "Female", "Male", "Female"),
  Education = c("High School", "Bachelor", "Bachelor", "High School", "Graduate", "Bachelor", "High School", "Graduate", "Bachelor", "High School"),
  Income = c(35000, 52000, 68000, 31000, 85000, 48000, 42000, 62000, 71000, 38000),
  Weight = c(0.85, 1.12, 0.95, 1.08, 0.92, 1.05, 0.98, 1.15, 0.88, 1.02)
)

# Save as R data file
save(example_survey, file = "data/example_survey.rda")

cat("Dataset created and saved to data/example_survey.rda\n")
