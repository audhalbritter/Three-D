###########################
### READ IN DATA ###
###########################

source("R/Load packages.R")
# only needed for soiltemp template
source("R/Rgathering/ReadInPlotLevel.R")


#### CLIMATE DATA ####

# Read in meta data
metaTomst <- read_excel(path = "data/metaData/Three-D_ClimateLogger_Meta_2019.xlsx", col_names = TRUE, col_types = c("text", "numeric", "numeric", "text", "date", "date", "date", "text", "date", "date", "text", "date", "text", "date", "text", "date", "text", "date", "text")) %>% 
  mutate(InitialDate = ymd(InitialDate),
         InitialDate_Time = ymd_hm(paste(InitialDate, paste(hour(InitialTime), minute(InitialTime), sep = ":"), sep = " ")))


### Read in files
files <- dir(path = "data/climate tomst", pattern = "^data.*\\.csv$", full.names = TRUE, recursive = TRUE)

# remove empty file
files <- files[!(files %in% c("data/climate tomst/2020_Sept_Joa/data_94195216_0.csv"))]

# Function to read in data
temp <- map_df(set_names(files), function(file) {
  file %>% 
    set_names() %>% 
    map_df(~ read_delim(file = file, col_names = FALSE, delim = ";"))
}, .id = "File")


# These are 3 unknown loggers. Temp pattern does not fit with rest of the data. And short time period
# "94201711", "94201712", "94201713"


TomstLogger_2019_2020 <- temp %>% 
  # rename column names
  rename("ID" = "X1", "Date_Time" = "X2", "Time_zone" = "X3", "SoilTemperature" = "X4", "GroundTemperature" = "X5", "AirTemperature" = "X6", "RawSoilmoisture" = "X7", "Shake" = "X8", "ErrorFlag" = "X9") %>% 
  mutate(Date_Time = ymd_hm(Date_Time)) %>% 
  # Soil moisture calibration
  #mutate(SoilMoisture = a * RawSoilmoisture^2 + b * RawSoilmoisture + c) %>% 
  # get logger ID -> not needed anymore, have whole filename now!!!
  mutate(LoggerID = substr(File, nchar(File)-13, nchar(File)-6)) %>% 
  left_join(metaTomst, by = "LoggerID") %>% 
  
  # Data curation
  
  # Remove data before initial date time
  group_by(LoggerID) %>% 
  filter(Date_Time > InitialDate_Time) %>% 
  
  # fix wrong values
  mutate(AirTemperature = case_when(LoggerID %in% c("94195252", "94195220") & AirTemperature < -40 ~ NA_real_,
                                    LoggerID == "94195209" & Date_Time > "2020-08-12 00:00:00" & Date_Time < "2020-08-13 00:00:00" ~ NA_real_,
                                    TRUE ~ as.numeric(AirTemperature)),
         
         GroundTemperature = case_when(LoggerID %in% c("94195208", "94195252") & GroundTemperature < -40 ~ NA_real_,
                                       LoggerID == "94195209" & Date_Time > "2020-08-12 00:00:00" & Date_Time < "2020-08-13 00:00:00" ~ NA_real_,
                                       TRUE ~ as.numeric(GroundTemperature)),
         
         SoilTemperature = case_when(LoggerID %in% c("94195252", "94195236") & SoilTemperature < -40 ~ NA_real_,
                                     LoggerID %in% c("94200493", "94200499") & Date_Time < "2020-07-03 08:00:00" ~ NA_real_,
                                     LoggerID %in% c("94195208") & ErrorFlag == 1 ~ NA_real_,
                                     LoggerID %in% c("94200493") & Date_Time > "2020-07-17 01:00:00" & Date_Time < "2020-09-16 01:00:00" ~ NA_real_,
                                     LoggerID == "94195209" & Date_Time > "2020-08-12 00:00:00" & Date_Time < "2020-08-13 00:00:00" ~ NA_real_,
                                    TRUE ~ as.numeric(SoilTemperature)))


# Save clean file
write_csv(x = TomstLogger_2019_2020, path = "data_cleaned/climate/THREE-D_TomstLogger_2019_2020.csv")


# Checking data
dd <- TomstLogger_2019_2020


dd %>% 
  #filter(destSiteID == "Lia") %>% 
  filter(LoggerID %in% c("94195252", "94195230")) %>% 
  #filter(SoilTemperature < 20) %>% 
  #filter(Date_Time < "2020-07-05 08:00:00") %>% 
  ggplot(aes(x = Date_Time, y = SoilTemperature, colour = as.factor(LoggerID))) +
  geom_line() +
  geom_vline(xintercept = ymd_hms("2020-06-25 12:00:00")) +
  facet_wrap(~ LoggerID) +
  theme(legend.position="none")

