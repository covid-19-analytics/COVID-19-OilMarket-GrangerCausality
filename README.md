# COVID-19-OilMarket-GrangerCausality

Appendix A: R code snippets to compute the Granger causality results in the iterative manner.

Data inputs:
1. `df_riskScore` [provided data]: R object for risk scores data.frame (e.g., *`df_final_riskScore_Jan11_2022.csv`*)
  - columns: *ref_date* (Date), *SRS* (numeric), *PRS* (numeric)
2. `df_CrudeOilFuture` [paid data]: R object for Crude oil WTI price data.frame 
  - from paid data: e.g., Bloomberg .xlsx
  - columns: *ref_date* (Date), *Price* (numeric)
3. `windowSize_GC`: R object for selected window size (e.g., 42, 49, 56)
4. `max_p`: define the maximum p-lag (default: `v_pLag <- seq(6, max_p)`)

Simple usage guide:
1. Retrieve the Crude oil WTI price from external source
2. Download the pandemic risk scores (PRS, SRS) from this repository
3. Install the required libraries (*`dplyr`*, *`readr`*, *`lubridate`*, *`vars`*)
4. Load the required data into the R Objects `df_riskScore` and `df_CrudeOilFuture` (Beware the name of each object); (optional) perform data cleansing if needed
5. Setup the initial values for `windowSize_GC` and `max_p`
6. Run the code snippet *`code_snippet_for_GrangerCausality.R`*
7. You will get all the results in single data.frame `df_all_rolling_test_results`
