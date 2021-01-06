### READ IN GRIDDED CLIMATE DATA 2009 - 2017

# Explanation for variables
# TAM er temperatur (døgnmiddel)
# UUM - rel.luftfuktighet
# FFM - middelvind
# NNM - midlere skydekke (i 8-deler)
# RR - døgnnedbør

source("R/Load packages.R")

# Download raw data from OSF
get_file(node = "pk4bg",
         file = "THREE-D_Gridded_Climate_Data_2009-2019.zip",
         path = "data/climate",
         remote_path = "RawData/Climate")


# FUNCTIONS
# Function to read in the data
ReadInFiles <- function(textfile){
  dat <- read.table(textfile, colClasses = "character")
  colnames(dat) <- c("Site", "Year", "Month", "Day", "Temperature", "RelAirMoisture", "Wind", "CloudCover", "Precipitation") # rename variables
  dat <- dat[-1,] # remove first columne
  dat$Date <- ymd(paste(dat$Year, dat$Month, dat$Day)) # create date object
  return(dat)
}

# List of files
myfiles <- list.files(path="data/climate/AH2019", pattern='\\.dat$', recursive = TRUE, full.names = TRUE)

# read in data
gridclimate <- plyr::ldply(myfiles, ReadInFiles) %>% 
  as_tibble()

climate <- gridclimate %>% 
  # filter for Three-D sites
  filter(Site %in% c("888012", "888191", "888192")) %>% 
  # replace site names by real names
  mutate(Site = plyr::mapvalues(Site, c("888012", "888191", "888192"), c("Vik", "Joa", "Lia"))) %>% 
  mutate(Site = factor(Site, levels = c("Vik", "Joa", "Lia"))) %>% 
  mutate(Year = as.numeric(Year)) %>% 
  mutate(Temperature = as.numeric(Temperature), 
         RelAirMoisture = as.numeric(RelAirMoisture), 
         Wind = as.numeric(Wind), 
         CloudCover = as.numeric(CloudCover), 
         Precipitation = as.numeric(Precipitation)) %>% 
  rename(destSiteID = Site, year = Year, month = Month, day = Day, temperature = Temperature, rel_air_moisture = RelAirMoisture,  wind = Wind, cloud_cover = CloudCover, precipitation = Precipitation, date = Date) %>% 
  pivot_longer(cols = temperature:precipitation, names_to = "logger", values_to = "value")

write_csv(climate, path = "data_cleaned/climate/THREE_D_Gridded_DailyClimate_2009-2019.csv")


# Calculate Monthly Mean
monthlyClimate <- climate %>%
  select(-year, -month, -day) %>% 
  mutate(dateMonth = dmy(paste0("15-",format(date, "%b.%Y")))) %>%
  group_by(dateMonth, logger, destSiteID) %>%
  summarise(n = n(), 
            value = mean(value), 
            sum = sum(value)) %>% 
  mutate(value = ifelse(logger == "pPrecipitation", sum, value)) %>% 
  select(-n, -sum)

write_csv(climate, path = "data_cleaned/climate/THREE_D_Gridded_MonthlyClimate_2009-2019.csv")