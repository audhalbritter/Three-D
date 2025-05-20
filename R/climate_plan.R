# climate data plan

climate_plan <- list(
  
  # climate meta
  # download data
  tar_target(
    name = metaTomst_download,
    command = get_file(node = "pk4bg",
               file = "Three-D_ClimateLogger_Meta_2019.xlsx",
               path = "data",
               remote_path = "RawData/Climate"),
    format = "file"
  ),
  
  # import and clean
  tar_target(
    name = metaTomst,
    command = read_excel(path = metaTomst_download, 
                         col_names = TRUE, 
                         col_types = c("text", "numeric", "numeric", "text", "date", "date", "date", "date", "date",  rep("text", 20))) %>% 
      mutate(InitialDate = ymd(InitialDate),
             InitialDate_Time = ymd_hm(paste(InitialDate, paste(hour(InitialTime), minute(InitialTime), sep = ":"), sep = " ")),
             EndDate_Time = ymd_hm(paste(EndDate, paste(hour(EndTime), minute(EndTime), sep = ":"), sep = " "))) %>% 
      select(destSiteID:loggerID, InitialDate_Time, EndDate_Time, earlyStart, Remark:Remark_17_10_21)
  ),
  
  # climate data
  # download data
  tar_target(
    name = climate_download,
    command = {
      get_file(node = "pk4bg",
               file = "Three-D_raw_microclimate_2019-2022.zip",
               path = "data",
               remote_path = "RawData/Climate")
      
      unzip(zipfile = "data/Three-D_raw_microclimate_2019-2022.zip", 
            exdir = "data")
      
    },
    format = "file"
  ),
  
  # download extra loggers fixed by Tomst
  tar_target(
    name = fixed_tomst_download,
    command = {
      get_file(node = "pk4bg",
                       file = "Fixed_by_tomst.zip",
                       path = "data",
                       remote_path = "RawData/Climate")
      
      unzip(zipfile = "Fixed_by_tomst", 
            exdir = "data")
      },
    format = "file"
  ),
  
  
  # import data
  tar_target(
    name = temp_raw,
    command = import_climate_temp()
  ),
  
  # clean data
  # step1
  tar_target(
    name = temp1,
    command = clean1_climate_temp(temp_raw)
  ),
  
  # step2
  tar_target(
    name = temp2,
    command = clean2_climate_temp(temp1, metaTomst)
  ),

  # clean air and ground temp
  tar_target(
    name = temp3,
    command = clean_air_ground_soil_temp(temp2)
  ),

  tar_target(
    name = temp4,
    command = clean_climate_moisture(temp3)
  ),

  tar_target(
    name = climate_clean,
    command = final_climate_cleaning(temp4, metaTurfID)
  ),

  # save clean plot data
  tar_target(
    name = climate_out,
    command = save_csv(climate_clean,
                       name = "clean_microclimate_2019-2022")
  )

)