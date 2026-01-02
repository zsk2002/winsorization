library(readxl)
library(tidyverse)
aer_2024_automated <- read_excel("Desktop/winsorization_data/aer_2024_all_papers.xlsx")
aer_2024_manual <- read_excel("Desktop/winsorization_data/aer_2024_previously_manually_checked/aer_2024_all_papers copy.xlsx")

merged <- aer_2024_automated %>% 
  left_join(aer_2024_manual, 
            by = "doi",
            suffix = c("_auto", "_manual"))

merged_comp <- merged %>% 
  select(title_auto, doi,is_empirical_auto, is_empirical_2)

percent_unmatched <- length(which(merged_comp$is_empirical_auto != merged_comp$is_empirical_2))/ nrow(merged_comp)
percent_unmatched  

confusion <- table(
  Manual = merged_comp$is_empirical_2,
  Auto   = merged_comp$is_empirical_auto
)
confusion
# Comment: Many non-empirical are treated as empirical

aer_2024_automated <- read_excel("Desktop/winsorization_data/aer_2024_all_papers_2.xlsx")
aer_2024_manual <- read_excel("Desktop/winsorization_data/aer_2024_previously_manually_checked/aer_2024_all_papers copy.xlsx")

merged <- aer_2024_automated %>% 
  left_join(aer_2024_manual, 
            by = "doi",
            suffix = c("_auto", "_manual"))

merged_comp <- merged %>% 
  select(title_auto, doi,is_empirical_auto,  is_empirical_2)

percent_unmatched <- length(which(merged_comp$is_empirical_auto != merged_comp$is_empirical_2))/ nrow(merged_comp)
percent_unmatched  

confusion <- table(
  Manual = merged_comp$is_empirical_2,
  Auto   = merged_comp$is_empirical_auto
)
confusion

aer_2024_automated <- read_excel("Desktop/winsorization_data/aer_2024_all_papers_3.xlsx")
aer_2024_manual <- read_excel("Desktop/winsorization_data/aer_2024_previously_manually_checked/aer_2024_all_papers copy.xlsx")

merged <- aer_2024_automated %>% 
  left_join(aer_2024_manual, 
            by = "doi",
            suffix = c("_auto", "_manual"))

merged_comp <- merged %>% 
  select(title_auto, doi,is_empirical_auto, is_empirical_3)

percent_unmatched <- length(which(merged_comp$is_empirical_auto != merged_comp$is_empirical_2))/ nrow(merged_comp)
percent_unmatched  

confusion <- table(
  Manual = merged_comp$is_empirical_3,
  Auto   = merged_comp$is_empirical_auto
)
confusion


aer_2023_automated <- read_excel("Desktop/winsorization_data/aer_2023_all_papers.xlsx")
aer_2023_manual <- read_excel("Desktop/winsorization_data/aer_2023_manually_checked/aer_2023_all_papers_manually_checked.xlsx")

merged <- aer_2023_automated %>% 
  left_join(aer_2023_manual, 
            by = "doi",
            suffix = c("_auto", "_manual"))

merged_comp <- merged %>% 
  select(title_auto, doi,is_empirical_auto, is_empirical_manual)

percent_unmatched <- length(which(merged_comp$is_empirical_auto != merged_comp$is_empirical_manual))/ nrow(merged_comp)
percent_unmatched  

confusion <- table(
  Manual = merged_comp$is_empirical_manual,
  Auto   = merged_comp$is_empirical_auto
)
confusion
