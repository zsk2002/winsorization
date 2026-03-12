library(readr)
library(tidyverse)
summarized_by_year <- read_csv("summarized_by_year.csv")
ggplot(summarized_by_year, aes(x = year, y = frac_winsor)) +
  geom_point(size = 2) + 
  labs(x = "Year", y = "Fraction") + 
  theme_bw() 

summarized_by_year_after_1990 <- summarized_by_year %>% 
  filter(year >=1990)

ggplot(summarized_by_year_after_1990, aes(x = year, y = frac_winsor)) +
  geom_point(size = 2) +  
  labs(x = "Year", y = "Fraction") +  
  theme_bw() 