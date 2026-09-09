# -----------------------------------------------------------------------------
# 03_power_sensitivity.R
# A general methodological extension: given the study's own reported
# within-subject CV%, how does statistical power (and the sample size needed
# for 80% power) change with the true underlying ratio and with CV? This is
# the same sensitivity analysis a biostatistician runs during study design,
# and it demonstrates the mechanics behind why Cmax (CV 24%) needed a larger
# sample than AUC0-t (CV 13%) would have, for the same target power.
# -----------------------------------------------------------------------------

suppressPackageStartupMessages(library(dplyr))

#' Sample size required for 80% power across a grid of true ratios, for one CV
sample_size_curve <- function(cv_pct, ratios = seq(0.90, 1.00, by = 0.01),
                               target_power = 0.80) {
  purrr_map <- lapply(ratios, function(r) {
    res <- required_n(cv_pct, true_gmr = r, target_power = target_power)
    data.frame(true_gmr = r, cv_pct = cv_pct, n_required = res$n, power_at_n = res$power)
  })
  bind_rows(purrr_map)
}

#' Power achieved at the study's actual sample size, across a range of CVs
#'
#' Answers: "if this study's within-subject variability had been different,
#' would the achieved sample size (n=31) still have delivered adequate
#' power to declare bioequivalence at a true ratio close to 1?"
power_vs_cv_curve <- function(n_actual, cv_range = seq(10, 35, by = 1),
                               true_gmr = 0.95) {
  data.frame(
    cv_pct = cv_range,
    n = n_actual,
    power = vapply(cv_range, function(cv) crossover_power(n_actual, cv, true_gmr = true_gmr),
                    numeric(1))
  )
}

run_power_sensitivity <- function(be) {
  n_actual <- as.integer(be$design[["n_PK_analysis_total"]])

  cv_cmax  <- as.numeric(be$design[["within_subject_cv_cmax_pct"]])
  cv_auc0t <- as.numeric(be$design[["within_subject_cv_auc0t_pct"]])

  ss_curves <- bind_rows(
    sample_size_curve(cv_cmax) %>% mutate(parameter = "Cmax"),
    sample_size_curve(cv_auc0t) %>% mutate(parameter = "AUC0t")
  )

  power_curves <- power_vs_cv_curve(n_actual) %>% mutate(parameter = "at actual n")

  # Power actually achieved by this study's design (n=31) for each parameter,
  # assuming the observed CV and a true ratio equal to the observed GMR.
  achieved <- data.frame(
    parameter = c("Cmax", "AUC0t"),
    cv_pct = c(cv_cmax, cv_auc0t),
    n_actual = n_actual,
    power_at_n31_gmr095 = vapply(c(cv_cmax, cv_auc0t), function(cv)
      crossover_power(n_actual, cv, true_gmr = 0.95), numeric(1))
  )

  list(ss_curves = ss_curves, power_curves = power_curves, achieved = achieved)
}
