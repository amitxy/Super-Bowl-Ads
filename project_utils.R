library(tidyverse)
library(gtrendsR)

fmt <- "%Y-%m-%d"

topics <- read.csv("data\\brand_topics.csv")
ads <- get_data()
trends <- read.csv("data\\trends_data.csv")
z <- DATA_SETUP(ads = ads,trends = trends)

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

# Works like the gtrends function, we used it to retrive the data
# from google
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

# Here we take the data from google and apply it in our dataframe
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

# This is how we created our main data frame with the data
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

#setting up the data sets
DATA_SETUP <- function(ads,trends) {
  ads <- na.exclude(ads)
  ads <- ads %>% filter(cost!=0,year>=2004)
  cost_table <- ads%>%group_by(brand,year)%>%summarise(sum_of_ads=sum(cost))
  trends$X<-as.integer(rownames(trends))
  trends$hits[trends$hits==0] <-0.001 
  z<- trends%>%
    summarise(brand=brand[is_sup_week==T],
              ratio=hits[X[is_sup_week==T]]/hits[X[is_sup_week==T]-1],
              dates=paste(date[(X[trends$is_sup_week==T]-1)],date[X[is_sup_week==T]],sep = "--"))%>%
    mutate(year=year(dates))
  #merging the ads' cost with the ratio
  z$ad_cost <-vector(length = length(z$ratio)) 
  for (i in 1:114) {
    z$ad_cost[i] <-  cost_table$sum_of_ads[(cost_table$brand==z$brand[i])&cost_table$year==z$year[i]]
  }
  return(z)
}

#calculating robust coefficients
TukeyLine <- function(x, y) { 
  ### split into quantiles 
  quants   <- quantile(x, c(1/3, 2/3), type = 6)  
  y_anchor <- c(median(y[x <= quants[1]]), median(y[x > quants[2]]))
  x_anchor <- c(median(x[x <= quants[1]]), median(x[x > quants[2]]))
  ## find the line 
  beta1  <- (y_anchor[2] - y_anchor[1]) / (x_anchor[2] - x_anchor[1]) 
  beta0  <- median(y - beta1 * x)
  return(c(beta0, beta1))
}
robust_coef<- TukeyLine(z$ad_cost,z$ratio)

#least squares model and robust model plot
linear.model.plot <- function(x,y,LS.model,Robust.model) {
  plot(y = (y),x = (x),main = "Search ratio VS Ads cost",xlab = "Ad cost",ylab = "Search ratio",las=1)
  abline(a = coefficients(LS.model)[1],b = coefficients(LS.model)[2],col="red")
  abline(a=Robust.model[1],b=Robust.model[2],col="purple")
  legend("topright",legend = c("Least squares","Robust line"),col = c("red","purple"),lty =1 )
  
}
