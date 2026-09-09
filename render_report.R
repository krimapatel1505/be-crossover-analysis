# -----------------------------------------------------------------------------
# render_report.R
# Renders the analysis report and publishes a copy for GitHub Pages.
#
# The report is written to two places:
#   outputs/be_crossover_report.html   the canonical build artefact
#   docs/index.html                    served by GitHub Pages at the repo root
# -----------------------------------------------------------------------------

rmarkdown::render(
  input         = "analysis/be_crossover_report.Rmd",
  output_dir    = "outputs",
  output_file   = "be_crossover_report.html",
  knit_root_dir = normalizePath("."),
  quiet         = TRUE
)

dir.create("docs", showWarnings = FALSE)
file.copy(
  from      = "outputs/be_crossover_report.html",
  to        = "docs/index.html",
  overwrite = TRUE
)

# Tells GitHub Pages to serve the files as-is instead of running Jekyll over them.
file.create("docs/.nojekyll", showWarnings = FALSE)

message("Report rendered to outputs/ and published to docs/index.html")
