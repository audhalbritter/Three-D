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
      
      unzip(zipfile = "Three-D_raw_microclimate_2019-2022.zip", 
            exdir = "data")
      
    },
    format = "file"
  ),
  
  # import and clean data
  tar_target(
    name = climate_clean,
    command = clean_climate(metaTurfID, metaTomst)
  ),

  # save clean plot data
  tar_target(
    name = climate_out,
    command = save_csv(climate_clean,
                       name = "clean_microclimate_2019-2022_2019")
  )

)