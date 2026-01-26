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
    n_winsor = sum(using_winsorization_1 == 1, na.rm = TRUE),
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
    n_winsor = sum(using_winsorization_2 == 1, na.rm = TRUE),
    frac_winsor = n_winsor / n_papers,
    .groups = "drop"
  ) %>%
  arrange(year)

ggplot(summarized_by_year) +
  geom_line(aes(x = year, y = frac_winsor)) +
  labs(x = "Year", y = "Fraction",
       title = "fraction of using winsorization across year") 

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




summarized_by_year_and_empirical <- All_AER_articles %>%
  group_by(year) %>%
  summarise(
    n_papers = n(),
    n_empirical = sum(is_empirical == 1, na.rm = TRUE),
    frac_empirical = n_empirical / n_papers,
    .groups = "drop"
  ) %>%
  arrange(year)

ggplot(summarized_by_year_and_empirical) +
  geom_line(aes(x = year, y = frac_empirical)) +
  labs(x = "Year", y = "Fraction empirical", title = "Fraction of empirical paper cross years")


