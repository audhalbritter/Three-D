# clean climate data

import_climate_temp <- function(){

  ### Read in files
  # list of files
  files <- dir(path = "data/",
               pattern = "^data.*\\.csv$",
               recursive = TRUE, full.names = TRUE) %>%
    # remove empty file
    grep(pattern = "2020_Sept_Joa/data_94195216_0|2021_Spring_lia|2021_Spring_Joa|2022_autumn_Joa|2022_autumn_Lia|2022_autumn_Vik|data//Fixed_by_tomst/data_94195236_2023_09_26_0.csv|data//Fixed_by_tomst/data_tomst_94195230_0.csv",
         x = .,
         invert = TRUE, value = TRUE, ignore.case = TRUE)

  # list of files with comma for decimal separator
  odd_files <- dir(path = "data/",
                   pattern = "^data.*\\.csv$",
                   recursive = TRUE, full.names = TRUE) %>%
    # remove empty file
    grep(pattern = "2021_Spring_lia|2021_Spring_Joa|2022_autumn_Joa|2022_autumn_Lia|2022_autumn_Vik|data//Fixed_by_tomst/data_94195236_2023_09_26_0.csv",
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

}
  
# clean data
clean1_climate_temp <- function(temp_raw){
  
  temp_raw <- setDT(temp_raw)

  # other special cases
  other_dat <- read_csv2("data/Fixed_by_tomst/data_tomst_94195230_0.csv", col_names = FALSE) |>
    mutate(file = "data/Fixed_by_tomst/data_tomst_94195230_0.csv") |>
    mutate(X4 = as.double(X4),
           X5 = as.double(X5),
           X6 = as.double(X6))
  
  # continue with DT
  other_dat <- setDT(other_dat)
    
  dt <- rbind(temp_raw, other_dat, use.names = TRUE, fill = TRUE)
  
  # Assuming 'dt' is your data.table
  # Remove empty row
  dt[, X10 := NULL] 
  
  # Rename columns
  setnames(dt, old = c("X1", "X2", "X3", "X4", "X5", "X6", "X7", "X8", "X9"),
           new = c("ID", "date_time", "time_zone", "soil_temperature", 
                   "ground_temperature", "air_temperature", 
                   "raw_soilmoisture", "shake", "error_flag"))
  
  # Convert date_time to POSIXct
  # depending on if there are seconds or not
  dt <- dt |> mutate(date_time = if_else(nchar(date_time) == 16, 
                                          ymd_hm(date_time), 
                                          ymd_hms(date_time)))
  
  #dt[, date_time := ymd_hm(date_time)]
  
  # Autumn 2022 logger name adjustments
  dt[, file := gsub("_2022_10_07|_2022_10_07|_2022_10_07", "", file)]
  
  # Extract loggerID
  dt[, loggerID := substr(file, nchar(file) - 13, nchar(file) - 6)]
  
  # Remove corrupt data
  dt <- dt[!(file == "data/climate/2022_autumn_Joa/data_94195255_0.csv" & date_time < "2022-05-01 00:00:00")]
  
  # Remove duplicates
  dt <- unique(dt, by = c("loggerID", "date_time", "time_zone", 
                          "soil_temperature", "ground_temperature", 
                          "air_temperature", "raw_soilmoisture", "shake", 
                          "error_flag"))
  
  # Add year column
  dt[, year := year(date_time)]
  
}

# converted to DT
# # remove empty row
# select(-X10) |>
#   # rename column names
#   rename("ID" = "X1", "date_time" = "X2", "time_zone" = "X3", "soil_temperature" = "X4", "ground_temperature" = "X5", "air_temperature" = "X6", "raw_soilmoisture" = "X7", "shake" = "X8", "error_flag" = "X9") %>%
#   mutate(date_time = ymd_hm(date_time)) %>%
#   
#   # autumn 2022 logger name is longer
#   mutate(file = gsub("_2022_10_07|_2022_10_07|_2022_10_07", "", file)) |>
#   # extract loggerID
#   mutate(loggerID = substr(file, nchar(file)-13, nchar(file)-6)) %>%
#   
#   # remove corrupt part of file
#   filter(!(file == "data/climate/2022_autumn_Joa/data_94195255_0.csv" & date_time < "2022-05-01 00:00:00")) |>
#   
#   # remove duplicate data (due to always downloading all the data)
#   tidylog::distinct(loggerID, date_time, time_zone, soil_temperature, ground_temperature, air_temperature, raw_soilmoisture, shake, error_flag) |>
#   
#   mutate(year = year(date_time)) |>



clean2_climate_temp <- function(temp1, metaTomst){

  # Join with meta data

  metaTomst <- setDT(metaTomst |>
                       tidylog::filter(!is.na(InitialDate_Time)))
  metaTomst[, year := year(InitialDate_Time)]
  # Remove unwanted columns
  metaTomst <- metaTomst[, !c("Download_24_09-19", "Download_11_05_20", "Remark_11_05_20", "Download_25_06_20", "Remark_25_06_20", "Download_28_09_20", "Remark_28_09_20", "Download_23_09_20", "Remark_23_09_20", "Download_17_10_21", "Remark_17_10_21"), with = FALSE]

  m2 <- metaTomst |>
    distinct(loggerID, year, InitialDate_Time, EndDate_Time) |>
    mutate(Start = year(InitialDate_Time),
           End = year(EndDate_Time)) |> 
    group_by(loggerID, year) |>
    nest() %>%
    mutate(year2 = map(data, ~seq(.$Start, .$End, by = 1))) |>
    unnest(year2) |>
    ungroup() |>
    select(-data)

  metaTomst2 <- metaTomst |>
    full_join(m2, by = c("loggerID", "year")) |>
    select(destSiteID:Remark, year = year2)


  temp2 <- temp1 |>
    tidylog::mutate(loggerID = if_else(loggerID == "23_09_26", "94195236", loggerID)) |> 
    tidylog::left_join(metaTomst2,
                       by = c("loggerID", "year")) |> 
    # Remove data before initial date time
    tidylog::filter(date_time > InitialDate_Time,
                      is.na(EndDate_Time) |
                      date_time < EndDate_Time)

}

# temp1 |> filter(loggerID == "94200493") |> distinct(file)
# metaTomst |> filter(loggerID == "94195261")
# 
# loggerID
# 1: 94195261: seedclim
# 2: 94195252: ends early
# 3: 94195262: seedclim
# 4: 94195269: seedclim
# 5: 94200491
# 6: 94200493 -> lia new block
# 7: 94200494
# 8: 94200495
# 9: 94200496
# 10: 94200497 -> lia new block
# 11: 94200499 -> lia new block
# 12: 94201707: only 21, 22
# 13: 94200498: only 21, 22
# 14: 94201711
# 15: 94201712
# 16: 94201713
# 17: 94200500
   
#   # join meta data on loggers
#   left_join(metaTomst, by = "loggerID") %>% 
#   select(-c(`Download_24_09-19`:Remark_17_10_21)) %>% 
#   
#   # Remove data before initial date time
#   tidylog::filter(date_time > InitialDate_Time,
#                   is.na(EndDate_Time) |
#                     date_time < EndDate_Time)



clean_air_ground_soil_temp <- function(temp2){
  
  # clean air temp
  temp2[, air_temperature := fifelse(
    loggerID %in% c("94195205", "94195225", "94195252", "94195220", "94195231", "94195237", "94195255") & air_temperature < -40, NA_real_,
    fifelse(loggerID %in% c("94195208", "94195241") & air_temperature < -20, NA_real_,
            fifelse(loggerID == "94195209" & date_time > "2020-08-12 00:00:00" & date_time < "2020-08-13 00:00:00", NA_real_,
                    as.numeric(air_temperature)
            )))
  ]
  
  # temp2[, air_temperature := fifelse(loggerID %in% c("94195255") & air_temperature > 35, NA_real_, air_temperature)]
  temp2[
    loggerID == "94195255" & date_time > "2019-10-24 00:00:00" & date_time < "2019-10-24 04:00:00", 
    air_temperature := NA_real_
  ]

  # clean ground temp
  temp2[, ground_temperature := fifelse(
    loggerID %in% c("94195208", "94195252", "94195241", "94195255") & ground_temperature < -40, NA_real_,
            fifelse(loggerID == "94195209" & date_time > "2020-08-12 00:00:00" & date_time < "2020-08-13 00:00:00", NA_real_,
                    as.numeric(ground_temperature)
            ))
  ]
  
  temp2[, ground_temperature := fifelse(
    loggerID %in% c("94195255", "94195241") & ground_temperature > 35, NA_real_,
    fifelse(loggerID == "94195241" & ground_temperature < -20, NA_real_, ground_temperature)
  )
  ]
  
  # First set of conditions
  temp2[, soil_temperature := fifelse(
    loggerID %in% c("94195255", "94195205", "94195225", "94195252", "94195236", "94195231", "94195241") & soil_temperature < -40, NA_real_,
    as.numeric(soil_temperature))
    ]
  
  temp2[, soil_temperature := fifelse(
    loggerID %in% c("94195241") & soil_temperature < -10, NA_real_,
    fifelse(loggerID == "94195241" & soil_temperature > 20, NA_real_, soil_temperature)
  )
  ]
  
  temp2[
    loggerID == "94195255" & date_time > "2019-10-24 00:00:00" & date_time < "2019-10-24 04:00:00", 
    soil_temperature := NA_real_
  ]
  
  # Second set of conditions
  temp2[, soil_temperature := fifelse(
    loggerID %in% c("94195255", "94195225", "94195242", "94200499", "94195246", "94195201", "94195212", "94195218", "94200491") & soil_temperature > 25, NA_real_,
    soil_temperature)]
  
  # Third set of conditions
  temp2[, soil_temperature := fifelse(
    loggerID %in% c("94195271") & soil_temperature > 35, NA_real_,
    soil_temperature)]
  
  # Fourth set of conditions
  temp2[, soil_temperature := fifelse(
    loggerID %in% c("94195230", "94195224", "94200495") & soil_temperature > 20, NA_real_,
    soil_temperature)]
  
  # Fifth set of conditions (date-time based)
  temp2[, soil_temperature := fifelse(
    loggerID %in% c("94200493", "94200499") & date_time < "2020-07-03 08:00:00", NA_real_,
    soil_temperature)]
  
  # Sixth set of conditions (error flag based)
  temp2[, soil_temperature := fifelse(
    loggerID %in% c("94195208") & error_flag == 1, NA_real_,
    soil_temperature)]
  
  # Additional date-time based conditions
  temp2[, soil_temperature := fifelse(
    loggerID == "94200493" & date_time > "2020-07-17 01:00:00" & date_time < "2020-09-16 01:00:00", NA_real_,
    soil_temperature)]
  
  temp2[, soil_temperature := fifelse(
    loggerID == "94195209" & date_time > "2020-08-12 00:00:00" & date_time < "2020-08-13 00:00:00", NA_real_,
    soil_temperature)]
  
  temp2[, soil_temperature := fifelse(
    loggerID == "94195206" & date_time > "2020-06-19 01:00:00" & date_time < "2020-06-26 01:00:00", NA_real_,
    soil_temperature)]
  
  # More conditions
  temp2[, soil_temperature := fifelse(
    loggerID == "94195220" & date_time > "2020-06-18 01:00:00" & date_time < "2020-06-26 01:00:00", NA_real_,
    soil_temperature)]
  
  temp2[, soil_temperature := fifelse(
    loggerID == "94195251" & date_time > "2020-06-21 01:00:00" & date_time < "2020-06-26 01:00:00", NA_real_,
    soil_temperature)]
  
  temp2[, soil_temperature := fifelse(
    loggerID == "94195250" & date_time > "2020-06-28 01:00:00" & date_time < "2020-07-04 01:00:00", NA_real_,
    soil_temperature)]
  
  temp2[, soil_temperature := fifelse(
    loggerID == "94195216" & date_time > "2019-09-27 01:00:00" & date_time < "2019-10-01 01:00:00", NA_real_,
    soil_temperature)]
  
  temp2[, soil_temperature := fifelse(
    loggerID == "94195257" & date_time > "2020-06-17 01:00:00" & date_time < "2020-06-26 01:00:00", NA_real_,
    soil_temperature)]
  
  temp2[, soil_temperature := fifelse(
    loggerID == "94195239" & date_time > "2022-06-20 01:00:00" & date_time < "2022-07-01 01:00:00", NA_real_,
    soil_temperature)]
  
  # Final set of conditions
  temp2[, soil_temperature := fifelse(
    loggerID %in% c("94195235", "94195264") & date_time > "2019-11-01 01:00:00" & date_time < "2020-05-12 01:00:00", NA_real_,
    soil_temperature)]
  
}

# convert to DT
  # temp_raw4 <- temp_raw3 |>
  #   # some data cleaning
  #   # air
  #   mutate(air_temperature = case_when(
  #     loggerID %in% c("94195205", "94195225", "94195252", "94195220",  "94195231", "94195237") & air_temperature < -40 ~ NA_real_,
  #     loggerID %in% c("94195208") & air_temperature < -20 ~ NA_real_,
  #     loggerID == "94195209" & date_time > "2020-08-12 00:00:00" & date_time < "2020-08-13 00:00:00" ~ NA_real_,
  #     TRUE ~ as.numeric(air_temperature)))

  # temp_raw5 <- temp_raw4 |>
  #     # ground
  #   mutate(ground_temperature = case_when(
  #       loggerID %in% c("94195208", "94195252") & ground_temperature < -40 ~ NA_real_,
  #       loggerID == "94195209" & date_time > "2020-08-12 00:00:00" & date_time < "2020-08-13 00:00:00" ~ NA_real_,
  #       TRUE ~ as.numeric(ground_temperature)))

# temp_raw6 <- temp_raw5 |>
#   #soil
#   mutate(soil_temperature = case_when(loggerID %in% c("94195255", "94195205", "94195225", "94195252", "94195236", "94195231") & soil_temperature < -40 ~ NA_real_,
#                                       loggerID %in% c("94195255", "94195225", "94195242", "94200499", "94195246", "94195201", "94195212", "94195218", "94200491") & soil_temperature > 25 ~ NA_real_,
#                                       loggerID %in% c("94195271") & soil_temperature > 35 ~ NA_real_,
#                                       loggerID %in% c("94195230", "94195224", "94200495") & soil_temperature > 20 ~ NA_real_,
#                                       loggerID %in% c("94200493", "94200499") & date_time < "2020-07-03 08:00:00" ~ NA_real_,
#                                       loggerID %in% c("94195208") & error_flag == 1 ~ NA_real_,
#                                       loggerID == "94200493" & date_time > "2020-07-17 01:00:00" & date_time < "2020-09-16 01:00:00" ~ NA_real_,
#                                       loggerID == "94195209" & date_time > "2020-08-12 00:00:00" & date_time < "2020-08-13 00:00:00" ~ NA_real_,
#                                       loggerID == "94195206" & date_time > "2020-06-19 01:00:00" & date_time < "2020-06-26 01:00:00" ~ NA_real_,
#                                       loggerID == "94195220" & date_time > "2020-06-18 01:00:00" & date_time < "2020-06-26 01:00:00" ~ NA_real_,
#                                       loggerID == "94195251" & date_time > "2020-06-21 01:00:00" & date_time < "2020-06-26 01:00:00" ~ NA_real_,
#                                       loggerID == "94195250" & date_time > "2020-06-28 01:00:00" & date_time < "2020-07-04 01:00:00" ~ NA_real_,
#                                       loggerID == "94195216" & date_time > "2019-09-27 01:00:00" & date_time < "2019-10-01 01:00:00" ~ NA_real_,
#                                       loggerID == "94195257" & date_time > "2020-06-17 01:00:00" & date_time < "2020-06-26 01:00:00" ~ NA_real_,
#                                       loggerID == "94195239" & date_time > "2022-06-20 01:00:00" & date_time < "2022-07-01 01:00:00" ~ NA_real_,
#                                       
#                                       
#                                       loggerID %in% c("94195235", "94195264") & date_time > "2019-11-01 01:00:00" & date_time < "2020-05-12 01:00:00" ~ NA_real_,
#                                       TRUE ~ as.numeric(soil_temperature)))


clean_climate_moisture <- function(temp3){
  
  d <- temp3
  
  # Step 1: Set negative values to NA for raw_soilmoisture
  d[raw_soilmoisture < 0, raw_soilmoisture := NA_real_]
  
  # Step 2: Lia site-specific cleaning
  d[destSiteID == "Lia" & raw_soilmoisture < 0.1 & loggerID != "94195225", raw_soilmoisture := NA_real_]
  d[loggerID == "94195225" & raw_soilmoisture < 0.03, raw_soilmoisture := NA_real_]
  
  # Step 3: Cleaning based on specific date_time values
  d[loggerID == "94195260" & date_time == ymd_hms("2020-08-10 17:00:00"), raw_soilmoisture := NA_real_]
  d[loggerID == "94195223" & date_time == ymd_hms("2022-07-06 09:45:00"), raw_soilmoisture := NA_real_]
  d[loggerID == "94195262" & date_time == ymd_hms("2022-07-06 13:30:00"), raw_soilmoisture := NA_real_]
  
  # Step 4: Cleaning for loggerID 94195211 in a specific time range
  d[loggerID == "94195211" & date_time >= ymd_hms("2020-07-17 11:45:00") & date_time <= ymd_hms("2020-07-17 12:30:00"), raw_soilmoisture := NA_real_]
  
  # Step 5: Additional specific conditions based on loggerID and date_time
  d[loggerID == "94195223" & date_time == ymd_hms("2022-07-06 10:00:00"), raw_soilmoisture := NA_real_]
  d[loggerID == "94195219" & date_time >= ymd_hms("2022-07-04 17:30:00") & date_time <= ymd_hms("2022-07-04 18:15:00"), raw_soilmoisture := NA_real_]
  
  # Step 6: More specific cases for various loggerID and date_time combinations
  d[loggerID == "94195254" & date_time == ymd_hms("2020-07-17 12:45:00"), raw_soilmoisture := NA_real_]
  d[loggerID == "94195254" & date_time >= ymd_hms("2022-07-04 13:15:00") & date_time <= ymd_hms("2022-07-04 14:00:00"), raw_soilmoisture := NA_real_]
  d[loggerID == "94195255" & date_time >= ymd_hms("2022-08-15 13:30:00") & date_time <= ymd_hms("2022-08-15 14:45:00"), raw_soilmoisture := NA_real_]
  
  # Step 7: Similar cleaning for other loggerID and date_time conditions
  d[loggerID == "94195253" & date_time >= ymd_hms("2022-07-07 11:15:00") & date_time <= ymd_hms("2022-07-07 12:30:00"), raw_soilmoisture := NA_real_]
  d[loggerID == "94195258" & date_time == ymd_hms("2020-09-08 08:45:00"), raw_soilmoisture := NA_real_]
  d[loggerID == "94195258" & date_time >= ymd_hms("2022-07-08 06:30:00") & date_time <= ymd_hms("2022-07-08 08:00:00"), raw_soilmoisture := NA_real_]
  
  # Step 8: Continue with more loggerID and date_time combinations
  d[loggerID == "94195201" & date_time >= ymd_hms("2022-07-07 15:30:00") & date_time <= ymd_hms("2022-07-07 16:00:00"), raw_soilmoisture := NA_real_]
  d[loggerID == "94195213" & date_time >= ymd_hms("2022-07-06 15:00:00") & date_time <= ymd_hms("2022-07-06 15:15:00"), raw_soilmoisture := NA_real_]
  d[loggerID == "94195213" & date_time == ymd_hms("2020-09-08 09:45:00"), raw_soilmoisture := NA_real_]
  
  # Step 9: Further conditions
  d[loggerID == "94195204" & date_time == ymd_hms("2022-07-06 14:30:00"), raw_soilmoisture := NA_real_]
  d[loggerID == "94195266" & date_time == ymd_hms("2022-08-16 08:15:00"), raw_soilmoisture := NA_real_]
  
  # Step 10: More conditions for loggerID 94195269 and other loggerIDs
  d[loggerID == "94195269" & date_time >= ymd_hms("2022-07-06 08:15:00") & date_time <= ymd_hms("2022-07-06 09:15:00"), raw_soilmoisture := NA_real_]
  d[loggerID == "94195269" & date_time >= ymd_hms("2022-08-16 08:00:00") & date_time <= ymd_hms("2022-08-16 09:15:00"), raw_soilmoisture := NA_real_]
  d[loggerID == "94195203" & date_time >= ymd_hms("2022-07-05 15:45:00") & date_time <= ymd_hms("2022-07-05 16:15:00"), raw_soilmoisture := NA_real_]
  d[loggerID == "94195215" & date_time >= ymd_hms("2022-07-05 08:00:00") & date_time <= ymd_hms("2022-07-05 09:45:00"), raw_soilmoisture := NA_real_]
  d[loggerID == "94195207" & date_time == ymd_hms("2022-06-13 12:45:00"), raw_soilmoisture := NA_real_]
  d[loggerID == "94195202" & date_time == ymd_hms("2020-06-25 13:00:00"), raw_soilmoisture := NA_real_]
  d[loggerID == "94195210" & date_time == ymd_hms("2020-09-09 15:30:00"), raw_soilmoisture := NA_real_]
  
  # Step 11: Cleaning for more date_time cases with Vik site loggerIDs
  d[loggerID == "94195231" & date_time == ymd_hms("2022-05-30 11:15:00"), raw_soilmoisture := NA_real_]
  d[loggerID == "94195231" & date_time == ymd_hms("2022-05-30 09:15:00"), raw_soilmoisture := NA_real_]
  d[loggerID == "94195271" & date_time == ymd_hms("2020-09-11 09:15:00"), raw_soilmoisture := NA_real_]
  d[loggerID == "94195263" & date_time == ymd_hms("2020-09-07 11:45:00"), raw_soilmoisture := NA_real_]
  
  # Step 12: Final set of conditions for loggerID and date_time
  d[loggerID == "94195233" & date_time == ymd_hms("2022-07-05 12:30:00"), raw_soilmoisture := NA_real_]
  d[loggerID == "94195233" & date_time == ymd_hms("2022-07-05 12:45:00"), raw_soilmoisture := NA_real_]
  d[loggerID == "94195267" & date_time == ymd_hms("2022-05-30 13:00:00"), raw_soilmoisture := NA_real_]
  d[loggerID == "94195267" & date_time == ymd_hms("2022-08-18 13:30:00"), raw_soilmoisture := NA_real_]
  
  
  # Soil moisture correction using function
  d[, soilmoisture := soil.moist(rawsoilmoist = raw_soilmoisture,
                                 soil_temp = soil_temperature,
                                 soilclass = "loamy_sand_A")]
  
  d[soilmoisture > 0]
  
  d[
    loggerID %in% c("94200495", "94195249") & soilmoisture < 0.2, 
    soilmoisture := NA_real_
  ]
  
  d[
    loggerID %in% c("94195244", "94195242", "94195224", "94195222") & soilmoisture < 0.1, 
    soilmoisture := NA_real_
  ]
  
  d[
    loggerID %in% c("94195225") & soilmoisture < 0.05, 
    soilmoisture := NA_real_
  ]
  
  d[
    loggerID %in% c("94200497", "94195241", "94200494") & soilmoisture < 0, 
    soilmoisture := NA_real_
  ]

}


# code converted to data.table
  # # soil moisture cleaning
  # d <- temp3 |>
  #   mutate(raw_soilmoisture = if_else(raw_soilmoisture < 0, NA_real_, raw_soilmoisture))
  # # Lia
  # d <- d |>
  #   mutate(raw_soilmoisture = if_else(destSiteID == "Lia" & raw_soilmoisture < 0.1 & loggerID != "94195225", NA_real_, raw_soilmoisture))
  # 
  # d <- d |>
  #   mutate(raw_soilmoisture = if_else(loggerID == "94195225" & raw_soilmoisture < 0.03, NA_real_, raw_soilmoisture))
  # d <- d |>
  #   mutate(raw_soilmoisture = if_else(loggerID == "94195260" & date_time == ymd_hms("2020-08-10 17:00:00"), NA_real_, raw_soilmoisture))
  # 
  # d <- d |>
  #   mutate(raw_soilmoisture = if_else(loggerID == "94195223" & date_time == ymd_hms("2022-07-06 09:45:00"), NA_real_, raw_soilmoisture))
  # 
  # d <- d |>
  #   mutate(raw_soilmoisture = if_else(loggerID == "94195262" & date_time == ymd_hms("2022-07-06 13:30:00"), NA_real_, raw_soilmoisture))
  # 
  # d <- d |>
  #   mutate(raw_soilmoisture = if_else(loggerID == "94195211" & date_time >= ymd_hms("2020-07-17 11:45:00") & date_time <= ymd_hms("2020-07-17 12:30:00"), NA_real_, raw_soilmoisture))
  # 
  # d <- d |> mutate(raw_soilmoisture = case_when(raw_soilmoisture < 0 ~ NA_real_,
  #                                 # Lia
  #                                 destSiteID == "Lia" & raw_soilmoisture < 0.1 & loggerID != "94195225" ~ NA_real_,
  #                                 loggerID == "94195225" & raw_soilmoisture < 0.03 ~ NA_real_,
  # 
  #                                 # Joa
  #                                 # ambient
  #                                 loggerID == "94195260" & date_time == ymd_hms("2020-08-10 17:00:00") ~ NA_real_,
  #                                 loggerID == "94195262" & date_time == ymd_hms("2022-07-06 13:30:00") ~ NA_real_,
  #                                 loggerID == "94195223" & date_time == ymd_hms("2022-07-06 09:45:00") ~ NA_real_,
  #                                 loggerID == "94195211" & date_time >= ymd_hms("2020-07-17 11:45:00") &
  #                                 date_time <= ymd_hms("2020-07-17 12:30:00") ~ NA_real_,
  #                                 loggerID == "94195223" & date_time == ymd_hms("2022-07-06 10:00:00") ~ NA_real_,
  #                                 loggerID == "94195219" & date_time >= ymd_hms("2022-07-04 17:30:00") &
  #                                   date_time <= ymd_hms("2022-07-04 18:15:00") ~ NA_real_,
  #                                 loggerID == "94195254" & date_time == ymd_hms("2020-07-17 12:45:00") ~ NA_real_,
  #                                 loggerID == "94195254" & date_time >= ymd_hms("2022-07-04 13:15:00") &
  #                                   date_time <= ymd_hms("2022-07-04 14:00:00 ") ~ NA_real_,
  #                                 loggerID == "94195255" & date_time >= ymd_hms("2022-08-15 13:30:00") &
  #                                   date_time <= ymd_hms("2022-08-15 14:45:00") ~ NA_real_,
  #                                 loggerID == "94195253" & date_time >= ymd_hms("2022-07-07 11:15:00") &
  #                                   date_time <= ymd_hms("2022-07-07 12:30:00") ~ NA_real_,
  #                                 # warm
  #                                 loggerID == "94195258" & date_time == ymd_hms("2020-09-08 08:45:00") ~ NA_real_,
  #                                 loggerID == "94195258" & date_time >= ymd_hms("2022-07-08 06:30:00") &
  #                                   date_time <= ymd_hms("2022-07-08 08:00:00") ~ NA_real_,
  #                                 loggerID == "94195201" & date_time >= ymd_hms("2022-07-07 15:30:00") &
  #                                   date_time <= ymd_hms("2022-07-07 16:00:00") ~ NA_real_,
  #                                 loggerID == "94195213" & date_time >= ymd_hms("2022-07-06 15:00:00") &
  #                                   date_time <= ymd_hms("2022-07-06 15:15:00") ~ NA_real_,
  #                                 loggerID == "94195213" & date_time == ymd_hms("2020-09-08 09:45:00") ~ NA_real_,
  #                                 loggerID == "94195204" & date_time == ymd_hms("2022-07-06 14:30:00") ~ NA_real_,
  #                                 loggerID == "94195266" & date_time == ymd_hms("2022-08-16 08:15:00") ~ NA_real_,
  #                                 loggerID == "94195269" & date_time >= ymd_hms("2022-07-06 08:15:00") &
  #                                   date_time <= ymd_hms("2022-07-06 09:15:00") ~ NA_real_,
  #                                 loggerID == "94195269" & date_time >= ymd_hms("2022-08-16 08:00:00") &
  #                                   date_time <= ymd_hms("2022-08-16 09:15:00") ~ NA_real_,
  #                                 loggerID == "94195203" & date_time >= ymd_hms("2022-07-05 15:45:00") &
  #                                   date_time <= ymd_hms("2022-07-05 16:15:00") ~ NA_real_,
  #                                 loggerID == "94195215" & date_time >= ymd_hms("2022-07-05 08:00:00") &
  #                                   date_time <= ymd_hms("2022-07-05 09:45:00") ~ NA_real_,
  #                                 loggerID == "94195207" & date_time == ymd_hms("2022-06-13 12:45:00") ~ NA_real_,
  #                                 loggerID == "94195202" & date_time == ymd_hms("2020-06-25 13:00:00") ~ NA_real_,
  #                                 loggerID == "94195210" & date_time == ymd_hms("2020-09-09 15:30:00") ~ NA_real_,
  #                                 loggerID == "94195210" & date_time == ymd_hms("2021-06-23 09:15:00") ~ NA_real_,
  # 
  #                                 # Vik
  #                                 loggerID == "94195231" & date_time == ymd_hms("2022-05-30 11:15:00") ~ NA_real_,
  #                                 loggerID == "94195231" & date_time == ymd_hms("2022-05-30 09:15:00") ~ NA_real_,
  #                                 loggerID == "94195271" & date_time == ymd_hms("2020-09-11 09:15:00") ~ NA_real_,
  #                                 loggerID == "94195263" & date_time == ymd_hms("2020-09-07 11:45:00") ~ NA_real_,
  # 
  #                                 loggerID == "94195240" & date_time == ymd_hms("2020-09-11 09:45:00") ~ NA_real_,
  #                                 loggerID == "94200491" & date_time == ymd_hms("2021-06-05 11:15:00") ~ NA_real_,
  #                                 loggerID == "94200491" & date_time == ymd_hms("2022-08-18 13:45:00") ~ NA_real_,
  #                                 loggerID == "94195233" & date_time == ymd_hms("2022-07-05 12:30:00") ~ NA_real_,
  #                                 loggerID == "94195233" & date_time == ymd_hms("2022-07-05 12:45:00") ~ NA_real_,
  #                                 loggerID == "94195267" & date_time == ymd_hms("2022-05-30 13:00:00") ~ NA_real_,
  #                                 loggerID == "94195267" & date_time == ymd_hms("2022-08-18 13:30:00") ~ NA_real_,
  # 
  #                                 TRUE ~ as.numeric(raw_soilmoisture)))


# d <- d |>
#   # Soil moisture correction using function
#   mutate(soilmoisture = soil.moist(rawsoilmoist = raw_soilmoisture,
#                                    soil_temp = soil_temperature,
#                                    soilclass = "loamy_sand_A"))


final_climate_cleaning <- function(temp4, metaTurfID){
  
  metaTurfID <- setDT(metaTurfID)
  
  temp4[, 
                         destSiteID := fcase(
                           destSiteID == "Joa", "Joasete",
                           destSiteID == "Lia", "Liahovden",
                           destSiteID == "Vik", "Vikesland",
                           default = destSiteID
                         )
  ]
  
  temp4[metaTurfID, on = .(destSiteID, destBlockID, destPlotID), 
    nomatch = 0][, 
                 .(date_time, 
                   destSiteID, 
                   destBlockID, 
                   destPlotID, 
                   turfID, 
                   origPlotID, 
                   origBlockID, 
                   origSiteID, 
                   warming, 
                   Nlevel, 
                   grazing, 
                   Namount_kg_ha_y, 
                   air_temperature,
                   ground_temperature,
                   soil_temperature,
                   soilmoisture,
                   loggerID, 
                   shake, 
                   error_flag, 
                   remark = Remark)]


}

# converted to DT
# clean_climate <- temp4 |>
#   # change site names
#   mutate(destSiteID = case_when(destSiteID == "Joa" ~ "Joasete",
#                                 destSiteID == "Lia" ~ "Liahovden",
#                                 destSiteID == "Vik" ~ "Vikesland",
#                                 TRUE ~ destSiteID)) |>
#   #join with meta data table
#   left_join(metaTurfID, by = c("destSiteID", "destBlockID", "destPlotID")) %>%
#   select(date_time, destSiteID, destBlockID, destPlotID, turfID, origPlotID, origBlockID, origSiteID, warming, Nlevel, grazing, Namount_kg_ha_y, soil_temperature:raw_soilmoisture, loggerID, shake, error_flag, initiale_date_time = InitialDate_Time, end_date_time = EndDate_Time, remark = Remark)

