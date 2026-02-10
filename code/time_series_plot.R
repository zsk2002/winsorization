library(readxl)
library(tidyverse)
All_AER_articles <- read_excel("~/Desktop/winsorization_data/AER_2022_articles_and_before/All_AER_articles_2.xlsx")

View(All_AER_articles)

library(dplyr)
library(stringr)

All_AER_articles  <- All_AER_articles  %>%
  mutate(
    year = str_extract(as.character(published_date), "^\\d{4}"),
    year = as.integer(year)
  )


summarized_by_year <- All_AER_articles %>%
  group_by(year) %>%
  summarise(
    n_papers = n(),
    n_winsor = sum(using_winsorization_2 == 1, na.rm = TRUE),
    frac_winsor = n_winsor / n_papers,
    .groups = "drop"
  ) %>%
  arrange(year)

ggplot(summarized_by_year) +
  geom_line(aes(x = year, y = frac_winsor)) +
  labs(x = "Year", y = "Fraction",
       title = "fraction of using winsorization across year") 

summarized_by_year_after_1975 <- All_AER_articles %>%
  group_by(year) %>%
  summarise(
    n_papers = n(),
    n_winsor = sum(using_winsorization_2 == 1, na.rm = TRUE),
    frac_winsor = n_winsor / n_papers,
    .groups = "drop"
  ) %>%
  arrange(year) %>%
  filter(year > 1975)

ggplot(summarized_by_year_after_1975, aes(x = year, y = frac_winsor)) +
  geom_point(size = 3) +  # bigger dots
  labs(x = "Year", y = "Fraction") +  # no title
  theme_bw() 


summarized_by_year_after_1990 <- All_AER_articles %>%
  group_by(year) %>%
  summarise(
    n_papers = n(),
    n_winsor = sum(using_winsorization_2 == 1, na.rm = TRUE),
    frac_winsor = n_winsor / n_papers,
    .groups = "drop"
  ) %>%
  arrange(year) %>%
  filter(year >= 1990)

subset_before_2023 <- All_AER_articles[which(All_AER_articles$using_winsorization_2 != All_AER_articles$using_winsorization_1),]

aer_2024_all_papers_2 <- read_excel("Desktop/winsorization_data/aer_2024_all_papers_2.xlsx")
aer_2023_all_papers_2 <- read_excel("Desktop/winsorization_data/aer_2023_all_papers_2.xlsx")
aer_2025_all_papers_2 <- read_excel("Desktop/winsorization_data/aer_2025_all_papers_5.xlsx")

aer_2024_all_papers_2['year'] <- 2024
aer_2023_all_papers_2['year'] <- 2023
aer_2025_all_papers_2['year'] <- 2025
aer_2023_after <- rbind(aer_2023_all_papers_2, aer_2024_all_papers_2, aer_2025_all_papers_2)

subset <- aer_2023_after[which(aer_2023_after$using_winsorization_2 != aer_2023_after$using_winsorization_1),]

aer_2023_after <- aer_2023_after %>% 
  group_by(year) %>%
  summarise(
    n_papers = n(),
    n_winsor = sum(using_winsorization_1 == 1, na.rm = TRUE),
    frac_winsor = n_winsor / n_papers,
    .groups = "drop"
  ) %>%
  arrange(year)



summarized_by_year_after_1990 <- rbind(summarized_by_year_after_1990, aer_2023_after)
summarized_by_year <- rbind(summarized_by_year, aer_2023_after)
write.csv(summarized_by_year, "/Users/zhushangkai/Desktop/winsorizationsummarized_by_year.csv", row.names = FALSE)

ggplot(summarized_by_year, aes(x = year, y = frac_winsor)) +
  geom_point(size = 2) +  # bigger dots
  labs(x = "Year", y = "Fraction") +  # no title
  theme_bw() 

summarized_by_year <- All_AER_articles %>%
  group_by(year) %>%
  summarise(
    n_papers = n(),
    n_winsor = sum(using_winsorization_2 == 1, na.rm = TRUE),
    frac_winsor = n_winsor / n_papers,
    .groups = "drop"
  ) %>%
  arrange(year)

ggplot(summarized_by_year) +
  geom_line(aes(x = year, y = frac_winsor)) +
  labs(x = "Year", y = "Fraction",
       title = "fraction of using winsorization across year") 

summarized_by_year <- All_AER_articles %>%
  group_by(year) %>%
  summarise(
    n_papers = n(),
    frac_winsor_1 = sum(using_winsorization_1 == 1, na.rm = TRUE) / n_papers,
    frac_winsor_2 = sum(using_winsorization_2 == 1, na.rm = TRUE) / n_papers,
    .groups = "drop"
  ) %>%
  pivot_longer(
    cols = starts_with("frac_winsor"),
    names_to = "definition",
    values_to = "frac_winsor"
  )

ggplot(summarized_by_year, aes(x = year, y = frac_winsor)) +
  geom_line() +
  facet_wrap(~ definition, ncol = 2) +
  labs(x = "Year", y = "Fraction",
       title = "Fraction using winsorization across years")

winsorization_unmatched_subset <- All_AER_articles[which(All_AER_articles$using_winsorization_1 != All_AER_articles$using_winsorization_2),]
View(winsorization_unmatched_subset)

winsor_2_subset <- All_AER_articles[which(All_AER_articles$using_winsorization_2 == 1),]
View(winsor_2_subset)

is_empirical_unmatched_subset <- All_AER_articles[which(All_AER_articles$is_empirical_1 != All_AER_articles$is_empirical_2),]
View(is_empirical_unmatched_subset)



summarized_by_year_subset_empirical <- All_AER_articles %>%
  filter(is_empirical_1 == 1)%>% 
  group_by(year) %>%
  summarise(
    n_empirical_papers = n(),
    n_winsor = sum(using_winsorization_1 == 1, na.rm = TRUE),
    frac_winsor = n_winsor / n_empirical_papers,
    .groups = "drop"
  ) %>%
  arrange(year)

ggplot(summarized_by_year_subset_empirical) +
  geom_line(aes(x = year, y = frac_winsor)) +
  labs(x = "Year", y = "Fraction",
       title = "Fraction of empirical paper using winsorization cross years")



summarized_by_year_subset_empirical <- All_AER_articles %>%
  filter(is_empirical_2 == 1)%>% 
  group_by(year) %>%
  summarise(
    n_empirical_papers = n(),
    n_winsor = sum(using_winsorization_2 == 1, na.rm = TRUE),
    frac_winsor = n_winsor / n_empirical_papers,
    .groups = "drop"
  ) %>%
  arrange(year)

ggplot(summarized_by_year_subset_empirical) +
  geom_line(aes(x = year, y = frac_winsor)) +
  labs(x = "Year", y = "Fraction",
       title = "Fraction of empirical paper using winsorization cross years")


summarized_by_year_subset_empirical <- All_AER_articles %>%
  group_by(year) %>%
  summarise(
    frac_winsor_1 = sum(using_winsorization_1 == 1 & is_empirical_1 == 1, na.rm = TRUE) /
      sum(is_empirical_1 == 1, na.rm = TRUE),
    frac_winsor_2 = sum(using_winsorization_2 == 1 & is_empirical_2 == 1, na.rm = TRUE) /
      sum(is_empirical_2 == 1, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  pivot_longer(
    cols = starts_with("frac_winsor"),
    names_to = "definition",
    values_to = "frac_winsor"
  )

ggplot(summarized_by_year_subset_empirical,
       aes(x = year, y = frac_winsor)) +
  geom_line() +
  facet_wrap(~ definition, ncol = 2) +
  labs(x = "Year", y = "Fraction",
       title = "Fraction of empirical papers using winsorization")






summarized_both <- All_AER_articles %>%
  group_by(year) %>%
  summarise(
    n_papers = n(),
    frac_empirical_1 = sum(is_empirical_1 == 1, na.rm = TRUE) / n_papers,
    frac_empirical_2 = sum(is_empirical_2 == 1, na.rm = TRUE) / n_papers,
    .groups = "drop"
  ) %>%
  pivot_longer(
    cols = starts_with("frac_empirical"),
    names_to = "definition",
    values_to = "frac_empirical"
  )

ggplot(summarized_both, aes(x = year, y = frac_empirical)) +
  geom_line() +
  facet_wrap(~ definition, nrow = 1,
             labeller = labeller(
               definition = c(
                 frac_empirical_1 = "Empirical definition 1",
                 frac_empirical_2 = "Empirical definition 2"
               )
             )) +
  labs(
    x = "Year",
    y = "Fraction empirical",
    title = "Fraction of empirical AER papers over time"
  ) +
  theme_bw()


