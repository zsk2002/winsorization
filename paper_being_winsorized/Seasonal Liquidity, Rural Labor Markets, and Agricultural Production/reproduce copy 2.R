# analysis in R
library(haven)
library(dplyr)
library(stringr)
library(fixest)   # feols
library(purrr)
library(tidyr)
library(broom)
library(haven)
library(tidyverse)
library(marginaleffects)
household_panel_final <- read_dta("Desktop/seasonal_liquidity/cleaned_stuff/paper_being_winsorized/Seasonal Liquidity, Rural Labor Markets, and Agricultural Production/119649-V1/Data/Analysis/household_panel_final.dta")
View(household_panel_final)

base_controls <- c(
  "b_head_age","b_imp_head_age_dum","b_head_female",
  "b_did_ganyu","b_plan_ganyu",
  "b_acres_maize_total","b_acres_cash_crops","b_harvest_total_value","b_crop_diversity",
  "b_asset_quintile","b_livestock_value","b_input_value","b_hired_ganyu",
  "b_num_farm_workers","b_num_iga_workers","control_gift"
)
members_controls <- grep("^b_members_", names(df), value = TRUE)
controls <- unique(c(base_controls, members_controls))

blocks <- c("block_dum_Chanje","block_dum_Chiparamba",
            "block_dum_Eastern","block_dum_Southern","block_dum_Western")

rhs_panelA_hours <- paste(
  "treated + factor(monthyear)",
  paste(controls, collapse = " + "),
  paste(blocks,   collapse = " + "),
  sep = " + "
)

results <- c("work_hours_p100", "hire_hours_p100", "fam_hours_p100", "daily_earnings_p100")

create_percentile <- function(data, results, qs = 90:99, na.rm = TRUE, quantile_type = 7) {
  stopifnot(is.data.frame(data))
  df <- data
  for (q in qs) {
    for (res in results) {
      new_name <- sub("100$", as.character(q), res)
      thr <- as.numeric(quantile(df[[res]], probs = q / 100, na.rm = na.rm, type = quantile_type))
      df[[new_name]] <- pmin(df[[res]], thr)
    }
  }
  
  df
}

df <- read_dta("119649-V1/Data/Analysis/household_panel_final.dta")
df <- create_percentile(df, results)
# # 99 % percentile directly input by the author
# max(na.omit(df_year_1$work_hours))
# max(na.omit(df_year_1$work_hours_p99))
# 
# max(na.omit(df_year_1$fam_hours))
# max(na.omit(df_year_1$fam_hours_p99))
# 
# max(na.omit(df_year_1$hire_hours))
# max(na.omit(df_year_1$hire_hours_p99))
# 
# # Trials see if the data matches.
# Labor_panel_short_recall_clean <- read_dta("119649-V1/Data/Clean Subject Panels/Labor_panel_short_recall_clean.dta") 
# max(na.omit(Labor_panel_short_recall_clean$daily_earnings))
# quantile(Labor_panel_short_recall_clean$daily_earnings, na.rm = TRUE, c(0.95, 0.99))
# max(na.omit(Labor_panel_short_recall_clean$daily_earnings99))
# max(na.omit(Labor_panel_short_recall_clean$daily_earnings95))
# 
# max(na.omit(Labor_panel_short_recall_clean$hired_ganyu_hours))
# quantile(Labor_panel_short_recall_clean$hired_ganyu_hours, na.rm = TRUE, c(0.99))
# max(na.omit(Labor_panel_short_recall_clean$hired_ganyu_hours99))
# 
# max(na.omit(Labor_panel_short_recall_clean$did_ganyu_hours))
# quantile(Labor_panel_short_recall_clean$did_ganyu_hours, na.rm = TRUE, c(0.99))
# max(na.omit(Labor_panel_short_recall_clean$did_ganyu_hours99))
# 
# df <- Labor_panel_short_recall_clean %>%
#   group_by(treatment, year) %>%
#   mutate(
#     daily_earnings_p99 = pmin(daily_earnings, quantile(daily_earnings, 0.99, na.rm = TRUE)),
#     daily_earnings_p95 = pmin(daily_earnings, quantile(daily_earnings, 0.95, na.rm = TRUE))
#   ) %>%
#   ungroup()
# 
# max(na.omit(df$daily_earnings_p99))
# max(na.omit(df$daily_earnings_p95))
# max(na.omit(df$daily_earnings99))
# max(na.omit(df$daily_earnings95))
# 
# df <- Labor_panel_short_recall_clean %>% 
#   filter(year == 1, treated == 1)
# quantile(df$daily_earnings, 0.99, na.rm = TRUE)
# 
# 
# Labor_panel_short_recall_clean <- read_dta("119649-V1/Data/Clean Subject Panels/Labor_panel_short_recall_clean.dta") %>% 
#   filter(calendar_month < 4)
# quantile(Labor_panel_short_recall_clean$daily_earnings, na.rm = TRUE, c(0.95, 0.99))
# max(na.omit(Labor_panel_short_recall_clean$daily_earnings99))
# max(na.omit(Labor_panel_short_recall_clean$daily_earnings95))


### Panel A #######
# reproduce paper results
# coef_se_on_treated <- function(model) {
#   tt <- tidy(model)
#   row <- tt[tt$term == "treated", , drop = FALSE]
#   if (nrow(row) == 0){
#     return(c(NA_real_, NA_real_))}
#   else{ 
#     return(c(row$estimate, row$std.error))}
# }
# df_year_1_hungry_season <- df %>% 
#   filter(calendar_month < 4, year == 1)
# outcomes <- c("any_ganyu","work_hours","hire_ganyu","hire_hours","fam_hours")
# res <- map_dfr(outcomes, function(y) {
#       fml <- as.formula(paste(y, "~", rhs))
#       m   <- feols(fml, data = df_year_1_hungry_season, cluster = ~ vid)  # clustered SEs like cl(vid)
#       cse <- coef_se_on_treated(m)
#       tibble(outcome = y, b = cse[1], se = cse[2])
#     })
#   
# Y1coef_vec <- sprintf("%.3f", res$b)
# Y1std_vec  <- sprintf("(%.3f)", res$se)
#   
# Y1coef_row <- paste(c("Any loan treatment", Y1coef_vec), collapse = " & ")
# Y1std_row  <- paste(c("", Y1std_vec),       collapse = " & ")
#   
# cat(Y1coef_row, "\n")
# cat(Y1std_row,  "\n")
# cat(res$b/res$se)

######  panel A
df_year_1_hungry_season <- df %>% filter(calendar_month < 4, year == 1)

# --- helper: extract (b, se) for the "treatment" main effect -----------------
coef_se_on_treated <- function(m, on_missing = c("na", "error")) {
  on_missing <- match.arg(on_missing)
  ct <- coeftable(m)
  rn <- rownames(ct)
  if (!"treated" %in% rn) {
    if (on_missing == "error") stop("'treated' not found in coefficients.")
    return(c(b = NA_real_, se = NA_real_))
  }
  
  c(
    b  = unname(ct["treated", "Estimate"]),
    se = unname(ct["treated", "Std. Error"])
  )
}


qs <- 90:100
out_roots <- c("work_hours_p", "hire_hours_p", "fam_hours_p")

panelA_all <- map_dfr(qs, function(p) {
  outs <- paste0(out_roots, p)
  # outs <- c("work_hours", "hire_hours", "fam_hours") # test for matching the results in paper
  map_dfr(outs, function(y) {
    stopifnot(y %in% names(df_year_1_hungry_season))
    fml <- reformulate(rhs_panelA_hours, response = y)
    m   <- feols(fml, data = df_year_1_hungry_season, cluster = ~ vid)
    
    cse <- coef_se_on_treated(m)
    tibble(
      percentile = p,
      outcome    = y,
      b          = cse[1],
      se         = cse[2],
      z          = b / se,
      N          = nobs(m)
    )
  })
})
panelA_all
panelA_all <- panelA_all %>%
  mutate(z = b / se)

plot_df <- panelA_all %>%
  mutate(outcome_root = str_remove(outcome, "\\d+$"),
         outcome_root = recode(outcome_root,
                               work_hours_p = "Work hours",
                               hire_hours_p = "Hired hours",
                               fam_hours_p  = "Family hours"))

ggplot(plot_df, aes(x = percentile, y = z, color = outcome_root)) +
  geom_line() +
  geom_point() +
  labs(
    x = "Winsorization percentile (p)",
    y = "z-score = estimate / std. error",
    color = "Outcome",
    title = "Treatment z-scores across percentiles"
  ) +
  scale_x_continuous(breaks = 90:100) +
  theme_minimal(base_size = 12)
  

############## panel B
df_year_2_hungry_season <- df %>% 
  filter(calendar_month < 4, year == 2)

rhs_panelB_hours <- paste(
  "treated * treatedin1",                   # main + interaction terms
  "factor(monthyear)",                      # i.monthyear
  paste(controls, collapse = " + "),        # $controls
  paste(blocks,   collapse = " + "),        # $blocks
  sep = " + "
)


panelB_extract <- function(m){
  ct <- coeftable(m)  # columns: Estimate, Std. Error, t value, Pr(>|t|)
  take <- function(nm, label){
    if (!nm %in% rownames(ct)) return(tibble(row = label, b = NA_real_, se = NA_real_, z = NA_real_, p = NA_real_))
    tibble(
      row = label,
      b   = unname(ct[nm, "Estimate"]),
      se  = unname(ct[nm, "Std. Error"]),
      z   = unname(ct[nm, "t value"])
    )
  }
  nm1 <- "treated"
  nm2 <- "treatedin1"
  nm3 <- "treated:treatedin1"
  
  # linear combo using vcov to get se; p from normal approx (no dof() needed)
  bt <- coef(m); V <- vcov(m)
  L <- numeric(length(bt)); names(L) <- names(bt)
  for(nm in c(nm1, nm2, nm3)) if (nm %in% names(L)) L[nm] <- 1
  b4  <- sum(L * bt)
  se4 <- sqrt(as.numeric(t(L) %*% V %*% L))
  z4  <- b4 / se4
  
  bind_rows(
    take(nm1, "Any loan treatment"),
    take(nm2, "Treated in Y1"),
    take(nm3, "Loan × treated in Y1"),
    tibble(row = "Loan + Y1 + loan × Y1", b = b4, se = se4, z = z4)
  )
}

qs <- 90:100
out_roots <- c("work_hours_p","hire_hours_p","fam_hours_p")

panelB_all <- map_dfr(qs, function(p){
  outs <- paste0(out_roots, p)
  #outs <- c("work_hours", "hire_hours", "fam_hours") # test for matching the results in paper
  map_dfr(outs, function(y){
    stopifnot(y %in% names(df_year_2_hungry_season))
    fml <- as.formula(paste(y, "~", rhs_panelB_hours))
    m   <- feols(fml,
                 data    = df_year_2_hungry_season,
                 cluster = ~ vid)  # ensure adj is a logical scalar
    panelB_extract(m) %>% mutate(p = p, outcome = y)
  })
})
panelB_all

plotB_df <- panelB_all %>%
  mutate(
    percentile   = p,
    outcome_root = str_remove(outcome, "\\d+$"),
    outcome_root = recode(outcome_root,
                          work_hours_p = "Work hours",
                          hire_hours_p = "Hired hours",
                          fam_hours_p  = "Family hours"),
    row = factor(row, levels = c(
      "Any loan treatment",
      "Treated in Y1",
      "Loan × treated in Y1",
      "Loan + Y1 + loan × Y1"
    ))
  )

ggplot(plotB_df, aes(x = percentile, y = z, color = row, group = row)) +
  geom_line() +
  geom_point() +
  facet_wrap(~ outcome_root, ncol = 1, scales = "free_y") +
  scale_x_discrete(drop = FALSE) +               # keep all p even if missing
  labs(
    x = "Winsorization percentile (p)",
    y = "z-score = estimate / std. error",
    color = "Term",
    title = "Panel B: z-scores across percentiles by term"
  ) +
  theme_minimal(base_size = 12)

############### Panel C
df_all <- df %>%
  mutate(
    treatment  = factor(treatment, levels = c(1, 2, 3)),  # 1=control, 2=cash, 3=maize
    treatedin1 = as.integer(treatedin1),
    monthyear  = factor(monthyear)
  ) %>% 
  filter(calendar_month < 4)
df_all$treatment <- relevel(df_all$treatment, ref = "1")
rhs_panelC_hours <- paste(
  "treatment * treatedin1",         # i.treatment##i.treatedin1
  "monthyear",                      # i.monthyear
  paste(controls, collapse = " + "),
  paste(blocks,   collapse = " + "),
  sep = " + "
)

qs <- 90:100
out_roots <- c("work_hours_p","hire_hours_p","fam_hours_p")

panelC_all <- map_dfr(qs, function(p){
  outs <- paste0(out_roots, p)
  # outs <- c("work_hours", "hire_hours", "fam_hours") # test for matching the results in paper
  map_dfr(outs, function(y){
    stopifnot(y %in% names(df_all))
    # use the single outcome y on the LHS
    fml <- reformulate(rhs_panelC_hours, response = y)
    m <- feols(fml, data = df_all, cluster = ~ vid)
    avg_comparisons(
      m,
      variables   = "treatment",
      comparison  = "difference",
      vcov        = ~ vid,         # your exact argument
      type        = "response"
    ) |>
      as.data.frame() |>
      mutate(percentile = p, outcome = y)
  })
})
panelC_all
# Assume your Panel C tibble is called `panelC_all`
panelC_plotdf <- panelC_all %>%
  mutate(
    # map contrasts to arms
    contrast_norm = str_replace_all(contrast, "\\s+", ""),
    arm = case_when(
      contrast_norm == "2-1" ~ "Cash",
      contrast_norm == "3-1" ~ "Maize",
      TRUE ~ contrast
    ),
    arm = factor(arm, levels = c("Cash", "Maize")),
    
    # nicer outcome labels
    outcome_root = str_remove(outcome, "\\d+$"),
    outcome_root = recode(outcome_root,
                          work_hours_p = "Work hours",
                          hire_hours_p = "Hired hours",
                          fam_hours_p  = "Family hours"
    ),
    
    # discrete x-axis
    percentile = factor(percentile, levels = 90:100),
    
    # z-score (estimate / std.error)
    z = estimate / std.error
  )


ggplot(panelC_plotdf, aes(x = percentile, y = z, color = arm, group = arm)) +
  geom_line() +
  geom_point() +
  facet_wrap(~ outcome_root, ncol = 1, scales = "free_y") +
  scale_x_discrete(drop = FALSE) +
  labs(
    x = "Winsorization percentile (p)",
    y = "z-score = estimate / std. error",
    color = "Arm",
    title = "Panel C: z-scores across percentiles (Cash = 2–1, Maize = 3–1)"
  ) +
  theme_minimal(base_size = 12)

########### daily earnings panel A
df_year_1_hungry_season <- df %>% filter(calendar_month < 4, year == 1)

rhs_panelA_earnings <- paste(
  "treated + factor(monthyear) + cen_num_hh+ hours_day",
  paste(controls, collapse = " + "),
  paste(blocks,   collapse = " + "),
  sep = " + "
)

qs <- 90:100
out_roots <- c("daily_earnings_p")

panelA_earnings_all <- map_dfr(qs, function(p) {
  outs <- paste0(out_roots, p)
  # outs <- c("daily_earnings95", "daily_earnings99") #test for matching the results in paper
  map_dfr(outs, function(y) {
    stopifnot(y %in% names(df_year_1_hungry_season))
    fml <- reformulate(rhs_panelA_earnings, response = y)
    m   <- feols(fml, data = df_year_1_hungry_season, cluster = ~ vid)
    
    cse <- coef_se_on_treated(m)
    tibble(
      percentile = p,
      outcome    = y,
      b          = cse[1],
      se         = cse[2],
      z          = b / se,
      N          = nobs(m)
    )
  })
})
panelA_earnings_all

panelA_earnings_all <- panelA_earnings_all %>%
  mutate(z = b / se)

plot_df <- panelA_earnings_all %>%
  mutate(outcome_root = str_remove(outcome, "\\d+$"),
         outcome_root = recode(outcome_root,
                               daily_earnings_p = "Daily earnings"))

ggplot(plot_df, aes(x = percentile, y = z, color = outcome_root)) +
  geom_line() +
  geom_point() +
  labs(
    x = "Winsorization percentile (p)",
    y = "z-score = estimate / std. error",
    color = "Outcome",
    title = "Treatment z-scores across percentiles"
  ) +
  scale_x_continuous(breaks = 90:100) +
  theme_minimal(base_size = 12)

#################### daily earnings Panel B
df_year_2_hungry_season <- df %>% 
  filter(calendar_month < 4, year == 2)

rhs_panelB_earnings<- paste(
  "treated * treatedin1",                   # main + interaction terms
  "factor(monthyear)", 
  "hours_day",
  "cen_num_hh",
  paste(controls, collapse = " + "),        # $controls
  paste(blocks,   collapse = " + "),        # $blocks
  sep = " + "
)

panelB_extract <- function(m){
  ct <- coeftable(m)  # columns: Estimate, Std. Error, t value, Pr(>|t|)
  take <- function(nm, label){
    if (!nm %in% rownames(ct)) return(tibble(row = label, b = NA_real_, se = NA_real_, z = NA_real_, p = NA_real_))
    tibble(
      row = label,
      b   = unname(ct[nm, "Estimate"]),
      se  = unname(ct[nm, "Std. Error"]),
      z   = unname(ct[nm, "t value"])
    )
  }
  nm1 <- "treated"
  nm2 <- "treatedin1"
  nm3 <- "treated:treatedin1"
  
  # linear combo using vcov to get se; p from normal approx (no dof() needed)
  bt <- coef(m); V <- vcov(m)
  L <- numeric(length(bt)); names(L) <- names(bt)
  for(nm in c(nm1, nm2, nm3)) if (nm %in% names(L)) L[nm] <- 1
  b4  <- sum(L * bt)
  se4 <- sqrt(as.numeric(t(L) %*% V %*% L))
  z4  <- b4 / se4
  
  bind_rows(
    take(nm1, "Any loan treatment"),
    take(nm2, "Treated in Y1"),
    take(nm3, "Loan × treated in Y1"),
    tibble(row = "Loan + Y1 + loan × Y1", b = b4, se = se4, z = z4)
  )
}

qs <- 90:100
out_roots <- c("daily_earnings_p")

panelB_earnings_all <- map_dfr(qs, function(p){
  outs <- paste0(out_roots, p)
  # outs <- c("daily_earnings95", "daily_earnings99") #test for matching the results in paper
  map_dfr(outs, function(y){
    stopifnot(y %in% names(df_year_2_hungry_season))
    fml <- as.formula(paste(y, "~", rhs_panelB_earnings))
    m   <- feols(fml,
                 data    = df_year_2_hungry_season,
                 cluster = ~ vid)  # ensure adj is a logical scalar
    panelB_extract(m) %>% mutate(p = p, outcome = y)
  })
})
panelB_earnings_all

plotB_df <- panelB_earnings_all %>%
  mutate(
    percentile   = p,
    outcome_root = str_remove(outcome, "\\d+$"),
    outcome_root = recode(outcome_root,
                          daily_earings_p = "Daily earings"),
    row = factor(row, levels = c(
      "Any loan treatment",
      "Treated in Y1",
      "Loan × treated in Y1",
      "Loan + Y1 + loan × Y1"
    ))
  )

ggplot(plotB_df, aes(x = percentile, y = z, color = row, group = row)) +
  geom_line() +
  geom_point() +
  facet_wrap(~ outcome_root, ncol = 1, scales = "free_y") +
  scale_x_discrete(drop = FALSE) +               # keep all p even if missing
  labs(
    x = "Winsorization percentile (p)",
    y = "z-score = estimate / std. error",
    color = "Term",
    title = "Panel B: z-scores across percentiles by term"
  ) +
  theme_minimal(base_size = 12)

################## daily earnings Panel C
df_all <- df %>%
  mutate(
    treatment  = factor(treatment, levels = c(1, 2, 3)),  # 1=control, 2=cash, 3=maize
    treatedin1 = as.integer(treatedin1),
    monthyear  = factor(monthyear)
  ) %>% 
  filter(calendar_month < 4)
df_all$treatment <- relevel(df_all$treatment, ref = "1")
rhs_panelC_earnings <- paste(
  "treatment * treatedin1", 
  "monthyear",          
  "cen_num_hh",
  "hours_day",
  paste(controls, collapse = " + "),
  paste(blocks,   collapse = " + "),
  sep = " + "
)


qs <- 90:100
out_roots <- c("daily_earnings_p")

panelC_earnings_all <- map_dfr(qs, function(p){
  outs <- paste0(out_roots, p)
  # outs <- c("daily_earnings95", "daily_earnings99") #test for matching the results in paper
  map_dfr(outs, function(y){
    stopifnot(y %in% names(df_all))
    # use the single outcome y on the LHS
    fml <- reformulate(rhs_panelC_earnings, response = y)
    m <- feols(fml, data = df_all, cluster = ~ vid)
    avg_comparisons(
      m,
      variables   = "treatment",
      comparison  = "difference",
      vcov        = ~ vid,         # your exact argument
      type        = "response"
    ) |>
      as.data.frame() |>
      mutate(percentile = p, outcome = y, .before = 1)
  })
})
panelC_earnings_all
# Assume your Panel C tibble is called `panelC_all`
panelC_plotdf <- panelC_earnings_all %>%
  mutate(
    # map contrasts to arms
    contrast_norm = str_replace_all(contrast, "\\s+", ""),
    arm = case_when(
      contrast_norm == "2-1" ~ "Cash",
      contrast_norm == "3-1" ~ "Maize",
      TRUE ~ contrast
    ),
    arm = factor(arm, levels = c("Cash", "Maize")),
    
    # nicer outcome labels
    outcome_root = str_remove(outcome, "\\d+$"),
    outcome_root = recode(outcome_root,
                          daily_earings_p = "Daily earnings"
                      
    ),
    
    # discrete x-axis
    percentile = factor(percentile, levels = 90:100),
    
    # z-score (estimate / std.error)
    z = estimate / std.error
  )


ggplot(panelC_plotdf, aes(x = percentile, y = z, color = arm, group = arm)) +
  geom_line() +
  geom_point() +
  facet_wrap(~ outcome_root, ncol = 1, scales = "free_y") +
  scale_x_discrete(drop = FALSE) +
  labs(
    x = "Winsorization percentile (p)",
    y = "z-score = estimate / std. error",
    color = "Arm",
    title = "Panel C: z-scores across percentiles (Cash = 2–1, Maize = 3–1)"
  ) +
  theme_minimal(base_size = 12)
