###########################
### READ IN DATA ###
###########################

source("R/Load packages.R")

# Download raw data from OSF
# get_file(node = "pk4bg",
#          file = "THREE-D_Climate_Tomst_2019_2020.zip",
#          path = "data/climate",
#          remote_path = "RawData/Climate")


#### CLIMATE DATA ####

# Read in meta data
metaTomst <- read_excel(path = "data/climate/Three-D_ClimateLogger_Meta_2019.xlsx", col_names = TRUE, col_types = c("text", "numeric", "numeric", "text", "date", "date", "date", "date", "date", "date", "text", "date", "text", "date", "text", "date", "text", "date", "text")) %>% 
  mutate(InitialDate = ymd(InitialDate),
         InitialDate_Time = ymd_hm(paste(InitialDate, paste(hour(InitialTime), minute(InitialTime), sep = ":"), sep = " ")),
         EndDate_Time = ymd_hm(paste(EndDate, paste(hour(EndTime), minute(EndTime), sep = ":"), sep = " "))) %>% 
  select(-InitialDate, - InitialTime, -EndDate, -EndTime)


### Read in files
files <- dir(path = "data/climate", pattern = "^data.*\\.csv$", full.names = TRUE, recursive = TRUE)

# remove empty file
files <- files[!(files %in% c("data/climate/2020_Sept_Joa/data_94195216_0.csv"))] 

# Function to read in data
temp_raw <- map_df(set_names(files), function(file) {
  file %>% 
    set_names() %>% 
    map_df(~ read_delim(file = file, col_names = FALSE, delim = ";"))
}, .id = "file")


# These are 3 unknown loggers. Temp pattern does not fit with rest of the data. And short time period
# "94201711", "94201712", "94201713"

temp_raw1 <- temp_raw %>% 
  # rename column names
  rename("ID" = "X1", "date_time" = "X2", "time_zone" = "X3", "soil_temperature" = "X4", "ground_temperature" = "X5", "air_temperature" = "X6", "raw_soilmoisture" = "X7", "shake" = "X8", "error_flag" = "X9") %>% 
  mutate(date_time = ymd_hm(date_time)) %>% 
  mutate(loggerID = substr(file, nchar(file)-13, nchar(file)-6)) %>% 
  left_join(metaTomst, by = "loggerID") %>% 
  select(-c(`Download_24_09-19`:Remark_23_09_20)) %>% 
  pivot_longer(cols = soil_temperature:raw_soilmoisture, names_to = "variable", values_to = "value") %>% 
  
  # Soil moisture calibration !!!!
  #mutate(value = a * RawSoilmoisture^2 + b * RawSoilmoisture + c) %>% 

  # Data curation

  # Remove data before initial date time
  group_by(loggerID, variable) %>% 
  filter(date_time > InitialDate_Time,
         is.na(EndDate_Time) |
         date_time < EndDate_Time)

 
  
    # fix wrong values
  
dd <- temp_raw1 %>%
  # remove period with wrong values for this logger
  mutate(value = if_else(loggerID == "94200493" & variable == "soil_temperature" & date_time > "2020-07-17 01:00:00" & date_time < "2020-09-16 01:00:00", NA_real_, value)) %>% 
  # remove when error flag is > 0 for soil, air and ground
  # These logger need to be checked again when new data is added
  mutate(value = if_else(loggerID %in% c("94195209", "94195252", "94195208") & variable %in% c("soil_temperature", "ground_temperature", "air_temperature") & error_flag > 0, NA_real_, value)) %>% 
  # only soil temp needs to be removed
  mutate(value = if_else(loggerID == "94195236" & variable == "soil_temperature" & error_flag > 0, NA_real_, value)) 
  
  # remove when temp diff is too large
  


# Save clean file
#write_csv(x = TomstLogger_2019_2020, path = "data_cleaned/climate/THREE-D_TomstLogger_2019_2020.csv")


# Checking data
# problem with ending:
# "94195230", "94195256", "94195230"

# other problems
# L: "94195224", "94195230", "94195246", "94195250", "94195256", "94200493", "94200495", "942004939"
# V: "94195235", "94195264", "94195263"
# J: "94195206", "94195220", "94195251", "94195257"
  
dd %>% 
  filter(variable == "soil_temperature") %>% 
  #filter(destSiteID == "Joa") %>% 
  filter(loggerID %in% c("94195206", "94195220", "94195251", "94195257")) %>% 
  # calculate temperature difference between each step to remove obvious spikes
  mutate(lag_diff = value - lag(value)) %>% 
  #filter(abs(lag_diff) < 2) %>% 
  # group_by(day(date_time)) %>% 
  # mutate(sd = sd(value)) %>% 
  #filter(date_time > "2020-07-01 08:00:00") %>% 
  ggplot(aes(x = date_time, y = value)) +
  geom_line() +
  #geom_vline(xintercept = ymd_hms("2020-10-16 01:00:00"), colour = "pink") +
  facet_wrap(~ loggerID) +
  theme(legend.position="none")

library("zoo")
library("tidyquant")

# Custom function to return mean, sd, 95% conf interval
rolling_functions <- function(x, na.rm = TRUE) {
  
  m  <- mean(x, na.rm = na.rm)
  s  <- sd(x, na.rm = na.rm)
  hi <- m + 2*s
  lo <- m - 2*s
  
  ret <- c(mean = m, stdev = s, hi.95 = hi, lo.95 = lo) 
  return(ret)
}


# Roll apply using custom stat function
dd2 <- dd %>%
  filter(variable == "soil_temperature") %>% 
  #filter(loggerID %in% c("94195206")) %>% 
  tq_mutate(select = value,
            mutate_fun = rollapply, 
            # rollapply args
            width = 30,
            align = "right",
            by.column  = FALSE,
            FUN = rolling_functions,
            # FUN args
            na.rm = TRUE)

dd2 %>% filter(!is.na(sd)) %>% 
  group_by(loggerID, variable) %>% 
  summarise(min(stdev), max(stdev))
dd2 %>%
  filter(stdev < 2) %>% 
  ggplot(aes(x = date_time)) +
  # Data
  geom_line(aes(y = value), color = "grey40", alpha = 0.5) +
  geom_ribbon(aes(ymin = lo.95, ymax = hi.95), alpha = 0.4) +
  geom_point(aes(y = mean), linetype = 3, size = 0.1, alpha = 0.5) +
  # Aesthetics
  scale_color_tq(theme = "light") +
  g
  theme_tq() +
  theme(legend.position="none")
  
dd2 %>% 
  ggplot(aes(x = date_time, y = stdev)) +
  geom_line(color = "grey40", alpha = 0.5)












mutate(air_temperature = case_when(loggerID %in% c("94195252", "94195220") & air_temperature < -40 ~ NA_real_,
                                   #loggerID == "94195209" & date_time > "2020-08-12 00:00:00" & date_time < "2020-08-13 00:00:00" ~ NA_real_,
                                   TRUE ~ as.numeric(air_temperature)),
       
       ground_temperature = case_when(#loggerID %in% c("94195208", "94195252") & ground_temperature < -40 ~ NA_real_,
         #loggerID == "94195209" & date_time > "2020-08-12 00:00:00" & date_time < "2020-08-13 00:00:00" ~ NA_real_,
         TRUE ~ as.numeric(ground_temperature)),
       
       soil_temperature = case_when(#loggerID %in% c("94195252", "94195236") & SoilTemperature < -40 ~ NA_real_,
         loggerID %in% c("94195230") & SoilTemperature >30 ~ NA_real_,
         loggerID %in% c("94200493", "94200499") & date_time < "2020-07-03 08:00:00" ~ NA_real_,
         #loggerID %in% c("94195208") & error_flag == 1 ~ NA_real_,
         #loggerID %in% c("94200493") & date_time > "2020-07-17 01:00:00" & date_time < "2020-09-16 01:00:00" ~ NA_real_,
         #loggerID == "94195209" & date_time > "2020-08-12 00:00:00" & date_time < "2020-08-13 00:00:00" ~ NA_real_,
         TRUE ~ as.numeric(soil_temperature)))
