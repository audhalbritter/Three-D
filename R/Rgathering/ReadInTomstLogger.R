###########################
### READ IN DATA ###
###########################

source("R/Load packages.R")
source("R/create meta data.R")


#### CLIMATE DATA ####

# Read in meta data
meta <- read_excel(path = "data/metaData/Three-D_ClimateLogger_Meta_2019.xlsx", col_names = TRUE)

### Read in files
files <- dir(path = "data/climate tomst/", pattern = "^data.*\\.csv$", full.names = TRUE, recursive = TRUE)

# Function to read in data
temp <- map_df(set_names(files), function(file) {
  file %>% 
    set_names() %>% 
    map_df(~ read_delim(file = file, col_names = FALSE, delim = ";"))
}, .id = "File") %>% 
  # rename column names
  rename("ID" = "X1", "Date_Time" = "X2", "Time_zone" = "X3", "SoilTemperature" = "X4", "GroundTemperaure" = "X5", "AirTemperature" = "X6", "RawSoilmoisture" = "X7", "Shake" = "X8", "ErrorFlag" = "X9") %>% 
  mutate(Date_Time = ymd_hm(Date_Time)) %>% 
  # Soil moisture calibration
  #mutate(SoilMoisture = a * RawSoilmoisture^2 + b * RawSoilmoisture + c) %>% 
  # get logger ID
  mutate(LoggerID = as.numeric(substr(File, nchar(File)-9, nchar(File)-6))) %>% 
  left_join(meta, by = "LoggerID")
  


  
  


