library(tidyverse)
#library(docstring)
fmt <- "%Y-%m-%d"

get_data <- function()
{
  data <- read.csv("data\\superbowl-ads.csv") %>%  filter(year > 2003)
  return(data)
}

get_rating_data <- function()
{
  rating <-  read.csv("data\\super-bowl-ratings.csv")[-55,] %>% 
    mutate(year=year(date), date=as.Date(date)) %>% 
    filter(year > 2003)
  return(rating)
}

get_general_data <- function()
{
  general <- read.csv("data\\superbowl-ads-general.csv") %>% 
    filter(!is.na(suppressWarnings(as.numeric(Year))), Year > 2003)
  return(general)
}

# Returns the dates where a brand had a commercial  
search_dates <- function(brand)
{
  brand_history <- data %>% 
    group_by(brand, year) %>% 
    filter(brand ==brand)
  
  r <- rating %>% 
    filter(year %in% brand_history[["year"]])
  
  return(r["date"])
}


# rday - how many days to display before and after date 
gtrends_plot <- function(brands, date, rday=2)
{
  time_q <- paste(date - rday, date + rday)
  trands <- gtrends(brands, geo = "US", time=time_q)
  
  hits <-  trands$interest_over_time$hits
  date <-  trands$interest_over_time$date
  
  ggplot(trands$interest_over_time, aes(x=date ,y=hits, colour=keyword)) +
    geom_line() +
    geom_vline(xintercept=date[rday + 1],linetype = "dashed")
  
}
  