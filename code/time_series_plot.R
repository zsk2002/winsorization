library(readxl)
library(tidyverse)
All_AER_articles <- read_excel("~/Desktop/winsorization_data/AER_2022_articles_and_before/All_AER_articles.xlsx")

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
    n_winsor = sum(using_winsorization == 1, na.rm = TRUE),
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
    n_winsor = sum(using_winsorization == 1, na.rm = TRUE),
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
    n_winsor = sum(using_winsorization == 1, na.rm = TRUE),
    frac_winsor = n_winsor / n_papers,
    .groups = "drop"
  ) %>%
  arrange(year) %>%
  filter(year >= 1990)



aer_2024_all_papers <- read_excel("~/Desktop/winsorization_data/aer_2024_all_papers.xlsx")
aer_2023_all_papers <- read_excel("~/Desktop/winsorization_data/aer_2023_all_papers.xlsx")
aer_2025_all_papers <- read_excel("~/Desktop/winsorization_data/aer_2025_all_papers.xlsx")

aer_2024_all_papers['year'] <- 2024
aer_2023_all_papers['year'] <- 2023
aer_2025_all_papers['year'] <- 2025
aer_2023_after <- rbind(aer_2023_all_papers, aer_2024_all_papers, aer_2025_all_papers)


aer_2023_after <- aer_2023_after %>% 
  group_by(year) %>%
  summarise(
    n_papers = n(),
    n_winsor = sum(using_winsorization == 1, na.rm = TRUE),
    frac_winsor = n_winsor / n_papers,
    .groups = "drop"
  ) %>%
  arrange(year)



summarized_by_year_after_1990 <- rbind(summarized_by_year_after_1990, aer_2023_after)
summarized_by_year <- rbind(summarized_by_year, aer_2023_after)
write.csv(summarized_by_year, "/Users/zhushangkai/Desktop/winsorization_data/summarized_by_year.csv", row.names = FALSE)

ggplot(summarized_by_year, aes(x = year, y = frac_winsor)) +
  geom_point(size = 2) +  # bigger dots
  labs(x = "Year", y = "Fraction") +  # no title
  theme_bw() 



summarized_by_year_subset_empirical <- All_AER_articles %>%
  filter(is_empirical == 1)%>% 
  group_by(year) %>%
  summarise(
    n_empirical_papers = n(),
    n_winsor = sum(using_winsorization == 1, na.rm = TRUE),
    frac_winsor = n_winsor / n_empirical_papers,
    .groups = "drop"
  ) %>%
  arrange(year)
ggplot(summarized_by_year_subset_empirical) +
  geom_line(aes(x = year, y = frac_winsor)) +
  labs(x = "Year", y = "Fraction",
       title = "Fraction of empirical paper using winsorization cross years")









