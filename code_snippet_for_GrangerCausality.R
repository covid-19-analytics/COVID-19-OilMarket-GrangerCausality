# Combine datasets (riskScore: PRS/ SRS; CrudeOilFuture: from Bloomberg) 
#   by reference dates ------
df_combined <- left_join(df_riskScore, df_CrudeOilFuture, by= "ref_date") %>%
  dplyr::filter(!is.na(PRS) & !is.na(SRS) & !is.na(Price))

tmp_constant_min <- abs(min(df_combined$Price)) + 0.001
df_log_return <- df_combined %>%
  dplyr::mutate(Price= ifelse(Price<0, Price+tmp_constant_min, Price)) %>%
  dplyr::mutate(
    PRS_t= log(PRS) - log(lag(PRS, n= 1L)),
    SRS_t= log(SRS) - log(lag(SRS, n= 1L)),
    # Price_t: daily return of oil price at time t; Yt
    Price_t= log(Price) - log(lag(Price, n= 1L))) 

# Iterate through all selected windowSize ----------
lapply(windowSize_GC, function(tmp_windowSize_GC) {
  start_idx <- 2
  v_dates <- sort(unique(df_log_return$ref_date)) # *** Trading days ***
  n <- length(v_dates)
  l_rollingWindow <- list()
  tmp_remaining <- n
  round_idx <- 0
  
  # Create the rollingWindow sets ----------
  while(tmp_remaining >= tmp_windowSize_GC) {
    idx_begin <- start_idx+round_idx*1
    idx_end <- idx_begin + tmp_windowSize_GC - 1
    sel_dates <- v_dates[idx_begin:idx_end]
    tmp_remaining <- n - (idx_begin)
    round_idx <- round_idx + 1
    
    l_rollingWindow <- append(l_rollingWindow, list(sel_dates))
  }
  
  # Iterate through the rolling sets ----------
  lapply(seq(length(l_rollingWindow)), function(idx) {
    tmp_dates <- as_date(l_rollingWindow[[idx]])
    
    # Iterate through the p-lags ----------
    lapply(v_pLag, function(tmp_p) {
      tmp_df <- df_log_return %>%
        dplyr::filter(ref_date %in% tmp_dates) %>%
        tibble::column_to_rownames("ref_date") %>%
        
        dplyr::select(PRS_t, SRS_t, Price_t) %>%
        dplyr::filter(!is.na(PRS_t) & !is.na(SRS_t) & !is.na(Price_t))
      
      tmp_test_results <- NULL        
      
      tryCatch({
        # Perform Granger Causailty with (PRS, SRS) -> daily return ----------
        tmp_model_var <- vars::VAR(tmp_df, p= tmp_p, type= "const")
        tmp_causality_results <- vars::causality(
          tmp_model_var, cause= c("PRS_t", "SRS_t"))
        
        if (is.null(tmp_causality_results)) { next() }
        
        tmp_test_results <- data.frame(
          "hypothesis"= sprintf("%s, %s -> %s", "PRS_t", "SRS_t", "Price_t"),
          "F-statistic"= tmp_causality_results$Granger$statistic,
          "p-value"= tmp_causality_results$Granger$p.value,
          "p_lag"= tmp_p,
          stringsAsFactors= FALSE)
        
        colnames(tmp_test_results) <- c(
          "hypothesis", "F-statistic", "p-value", "p_lag")
        
      },  error= function(e) {
        # cat("error: ...\n")
        tmp_test_results <- NULL
      })
      
      return(tmp_test_results)
    }) -> l_test_results
    
    df_test_result <- NULL
    if (length(purrr::compact(l_test_results))>0) {
      df_test_result <- do.call("rbind", l_test_results) 
      df_test_result$ref_date <- max(tmp_dates)
    } else {
      df_test_result <- NULL
    }
    return(df_test_result)
    
  }) -> l_rolling_test_results
  
  if (length(purrr::compact(l_rolling_test_results)) <=0) { next() }
  
  df_rolling_test_results <- do.call("rbind", l_rolling_test_results) 
  df_rolling_test_results$windowSize_GC <- tmp_windowSize_GC
  
  return(df_rolling_test_results)
  
}) -> l_rolling_test_results

# Combine all rolling test results into single data.frame ----------
df_all_rolling_test_results <- do.call("rbind", l_rolling_test_results)