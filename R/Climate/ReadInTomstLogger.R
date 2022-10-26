###########################
### READ IN DATA ###
###########################

source("R/Load packages.R")

source("R/Climate/soilmoisture_correction.R")

# Download raw data from OSF
# get_file(node = "pk4bg",
#          file = "THREE-D_Climate_Tomst_2019_2020.zip",
#          path = "data/climate",
#          remote_path = "RawData/Climate")



#### CLIMATE DATA ####

# Read in meta data
metaTomst <- read_excel(path = "data/climate/Three-D_ClimateLogger_Meta_2019.xlsx", col_names = TRUE, col_types = c("text", "numeric", "numeric", "text", "date", "date", "date", "date", "date",  rep("text", 20))) %>% 
  mutate(InitialDate = ymd(InitialDate),
         InitialDate_Time = ymd_hm(paste(InitialDate, paste(hour(InitialTime), minute(InitialTime), sep = ":"), sep = " ")),
         EndDate_Time = ymd_hm(paste(EndDate, paste(hour(EndTime), minute(EndTime), sep = ":"), sep = " "))) %>% 
  select(destSiteID:loggerID, InitialDate_Time, EndDate_Time, earlyStart, Remark:Remark_17_10_21)

### Read in files
# list of files
files <- dir(path = "data/climate/", 
           pattern = "^data.*\\.csv$", 
           recursive = TRUE, full.names = TRUE) %>% 
  # remove empty file
  grep(pattern = "2020_Sept_Joa/data_94195216_0|2021_Spring_lia|2021_Spring_Joa|2022_autumn_Joa|2022_autumn_Lia|2022_autumn_Vik", 
       x = ., 
       invert = TRUE, value = TRUE, ignore.case = TRUE)

# list of files with comma for decimal separator
odd_files <- dir(path = "data/climate", 
                 pattern = "^data.*\\.csv$", 
                 recursive = TRUE, full.names = TRUE) %>% 
  # remove empty file
  grep(pattern = "2021_Spring_lia|2021_Spring_Joa|2022_autumn_Joa|2022_autumn_Lia|2022_autumn_Vik", 
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

# Save rds file so do not have to read it everytime
#saveRDS(temp_raw, "data/climate/climate_raw.rds")

# These are 3 unknown loggers. Temp pattern does not fit with rest of the data. And short time period
# "94201711", "94201712", "94201713"

# create metaTurfID
metaTurfID <- create_threed_meta_data()

microclimate <- temp_raw %>% 
  # remove empty row
  select(-X10) |> 
  # rename column names
  rename("ID" = "X1", "date_time" = "X2", "time_zone" = "X3", "soil_temperature" = "X4", "ground_temperature" = "X5", "air_temperature" = "X6", "raw_soilmoisture" = "X7", "shake" = "X8", "error_flag" = "X9") %>% 
  mutate(date_time = ymd_hm(date_time)) %>% 
  
  # autumn 2022 logger name is longer
  mutate(file = gsub("_2022_10_07|_2022_10_07|_2022_10_07", "", file)) |> 
  # extract loggerID
  mutate(loggerID = substr(file, nchar(file)-13, nchar(file)-6)) %>%
  
  # remove corrupt part of file
  filter(!(file == "data/climate/2022_autumn_Joa/data_94195255_0.csv" & date_time < "2022-05-01 00:00:00")) |>

  # remove duplicate data (due to always downloading all the data)
  tidylog::distinct(loggerID, date_time, time_zone, soil_temperature, ground_temperature, air_temperature, raw_soilmoisture, shake, error_flag) |> 
  
  # join meta data on loggers
  left_join(metaTomst, by = "loggerID") %>% 
  select(-c(`Download_24_09-19`:Remark_17_10_21)) %>% 

  # Remove data before initial date time
  tidylog::filter(date_time > InitialDate_Time,
         is.na(EndDate_Time) |
         date_time < EndDate_Time) %>% 
  
  # some data cleaning
  # air
  mutate(air_temperature = case_when(
    loggerID %in% c("94195205", "94195225", "94195252", "94195220",  "94195231", "94195237") & air_temperature < -40 ~ NA_real_,
    loggerID %in% c("94195208") & air_temperature < -20 ~ NA_real_,
    loggerID == "94195209" & date_time > "2020-08-12 00:00:00" & date_time < "2020-08-13 00:00:00" ~ NA_real_,
    TRUE ~ as.numeric(air_temperature)),
         
    # ground
         ground_temperature = case_when(
           loggerID %in% c("94195208", "94195252") & ground_temperature < -40 ~ NA_real_,
           loggerID == "94195209" & date_time > "2020-08-12 00:00:00" & date_time < "2020-08-13 00:00:00" ~ NA_real_,
           TRUE ~ as.numeric(ground_temperature)),
         
    #soil
         soil_temperature = case_when(loggerID %in% c("94195255", "94195205", "94195225", "94195252", "94195236", "94195231") & soil_temperature < -40 ~ NA_real_,
           loggerID %in% c("94195255", "94195225", "94195242", "94200499", "94195246", "94195201", "94195212", "94195218", "94200491") & soil_temperature > 25 ~ NA_real_,
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
           loggerID == "94195239" & date_time > "2022-06-20 01:00:00" & date_time < "2022-07-01 01:00:00" ~ NA_real_,
           
           
           loggerID %in% c("94195235", "94195264") & date_time > "2019-11-01 01:00:00" & date_time < "2020-05-12 01:00:00" ~ NA_real_,
           TRUE ~ as.numeric(soil_temperature))) %>% 
  
  #join with meta data table
  left_join(metaTurfID, by = c("destSiteID", "destBlockID", "destPlotID")) %>% 
  select(date_time, destSiteID, destBlockID, destPlotID, turfID, origPlotID, origBlockID, origSiteID, warming, Nlevel, grazing, Namount_kg_ha_y, soil_temperature:raw_soilmoisture, loggerID, shake, error_flag, InitialDate_Time:EndDate_Time, Remark)

# Soil moisture correction using function
microclimate <- microclimate %>% 
  mutate(soilmoisture = soil.moist(rawsoilmoist = raw_soilmoisture, 
                                   soil_temp = soil_temperature, 
                                   soilclass = "loamy_sand_A")) %>% 
  
  select(date_time:air_temperature, soilmoisture, loggerID:Remark) |> 
  
  # soil moisture cleaning
  mutate(soilmoisture = case_when(soilmoisture < 0 ~ NA_real_,
                                  # Lia
                                  destSiteID == "Lia" & soilmoisture < 0.1 & loggerID != "94195225" ~ NA_real_,
                                  loggerID == "94195225" & soilmoisture < 0.03 ~ NA_real_,
                                  
                                  # Joa
                                  # ambient
                                  loggerID == "94195260" & date_time == ymd_hms("2020-08-10 17:00:00") ~ NA_real_,
                                  loggerID == "94195262" & date_time == ymd_hms("2022-07-06 13:30:00") ~ NA_real_,
                                  loggerID == "94195223" & date_time == ymd_hms("2022-07-06 09:45:00") ~ NA_real_,
                                  loggerID == "94195211" & date_time >= ymd_hms("2020-07-17 11:45:00") & 
                                    date_time <= ymd_hms("2020-07-17 12:30:00") ~ NA_real_,
                                  loggerID == "94195223" & date_time == ymd_hms("2022-07-06 10:00:00") ~ NA_real_,
                                  loggerID == "94195219" & date_time >= ymd_hms("2022-07-04 17:30:00") & 
                                    date_time <= ymd_hms("2022-07-04 18:15:00") ~ NA_real_,
                                  loggerID == "94195254" & date_time == ymd_hms("2020-07-17 12:45:00") ~ NA_real_,
                                  loggerID == "94195254" & date_time >= ymd_hms("2022-07-04 13:15:00") & 
                                    date_time <= ymd_hms("2022-07-04 14:00:00 ") ~ NA_real_,
                                  loggerID == "94195255" & date_time >= ymd_hms("2022-08-15 13:30:00") & 
                                    date_time <= ymd_hms("2022-08-15 14:45:00") ~ NA_real_,
                                  loggerID == "94195253" & date_time >= ymd_hms("2022-07-07 11:15:00") & 
                                    date_time <= ymd_hms("2022-07-07 12:30:00") ~ NA_real_,
                                  # warm
                                  loggerID == "94195258" & date_time == ymd_hms("2020-09-08 08:45:00") ~ NA_real_,
                                  loggerID == "94195258" & date_time >= ymd_hms("2022-07-08 06:30:00") & 
                                    date_time <= ymd_hms("2022-07-08 08:00:00") ~ NA_real_,
                                  loggerID == "94195201" & date_time >= ymd_hms("2022-07-07 15:30:00") & 
                                    date_time <= ymd_hms("2022-07-07 16:00:00") ~ NA_real_,
                                  loggerID == "94195213" & date_time >= ymd_hms("2022-07-06 15:00:00") & 
                                    date_time <= ymd_hms("2022-07-06 15:15:00") ~ NA_real_,
                                  loggerID == "94195213" & date_time == ymd_hms("2020-09-08 09:45:00") ~ NA_real_,
                                  loggerID == "94195204" & date_time == ymd_hms("2022-07-06 14:30:00") ~ NA_real_,
                                  loggerID == "94195266" & date_time == ymd_hms("2022-08-16 08:15:00") ~ NA_real_,
                                  loggerID == "94195269" & date_time >= ymd_hms("2022-07-06 08:15:00") & 
                                    date_time <= ymd_hms("2022-07-06 09:15:00") ~ NA_real_,
                                  loggerID == "94195269" & date_time >= ymd_hms("2022-08-16 08:00:00") & 
                                    date_time <= ymd_hms("2022-08-16 09:15:00") ~ NA_real_,
                                  loggerID == "94195203" & date_time >= ymd_hms("2022-07-05 15:45:00") & 
                                    date_time <= ymd_hms("2022-07-05 16:15:00") ~ NA_real_,
                                  loggerID == "94195215" & date_time >= ymd_hms("2022-07-05 08:00:00") & 
                                    date_time <= ymd_hms("2022-07-05 09:45:00") ~ NA_real_,
                                  loggerID == "94195207" & date_time == ymd_hms("2022-06-13 12:45:00") ~ NA_real_,
                                  loggerID == "94195202" & date_time == ymd_hms("2020-06-25 13:00:00") ~ NA_real_,
                                  loggerID == "94195210" & date_time == ymd_hms("2020-09-09 15:30:00") ~ NA_real_,
                                  loggerID == "94195210" & date_time == ymd_hms("2021-06-23 09:15:00") ~ NA_real_,
                                  
                                  # Vik
                                  loggerID == "94195231" & date_time == ymd_hms("2022-05-30 11:15:00") ~ NA_real_,
                                  loggerID == "94195231" & date_time == ymd_hms("2022-05-30 09:15:00") ~ NA_real_,
                                  loggerID == "94195271" & date_time == ymd_hms("2020-09-11 09:15:00") ~ NA_real_,
                                  loggerID == "94195263" & date_time == ymd_hms("2020-09-07 11:45:00") ~ NA_real_,
                                  
                                  loggerID == "94195240" & date_time == ymd_hms("2020-09-11 09:45:00") ~ NA_real_,
                                  loggerID == "94200491" & date_time == ymd_hms("2021-06-05 11:15:00") ~ NA_real_,
                                  loggerID == "94200491" & date_time == ymd_hms("2022-08-18 13:45:00") ~ NA_real_,
                                  loggerID == "94195233" & date_time == ymd_hms("2022-07-05 12:30:00") ~ NA_real_,
                                  loggerID == "94195233" & date_time == ymd_hms("2022-07-05 12:45:00") ~ NA_real_,
                                  loggerID == "94195267" & date_time == ymd_hms("2022-05-30 13:00:00") ~ NA_real_,
                                  loggerID == "94195267" & date_time == ymd_hms("2022-08-18 13:30:00") ~ NA_real_,
                                  
                                  TRUE ~ as.numeric(soilmoisture)))
  


# Save clean file
write_csv(x = microclimate, file = "data_cleaned/climate/THREE-D_clean_microclimate_2019-2022.csv")


# strange soil temp data, but probably ok
# 94200497 around june 2021
# 94195216 around june 2020
# need to be a bit careful with soil temp at vik, variance is variable

# Checking data
dd <- microclimate %>% 
  filter(destSiteID == "Vik")
  #distinct(loggerID, turfID) |> print(n = Inf)
  #filter(!soilmoisture < 0)
  
ggplot(dd, aes(x = date_time, y = soilmoisture)) +
  geom_line() +
  #geom_vline(xintercept = ymd_hms("2020-06-17 01:00:00"), colour = "pink") +
  #geom_vline(xintercept = ymd_hms("2020-06-26 01:00:00"), colour = "lightblue") +
  facet_wrap(~ turfID) +
  theme(legend.position = "none")
