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
    filter(brand == brand)
  
  r <- rating %>% 
    filter(year %in% brand_history[["year"]])
  
  return(r["date"])
}

# Returns the brands that had a commercial in the same year  
search_brands <- function(ad_year)
{
  brands <- data %>%
    group_by(brand) %>%
    filter(year == ad_year) %>% 
    summarise(count=n())
  
  return(brands)
}


# rday - how many days to display before and after date 
gtrends_plot <- function(brands, date, rday=1)
{
  
  padding <- ifelse(rday < 7, 0, 0)
  time_q <- paste(date - rday - padding, date + rday + padding)
  trands <- gtrends(brands, geo = "US", time=time_q,
                    onlyInterest=TRUE,low_search_volume=TRUE)
  
  hits <-  trands$interest_over_time$hits
  date <-  as.Date(trands$interest_over_time$date)
  
  gplot <- ggplot(trands$interest_over_time, aes(x=as.Date(date) ,y=hits, colour=keyword)) +
    geom_line(na.rm = TRUE) +
    geom_vline(xintercept=date[rday + padding + 1],linetype = "dashed") + 
    xlab("Date") +
    ylab("Search hits")
  
  # To avoid a bug in gtrands package
  if (padding)
    gplot + xlim(date[padding + 1], date[padding + 1 + 2*rday])
  
  else
    gplot
  
}

