###########################
### READ IN DATA ###
###########################

source("R/Load packages.R")
source("R/create meta data.R")


#### CLIMATE DATA ####

# Read in meta data
meta <- read_excel(path = "data/metaData/Three-D_ClimateLogger_Meta_2019.xlsx", col_names = TRUE, col_types = c("text", "numeric", "text", "text", "date", "date", "text")) %>% 
  mutate(InitialDate = ymd(InitialDate),
         InitialDate_Time = ymd_hm(paste(InitialDate, paste(hour(InitialTime), minute(InitialTime), sep = ":"), sep = " ")))


### Read in files
files <- dir(path = "data/climate tomst/", pattern = "^data.*\\.csv$", full.names = TRUE, recursive = TRUE)

# Function to read in data
temp <- map_df(set_names(files), function(file) {
  file %>% 
    set_names() %>% 
    map_df(~ read_delim(file = file, col_names = FALSE, delim = ";"))
}, .id = "File") %>% 
  # rename column names
  rename("ID" = "X1", "Date_Time" = "X2", "Time_zone" = "X3", "SoilTemperature" = "X4", "GroundTemperature" = "X5", "AirTemperature" = "X6", "RawSoilmoisture" = "X7", "Shake" = "X8", "ErrorFlag" = "X9") %>% 
  mutate(Date_Time = ymd_hm(Date_Time)) %>% 
  # Soil moisture calibration
  #mutate(SoilMoisture = a * RawSoilmoisture^2 + b * RawSoilmoisture + c) %>% 
  # get logger ID
  mutate(LoggerID = substr(File, nchar(File)-9, nchar(File)-6)) %>% 
  left_join(meta, by = "LoggerID")
  

# Fix data
temp <- temp %>% 
  # Remove logger failure
  filter(ErrorFlag == 0) %>% 
  # Remove data before initial date time
  group_by(LoggerID) %>% 
  filter(Date_Time > InitialDate_Time)

temp %>% filter(LoggerID == "5255") %>% select(InitialDate_Time)

temp %>% 
  ggplot(aes(x = Date_Time, y = AirTemperature, colour = as.factor(LoggerID))) +
  geom_line() +
  facet_grid(BlockID ~ Site) +
  theme(legend.position="none")
  


