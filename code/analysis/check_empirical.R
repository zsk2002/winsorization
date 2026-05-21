library(readxl)
library(tidyverse)
aer_2024_automated <- read_excel("Desktop/winsorization_data/aer_2024_all_papers_2.xlsx")
aer_2024_manual <- read_excel("Desktop/winsorization_data/aer_2024_previously_manually_checked/aer_2024_all_papers copy.xlsx")
aer_2024_chatgpt <- aer_2024_all_papers_2_chat <- read_excel("Desktop/winsorization_data/aer_2024_all_papers_2_chat.xlsx")

merged <- aer_2024_automated %>% 
  left_join(aer_2024_manual, 
            by = "doi",
            suffix = c("_auto", "_manual"))
colnames(merged)

# check 2024
(length(which(merged$is_empirical_1 !=merged$is_empirical)))
(length(which(merged$is_empirical_2 !=merged$is_empirical)))
(length(which(merged$is_empirical_1 !=merged$is_empirical_2)))
(length(which(merged$using_winsorization_1!=merged$using_winsorization_trimming)))
(length(which(merged$using_winsorization_2 !=merged$using_winsorization_trimming)))
(length(which(merged$using_winsorization_1 !=merged$using_winsorization_2)))


merged_chatgpt <- aer_2024_manual %>% 
  left_join(
    aer_2024_chatgpt,
    by = "doi",
    suffix = c("_manual", "_auto")
  )
colnames(merged_chatgpt)

(length(which(merged_chatgpt$is_empirical != merged_chatgpt$is_empirical_1)))
(length(which(merged_chatgpt$is_empirical != merged_chatgpt$is_empirical_2)))
(length(which(merged_chatgpt$is_empirical != merged_chatgpt$is_empirical_chatgpt)))

(length(which(merged_chatgpt$using_winsorization_trimming != merged_chatgpt$using_winsorization_1)))
(length(which(merged_chatgpt$using_winsorization_trimming != merged_chatgpt$using_winsorization_2)))
(length(which(merged_chatgpt$using_winsorization_trimming != merged_chatgpt$using_winsorization_chatgpt)))

merged_comp <- merged %>% 
  select(title_auto, is_empirical_auto, is_empirical_2, is_empirical_manual, 
         using_winsorization, using_winsorization_2, using_winsorization_trimming)

percent_unmatched <- length(which(merged_comp$is_empirical_auto != merged_comp$is_empirical_2))/ nrow(merged_comp)
percent_unmatched  

confusion <- table(
  Manual = merged_comp$is_empirical_2,
  Auto   = merged_comp$is_empirical_auto
)
confusion



## check 1918
AER_1918_chat <- read_excel("Desktop/winsorization_data/AER_1918_chat.xlsx")
length(which(AER_1918_chat$is_empirical_chatgpt == 1))
(length(which(AER_1918_chat$is_empirical_1 != AER_1918_chat$is_empirical_chatgpt)))
(length(which(AER_1918_chat$is_empirical_2 != AER_1918_chat$is_empirical_chatgpt)))
(length(which(AER_1918_chat$using_winsorization_1!= AER_1918_chat$using_winsorization_chatgpt)))
(length(which(AER_1918_chat$using_winsorization_2!= AER_1918_chat$using_winsorization_chatgpt)))


