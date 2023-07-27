library(tidyverse)
library(gtrendsR)

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
search_dates <- function(brand_name)
{
  brand_history <- filter(data, brand == brand_name)
  
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
  #brands_topics <-topics$query[topics$brand == brand]
  trends <- gtrends(brands_topics,
                    geo = "US",
                    time=time,
                    onlyInterest = TRUE,
                    low_search_volume = TRUE)$interest_over_time
  
  # changes back from topic query to the brand name
  trends$keyword <- sapply(trends$keyword,
                                              function(t) topics$brand[topics$query == t])
  # get rid of the time zone stamp
  trends$date <- sapply(trends$date,
                                           function(d) format(d, format = fmt))
  # fix noise data
  if(typeof(trends$hits) == "character")
  {
    trends$hits <- replace(trends$hits, trends$hits == '<1', 0.5)
    trends$hits <- as.numeric(trends$hits)
  }
  
  return(trends)
  
}

update_df <- function(df, brand, rday=3)
{ 
  for (y in seq(2004, 2020))
  {
    output <- gtopics(brand, time=sprintf("%s-01-01 %s-01-01",y, y+1))
    ad_date = search_dates(brand) %>% filter(year(date) == y)
    
    weeks <- rep(FALSE, nrow(output))
    if (nrow(ad_date))
    {
      weeks <- sapply(output$date,
                      function (date) {return((date <= ad_date + rday) & (date >= ad_date - rday))})
    }
    
    
    temp <- tibble(date=output$date,
                   brand=output$keyword, 
                   hits=output$hits,
                   is_sup_week=weeks,
                   is_sup_year=rep(as.logical(nrow(ad_date)),nrow(output))
    )
    
    df <- df %>% add_row(temp)
    
  }
  
  return(df)
}

create_df <- function()
{
  df <- tibble(date=c(as.character(NA)),
               brand=c(as.character(NA)),
               hits=c(as.numeric(NA)), 
               is_sup_week=c(as.logical(NA)),
               is_sup_year=c(as.logical(NA))) %>% na.omit()
  
  for (brand in brands$brand) {df <- update_df(df, brand); Sys.sleep(6)}
  
  df$date <- as.Date(df$date)
  write.csv(df,"data\\trends_data.csv", row.names = FALSE)
}


################## REMOVE ######################

gtopics_r <- function(brands, date, rday=1)
{
  time_q <- paste(date - rday, date + rday)
  return(gtopics(brands, time_q))
}

# rday - how many days to display before and after date 
gtopics_plot <- function(brands, date, rday=1)
{
  trends <- gtopics_r(brands, date, rday)
  
  hits <-  trends$hits
  date <-  as.Date(trends$date)
  
  gplot <- ggplot(trends, aes(x=as.Date(date) ,y=hits, colour=keyword)) +
    geom_line(na.rm = TRUE) +
    geom_vline(xintercept=date[rday + 1],linetype = "dashed") + 
    xlab("Date") +
    ylab("Search hits")
  
  gplot
}
