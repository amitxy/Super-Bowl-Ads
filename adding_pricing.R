# Function to retrieve price based on year
get_price <- function(year, ratings) {
  subset <- data[data$year == year, ]
    return(subset$price)
}

#Adding the price column:
general_csv$price_for_year <- get_price(general_csv$year, ratings)

# Add a new column "Value" to "your_data" with the corresponding values based on the index
general_csv$total_price <- general_csv$duration * (price_for_year/30)