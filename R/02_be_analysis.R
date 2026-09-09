# -----------------------------------------------------------------------------
# 02_be_analysis.R
# Independent recomputation of the geometric mean ratio and 90% CI for Cmax
# and AUC0-t, from the published summary statistics, using the standard
# 2x2x2 crossover method -- and a direct comparison against the study's own
# published 90% CI.
# -----------------------------------------------------------------------------

suppressPackageStartupMessages(library(dplyr))

#' Run the recomputation for one PK parameter and compare to the published CI
#'
#' @param be output of load_be_data()
#' @param param_name "Cmax" or "AUC0t"
#' @param cv_field name of the design field holding that parameter's
#'   within-subject CV%
#' @param pub_low_field,pub_high_field design fields holding the published CI
#' @return one-row data frame summarizing recomputed vs published results
analyze_parameter <- function(be, param_name, cv_field, pub_low_field, pub_high_field) {
  row <- be$wide %>% filter(parameter == param_name)

  n1 <- as.integer(be$design[["n_TR_sequence_analysed"]])
  n2 <- as.integer(be$design[["n_RT_sequence_analysed"]])
  cv <- as.numeric(be$design[[cv_field]])

  result <- be_gmr_ci(
    gm_test = row$geometric_mean_Test,
    gm_ref  = row$geometric_mean_Reference,
    cv_pct  = cv,
    n1 = n1, n2 = n2
  )

  pub_low  <- as.numeric(be$design[[pub_low_field]])
  pub_high <- as.numeric(be$design[[pub_high_field]])

  data.frame(
    parameter = param_name,
    gm_test = row$geometric_mean_Test,
    gm_ref = row$geometric_mean_Reference,
    within_subject_cv_pct = cv,
    n1 = n1, n2 = n2, df = result$df,
    gmr_pct = result$gmr_pct,
    recomputed_ci_lower_pct = result$ci_lower_pct,
    recomputed_ci_upper_pct = result$ci_upper_pct,
    published_ci_lower_pct = pub_low,
    published_ci_upper_pct = pub_high,
    recomputed_ci_width_pct = result$ci_upper_pct - result$ci_lower_pct,
    published_ci_width_pct = pub_high - pub_low,
    be_verdict_recomputed = classify_be(result$ci_lower_pct, result$ci_upper_pct),
    be_verdict_published = classify_be(pub_low, pub_high),
    stringsAsFactors = FALSE
  )
}

run_be_analysis <- function(be) {
  cmax  <- analyze_parameter(be, "Cmax", "within_subject_cv_cmax_pct",
                              "reported_gmr_cmax_ci90_low_pct", "reported_gmr_cmax_ci90_high_pct")
  auc0t <- analyze_parameter(be, "AUC0t", "within_subject_cv_auc0t_pct",
                              "reported_gmr_auc0t_ci90_low_pct", "reported_gmr_auc0t_ci90_high_pct")
  bind_rows(cmax, auc0t)
}
