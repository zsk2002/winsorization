library(haven)      # read_dta
library(dplyr)      # data wrangling
library(fixest)     # regressions with FE + clustered SEs
library(tidyverse)
# table 2a
compustat_ready <-  read_dta("~/Desktop/winsorization_data/paper_being_winsorized/Market Power and Innovation in the Intangible Economy/AER/data/analysis/compustat_ready.dta")
compu_filter_year <- compustat_ready %>% 
  filter(year %in% c(2010, 2012, 2013, 2014, 2015))

itspend <-  read_dta("~/Desktop/winsorization_data/paper_being_winsorized/Market Power and Innovation in the Intangible Economy/AER/data/analysis/hartehanks/itspend_20102016_firmlevel.dta")

df_soft <- inner_join(
  compu_filter_year,
  itspend |> select(gvkey, year, budget_software_firm),
  by = c("gvkey", "year")
)

winsorize <- function(x, p = 0.01) {
  q_low  <- quantile(x, p,     na.rm = TRUE)
  q_high <- quantile(x, 1 - p, na.rm = TRUE)
  x <- pmin(pmax(x, q_low), q_high)
  return(x)
}

df_soft <- df_soft |> filter(!is.na(fixedcosts_1_w))
df_soft <- df_soft |>
  mutate(
    budget_software_firm = case_when(
      year == 2010 ~ budget_software_firm * 100.00 / 100,
      year == 2012 ~ budget_software_firm * 94.09 / 100,
      year == 2013 ~ budget_software_firm * 93.18 / 100,
      year == 2014 ~ budget_software_firm * 93.63 / 100,
      year == 2015 ~ budget_software_firm * 92.47 / 100,
      TRUE ~ budget_software_firm
    ),
    ## log software/sales
    lbudget_software_sale_firm = log(budget_software_firm / sale)
  )

for (per in 1:10) {
  colname <- paste0("lbudget_software_sale_firm_w_", per)
  df_soft[[colname]] <- winsorize(df_soft$lbudget_software_sale_firm, p = per / 100)
}

df_soft <- df_soft |>
  mutate(
    ## NAICS2: first 2 digits of naics
    naics2 = substr(as.character(naics), 1, 2),
    naics2 = factor(naics2),
    year   = factor(year),
    
    ## log(fixedcosts * costs / sales)
    lfixedcosts_sale = log(fixedcosts_1 * costs1 / sale),
    lfixedcosts_sale_w = winsorize(lfixedcosts_sale, p = 0.01),
    
    ## log(costs)
    lcosts   = log(costs1),
    lcosts_w = winsorize(lcosts, p = 0.01),
    
    ## log(sales)
    lca   = log(sale),
    lca_w = winsorize(lca, p = 0.01),
    
    ## log fixed costs level
    lfixedcosts   = log(fixedcosts_1 * costs1),
    lfixedcosts_w = winsorize(lfixedcosts, p = 0.01)
  )

## Clean up: Stata drops if lcosts_w == .
df_soft <- df_soft |>
  filter(!is.na(lcosts_w))

# fix lfixedcosts_sale_w for now and varying the covariates lbudget_software_sale_firm_w_
for (per in 0:10) {
  colname <- paste0("lbudget_software_sale_firm_w_", per)
  df_soft[[colname]] <- winsorize(df_soft$lbudget_software_sale_firm, p = per / 100)
}

# containers
coefs   <- numeric(11)
ses     <- numeric(11)
z_score <- numeric(11)
names(coefs)   <- 0:10
names(ses)     <- 0:10
names(z_score) <- 0:10

for (per in 0:10) {
  rhs <- paste0("lbudget_software_sale_firm_w_", per)
  
  # build formula: lfixedcosts_sale_w ~ lbudget_software_sale_firm_w_k
  fml <- as.formula(paste("lfixedcosts_sale_w ~", rhs))
  
  m <- feols(
    fml,
    data    = df_soft,
    cluster = ~ gvkey
  )
  
  # extract coef and se for the RHS variable
  coefs[per + 1]   <- coef(m)[rhs]
  ses[per + 1]     <- se(m)[rhs]      # `se()` is from fixest
  z_score[per + 1] <- coefs[per + 1] / ses[per + 1]
}
per <- 0:10
plot(
  per, z_score,
  type = "b",                # points + lines
  xlab = "Winsorization p (percent)",
  ylab = "z-score of coef(lbudget_software_sale_firm_w)",
  main = "Sensitivity of z-score to Winsorization"
)
abline(h = 0, lty = 2)
abline(h = c(-1.96, 1.96), lty = 3) 


# fixing the covariates lbudget_software_sale_firm_w and varying in the outcome lfixedcosts_sale_w
for (per in 0:10) {
  colname <- paste0("lfixedcosts_sale_w_", per)
  lfixedcosts_sale = log(df_soft$fixedcosts_1 * df_soft$costs1 / df_soft$sale)
  df_soft[[colname]] <- winsorize(df_soft$lfixedcosts_sale, p = per / 100)
}
df_soft <- df_soft |>
  filter(!is.na(lcosts_w))

coefs   <- numeric(11)
ses     <- numeric(11)
z_score <- numeric(11)
names(coefs)   <- 0:10
names(ses)     <- 0:10
names(z_score) <- 0:10

for (per in 0:10) {
  lhs <- paste0("lfixedcosts_sale_w_", per)
  
  # build formula: lfixedcosts_sale_w ~ lbudget_software_sale_firm_w_k
  
  fml <- as.formula(paste(lhs, " ~ lbudget_software_sale_firm_w_1"))
  
  m <- feols(
    fml,
    data    = df_soft,
    cluster = ~ gvkey
  )
  print(summary(m))
  coefs[per + 1]   <- coef(m)["lbudget_software_sale_firm_w_1"]
  ses[per + 1]     <- se(m)["lbudget_software_sale_firm_w_1"]      # `se()` is from fixest
  z_score[per + 1] <- coefs[per + 1] / ses[per + 1]
}
per <- 0:10
plot(
  per, z_score,
  type = "b",                # points + lines
  xlab = "Winsorization p (percent)",
  ylab = "z-score",
  main = "Sensitivity of z-score to Winsorization"
)
abline(h = 0, lty = 2)

# varying the outcomes for II
coefs   <- numeric(11)
ses     <- numeric(11)
z_score <- numeric(11)
names(coefs)   <- 0:10
names(ses)     <- 0:10
names(z_score) <- 0:10

for (per in 0:10) {
  lhs <- paste0("lfixedcosts_sale_w_", per)
  
  # build formula: lfixedcosts_sale_w ~ lbudget_software_sale_firm_w_k
  fml <- as.formula(paste(lhs, " ~ lbudget_software_sale_firm_w_1 + lca_w"))
  
  m <- feols(
    fml,
    data    = df_soft,
    cluster = ~ gvkey
  )
  
  # extract coef and se for the RHS variable
  coefs[per + 1]   <- coef(m)["lbudget_software_sale_firm_w_1"]
  ses[per + 1]     <- se(m)["lbudget_software_sale_firm_w_1"]      # `se()` is from fixest
  z_score[per + 1] <- coefs[per + 1] / ses[per + 1]
}
per <- 0:10
plot(
  per, z_score,
  type = "b",                # points + lines
  xlab = "Winsorization p (percent)",
  ylab = "z-score",
  main = "Sensitivity of z-score to Winsorization"
)
abline(h = 0, lty = 2)

## varying outcome for III
coefs   <- numeric(11)
ses     <- numeric(11)
z_score <- numeric(11)
names(coefs)   <- 0:10
names(ses)     <- 0:10
names(z_score) <- 0:10

for (per in 0:10) {
  lhs <- paste0("lfixedcosts_sale_w_", per)
  
  # build formula: lfixedcosts_sale_w ~ lbudget_software_sale_firm_w_k
  fml <- as.formula(paste(lhs, " ~ lbudget_software_sale_firm_w_1 + lca_w + naics2"))
  
  m <- feols(
    fml,
    data    = df_soft,
    cluster = ~ gvkey
  )
  
  # extract coef and se for the RHS variable
  coefs[per + 1]   <- coef(m)["lbudget_software_sale_firm_w_1"]
  ses[per + 1]     <- se(m)["lbudget_software_sale_firm_w_1"]      # `se()` is from fixest
  z_score[per + 1] <- coefs[per + 1] / ses[per + 1]
}
per <- 0:10
plot(
  per, z_score,
  type = "b",                # points + lines
  xlab = "Winsorization p (percent)",
  ylab = "z-score",
  main = "Sensitivity of z-score to Winsorization"
)
abline(h = 0, lty = 2)

#### varying outcome for IV
coefs   <- numeric(11)
ses     <- numeric(11)
z_score <- numeric(11)
names(coefs)   <- 0:10
names(ses)     <- 0:10
names(z_score) <- 0:10

for (per in 0:10) {
  lhs <- paste0("lfixedcosts_sale_w_", per)
  
  # build formula: lfixedcosts_sale_w ~ lbudget_software_sale_firm_w_k
  fml <- as.formula(paste(lhs, " ~ lbudget_software_sale_firm_w_1 + lca_w + naics2 + year"))
  
  m <- feols(
    fml,
    data    = df_soft,
    cluster = ~ gvkey
  )
  
  # extract coef and se for the RHS variable
  coefs[per + 1]   <- coef(m)["lbudget_software_sale_firm_w_1"]
  ses[per + 1]     <- se(m)["lbudget_software_sale_firm_w_1"]      # `se()` is from fixest
  z_score[per + 1] <- coefs[per + 1] / ses[per + 1]
}
coefs
ses
per <- 0:10
plot(
  per, z_score,
  type = "b",                # points + lines
  xlab = "Winsorization p (percent)",
  ylab = "z-score",
  main = "Sensitivity of z-score to Winsorization"
)
abline(h = 0, lty = 2)

## varying outcome for V
coefs   <- numeric(11)
ses     <- numeric(11)
z_score <- numeric(11)
names(coefs)   <- 0:10
names(ses)     <- 0:10
names(z_score) <- 0:10

for (per in 0:10) {
  lhs <- paste0("lfixedcosts_sale_w_", per)
  
  # build formula: lfixedcosts_sale_w ~ lbudget_software_sale_firm_w_k
  fml <- as.formula(paste(lhs, " ~ lbudget_software_sale_firm_w_1 +  lca_w | gvkey"))
  
  m <- feols(
    fml,
    data    = df_soft,
    cluster = ~ gvkey
  )
  
  # extract coef and se for the RHS variable
  coefs[per + 1]   <- coef(m)["lbudget_software_sale_firm_w_1"]
  ses[per + 1]     <- se(m)["lbudget_software_sale_firm_w_1"]      # `se()` is from fixest
  z_score[per + 1] <- coefs[per + 1] / ses[per + 1]
}
coefs
ses
per <- 0:10
plot(
  per, z_score,
  type = "b",                # points + lines
  xlab = "Winsorization p (percent)",
  ylab = "z-score",
  main = "Sensitivity of z-score to Winsorization"
)
abline(h = 0, lty = 2)

## varying outcome for VI
coefs   <- numeric(11)
ses     <- numeric(11)
z_score <- numeric(11)
names(coefs)   <- 0:10
names(ses)     <- 0:10
names(z_score) <- 0:10

for (per in 0:10) {
  lhs <- paste0("lfixedcosts_sale_w_", per)
  
  # build formula: lfixedcosts_sale_w ~ lbudget_software_sale_firm_w_k
  fml <- as.formula(paste(lhs, " ~ lbudget_software_sale_firm_w_1 +  lca_w | gvkey + year"))
  
  m <- feols(
    fml,
    data    = df_soft,
    cluster = ~ gvkey
  )
  
  # extract coef and se for the RHS variable
  coefs[per + 1]   <- coef(m)["lbudget_software_sale_firm_w_1"]
  ses[per + 1]     <- se(m)["lbudget_software_sale_firm_w_1"]      # `se()` is from fixest
  z_score[per + 1] <- coefs[per + 1] / ses[per + 1]
}
coefs
ses
per <- 0:10
plot(
  per, z_score,
  type = "b",                # points + lines
  xlab = "Winsorization p (percent)",
  ylab = "z-score",
  main = "Sensitivity of z-score to Winsorization"
)
abline(h = 0, lty = 2)

########################### combined

spec_labels <- c(
  "I: Y ~ X",
  "II: + lca_w",
  "III: + lca_w + naics2",
  "IV: + lca_w + naics2 + year",
  "V: FE(gvkey) + lca_w",
  "VI: FE(gvkey, year) + lca_w"
)

# container for all results
z_df <- expand.grid(
  per  = 0:10,
  spec = factor(1:6, labels = spec_labels)
)
z_df$z <- NA_real_

rhs_name <- "lbudget_software_sale_firm_w_1"

for (s in 1:6) {
  for (per in 0:10) {
    lhs <- paste0("lfixedcosts_sale_w_", per)
    
    # build formula string depending on spec
    fml_str <- switch(
      as.character(s),
      # I
      "1" = paste(lhs, "~", rhs_name),
      # II
      "2" = paste(lhs, "~", rhs_name, "+ lca_w"),
      # III
      "3" = paste(lhs, "~", rhs_name, "+ lca_w + naics2"),
      # IV
      "4" = paste(lhs, "~", rhs_name, "+ lca_w + naics2 + year"),
      # V  (firm FE)
      "5" = paste(lhs, "~", rhs_name, "+ lca_w | gvkey"),
      # VI (firm + year FE)
      "6" = paste(lhs, "~", rhs_name, "+ lca_w | gvkey + year")
    )
    
    fml <- as.formula(fml_str)
    
    m <- feols(
      fml,
      data    = df_soft,
      cluster = ~ gvkey
    )
    
    z_val <- coef(m)[rhs_name] / se(m)[rhs_name]
    
    # store into z_df
    idx <- z_df$spec == spec_labels[s] & z_df$per == per
    z_df$z[idx] <- z_val
  }
}

ggplot(z_df, aes(x = per, y = z, color = spec)) +
  geom_line() +
  geom_point() +
  geom_hline(yintercept = 0,    linetype = "dashed") +
  geom_hline(yintercept = c(-1.96, 1.96), linetype = "dotted") +
  labs(
    x = "Winsorization p (percent) on outcome",
    y = "z-score for coef(lbudget_software_sale_firm_w_1)",
    color = "Specification",
    title = "Sensitivity of z-score to Winsorization across Table 2 specs"
  )


### table 3
compustat_ready <- read_dta("~/Desktop/winsorization_data/paper_being_winsorized/Market Power and Innovation in the Intangible Economy/AER/data/analysis/compustat_ready.dta")
itspend <-  read_dta("~/Desktop/winsorization_data/paper_being_winsorized/Market Power and Innovation in the Intangible Economy/AER/data/analysis/hartehanks/itspend_20102016_firmlevel.dta")
data3 <-inner_join(
  compustat_ready,
  itspend,  # if you only want budget_software_firm: itspend |> select(gvkey, year, budget_software_firm)
  by = c("gvkey", "year")
)
data3 <- data3 |>
  mutate(
    budget_software_firm = case_when(
      year == 2010 ~ budget_software_firm * 100.00 / 100,
      year == 2012 ~ budget_software_firm * 94.09 / 100,
      year == 2013 ~ budget_software_firm * 93.18 / 100,
      year == 2014 ~ budget_software_firm * 93.63 / 100,
      year == 2015 ~ budget_software_firm * 92.47 / 100,
      TRUE ~ budget_software_firm
    ),
    lbudget_software_firm        = log(budget_software_firm),
    lbudget_software_costs_firm  = log(budget_software_firm / costs1),
    lbudget_software_sale_firm   = log(budget_software_firm / sale),
    
    lbudget_software_firm_w       = winsorize(lbudget_software_firm,       p = 0.01),
    lbudget_software_costs_firm_w = winsorize(lbudget_software_costs_firm, p = 0.01),
    lbudget_software_sale_firm_w  = winsorize(lbudget_software_sale_firm,  p = 0.01)
  )

data3 <- data3 |>
  mutate(
    # tostring naics, gen naics2 = substr(naics,1,2)
    naics2 = substr(as.character(naics), 1, 2),
    naics2 = factor(naics2),
    year   = factor(year),
    
    lfixedcosts_1_w = log(fixedcosts_1_w),
    
    lcosts   = log(costs1),
    lcosts_w = winsorize(lcosts, p = 0.01),
    
    lca   = log(sale),
    lca_w = winsorize(lca, p = 0.01)
  )

data3 <- data3 |>
  filter(!is.na(lcosts_w), !is.na(lfixedcosts_1_w))

for (per in 0:10){
    data3$lxrd_sale   = log(data3$xrd / data3$sale)
    colname <- paste0("lxrd_sale_w_", per)
    data3[[colname]] <- winsorize(data3$lxrd_sale, p = per / 100)
}
coefs   <- numeric(11)
ses     <- numeric(11)
z_score <- numeric(11)
names(coefs)   <- 0:10
names(ses)     <- 0:10
names(z_score) <- 0:10

for (per in 0:10) {
  lhs <- paste0("lxrd_sale_w_", per)
  
  fml <- as.formula(paste(lhs, " ~ lfixedcosts_1_w"))
  
  m <- feols(
    fml,
    data    = data3,
    cluster = ~ gvkey
  )
  coefs[per + 1]   <- coef(m)["lfixedcosts_1_w"]
  ses[per + 1]     <- se(m)["lfixedcosts_1_w"]      # `se()` is from fixest
  z_score[per + 1] <- coefs[per + 1] / ses[per + 1]
}
per <- 0:10
plot(
  per, z_score,
  type = "b",                # points + lines
  xlab = "Winsorization p (percent)",
  ylab = "z-score",
  main = "Sensitivity of z-score to Winsorization"
)
abline(h = 0, lty = 2)

### II
coefs   <- numeric(11)
ses     <- numeric(11)
z_score <- numeric(11)
names(coefs)   <- 0:10
names(ses)     <- 0:10
names(z_score) <- 0:10

for (per in 0:10) {
  lhs <- paste0("lxrd_sale_w_", per)
  fml <- as.formula(paste(lhs, " ~ lfixedcosts_1_w + lca_w"))
  m <- feols(
    fml,
    data    = data3,
    cluster = ~ gvkey
  )
  coefs[per + 1]   <- coef(m)["lfixedcosts_1_w"]
  ses[per + 1]     <- se(m)["lfixedcosts_1_w"]      # `se()` is from fixest
  z_score[per + 1] <- coefs[per + 1] / ses[per + 1]
}
per <- 0:10
plot(
  per, z_score,
  type = "b",                # points + lines
  xlab = "Winsorization p (percent)",
  ylab = "z-score",
  main = "Sensitivity of z-score to Winsorization"
)
abline(h = 0, lty = 2)

### III
coefs   <- numeric(11)
ses     <- numeric(11)
z_score <- numeric(11)
names(coefs)   <- 0:10
names(ses)     <- 0:10
names(z_score) <- 0:10

for (per in 0:10) {
  lhs <- paste0("lxrd_sale_w_", per)
  fml <- as.formula(paste(lhs, " ~ lfixedcosts_1_w + lca_w + naics2"))
  m <- feols(
    fml,
    data    = data3,
    cluster = ~ gvkey
  )
  coefs[per + 1]   <- coef(m)["lfixedcosts_1_w"]
  ses[per + 1]     <- se(m)["lfixedcosts_1_w"]      # `se()` is from fixest
  z_score[per + 1] <- coefs[per + 1] / ses[per + 1]
}
per <- 0:10
plot(
  per, z_score,
  type = "b",                # points + lines
  xlab = "Winsorization p (percent)",
  ylab = "z-score",
  main = "Sensitivity of z-score to Winsorization"
)
abline(h = 0, lty = 2)

#### IV
coefs   <- numeric(11)
ses     <- numeric(11)
z_score <- numeric(11)
names(coefs)   <- 0:10
names(ses)     <- 0:10
names(z_score) <- 0:10

for (per in 0:10) {
  lhs <- paste0("lxrd_sale_w_", per)
  fml <- as.formula(paste(lhs, " ~ lfixedcosts_1_w + lca_w +naics2 + year"))
  m <- feols(
    fml,
    data    = data3,
    cluster = ~ gvkey
  )
  coefs[per + 1]   <- coef(m)["lfixedcosts_1_w"]
  ses[per + 1]     <- se(m)["lfixedcosts_1_w"]      # `se()` is from fixest
  z_score[per + 1] <- coefs[per + 1] / ses[per + 1]
}
per <- 0:10
plot(
  per, z_score,
  type = "b",                # points + lines
  xlab = "Winsorization p (percent)",
  ylab = "z-score",
  main = "Sensitivity of z-score to Winsorization"
)
abline(h = 0, lty = 2)

##### V
coefs   <- numeric(11)
ses     <- numeric(11)
z_score <- numeric(11)
names(coefs)   <- 0:10
names(ses)     <- 0:10
names(z_score) <- 0:10

for (per in 0:10) {
  lhs <- paste0("lxrd_sale_w_", per)
  fml <- as.formula(paste(lhs, " ~ lfixedcosts_1_w + lca_w | gvkey"))
  m <- feols(
    fml,
    data    = data3,
    cluster = ~ gvkey
  )
  coefs[per + 1]   <- coef(m)["lfixedcosts_1_w"]
  ses[per + 1]     <- se(m)["lfixedcosts_1_w"]      # `se()` is from fixest
  z_score[per + 1] <- coefs[per + 1] / ses[per + 1]
}
per <- 0:10
plot(
  per, z_score,
  type = "b",                # points + lines
  xlab = "Winsorization p (percent)",
  ylab = "z-score",
  main = "Sensitivity of z-score to Winsorization"
)
abline(h = 0, lty = 2)

##### VI

coefs   <- numeric(11)
ses     <- numeric(11)
z_score <- numeric(11)
names(coefs)   <- 0:10
names(ses)     <- 0:10
names(z_score) <- 0:10

for (per in 0:10) {
  lhs <- paste0("lxrd_sale_w_", per)
  fml <- as.formula(paste(lhs, " ~ lfixedcosts_1_w + lca_w | gvkey + year"))
  m <- feols(
    fml,
    data    = data3,
    cluster = ~ gvkey
  )
  coefs[per + 1]   <- coef(m)["lfixedcosts_1_w"]
  ses[per + 1]     <- se(m)["lfixedcosts_1_w"]      # `se()` is from fixest
  z_score[per + 1] <- coefs[per + 1] / ses[per + 1]
}
per <- 0:10
plot(
  per, z_score,
  type = "b",                # points + lines
  xlab = "Winsorization p (percent)",
  ylab = "z-score",
  main = "Sensitivity of z-score to Winsorization"
)
abline(h = 0, lty = 2)




### combined
spec_labels <- c(
  "I: Y ~ X",
  "II: + lca_w",
  "III: + lca_w + naics2",
  "IV: + lca_w + naics2 + year",
  "V: FE(gvkey) + lca_w",
  "VI: FE(gvkey, year) + lca_w"
)

# container for all results
z_df <- expand.grid(
  per  = 0:10,
  spec = factor(1:6, labels = spec_labels)
)
z_df$z <- NA_real_

rhs_name <- "lfixedcosts_1_w"

for (s in 1:6) {
  for (per in 0:10) {
    lhs <- paste0("lxrd_sale_w_", per)
    
    # build formula string depending on spec
    fml_str <- switch(
      as.character(s),
      # I
      "1" = paste(lhs, "~", rhs_name),
      # II
      "2" = paste(lhs, "~", rhs_name, "+ lca_w"),
      # III
      "3" = paste(lhs, "~", rhs_name, "+ lca_w + naics2"),
      # IV
      "4" = paste(lhs, "~", rhs_name, "+ lca_w + naics2 + year"),
      # V  (firm FE)
      "5" = paste(lhs, "~", rhs_name, "+ lca_w | gvkey"),
      # VI (firm + year FE)
      "6" = paste(lhs, "~", rhs_name, "+ lca_w | gvkey + year")
    )
    
    fml <- as.formula(fml_str)
    
    m <- feols(
      fml,
      data    = data3,
      cluster = ~ gvkey
    )
    
    z_val <- coef(m)[rhs_name] / se(m)[rhs_name]
    
    # store into z_df
    idx <- z_df$spec == spec_labels[s] & z_df$per == per
    z_df$z[idx] <- z_val
  }
}

ggplot(z_df, aes(x = per, y = z, color = spec)) +
  geom_line() +
  geom_point() +
  geom_hline(yintercept = 0,    linetype = "dashed") +
  geom_hline(yintercept = c(-1.96, 1.96), linetype = "dotted") +
  labs(
    x = "Winsorization p (percent) on outcome",
    y = "z-score for coef(lfixedcosts_1_w1)",
    color = "Specification",
    title = "Sensitivity of z-score to Winsorization across Table 3 specs"
  )


######## Table 4
compu <- read_dta("~/Desktop/winsorization_data/paper_being_winsorized/Market Power and Innovation in the Intangible Economy/AER/data/analysis/compustat_ready.dta")
compu <- compu |> filter(!is.na(fixedcosts_1_w))
compu <- compu |>
  filter(year %in% c(2010, 2012, 2013, 2014, 2015))
itspend <- read_dta("~/Desktop/winsorization_data/paper_being_winsorized/Market Power and Innovation in the Intangible Economy/AER/data/analysis/hartehanks/itspend_20102016_firmlevel.dta")
data4 <- inner_join(
  compu,
  itspend,  # if you only need budget_software_firm: itspend |> select(gvkey, year, budget_software_firm)
  by = c("gvkey", "year")
)

data4 <- data4 |>
  mutate(
    budget_software_firm = case_when(
      year == 2010 ~ budget_software_firm * 100.00 / 100,
      year == 2012 ~ budget_software_firm * 94.09 / 100,
      year == 2013 ~ budget_software_firm * 93.18 / 100,
      year == 2014 ~ budget_software_firm * 93.63 / 100,
      year == 2015 ~ budget_software_firm * 92.47 / 100,
      TRUE ~ budget_software_firm
    ),
    lbudget_software_costs_firm = log(budget_software_firm / costs1),
    lbudget_software_costs_firm_w = winsorize(lbudget_software_costs_firm, p = 0.01)
  )


data4 <- data4 |>
  mutate(
    # NAICS2
    naics2 = substr(as.character(naics), 1, 2),
    naics2 = factor(naics2),
    year   = factor(year),
    
    # log fixedcosts_1_w
    lfixedcosts_1_w = log(fixedcosts_1_w),
    
    # log(costs1)
    lcosts   = log(costs1),
    lcosts_w = winsorize(lcosts, p = 0.01),
    
    # log(sale)
    lca   = log(sale),
    lca_w = winsorize(lca, p = 0.01)
  )

data4 <- data4 |>
  filter(!is.na(lcosts_w), !is.na(lfixedcosts_1_w))

for (per in 0:10){
  lmu_3_w = log(data4$markup)
  colname <- paste0("lmu_3_w_", per)
  data4[[colname]] <- winsorize(lmu_3_w, p = per / 100)
}

coefs   <- numeric(11)
ses     <- numeric(11)
z_score <- numeric(11)
names(coefs)   <- 0:10
names(ses)     <- 0:10
names(z_score) <- 0:10

for (per in 0:10) {
  lhs <- paste0("lmu_3_w_", per)
  
  fml <- as.formula(paste(lhs, " ~ lfixedcosts_1_w"))
  
  m <- feols(
    fml,
    data    = data4,
    cluster = ~ gvkey
  )
  coefs[per + 1]   <- coef(m)["lfixedcosts_1_w"]
  ses[per + 1]     <- se(m)["lfixedcosts_1_w"]      # `se()` is from fixest
  z_score[per + 1] <- coefs[per + 1] / ses[per + 1]
}
per <- 0:10
plot(
  per, z_score,
  type = "b",                # points + lines
  xlab = "Winsorization p (percent)",
  ylab = "z-score",
  main = "Sensitivity of z-score to Winsorization"
)
abline(h = 0, lty = 2)

###### II
coefs   <- numeric(11)
ses     <- numeric(11)
z_score <- numeric(11)
names(coefs)   <- 0:10
names(ses)     <- 0:10
names(z_score) <- 0:10

for (per in 0:10) {
  lhs <- paste0("lmu_3_w_", per)
  
  fml <- as.formula(paste(lhs, " ~ lfixedcosts_1_w + lca_w + year | gvkey"))
  
  m <- feols(
    fml,
    data    = data4,
    cluster = ~ gvkey
  )
  coefs[per + 1]   <- coef(m)["lfixedcosts_1_w"]
  ses[per + 1]     <- se(m)["lfixedcosts_1_w"]      # `se()` is from fixest
  z_score[per + 1] <- coefs[per + 1] / ses[per + 1]
}
per <- 0:10
plot(
  per, z_score,
  type = "b",                # points + lines
  xlab = "Winsorization p (percent)",
  ylab = "z-score",
  main = "Sensitivity of z-score to Winsorization"
)
abline(h = 0, lty = 2)

