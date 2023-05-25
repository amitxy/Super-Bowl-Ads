library(tidyverse)

data <-  read.csv("data\\superbowl-ads.csv")
rating <-  read.csv("data\\super-bowl-ratings.csv")[-55,] %>% 
  mutate(year=year(date))
general <- read.csv("data\\superbowl-ads-general.csv")

#fmt <- "%Y-%m-%d"
#rating[["date"]] <- as.Date(rating[["date"]],fmt)

search_dates <- function(brand)
{
  brand_history <- data %>% 
    group_by(brand, year) %>% 
    filter(brand ==brand)
  
  r <- rating %>% 
    filter(year %in% brand_history[["year"]])
  
  return(r["date"])
}
  