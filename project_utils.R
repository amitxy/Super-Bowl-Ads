library(tidyverse)
#library(docstring)
fmt <- "%Y-%m-%d"

topics <- read.csv("data\\brand_topics.csv")


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

gtopics <- function(brands, time)
{
  # the gtrends topics
  brands_topics <-topics$query[topics$brand %in% c(brands)]
  trends <- gtrends(brands_topics,
                    geo = "US",
                    time=time,
                    onlyInterest = TRUE,
                    low_search_volume = FALSE)
  
  # changes back from topic query to the brand name
  trends$interest_over_time$keyword <- sapply(trends$interest_over_time$keyword,
                                              function(t) topics$brand[topics$query == t])
  # get rid of the time zone stamp
  trends$interest_over_time$date <- sapply(trends$interest_over_time$date,
                                           function(d) format(d, format = fmt))
  return(trends)
  
}

gtopics_r <- function(brands, date, rday=1)
{
  time_q <- paste(date - rday, date + rday)
  return(gtopics(brands, time_q))
}

# rday - how many days to display before and after date 
gtopics_plot <- function(brands, date, rday=1)
{
  trends <- gtrends_topic(brands, date, rday)
  
  hits <-  trends$interest_over_time$hits
  date <-  as.Date(trends$interest_over_time$date)
  
  gplot <- ggplot(trends$interest_over_time, aes(x=as.Date(date) ,y=hits, colour=keyword)) +
    geom_line(na.rm = TRUE) +
    geom_vline(xintercept=date[rday + 1],linetype = "dashed") + 
    xlab("Date") +
    ylab("Search hits")
  
  gplot
}

