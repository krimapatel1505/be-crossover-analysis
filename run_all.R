# -----------------------------------------------------------------------------
# run_all.R
# Executes the full analysis pipeline and writes figures and tables to outputs/.
# Run from the repository root:  Rscript run_all.R
# -----------------------------------------------------------------------------

suppressPackageStartupMessages({
  library(dplyr)
  library(ggplot2)
  library(scales)
})

source("R/utils.R")
source("R/01_load_data.R")
source("R/02_be_analysis.R")
source("R/03_power_sensitivity.R")

dir.create("outputs/figures", recursive = TRUE, showWarnings = FALSE)
dir.create("outputs/tables", recursive = TRUE, showWarnings = FALSE)

message("1. Loading data")
be <- load_be_data()
qc <- check_be_data(be)
stopifnot(qc$pass)
message("   integrity checks passed: ", paste(names(qc$checks), collapse = ", "))

message("2. Recomputing GMR and 90% CI, vs published values")
results <- run_be_analysis(be)
print(results %>% select(parameter, gmr_pct, recomputed_ci_lower_pct, recomputed_ci_upper_pct,
                          published_ci_lower_pct, published_ci_upper_pct))

message("3. Power / sample-size sensitivity")
sens <- run_power_sensitivity(be)
print(sens$achieved)

# --- Figure 1: recomputed vs published 90% CI --------------------------------
# Published point estimate is not printed in the article as a single number in
# the text extracted here, so it is taken as the log-scale midpoint of its own
# published 90% CI (the standard relationship for a symmetric-on-log-scale CI).
ci_compare <- bind_rows(
  results %>% transmute(parameter, source = "Recomputed (this analysis)",
                         point = gmr_pct,
                         lower = recomputed_ci_lower_pct, upper = recomputed_ci_upper_pct),
  results %>% transmute(parameter, source = "Published (article)",
                         point = sqrt(published_ci_lower_pct * published_ci_upper_pct),
                         lower = published_ci_lower_pct, upper = published_ci_upper_pct)
)

p1 <- ggplot(ci_compare, aes(x = source, y = point, colour = source)) +
  geom_hline(yintercept = 80, linetype = "dashed", colour = "#b22222", linewidth = 0.6) +
  geom_hline(yintercept = 125, linetype = "dashed", colour = "#b22222", linewidth = 0.6) +
  geom_hline(yintercept = 100, linetype = "dotted", colour = "grey50", linewidth = 0.6) +
  geom_errorbar(aes(ymin = lower, ymax = upper), width = 0.15, linewidth = 0.9) +
  geom_point(size = 3) +
  facet_wrap(~parameter) +
  scale_colour_manual(values = c("Published (article)" = "#c07830",
                                 "Recomputed (this analysis)" = "#1f4e79")) +
  labs(
    title = "Recomputed 90% CI vs the published result",
    subtitle = "Dashed lines mark the 80.00-125.00% bioequivalence limits",
    x = NULL, y = "Geometric mean ratio, test/reference (%)", colour = NULL
  ) +
  theme_minimal(base_size = 11) +
  theme(legend.position = "bottom", axis.text.x = element_blank(),
        plot.title = element_text(size = 13, face = "bold"))

ggsave("outputs/figures/fig1_ci_comparison.png", p1, width = 7.5, height = 5, dpi = 150)

# --- Figure 2: sample size vs true ratio, by parameter ------------------------
p2 <- ggplot(sens$ss_curves, aes(true_gmr, n_required, colour = parameter)) +
  geom_line(linewidth = 0.8) +
  geom_point(size = 1.8) +
  geom_vline(xintercept = 0.95, linetype = "dashed", colour = "grey50") +
  scale_colour_manual(values = c("Cmax" = "#c07830", "AUC0t" = "#1f4e79")) +
  labs(
    title = "Higher within-subject variability demands a larger study",
    subtitle = "Subjects needed for 80% power, by assumed true ratio (CV: Cmax 24%, AUC0-t 13%)",
    x = "Assumed true geometric mean ratio (test/reference)",
    y = "Total subjects needed for 80% power", colour = "Parameter"
  ) +
  theme_minimal(base_size = 11) +
  theme(legend.position = "bottom", plot.title = element_text(size = 13, face = "bold"))

ggsave("outputs/figures/fig2_sample_size_sensitivity.png", p2, width = 7.5, height = 5, dpi = 150)

# --- Figure 3: power at this study's actual n, vs CV --------------------------
p3 <- ggplot(sens$power_curves, aes(cv_pct, power)) +
  geom_line(linewidth = 0.8, colour = "#1f4e79") +
  geom_hline(yintercept = 0.80, linetype = "dashed", colour = "#b22222") +
  geom_vline(data = sens$achieved, aes(xintercept = cv_pct, colour = parameter),
             linetype = "dotted", linewidth = 0.8) +
  scale_colour_manual(values = c("Cmax" = "#c07830", "AUC0t" = "#1f4e79")) +
  scale_y_continuous(labels = percent) +
  labs(
    title = "Power at this study's actual sample size (n = 31), by CV%",
    subtitle = "Dotted lines: this study's observed CV%. Assumes a true ratio of 0.95.",
    x = "Within-subject CV (%)", y = "Power", colour = "Observed CV for"
  ) +
  theme_minimal(base_size = 11) +
  theme(legend.position = "bottom", plot.title = element_text(size = 13, face = "bold"))

ggsave("outputs/figures/fig3_power_vs_cv.png", p3, width = 7.5, height = 5, dpi = 150)

# --- Tables --------------------------------------------------------------------
write.csv(results, "outputs/tables/gmr_ci_comparison.csv", row.names = FALSE)
write.csv(sens$ss_curves, "outputs/tables/sample_size_sensitivity.csv", row.names = FALSE)
write.csv(sens$achieved, "outputs/tables/power_achieved.csv", row.names = FALSE)

writeLines(capture.output(sessionInfo()), "sessionInfo.txt")

message("Done. Figures in outputs/figures, tables in outputs/tables.")
