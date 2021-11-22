###########################
### READ IN DATA ###
###########################

source("R/Load packages.R")

source("R/Rgathering/create meta data.R")
source("R/Climate/soilmoisture_correction.R")

# Download raw data from OSF
# get_file(node = "pk4bg",
#          file = "THREE-D_Climate_Tomst_2019_2020.zip",
#          path = "data/climate",
#          remote_path = "RawData/Climate")



#### CLIMATE DATA ####

# Read in meta data
metaTomst <- read_excel(path = "data/climate/Three-D_ClimateLogger_Meta_2019.xlsx", col_names = TRUE, col_types = c("text", "numeric", "numeric", "text", "date", "date", "date", "date", "date",  rep("text", 12))) %>% 
  mutate(InitialDate = ymd(InitialDate),
         InitialDate_Time = ymd_hm(paste(InitialDate, paste(hour(InitialTime), minute(InitialTime), sep = ":"), sep = " ")),
         EndDate_Time = ymd_hm(paste(EndDate, paste(hour(EndTime), minute(EndTime), sep = ":"), sep = " "))) %>% 
  select(destSiteID:loggerID, InitialDate_Time, EndDate_Time, earlyStart, Remark:Remark_17_10_21)


### Read in files
# list of files
files <- dir(path = "data/climate", 
           pattern = "^data.*\\.csv$", 
           recursive = TRUE, full.names = TRUE) %>% 
  # remove empty file
  grep(pattern = "2020_Sept_Joa/data_94195216_0|2021_Spring_lia|2021_Spring_Joa", 
       x = ., 
       invert = TRUE, value = TRUE, ignore.case = TRUE)

# list of files with comma for decimal separator
odd_files <- dir(path = "data/climate", 
                 pattern = "^data.*\\.csv$", 
                 recursive = TRUE, full.names = TRUE) %>% 
  # remove empty file
  grep(pattern = "2021_Spring_lia|2021_Spring_Joa", 
       x = ., 
       value = TRUE, ignore.case = TRUE)

# Read in data
temp_raw <- bind_rows(
  map_df(set_names(files), function(file) {
  file %>% 
    set_names() %>% 
    map_dfr(~ read_delim(file = file, col_names = FALSE, delim = ";"))
}, .id = "file"),

  map_df(set_names(odd_files), function(file) {
  file %>%
    set_names() %>%
    map_df(~ read_csv2(file = file, col_names = FALSE))
}, .id = "file")
)

# These are 3 unknown loggers. Temp pattern does not fit with rest of the data. And short time period
# "94201711", "94201712", "94201713"

microclimate <- temp_raw %>% 
  # rename column names
  rename("ID" = "X1", "date_time" = "X2", "time_zone" = "X3", "soil_temperature" = "X4", "ground_temperature" = "X5", "air_temperature" = "X6", "raw_soilmoisture" = "X7", "shake" = "X8", "error_flag" = "X9") %>% 
  mutate(date_time = ymd_hm(date_time)) %>% 
  mutate(loggerID = substr(file, nchar(file)-13, nchar(file)-6)) %>%
  
  # join meta data on loggers
  left_join(metaTomst, by = "loggerID") %>% 
  select(-c(`Download_24_09-19`:Remark_17_10_21)) %>% 

  # Remove data before initial date time
  filter(date_time > InitialDate_Time,
         is.na(EndDate_Time) |
         date_time < EndDate_Time) %>% 
  
  # some data cleaning
  mutate(air_temperature = case_when(
    loggerID %in% c("94195252", "94195220",  "94195231") & air_temperature < -40 ~ NA_real_,
    loggerID %in% c("94195208") & air_temperature < -20 ~ NA_real_,
    loggerID == "94195209" & date_time > "2020-08-12 00:00:00" & date_time < "2020-08-13 00:00:00" ~ NA_real_,
    TRUE ~ as.numeric(air_temperature)),
         
         ground_temperature = case_when(
           loggerID %in% c("94195208", "94195252") & ground_temperature < -40 ~ NA_real_,
           loggerID == "94195209" & date_time > "2020-08-12 00:00:00" & date_time < "2020-08-13 00:00:00" ~ NA_real_,
           TRUE ~ as.numeric(ground_temperature)),
         
         soil_temperature = case_when(loggerID %in% c("94195252", "94195236", "94195231") & soil_temperature < -40 ~ NA_real_,
           loggerID %in% c("94200499", "94195246", "94195201", "94195212", "94195218", "94200491") & soil_temperature > 25 ~ NA_real_,
           loggerID %in% c("94195271") & soil_temperature > 35 ~ NA_real_,
           loggerID %in% c("94195230", "94195224", "94200495") & soil_temperature > 20 ~ NA_real_,
           loggerID %in% c("94200493", "94200499") & date_time < "2020-07-03 08:00:00" ~ NA_real_,
           loggerID %in% c("94195208") & error_flag == 1 ~ NA_real_,
           loggerID == "94200493" & date_time > "2020-07-17 01:00:00" & date_time < "2020-09-16 01:00:00" ~ NA_real_,
           loggerID == "94195209" & date_time > "2020-08-12 00:00:00" & date_time < "2020-08-13 00:00:00" ~ NA_real_,
           loggerID == "94195206" & date_time > "2020-06-19 01:00:00" & date_time < "2020-06-26 01:00:00" ~ NA_real_,
           loggerID == "94195220" & date_time > "2020-06-18 01:00:00" & date_time < "2020-06-26 01:00:00" ~ NA_real_,
           loggerID == "94195251" & date_time > "2020-06-21 01:00:00" & date_time < "2020-06-26 01:00:00" ~ NA_real_,
           loggerID == "94195250" & date_time > "2020-06-28 01:00:00" & date_time < "2020-07-04 01:00:00" ~ NA_real_,
           loggerID == "94195216" & date_time > "2019-09-27 01:00:00" & date_time < "2019-10-01 01:00:00" ~ NA_real_,
           loggerID == "94195257" & date_time > "2020-06-17 01:00:00" & date_time < "2020-06-26 01:00:00" ~ NA_real_,
           loggerID %in% c("94195235", "94195264") & date_time > "2019-11-01 01:00:00" & date_time < "2020-05-12 01:00:00" ~ NA_real_,
           TRUE ~ as.numeric(soil_temperature))) %>% 
  
  #join with meta data table
  left_join(metaTurfID, by = c("destSiteID", "destBlockID", "destPlotID")) %>% 
  select(date_time, destSiteID, destBlockID, destPlotID, turfID, origPlotID, origBlockID, origSiteID, warming, Nlevel, grazing, soil_temperature:raw_soilmoisture, loggerID, shake, error_flag, InitialDate_Time:EndDate_Time, Remark, file)

# Soil moisture correction using function
microclimate <- microclimate %>% 
  mutate(soilmoisture = soil.moist(rawsoilmoist = raw_soilmoisture, 
                                   soil_temp = soil_temperature, 
                                   soilclass = "loamy_sand_A")) %>% 
  select(date_time:air_temperature, soilmoisture, loggerID:file)

#ggplot(microclimate, aes(x = soilmoisture, y = raw_soilmoisture)) + geom_point()

# Save clean file
write_csv(x = microclimate, file = "data_cleaned/climate/THREE-D_clean_microclimate_2019-2021.csv")



# strange soil temp data, but probably ok
# 94200497 around june 2021
# 94195216 around june 2020
# need to be a bit careful with soil temp at vik, variance is variable


# Checking data
dd <- microclimate %>% 
  #filter(destSiteID == "Joa")
  filter(loggerID %in% c("94195271")) %>% 
  filter(date_time > "2020-06-01 08:00:00" & date_time < "2020-07-30 08:00:00")
ggplot(dd, aes(x = date_time, y = soil_temperature)) +
  geom_line() +
  geom_vline(xintercept = ymd_hms("2020-06-17 01:00:00"), colour = "pink") +
  geom_vline(xintercept = ymd_hms("2020-06-26 01:00:00"), colour = "lightblue") +
  facet_wrap(~ loggerID) +
  theme(legend.position = "none")


climate <- read_csv("data_cleaned/climate/THREE-D_clean_microclimate_2019-2021.csv")

dd <- climate %>% filter(destSiteID == "Vik")
ggplot(dd, aes(x = date_time, y = ground_temperature)) +
  geom_line() +
  facet_wrap(~ turfID) +
  theme(legend.position = "none")


### Trying to automate data cleaning usin folling functions

# special packages
#library(tibbletime)

# Custom function to return mean, sd, 95% conf interval
rolling_functions <- function(x, na.rm = TRUE) {

  m  <- mean(x, na.rm = na.rm)
  s  <- sd(x, na.rm = na.rm)
  hi <- m + 2*s
  lo <- m - 2*s

  ret <- c(mean = m, stdev = s, hi.95 = hi, lo.95 = lo)
  return(ret)
}

# calculate rolling mean and sd to remove outliers
# functions to perform
rollli_functions <- function(x) {
  data.frame(  
    rolled_summary_type = c("roll_mean", "roll_sd"),
    rolled_summary_value  = c(mean(x), sd(x))
  )
}
# window for half a day
rolling_summary <- rollify(~ rollli_functions(.x), window = 48, unlist = FALSE)

temp_raw1_rollo <- dd %>% 
  mutate(rollo_soil = rolling_summary(soil_temperature),
         rollo_ground = rolling_summary(soil_temperature),
         rollo_air = rolling_summary(soil_temperature)) 
#saveRDS(temp_raw1_rollo, "temp_raw1_rollo.RDS")

temp_raw1_rollo_unnest <- temp_raw1_rollo %>% 
  unnest(cols = c(rollo_soil)) %>% 
  filter(!is.na(rolled_summary_type)) %>% 
  pivot_wider(names_from = rolled_summary_type, values_from = rolled_summary_value) %>% 
  ggplot(aes(x = date_time, y = roll_sd)) +
  geom_line()



  # make long table
  pivot_longer(cols = soil_temperature:air_temperature, names_to = "variable", values_to = "value")
  
    # Curate data (outliers, logger failure etc)
    # usually a rolling sd

dd %>% 
  # fix values with stdev > 2
  mutate(value = if_else(variable == "soiltemperature" & loggerID %in% c("94195224", "94195230", "94195246", "94195250", "94195256", "94200493", "94200495", "942004939", "94195206", "94195220", "94195251", "94195257") & stdev > 2), NA_real_, value,
         # Problems at Vikesland stdev > 3
         value = if_else(variable == "soiltemperature" & loggerID %in% c("94195235", "94195264", "94195263") & stdev > 3), NA_real_, value)
  
dd <- temp_raw1 %>%
  # remove period with wrong values for this logger
  mutate(value = if_else(loggerID == "94200493" & variable == "soil_temperature" & date_time > "2020-07-17 01:00:00" & date_time < "2020-09-16 01:00:00", NA_real_, value)) %>% 
  # remove when error flag is > 0 for soil, air and ground
  # These logger need to be checked again when new data is added
  mutate(value = if_else(loggerID %in% c("94195209", "94195252", "94195208") & variable %in% c("soil_temperature", "ground_temperature", "air_temperature") & error_flag > 0, NA_real_, value)) %>% 
  # only soil temp needs to be removed
  mutate(value = if_else(loggerID == "94195236" & variable == "soil_temperature" & error_flag > 0, NA_real_, value)) 

