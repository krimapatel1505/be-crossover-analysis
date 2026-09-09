# -----------------------------------------------------------------------------
# 01_load_data.R
# Loads the published summary statistics and study design fields, and runs
# basic integrity checks (every value present, CVs positive, sequence counts
# consistent with the total analyzed).
# -----------------------------------------------------------------------------

suppressPackageStartupMessages(library(dplyr))

load_be_data <- function() {
  summary_long <- read.csv("data/raw/methocarbamol_be_summary.csv", stringsAsFactors = FALSE)
  design <- read.csv("data/raw/methocarbamol_be_design.csv", stringsAsFactors = FALSE)

  design_kv <- setNames(as.character(design$value), design$field)

  wide <- summary_long %>%
    tidyr::pivot_wider(
      id_cols = parameter,
      names_from = treatment,
      values_from = c(arithmetic_mean, geometric_mean)
    )

  list(summary_long = summary_long, wide = wide, design = design_kv)
}

check_be_data <- function(be) {
  checks <- list(
    all_geometric_means_positive = all(be$summary_long$geometric_mean > 0),
    all_arithmetic_means_positive = all(be$summary_long$arithmetic_mean > 0),
    sequence_counts_sum_to_total = (
      as.integer(be$design[["n_TR_sequence_analysed"]]) +
        as.integer(be$design[["n_RT_sequence_analysed"]])
    ) == as.integer(be$design[["n_PK_analysis_total"]]),
    cv_values_positive = all(
      as.numeric(be$design[["within_subject_cv_cmax_pct"]]) > 0,
      as.numeric(be$design[["within_subject_cv_auc0t_pct"]]) > 0
    ),
    geometric_mean_le_arithmetic_mean = all(
      be$summary_long$geometric_mean <= be$summary_long$arithmetic_mean
    )
  )
  list(checks = checks, pass = all(unlist(checks)))
}
