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

gtrends_topic <- function(brands, date, rday=1)
{
  # the gtrends topics
  b_topics <-topics$query[topics$brand %in% c(brands)]
  
  
  padding <- 0
  time_q <- paste(date - rday - padding, date + rday + padding)
  trends <- gtrends(b_topics,
                    geo = "US",
                    time=time_q,
                    onlyInterest = TRUE,
                    low_search_volume = FALSE)
  
  # changes back from topic query to the brand name
  trends$interest_over_time$keyword <- sapply(trends$interest_over_time$keyword,
                                              function(t) topics$brand[topics$query == t])
  return(trends)
}

# rday - how many days to display before and after date 
gtrends_plot <- function(brands, date, rday=1)
{
  padding <- 0
  trends <- gtrends_topic(brands, date, rday)
  
<<<<<<< Updated upstream
  padding <- ifelse(rday < 7, 0, 0)
  time_q <- paste(date - rday - padding, date + rday + padding)
  trands <- gtrends(brands, geo = "US", time=time_q,
                    onlyInterest=TRUE,low_search_volume=TRUE)
=======
  hits <-  trends$interest_over_time$hits
  date <-  as.Date(trends$interest_over_time$date)
>>>>>>> Stashed changes
  
  gplot <- ggplot(trends$interest_over_time, aes(x=as.Date(date) ,y=hits, colour=keyword)) +
    geom_line(na.rm = TRUE) +
    geom_vline(xintercept=date[rday + padding + 1],linetype = "dashed") + 
    xlab("Date") +
    ylab("Search hits")
  
  gplot
  ###Ignore for now ###
  # To avoid a bug in gtrends package
  #if (padding)
    #gplot + xlim(date[padding + 1], date[padding + 1 + 2*rday])
  
  #else
    #gplot
  
}

