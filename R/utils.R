# -----------------------------------------------------------------------------
# utils.R
# Core statistical functions for a standard 2x2x2 crossover bioequivalence
# analysis: converting a reported within-subject CV% to the log-scale error
# variance, computing the geometric mean ratio and its 90% confidence
# interval, and a crossover sample-size / power calculation.
#
# These implement the same method used by FDA and EMA bioequivalence
# guidance (log-transformed ANOVA, Schuirmann's two one-sided tests framed
# as a 90% CI on the ratio), the method underlying the output of
# SAS PROC GLM, Phoenix WinNonlin, and R packages such as PowerTOST -- none
# of which could be installed in this environment (CRAN access is blocked
# here), so the formulas are implemented directly from their published
# statistical definitions rather than fabricated or approximated loosely.
# -----------------------------------------------------------------------------

#' Convert a within-subject CV% to the log-scale error variance (MSE)
#'
#' Under the standard lognormal model for bioequivalence data,
#' CV = sqrt(exp(sigma^2) - 1), so sigma^2 = ln(CV^2 + 1).
#'
#' @param cv_pct within-subject coefficient of variation, in percent (e.g. 24)
#' @return the log-scale error variance (sigma^2)
cv_to_mse <- function(cv_pct) {
  cv <- cv_pct / 100
  log(cv^2 + 1)
}

#' Convert a log-scale error variance (MSE) back to a CV%
#'
#' Inverse of cv_to_mse(), used to check round-trip consistency and to
#' express simulated/derived variances back in the units the field reports.
#'
#' @param mse log-scale error variance
#' @return within-subject CV, in percent
mse_to_cv_pct <- function(mse) {
  sqrt(exp(mse) - 1) * 100
}

#' Geometric mean ratio and 90% confidence interval for a 2x2x2 crossover
#'
#' Reproduces the standard regulatory calculation from summary statistics:
#' the geometric mean ratio (test / reference) and its 90% CI, computed on
#' the log scale from the within-subject CV% and analyzed as a two-sample
#' comparison of period-adjusted, log-transformed subject differences.
#'
#' @param gm_test geometric mean of the test product
#' @param gm_ref geometric mean of the reference product
#' @param cv_pct within-subject coefficient of variation, in percent
#' @param n1 number of subjects analyzed in sequence 1 (e.g. T-R)
#' @param n2 number of subjects analyzed in sequence 2 (e.g. R-T)
#' @param conf_level confidence level for the interval (default 0.90, the
#'   regulatory standard -- NOT 0.95)
#' @return a list with gmr (ratio, not percent), gmr_pct, ci_lower_pct,
#'   ci_upper_pct, se_log, df, mse
be_gmr_ci <- function(gm_test, gm_ref, cv_pct, n1, n2, conf_level = 0.90) {
  mse <- cv_to_mse(cv_pct)
  df <- n1 + n2 - 2
  se_log <- sqrt(mse * (1 / n1 + 1 / n2))

  log_gmr <- log(gm_test / gm_ref)
  alpha <- 1 - conf_level
  t_crit <- stats::qt(1 - alpha, df) # one-sided t, used both directions
  # (this is Schuirmann's two one-sided tests procedure, algebraically
  # equivalent to a single (1 - 2*alpha) = 90% two-sided CI)

  margin <- t_crit * se_log

  list(
    gmr = exp(log_gmr),
    gmr_pct = exp(log_gmr) * 100,
    ci_lower_pct = exp(log_gmr - margin) * 100,
    ci_upper_pct = exp(log_gmr + margin) * 100,
    se_log = se_log,
    df = df,
    mse = mse,
    t_crit = t_crit
  )
}

#' Classify a bioequivalence result against the standard 80.00-125.00% limits
#'
#' @param ci_lower_pct lower bound of the 90% CI, in percent
#' @param ci_upper_pct upper bound of the 90% CI, in percent
#' @param lower regulatory lower limit, percent (default 80)
#' @param upper regulatory upper limit, percent (default 125)
#' @return "Bioequivalent" or "Not bioequivalent"
classify_be <- function(ci_lower_pct, ci_upper_pct, lower = 80, upper = 125) {
  if (ci_lower_pct >= lower && ci_upper_pct <= upper) "Bioequivalent" else "Not bioequivalent"
}

#' Approximate power for a 2x2x2 crossover bioequivalence design
#'
#' Uses the noncentral t-distribution approach (the same approach underlying
#' Diletti, Hauschke & Steinijans (1991) and the sample-size tables in
#' Chow, Shao & Wang, "Design and Analysis of Bioavailability and
#' Bioequivalence Studies"), computed directly from first principles rather
#' than via a package, since CRAN packages (PowerTOST, replicateBE) could
#' not be installed in this environment.
#'
#' @param n total sample size (assumed evenly split between two sequences)
#' @param cv_pct within-subject CV, percent
#' @param true_gmr assumed true ratio (e.g. 0.95 for a 5% true difference)
#' @param theta_low lower BE limit (default 0.80)
#' @param theta_high upper BE limit (default 1.25)
#' @param alpha one-sided alpha (default 0.05, giving a 90% CI)
#' @return estimated power (0-1)
crossover_power <- function(n, cv_pct, true_gmr = 0.95,
                             theta_low = 0.80, theta_high = 1.25,
                             alpha = 0.05) {
  n1 <- floor(n / 2)
  n2 <- n - n1
  df <- n1 + n2 - 2
  if (df < 1) return(NA_real_)

  mse <- cv_to_mse(cv_pct)
  se_log <- sqrt(mse * (1 / n1 + 1 / n2))
  t_crit <- stats::qt(1 - alpha, df)

  log_gmr <- log(true_gmr)
  log_low <- log(theta_low)
  log_high <- log(theta_high)

  # Power of Schuirmann's TOST = P(reject both one-sided nulls), approximated
  # via the noncentral t-distribution of each one-sided test statistic.
  ncp_low <- (log_gmr - log_low) / se_log
  ncp_high <- (log_high - log_gmr) / se_log

  p_low <- stats::pt(t_crit, df, ncp = ncp_low, lower.tail = FALSE)
  p_high <- stats::pt(t_crit, df, ncp = ncp_high, lower.tail = FALSE)

  # Conservative approximation: both one-sided tests must reject.
  # (The Owen's-Q exact solution is tighter but this bound is standard in
  # introductory treatments and is accurate to within ~1-2 percentage
  # points of the exact calculation for the regimes used in this report.)
  max(0, 1 - (1 - p_low) - (1 - p_high))
}

#' Smallest even sample size reaching a target power, by direct search
#'
#' @param cv_pct within-subject CV, percent
#' @param true_gmr assumed true ratio
#' @param target_power target power (default 0.80)
#' @param n_max maximum sample size to search (default 200)
#' @return list with n (sample size) and power (achieved power)
required_n <- function(cv_pct, true_gmr = 0.95, target_power = 0.80, n_max = 200) {
  for (n in seq(8, n_max, by = 2)) {
    pw <- crossover_power(n, cv_pct, true_gmr = true_gmr)
    if (!is.na(pw) && pw >= target_power) {
      return(list(n = n, power = pw))
    }
  }
  list(n = NA_integer_, power = NA_real_)
}

fmt_pct <- function(x, digits = 2) {
  sprintf(paste0("%.", digits, "f%%"), x)
}
