library(haven)
library(dplyr)
library(fixest)  

# 1. Read in the Stata file
mhtemp <- read_dta("~/Desktop/winsorization_data/paper_being_winsorized/The Economic Impact of Depression Treatment in India- Evidence from Community-Based Provision of Pharmacotherapy/191402-V1/Processed/mhtemp.dta")

# 2. Winsorization helper (your function, unchanged)
winsorize <- function(x, p, highonly = FALSE, lowonly = FALSE) {
  if (all(is.na(x))) return(x)
  
  if (!highonly && !lowonly) {
    # symmetric: trim p in each tail
    qs <- quantile(x, probs = c(p, 1 - p), na.rm = TRUE, type = 7)
    x[x < qs[1]] <- qs[1]
    x[x > qs[2]] <- qs[2]
  } else if (highonly) {
    q <- quantile(x, probs = 1 - p, na.rm = TRUE, type = 7)
    x[x > q] <- q
  } else if (lowonly) {
    q <- quantile(x, probs = p, na.rm = TRUE, type = 7)
    x[x < q] <- q
  }
  x
}


percentile_list <- 0:100  

for (p in percentile_list) {
  percentile <- p / 1000       
  suffix     <- paste0("_p", p) 
  
  ## Per-capita income
  pc_e6 <- mhtemp$e6 / mhtemp$hhsize
  mhtemp[[paste0("pc_e6_w", suffix)]] <-
    winsorize(pc_e6, p = percentile) * 7 / 30
  
  
  ## Per-capita savings
  pc_e10 <- mhtemp$e10 / mhtemp$hhsize
  mhtemp[[paste0("pc_e10_w", suffix)]] <-
    winsorize(pc_e10, p = percentile, highonly = TRUE)
  
  ## Per-capita debt
  pc_e12 <- mhtemp$e12 / mhtemp$hhsize
  mhtemp[[paste0("pc_e12_w", suffix)]] <-
    winsorize(pc_e12, p = percentile, highonly = TRUE)
  
  ## Per-capita credit
  pc_e14 <- mhtemp$e14 / mhtemp$hhsize
  mhtemp[[paste0("pc_e14_w", suffix)]] <-
    winsorize(pc_e14, p = percentile, highonly = TRUE)
  
  ## Per-capita liquid net worth
  mhtemp[[paste0("pc_nw_w", suffix)]] <-
    mhtemp[[paste0("pc_e10_w", suffix)]] +
    mhtemp[[paste0("pc_e14_w", suffix)]] -
    mhtemp[[paste0("pc_e12_w", suffix)]]
}
old_pc_nw_w_bb <- mhtemp$pc_nw_w_bb
old_pc_nw_w_bm <- mhtemp$pc_nw_w_bm

library(dplyr)
library(rlang)

baseline_R <- function(df, var, id = "respid", round = "round") {
  # Make sure we have a data.frame
  df <- as.data.frame(df)
  
  # Pull needed columns as plain vectors
  var_vec   <- df[[var]]
  id_vec    <- df[[id]]
  round_vec <- df[[round]]
  
  # mm_tmp: 1 if var is missing at baseline (round == 1), 0 otherwise
  mm_tmp <- ifelse(round_vec == 1 & is.na(var_vec), 1L, 0L)
  
  # vv_tmp: var only at baseline, NA otherwise
  vv_tmp <- ifelse(round_vec == 1, as.numeric(var_vec), NA_real_)
  
  # By-id max(mm_tmp), like Stata's "bysort id: egen var_bm = max(mm)"
  bm_by_id <- tapply(mm_tmp, id_vec, max, na.rm = TRUE)
  
  # By-id max(vv_tmp) (ignoring NAs); if all NA, return NA
  bb_raw_by_id <- tapply(vv_tmp, id_vec, function(z) {
    z <- z[!is.na(z)]
    if (length(z) == 0) NA_real_ else max(z)
  })
  
  # Map back to rows
  bm     <- bm_by_id[match(id_vec, names(bm_by_id))]
  bb_raw <- bb_raw_by_id[match(id_vec, names(bb_raw_by_id))]
  
  bm <- as.integer(bm)
  # Stata: replace x_bb = 0 if x_bm == 1
  bb <- ifelse(bm == 1L, 0, bb_raw)
  
  # Write new columns into df
  df[[paste0(var, "_bm")]] <- bm
  df[[paste0(var, "_bb")]] <- bb
  
  df
}

percentile_list <- 0:100
base_vars <- c("pc_nw_w", "pc_e10_w", "pc_e14_w", "pc_e12_w")

for (p in percentile_list) {
  suffix <- paste0("_p", p)
  
  for (v in base_vars) {
    dep <- paste0(v, suffix)
    if (!dep %in% names(mhtemp)) next
    mhtemp <- baseline_R(mhtemp, var = dep, id = "respid", round = "round")
  }
}



strat_vars <- grep("^strat_", names(mhtemp), value = TRUE)

rhs_terms <- c(
  paste0("dur_trt_", 1:3),
  paste0("aft_trt_", 1:3),
  "dur",
  "aft",
  "pc_e12_w_bb",
  "pc_e12_w_bm",
  strat_vars
)

fml_pc_nw <- as.formula(
  paste("pc_e12_w ~", paste(rhs_terms, collapse = " + "))
)

dat_sub <- subset(mhtemp, round > 1)

mod_pc_nw <- feols(
  fml_pc_nw,
  data    = dat_sub,
  cluster = ~ villid   # matches cl(villid)
)

summary(mod_pc_nw)




library(fixest)
library(dplyr)
library(broom)

# which percentiles you created pc_nw_w_p? for
percentile_list <- 0:100   # change if you have a different range

# grab all strat_* controls once
strat_vars <- grep("^strat_", names(mhtemp), value = TRUE)

pc_nw_all <- list()

for (p in percentile_list) {
  dep    <- paste0("pc_nw_w_p", p)      # e.g. "pc_nw_w_p1"
  dep_bb <- paste0(dep, "_bb")          # "pc_nw_w_p1_bb"
  dep_bm <- paste0(dep, "_bm")          # "pc_nw_w_p1_bm"
  
  # skip if this percentile wasn't created
  if (!all(c(dep, dep_bb, dep_bm) %in% names(mhtemp))) next
  
  rhs_terms <- c(
    paste0("dur_trt_", 1:3),
    paste0("aft_trt_", 1:3),
    "dur",
    "aft",
    dep_bb,
    dep_bm,
    strat_vars
  )
  
  fml_pc_nw <- as.formula(
    paste(dep, "~", paste(rhs_terms, collapse = " + "))
  )
  
  dat_sub <- subset(mhtemp, round > 1)
  
  mod_pc_nw <- feols(
    fml_pc_nw,
    data    = dat_sub,
    cluster = ~ villid
  )
  
  # store treatment effects for this percentile
  pc_nw_all[[as.character(p)]] <- tidy(mod_pc_nw) %>%
    filter(grepl("^dur_trt_|^aft_trt_", term)) %>%
    mutate(percentile = p, depvar = dep)
}

pc_nw_results <- bind_rows(pc_nw_all)
pc_nw_results

library(fixest)
library(dplyr)
library(broom)

percentile_list <- 0:100
base_vars       <- c("pc_nw_w", "pc_e10_w", "pc_e12_w", "pc_e14_w") # "pc_e14_w" not working

# grab all strat_* controls once
strat_vars <- grep("^strat_", names(mhtemp), value = TRUE)

all_results <- list()
i <- 1

for (v in base_vars) {
  print(v)
  for (p in percentile_list) {
    dep    <- paste0(v, "_p", p)      # e.g. "pc_e10_w_p3"
    dep_bb <- paste0(dep, "_bb")      # e.g. "pc_e10_w_p3_bb"
    dep_bm <- paste0(dep, "_bm")      # e.g. "pc_e10_w_p3_bm"
    
    # skip if this percentile/variable combo doesn't exist
    if (!all(c(dep, dep_bb, dep_bm) %in% names(mhtemp))) next
    
    rhs_terms <- c(
      paste0("dur_trt_", 1:3),
      paste0("aft_trt_", 1:3),
      "dur",
      "aft",
      dep_bb,
      dep_bm,
      strat_vars
    )
    
    fml <- as.formula(
      paste(dep, "~", paste(rhs_terms, collapse = " + "))
    )
    
    dat_sub <- subset(mhtemp, round > 1)
    
    mod <- feols(
      fml,
      data    = dat_sub,
      cluster = ~ villid
    )
    
    all_results[[i]] <- tidy(mod) %>%
      filter(grepl("^dur_trt_|^aft_trt_", term)) %>%   # treatment effects only
      mutate(
        percentile = p,
        depvar     = dep,
        base_var   = v
      )
    
    i <- i + 1
  }
}

b5_results <- bind_rows(all_results)
col_1 <- b5_results %>% filter(base_var == "pc_nw_w")

library(ggplot2)

ggplot(col_1,
       aes(x = percentile, y = estimate / std.error, col = term)) +
  geom_line() +
  labs(
    x = "Winsorization percentile",
    y = "t-stat for PC/LA (dur_trt_1)",
    title = "PC/LA effect on Net Savings vs winsorization level"
  ) +
  theme_minimal()

col_1_row_1 <- b5_results %>% filter(base_var == "pc_nw_w", 
                                     term == "dur_trt_1")
ggplot(col_1_row_1,
       aes(x = percentile/1000*100, y = estimate / std.error)) +
  geom_line() +
  geom_vline(xintercept = 0.05*100, linetype = "dashed") +         # 3.7%
  geom_hline(yintercept = 1194/1322, linetype = "dotted") +
  labs(
    x = "Winsorization percentile",
    y = "t-stat for PC/LA (dur_trt_1)",
    title = "PC/LA effect on Net Savings vs winsorization level"
  ) +
  theme_minimal()

col_1_row_2 <- b5_results %>% filter(base_var == "pc_nw_w", 
                                     term == "dur_trt_2")
ggplot(col_1_row_2,
       aes(x = percentile/1000*100, y = estimate / std.error)) +
  geom_line() +
  geom_vline(xintercept = 0.05*100, linetype = "dashed") +         # 3.7%
  geom_hline(yintercept = 1986/1130, linetype = "dotted") +
  labs(
    x = "Winsorization percentile",
    y = "t-stat for PC/LA (dur_trt_2)",
    title = "PC/LA effect on Net Savings vs winsorization level"
  ) +
  theme_minimal()

col_1_row_3 <- b5_results %>% filter(base_var == "pc_nw_w", 
                                     term == "dur_trt_3")
ggplot(col_1_row_3,
       aes(x = percentile/1000*100, y = estimate / std.error)) +
  geom_line() +
  geom_vline(xintercept = 0.05*100, linetype = "dashed") +         # 3.7%
  geom_hline(yintercept = 2553/1159, linetype = "dotted") +
  labs(
    x = "Winsorization percentile",
    y = "t-stat for PC/LA (dur_trt_3)",
    title = "PC/LA effect on Net Savings vs winsorization level"
  ) +
  theme_minimal()


col_1_row_4 <- b5_results %>% filter(base_var == "pc_nw_w", 
                                     term == "aft_trt_1")
ggplot(col_1_row_4,
       aes(x = percentile/1000*100, y = estimate / std.error)) +
  geom_line() +
  geom_vline(xintercept = 0.05*100, linetype = "dashed") +         # 3.7%
  geom_hline(yintercept = -2222/1540, linetype = "dotted") +
  labs(
    x = "Winsorization percentile",
    y = "t-stat for PC/LA (aft_trt_1)",
    title = "PC/LA effect on Net Savings vs winsorization level"
  ) +
  theme_minimal()

col_1_row_5 <- b5_results %>% filter(base_var == "pc_nw_w", 
                                     term == "aft_trt_2")
ggplot(col_1_row_5,
       aes(x = percentile/1000*100, y = estimate / std.error)) +
  geom_line() +
  geom_vline(xintercept = 0.05*100, linetype = "dashed") +         # 3.7%
  geom_hline(yintercept = -777/1457, linetype = "dotted") +
  labs(
    x = "Winsorization percentile",
    y = "t-stat for PC/LA (aft_trt_2)",
    title = "PC/LA effect on Net Savings vs winsorization level"
  ) +
  theme_minimal()

col_1_row_6 <- b5_results %>% filter(base_var == "pc_nw_w", 
                                     term == "aft_trt_3")
ggplot(col_1_row_6,
       aes(x = percentile/1000*100, y = estimate / std.error)) +
  geom_line() +
  geom_vline(xintercept = 0.05*100, linetype = "dashed") +         # 3.7%
  geom_hline(yintercept = 3087/1064, linetype = "dotted") +
  labs(
    x = "Winsorization percentile",
    y = "t-stat for PC/LA (aft_trt_3)",
    title = "PC/LA effect on Net Savings vs winsorization level"
  ) +
  theme_minimal()



col_3 <- b5_results %>% filter(base_var == "pc_e10_w")
ggplot(col_3,
       aes(x = percentile, y = estimate / std.error, col = term)) +
  geom_line() +
  labs(
    x = "Winsorization percentile",
    y = "t-stat for PC/LA (dur_trt_1)",
    title = "PC/LA effect on Net Savings vs winsorization level"
  ) +
  theme_minimal()

col_3_row_1 <- b5_results %>% filter(base_var == "pc_e10_w", term == "dur_trt_1")
ggplot(col_3_row_1,
       aes(x = percentile/1000*100, y = estimate / std.error)) +
  geom_line() +
  geom_vline(xintercept = 0.025*100, linetype = "dashed") +         
  geom_hline(yintercept = -88/46, linetype = "dotted") +
  labs(
    x = "Winsorization percentile",
    y = "t-stat for PC/LA (dur_trt_1)",
    title = "PC/LA effect on Savings vs winsorization level"
  ) +
  theme_minimal()

col_3_row_2 <- b5_results %>% filter(base_var == "pc_e10_w", term == "dur_trt_2")
ggplot(col_3_row_2,
       aes(x = percentile/1000*100, y = estimate / std.error)) +
  geom_line() +
  geom_vline(xintercept = 0.025*100, linetype = "dashed") +         
  geom_hline(yintercept = -29/58, linetype = "dotted") +
  labs(
    x = "Winsorization percentile",
    y = "t-stat for PC/LA (dur_trt_2)",
    title = "PC/LA effect on Savings vs winsorization level"
  ) +
  theme_minimal()


col_3_row_3 <- b5_results %>% filter(base_var == "pc_e10_w", term == "dur_trt_3")
ggplot(col_3_row_3,
       aes(x = percentile/1000*100, y = estimate / std.error)) +
  geom_line() +
  geom_vline(xintercept = 0.025*100, linetype = "dashed") +         
  geom_hline(yintercept = -60/50, linetype = "dotted") +
  labs(
    x = "Winsorization percentile",
    y = "t-stat for PC/LA (dur_trt_3)",
    title = "PC/LA effect on Savings vs winsorization level"
  ) +
  theme_minimal()

col_3_row_4 <- b5_results %>% filter(base_var == "pc_e10_w", term == "aft_trt_1")
ggplot(col_3_row_4,
       aes(x = percentile/1000*100, y = estimate / std.error)) +
  geom_line() +
  geom_vline(xintercept = 0.025*100, linetype = "dashed") +         
  geom_hline(yintercept = -62/55, linetype = "dotted") +
  labs(
    x = "Winsorization percentile",
    y = "t-stat for PC/LA (aft_trt_1)",
    title = "PC/LA effect on Savings vs winsorization level"
  ) +
  theme_minimal()

col_3_row_5 <- b5_results %>% filter(base_var == "pc_e10_w", term == "aft_trt_2")
ggplot(col_3_row_5,
       aes(x = percentile/1000*100, y = estimate / std.error)) +
  geom_line() +
  geom_vline(xintercept = 0.025*100, linetype = "dashed") +         
  geom_hline(yintercept = -45/51, linetype = "dotted") +
  labs(
    x = "Winsorization percentile",
    y = "t-stat for PC/LA (aft_trt_2)",
    title = "PC/LA effect on Savings vs winsorization level"
  ) +
  theme_minimal()

col_3_row_6 <- b5_results %>% filter(base_var == "pc_e10_w", term == "aft_trt_3")
ggplot(col_3_row_6,
       aes(x = percentile/1000*100, y = estimate / std.error)) +
  geom_line() +
  geom_vline(xintercept = 0.025*100, linetype = "dashed") +         
  geom_hline(yintercept = 13/59, linetype = "dotted") +
  labs(
    x = "Winsorization percentile",
    y = "t-stat for PC/LA (aft_trt_3)",
    title = "PC/LA effect on Savings vs winsorization level"
  ) +
  theme_minimal()





col_7 <- b5_results %>% filter(base_var == "pc_e12_w")
ggplot(col_7,
       aes(x = percentile, y = estimate / std.error, col = term)) +
  geom_line() +
  labs(
    x = "Winsorization percentile",
    y = "t-stat for PC/LA (dur_trt_1)",
    title = "PC/LA effect on Net Savings vs winsorization level"
  ) +
  theme_minimal()

col_7_row_1 <- b5_results %>% filter(base_var == "pc_e12_w", term == "dur_trt_1")
ggplot(col_7_row_1,
       aes(x = percentile/1000*100, y = estimate / std.error)) +
  geom_vline(xintercept = 0.025*100, linetype = "dashed") +         
  geom_hline(yintercept = -1417/1283, linetype = "dotted") +
  geom_line() +
  labs(
    x = "Winsorization percentile",
    y = "t-stat for PC/LA (dur_trt_1)",
    title = "PC/LA effect on Debt vs winsorization level"
  ) +
  theme_minimal()

col_7_row_2 <- b5_results %>% filter(base_var == "pc_e12_w", term == "dur_trt_2")
ggplot(col_7_row_2,
       aes(x = percentile/1000*100, y = estimate / std.error)) +
  geom_vline(xintercept = 0.025*100, linetype = "dashed") +         
  geom_hline(yintercept = -1923/1122, linetype = "dotted") +
  geom_line() +
  labs(
    x = "Winsorization percentile",
    y = "t-stat for PC/LA (dur_trt_2)",
    title = "PC/LA effect on Debt vs winsorization level"
  ) +
  theme_minimal()

col_7_row_3 <- b5_results %>% filter(base_var == "pc_e12_w", term == "dur_trt_3")
ggplot(col_7_row_3,
       aes(x = percentile/1000*100, y = estimate / std.error)) +
  geom_vline(xintercept = 0.025*100, linetype = "dashed") +         
  geom_hline(yintercept = -2642/1146, linetype = "dotted") +
  geom_line() +
  labs(
    x = "Winsorization percentile",
    y = "t-stat for PC/LA (dur_trt_3)",
    title = "PC/LA effect on Debt vs winsorization level"
  ) +
  theme_minimal()

col_7_row_4 <- b5_results %>% filter(base_var == "pc_e12_w", term == "aft_trt_1")
ggplot(col_7_row_4,
       aes(x = percentile/1000*100, y = estimate / std.error)) +
  geom_vline(xintercept = 0.025*100, linetype = "dashed") +         
  geom_hline(yintercept = 1848/1544, linetype = "dotted") +
  geom_line() +
  labs(
    x = "Winsorization percentile",
    y = "t-stat for PC/LA (aft_trt_1)",
    title = "PC/LA effect on Debt vs winsorization level"
  ) +
  theme_minimal()


col_7_row_5 <- b5_results %>% filter(base_var == "pc_e12_w", term == "aft_trt_2")
ggplot(col_7_row_5,
       aes(x = percentile/1000*100, y = estimate / std.error)) +
  geom_vline(xintercept = 0.025*100, linetype = "dashed") +         
  geom_hline(yintercept = 701/1418, linetype = "dotted") +
  geom_line() +
  labs(
    x = "Winsorization percentile",
    y = "t-stat for PC/LA (aft_trt_2)",
    title = "PC/LA effect on Debt vs winsorization level"
  ) +
  theme_minimal()

col_7_row_6 <- b5_results %>% filter(base_var == "pc_e12_w", term == "aft_trt_3")
ggplot(col_7_row_6,
       aes(x = percentile/1000*100, y = estimate / std.error)) +
  geom_vline(xintercept = 0.025*100, linetype = "dashed") +         
  geom_hline(yintercept = -3077/1058, linetype = "dotted") +
  geom_line() +
  labs(
    x = "Winsorization percentile",
    y = "t-stat for PC/LA (aft_trt_3)",
    title = "PC/LA effect on Debt vs winsorization level"
  ) +
  theme_minimal()


col_5 <- b5_results %>% filter(base_var == "pc_e14_w") # note only up to 0.033%, as it will fail after 0.034% percentile
ggplot(col_5,
       aes(x = percentile, y = estimate / std.error, col = term)) +
  geom_line() +
  labs(
    x = "Winsorization percentile",
    y = "t-stat for PC/LA (dur_trt_1)",
    title = "PC/LA effect on Net Savings vs winsorization level"
  ) +
  theme_minimal()

col_5_row_1 <- b5_results %>% filter(base_var == "pc_e14_w", term == "dur_trt_1") # note only up to 0.033%, as it will fail after 0.034% percentile
ggplot(col_5_row_1,
       aes(x = percentile/1000*100, y = estimate / std.error)) +
  geom_vline(xintercept = 0.005*100, linetype = "dashed") +         
  geom_hline(yintercept = -5.5/91, linetype = "dotted") +
  geom_line() +
  labs(
    x = "Winsorization percentile",
    y = "t-stat for PC/LA (dur_trt_1)",
    title = "PC/LA effect on Credit vs winsorization level"
  ) +
  theme_minimal()

col_5_row_2 <- b5_results %>% filter(base_var == "pc_e14_w", term == "dur_trt_2") # note only up to 0.033%, as it will fail after 0.034% percentile
ggplot(col_5_row_2,
       aes(x = percentile/1000*100, y = estimate / std.error)) +
  geom_vline(xintercept = 0.005*100, linetype = "dashed") +         
  geom_hline(yintercept = 53/105, linetype = "dotted") +
  geom_line() +
  labs(
    x = "Winsorization percentile",
    y = "t-stat for PC/LA (dur_trt_2)",
    title = "PC/LA effect on Credit vs winsorization level"
  ) +
  theme_minimal()

col_5_row_3 <- b5_results %>% filter(base_var == "pc_e14_w", term == "dur_trt_3") # note only up to 0.033%, as it will fail after 0.034% percentile
ggplot(col_5_row_3,
       aes(x = percentile/1000*100, y = estimate / std.error)) +
  geom_vline(xintercept = 0.005*100, linetype = "dashed") +         
  geom_hline(yintercept = -59/77, linetype = "dotted") +
  geom_line() +
  labs(
    x = "Winsorization percentile",
    y = "t-stat for PC/LA (dur_trt_3)",
    title = "PC/LA effect on Credit vs winsorization level"
  ) +
  theme_minimal()

col_5_row_4 <- b5_results %>% filter(base_var == "pc_e14_w", term == "aft_trt_1") # note only up to 0.033%, as it will fail after 0.034% percentile
ggplot(col_5_row_4 ,
       aes(x = percentile/1000*100, y = estimate / std.error)) +
  geom_vline(xintercept = 0.005*100, linetype = "dashed") +         
  geom_hline(yintercept = -270/82, linetype = "dotted") +
  geom_line() +
  labs(
    x = "Winsorization percentile",
    y = "t-stat for PC/LA (aft_trt_1)",
    title = "PC/LA effect on Credit vs winsorization level"
  ) +
  theme_minimal()

col_5_row_5 <- b5_results %>% filter(base_var == "pc_e14_w", term == "aft_trt_2") # note only up to 0.033%, as it will fail after 0.034% percentile
ggplot(col_5_row_5 ,
       aes(x = percentile/1000*100, y = estimate / std.error)) +
  geom_vline(xintercept = 0.005*100, linetype = "dashed") +         
  geom_hline(yintercept = -52/123, linetype = "dotted") +
  geom_line() +
  labs(
    x = "Winsorization percentile",
    y = "t-stat for PC/LA (aft_trt_2)",
    title = "PC/LA effect on Credit vs winsorization level"
  ) +
  theme_minimal()

col_5_row_6 <- b5_results %>% filter(base_var == "pc_e14_w", term == "aft_trt_3") # note only up to 0.033%, as it will fail after 0.034% percentile
ggplot(col_5_row_6 ,
       aes(x = percentile/1000*100, y = estimate / std.error)) +
  geom_vline(xintercept = 0.005*100, linetype = "dashed") +         
  geom_hline(yintercept = -75/121, linetype = "dotted") +
  geom_line() +
  labs(
    x = "Winsorization percentile",
    y = "t-stat for PC/LA (aft_trt_3)",
    title = "PC/LA effect on Credit vs winsorization level"
  ) +
  theme_minimal()




### lasso covariate
# Unable to replicate as some of the variables are not winsorized in the code. They are just given.

# Table 3
mhtemp <- read_dta("~/Desktop/winsorization_data/paper_being_winsorized/The Economic Impact of Depression Treatment in India- Evidence from Community-Based Provision of Pharmacotherapy/191402-V1/Processed/mhtemp.dta")
earn <- mhtemp$earn

# manually winsorized does not match the winsorized they 
# they are actual 0.04 winsorization
earn_w_0.037 <- winsorize(earn, 0.037)
earn_w_0.037 <- na.omit(earn_w_0.037)
max(earn_w_0.037)
min(earn_w_0.037)
max(mhtemp$earn_w)
min(mhtemp$earn_w)


earn_unpaid <- mhtemp$earn_unpaid
earn_unpaid_0.02 <- winsorize(earn_unpaid, 0.02)
max(earn_unpaid_0.02)
min(earn_unpaid_0.02)
max(mhtemp$earn_unpaid_w)
min(mhtemp$earn_unpaid_w)

# mhtemp$earnings <- earn_w_0.037 +earn_unpaid_0.02
# verification
strat_vars <- grep("^strat_", names(mhtemp), value = TRUE)

rhs_terms <- c(
  paste0("dur_trt_", 1:3),
  paste0("aft_trt_", 1:3),
  "dur",
  "aft",
  "earnings_bb",
  "earnings_bm",
  strat_vars
)

fml <- as.formula(
  paste("earnings ~", paste(rhs_terms, collapse = " + "))
)

dat_sub <- subset(mhtemp, round > 1)

mod <- feols(
  fml,
  data    = dat_sub,
  cluster = ~ villid   # matches cl(villid)
)

summary(mod)


percentile_list <- 0:100 

for (p in percentile_list) {
  percentile <- p / 1000       
  suffix     <- paste0("_p", p)
  earn <- mhtemp$earn
  mhtemp[[paste0("earn_w", suffix)]] <- winsorize(earn, p = percentile)
  earn_unpaid <- mhtemp$earn_unpaid
  mhtemp[[paste0("earn_unpaid_w", suffix)]] <- winsorize(earn_unpaid, p = percentile)
  mhtemp[[paste0("earnings_w", suffix)]] <- mhtemp[[paste0("earn_w", suffix)]] + mhtemp[[paste0("earn_unpaid_w", suffix)]]
}

percentile_list <- 0:100
base_vars <- c("earnings_w")

for (p in percentile_list) {
  suffix <- paste0("_p", p)
  
  for (v in base_vars) {
    dep <- paste0(v, suffix)
    if (!dep %in% names(mhtemp)) next
    mhtemp <- baseline_R(mhtemp, var = dep, id = "respid", round = "round")
  }
}

library(fixest)
library(dplyr)
library(broom)


percentile_list <- 0:100
base_vars       <- c("earnings_w") # "pc_e14_w" not working

# grab all strat_* controls once
strat_vars <- grep("^strat_", names(mhtemp), value = TRUE)

all_results <- list()
i <- 1

for (v in base_vars) {
  for (p in percentile_list) {
    dep    <- paste0(v, "_p", p)      # e.g. "pc_e10_w_p3"
    dep_bb <- paste0(dep, "_bb")      # e.g. "pc_e10_w_p3_bb"
    dep_bm <- paste0(dep, "_bm")      # e.g. "pc_e10_w_p3_bm"
    
    # skip if this percentile/variable combo doesn't exist
    if (!all(c(dep, dep_bb, dep_bm) %in% names(mhtemp))) next
    
    rhs_terms <- c(
      paste0("dur_trt_", 1:3),
      paste0("aft_trt_", 1:3),
      "dur",
      "aft",
      dep_bb,
      dep_bm,
      strat_vars
    )
    
    fml <- as.formula(
      paste(dep, "~", paste(rhs_terms, collapse = " + "))
    )
    
    dat_sub <- subset(mhtemp, round > 1)
    
    mod <- feols(
      fml,
      data    = dat_sub,
      cluster = ~ villid
    )
    
    all_results[[i]] <- tidy(mod) %>%
      filter(grepl("^dur_trt_|^aft_trt_", term)) %>%   # treatment effects only
      mutate(
        percentile = p,
        depvar     = dep,
        base_var   = v
      )
    
    i <- i + 1
  }
}
results <- bind_rows(all_results)


ggplot(results,
       aes(x = percentile/1000*100, y = estimate / std.error)) +
  geom_line() +
  labs(
    x = "Winsorization percentile",
    y = "t-stat for PC/LA (dur_trt_1)",
    title = "PC/LA effect on Net Savings vs winsorization level"
  ) +
  theme_minimal()

# vary earn_w only
mhtemp <-read_dta("~/Desktop/winsorization_data/paper_being_winsorized/The Economic Impact of Depression Treatment in India- Evidence from Community-Based Provision of Pharmacotherapy/191402-V1/Processed/mhtemp.dta")
percentile_list <- 0:100  

for (p in percentile_list) {
  percentile <- p / 1000       
  suffix     <- paste0("_p", p)
  earn <- mhtemp$earn
  mhtemp[[paste0("earn_w", suffix)]] <- winsorize(earn, p = percentile)
  earn_unpaid <- mhtemp$earn_unpaid

  mhtemp[[paste0("earnings_w", suffix)]] <- mhtemp[[paste0("earn_w", suffix)]] + mhtemp$earn_unpaid_w
}

percentile_list <- 0:100
base_vars <- c("earnings_w")

for (p in percentile_list) {
  suffix <- paste0("_p", p)
  
  for (v in base_vars) {
    dep <- paste0(v, suffix)
    if (!dep %in% names(mhtemp)) next
    mhtemp <- baseline_R(mhtemp, var = dep, id = "respid", round = "round")
  }
}

library(fixest)
library(dplyr)
library(broom)


percentile_list <- 0:100
base_vars       <- c("earnings_w") # "pc_e14_w" not working

# grab all strat_* controls once
strat_vars <- grep("^strat_", names(mhtemp), value = TRUE)

all_results <- list()
i <- 1

for (v in base_vars) {
  for (p in percentile_list) {
    dep    <- paste0(v, "_p", p)      # e.g. "pc_e10_w_p3"
    dep_bb <- paste0(dep, "_bb")      # e.g. "pc_e10_w_p3_bb"
    dep_bm <- paste0(dep, "_bm")      # e.g. "pc_e10_w_p3_bm"
    
    # skip if this percentile/variable combo doesn't exist
    if (!all(c(dep, dep_bb, dep_bm) %in% names(mhtemp))) next
    
    rhs_terms <- c(
      paste0("dur_trt_", 1:3),
      paste0("aft_trt_", 1:3),
      "dur",
      "aft",
      dep_bb,
      dep_bm,
      strat_vars
    )
    
    fml <- as.formula(
      paste(dep, "~", paste(rhs_terms, collapse = " + "))
    )
    
    dat_sub <- subset(mhtemp, round > 1)
    
    mod <- feols(
      fml,
      data    = dat_sub,
      cluster = ~ villid
    )
    
    all_results[[i]] <- tidy(mod) %>%
      filter(grepl("^dur_trt_|^aft_trt_", term)) %>%   # treatment effects only
      mutate(
        percentile = p,
        depvar     = dep,
        base_var   = v
      )
    
    i <- i + 1
  }
}
results <- bind_rows(all_results)
col_1_row_1 <- results %>% 
  filter(term == "dur_trt_1")

ggplot(col_1_row_1, aes(x = percentile/1000*100, y = estimate / std.error)) +
  geom_line() +
  geom_vline(xintercept = 0.037*100, linetype = "dashed") +         # 3.7%
  geom_hline(yintercept = 37.9/61.3, linetype = "dotted") +
  labs(
    x = "Winsorization percentile",
    y = "t-stat for PC/LA (dur_trt_1)",
    title = "PC/LA effect on Earnings vs winsorization level"
  ) +
  theme_minimal()

col_1_row_2 <-  results %>% 
  filter(term == "dur_trt_2")

ggplot(col_1_row_2, aes(x = percentile/1000*100, y = estimate / std.error)) +
  geom_line() +
  geom_vline(xintercept = 0.037*100, linetype = "dashed") +         # 3.7%
  geom_hline(yintercept = -65.4/54.2, linetype = "dotted") +
  labs(
    x = "Winsorization percentile",
    y = "t-stat for PC/LA (dur_trt_2)",
    title = "PC/LA effect on Earnings vs winsorization level"
  ) +
  theme_minimal()


col_1_row_3 <-  results %>% 
  filter(term == "dur_trt_3")

ggplot(col_1_row_3, aes(x = percentile/1000*100, y = estimate / std.error)) +
  geom_line() +
  geom_vline(xintercept = 0.037*100, linetype = "dashed") +         # 3.7%
  geom_hline(yintercept = -32.8/61.8, linetype = "dotted") +
  labs(
    x = "Winsorization percentile",
    y = "t-stat for PC/LA (dur_trt_3)",
    title = "PC/LA effect on Earnings vs winsorization level"
  ) +
  theme_minimal()

col_1_row_4 <-  results %>% 
  filter(term == "aft_trt_1")

ggplot(col_1_row_4, aes(x = percentile/1000*100, y = estimate / std.error)) +
  geom_line() +
  geom_vline(xintercept = 0.037*100, linetype = "dashed") +         # 3.7%
  geom_hline(yintercept = 38.7/67.3, linetype = "dotted") +
  labs(
    x = "Winsorization percentile",
    y = "t-stat for PC/LA (aft_trt_1)",
    title = "PC/LA effect on Earnings vs winsorization level"
  ) +
  theme_minimal()

col_1_row_5 <-  results %>% 
  filter(term == "aft_trt_2")

ggplot(col_1_row_5, aes(x = percentile/1000*100, y = estimate / std.error)) +
  geom_line() +
  geom_vline(xintercept = 0.037*100, linetype = "dashed") +         # 3.7%
  geom_hline(yintercept = -52.8/61.0, linetype = "dotted") +
  labs(
    x = "Winsorization percentile",
    y = "t-stat for PC/LA (aft_trt_2)",
    title = "PC/LA effect on Earnings vs winsorization level"
  ) +
  theme_minimal()

col_1_row_6 <-  results %>% 
  filter(term == "aft_trt_3")

ggplot(col_1_row_6, aes(x = percentile/1000*100, y = estimate / std.error)) +
  geom_line() +
  geom_vline(xintercept = 0.037*100, linetype = "dashed") +         # 3.7%
  geom_hline(yintercept = 47.9/62.2, linetype = "dotted") +
  labs(
    x = "Winsorization percentile",
    y = "t-stat for PC/LA (aft_trt_3)",
    title = "PC/LA effect on Earnings vs winsorization level"
  ) +
  theme_minimal()

#######3 vary earn_unpaid_w only
mhtemp <- read_dta("~/Desktop/winsorization_data/paper_being_winsorized/The Economic Impact of Depression Treatment in India- Evidence from Community-Based Provision of Pharmacotherapy/191402-V1/Processed/mhtemp.dta")
percentile_list <- 0:100  

for (p in percentile_list) {
  percentile <- p / 1000       
  suffix     <- paste0("_p", p)
  earn_unpaid <- mhtemp$earn_unpaid
  mhtemp[[paste0("earn_unpaid_w", suffix)]] <- winsorize(earn_unpaid, p = percentile)
  mhtemp[[paste0("earnings_w", suffix)]] <- mhtemp$earn_w + mhtemp[[paste0("earn_unpaid_w", suffix)]]

}

percentile_list <- 0:100
base_vars <- c("earnings_w")

for (p in percentile_list) {
  suffix <- paste0("_p", p)
  
  for (v in base_vars) {
    dep <- paste0(v, suffix)
    if (!dep %in% names(mhtemp)) next
    mhtemp <- baseline_R(mhtemp, var = dep, id = "respid", round = "round")
  }
}

library(fixest)
library(dplyr)
library(broom)


percentile_list <- 0:100
base_vars       <- c("earnings_w") 

# grab all strat_* controls once
strat_vars <- grep("^strat_", names(mhtemp), value = TRUE)

all_results <- list()
i <- 1

for (v in base_vars) {
  for (p in percentile_list) {
    dep    <- paste0(v, "_p", p)      # e.g. "pc_e10_w_p3"
    dep_bb <- paste0(dep, "_bb")      # e.g. "pc_e10_w_p3_bb"
    dep_bm <- paste0(dep, "_bm")      # e.g. "pc_e10_w_p3_bm"
    
    # skip if this percentile/variable combo doesn't exist
    if (!all(c(dep, dep_bb, dep_bm) %in% names(mhtemp))) next
    
    rhs_terms <- c(
      paste0("dur_trt_", 1:3),
      paste0("aft_trt_", 1:3),
      "dur",
      "aft",
      dep_bb,
      dep_bm,
      strat_vars
    )
    
    fml <- as.formula(
      paste(dep, "~", paste(rhs_terms, collapse = " + "))
    )
    
    dat_sub <- subset(mhtemp, round > 1)
    
    mod <- feols(
      fml,
      data    = dat_sub,
      cluster = ~ villid
    )
    
    all_results[[i]] <- tidy(mod) %>%
      filter(grepl("^dur_trt_|^aft_trt_", term)) %>%   # treatment effects only
      mutate(
        percentile = p,
        depvar     = dep,
        base_var   = v
      )
    
    i <- i + 1
  }
}
results <- bind_rows(all_results)
col_1_row_1 <- results %>% 
  filter(term == "dur_trt_1")

ggplot(col_1_row_1, aes(x = percentile/1000*100, y = estimate / std.error)) +
  geom_line() +
  geom_vline(xintercept = 0.02*100, linetype = "dashed") +        
  geom_hline(yintercept = 37.9/61.3, linetype = "dotted") +
  labs(
    x = "Winsorization percentile",
    y = "t-stat for PC/LA (dur_trt_1)",
    title = "PC/LA effect on Earnings vs winsorization level"
  ) +
  theme_minimal()

col_1_row_2 <-  results %>% 
  filter(term == "dur_trt_2")

ggplot(col_1_row_2, aes(x = percentile/1000*100, y = estimate / std.error)) +
  geom_line() +
  geom_vline(xintercept = 0.02*100, linetype = "dashed") +         # 3.7%
  geom_hline(yintercept = -65.4/54.2, linetype = "dotted") +
  labs(
    x = "Winsorization percentile",
    y = "t-stat for PC/LA (dur_trt_2)",
    title = "PC/LA effect on Earningss vs winsorization level"
  ) +
  theme_minimal()


col_1_row_3 <-  results %>% 
  filter(term == "dur_trt_3")

ggplot(col_1_row_3, aes(x = percentile/1000*100, y = estimate / std.error)) +
  geom_line() +
  geom_vline(xintercept = 0.02*100, linetype = "dashed") +         # 3.7%
  geom_hline(yintercept = -32.8/61.8, linetype = "dotted") +
  labs(
    x = "Winsorization percentile",
    y = "t-stat for PC/LA (dur_trt_3)",
    title = "PC/LA effect on Earningss vs winsorization level"
  ) +
  theme_minimal()

col_1_row_4 <-  results %>% 
  filter(term == "aft_trt_1")

ggplot(col_1_row_4, aes(x = percentile/1000*100, y = estimate / std.error)) +
  geom_line() +
  geom_vline(xintercept = 0.02*100, linetype = "dashed") +         
  geom_hline(yintercept = 38.7/67.3, linetype = "dotted") +
  labs(
    x = "Winsorization percentile",
    y = "t-stat for PC/LA (aft_trt_1)",
    title = "PC/LA effect on Earnings vs winsorization level"
  ) +
  theme_minimal()

col_1_row_5 <-  results %>% 
  filter(term == "aft_trt_2")

ggplot(col_1_row_5, aes(x = percentile/1000*100, y = estimate / std.error)) +
  geom_line() +
  geom_vline(xintercept = 0.02*100, linetype = "dashed") +         # 3.7%
  geom_hline(yintercept = -52.8/61.0, linetype = "dotted") +
  labs(
    x = "Winsorization percentile",
    y = "t-stat for PC/LA (aft_trt_2)",
    title = "PC/LA effect on Earnings vs winsorization level"
  ) +
  theme_minimal()

col_1_row_6 <-  results %>% 
  filter(term == "aft_trt_3")

ggplot(col_1_row_6, aes(x = percentile/1000*100, y = estimate / std.error)) +
  geom_line() +
  geom_vline(xintercept = 0.02*100, linetype = "dashed") +         # 3.7%
  geom_hline(yintercept = 47.9/62.2, linetype = "dotted") +
  labs(
    x = "Winsorization percentile",
    y = "t-stat for PC/LA (aft_trt_3)",
    title = "PC/LA effect on Earnings vs winsorization level"
  ) +
  theme_minimal()

