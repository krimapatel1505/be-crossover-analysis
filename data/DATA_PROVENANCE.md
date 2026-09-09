# Data provenance

## Source

Portoles-Perez A, et al. **Bioequivalence Study of Two Oral Methocarbamol
Formulations in Healthy Subjects Under Fasting Conditions: A Randomized,
Open-Label, Crossover Clinical Trial.** *Pharmaceuticals.* 2025;18(3):354.
DOI: [10.3390/ph18030354](https://doi.org/10.3390/ph18030354). Open access
(CC BY).

This is a real, peer-reviewed, published bioequivalence study of a generic
methocarbamol 1500 mg tablet against the reference listed product (Robaxin,
3 x 500 mg). It is not a hypothetical or textbook example.

## What is, and is not, reproduced here

Individual subject-level concentration or PK-parameter data are **not**
published for this study, and the authors state in the article that
underlying data are available from the corresponding author on request.
This is normal for bioequivalence trials: subject-level data are protected
health information and are essentially never released in a public journal
article or supplementary file, even in fully open-access papers. A search
across several recently published 2x2 crossover bioequivalence studies
(methocarbamol, mifepristone, rifapentine, lurasidone, omeprazole,
empagliflozin) confirmed the same pattern: journals publish summary
statistics, not subject-level tables.

What the article *does* publish, and what this project uses as its input
data, are the study's reported **summary statistics**:

- Arithmetic and geometric means of Cmax and AUC0-t for the test and
  reference products
- Within-subject (intra-subject) coefficient of variation (CV%) for Cmax
  and AUC0-t
- The number of subjects randomized and analyzed, by sequence group
- The study's own reported point estimate and 90% confidence interval for
  the geometric mean ratio of each parameter

These values are transcribed in `raw/methocarbamol_be_summary.csv` and
`raw/methocarbamol_be_design.csv`, exactly as reported in the article, at
the precision the article reports them (geometric means to two decimal
places, CV% as whole percentages).

## What this project does with that data

Rather than simply repeating the published conclusion, this project
independently **recomputes** the geometric mean ratio and 90% confidence
interval from the reported means and within-subject CV%, using the
standard regulatory method for a 2x2x2 crossover bioequivalence analysis
(log-transformed ANOVA / Schuirmann's two one-sided tests framework, as
specified in FDA and EMA bioequivalence guidance). This is the same
calculation a biostatistician performs by hand (or in SAS PROC GLM,
Phoenix WinNonlin, or R) when checking a bioequivalence table before it
goes into a submission.

The independent recomputation is then compared against the study's own
published 90% CI. Where the two differ, the difference and its likely
source (loss of precision from reporting CV% as a whole-number percentage,
rather than the full-precision ANOVA mean square error the original
analysis would have used) are reported explicitly. See the main report for
that comparison and discussion.

## Known constraints of this approach, stated up front

- The 90% CI recomputed here is derived from **summary statistics**, not
  from subject-level data, so it cannot be identical to the sponsor's own
  internal ANOVA output. It is expected to be close, and directionally
  consistent, but not numerically identical.
- AUC0-inf is discussed in the source article's methods but not reported
  as a separate summary table entry with the same precision as Cmax and
  AUC0-t, and is therefore not analyzed quantitatively here.
- The sample-size / power sensitivity analysis in this project uses the
  study's own reported within-subject CV% as an input to a standard
  crossover sample-size formula (Diletti, Hauschke, Steinijans 1991); it is
  a general methodological exploration, not a claim about how the original
  study was powered.

## Transcription check

Values were transcribed from two independent fetches of the published
article (its HTML rendering) and cross-checked against each other before
being entered into the CSV files.
