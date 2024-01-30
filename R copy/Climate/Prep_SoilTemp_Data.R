### Read in data
tomstlogger <- read_csv(file = "data_cleaned/climate/THREE-D_TomstLogger_2019_2020.csv")
height <- read_csv(file = "data_cleaned/community/THREE-D_Height_2019_2020.csv")
comm_structure <- read_csv(file = "data_cleaned/community/THREE-D_CommunityStructure_2019_2020.csv")
plot_meta_data <- read_excel(path = "data/metaData/Three-D_PlotLevel_MetaData_2019.xlsx")

source("R/Rgathering/create meta data.R")
source("R/Rgathering/ReadInPlotLevel.R")

# Prepare data for soiltemperature lab

soiltempdata <- tomstlogger %>% 
  select(LoggerID, Date_Time, SoilTemperature, ErrorFlag, destSiteID, destBlockID, destPlotID) %>%  # add soilmoisture once I have converted !!!
  mutate(Year = year(Date_Time),
         Month = month(Date_Time),
         Day = day(Date_Time),
         Time = format(Date_Time,"%H:%M:%S")) %>% 
  rename("Plotcode" = "LoggerID", "Temperature" = "SoilTemperature") %>% 
  select(Plotcode, Year:Time, Temperature:destPlotID, Date_Time) %>% 
  # join with meta and select control plots
  left_join(metaTurfID, by = c("destSiteID", "destBlockID", "destPlotID")) %>%
  # filter ambient and Nlevel 0
  filter(# all years
          (warming == "A" & Nlevel %in% c(1, 2) & grazing %in% c("C")) |
         # M and I plots from  2019
          (warming == "A" &  Nlevel %in% c(1, 2) & Date_Time < "2020-05-01 00:00:00")) %>% #distinct(turfID, Year) ### CHECK THIS!!!
  # select columns for soiltemperature data
  select(Plotcode:Temperature, destSiteID, turfID, Date_Time)


# Extra data
community_data <- height %>% 
  pivot_wider(names_from = Layer, values_from = MeanHeight) %>% 
  rename("Moss_layer_depth" = `Moss layer`, "Vegetation_height" = `Vascular plant layer`) %>% 
  left_join(comm_structure %>% 
              filter(FunctionalGroup == "SumofCover") %>% 
              select(turfID, MeanCover) %>% 
              rename("Total_vegetation_cover" = "MeanCover"), by = "turfID") %>% 
  left_join(metaTurfID, by = c("turfID")) %>% 
  filter(warming == "A" &  Nlevel %in% c(1, 2) & grazing %in% c("C")) %>% 
  # add plotMetaData once slope and exposure have been measured at dest site !!!
  left_join(plot_meta_data %>% select(-destSiteID, -destBlockID, -destPlotID), by = c("origSiteID", "origBlockID", "origPlotID")) %>% 
  rename("Aspect" = "Exposure") %>% 
  select(turfID, Year, Moss_layer_depth, Vegetation_height, Total_vegetation_cover, Slope, Aspect) %>% 
  group_by(turfID) %>% 
  summarise(Moss_layer_depth = mean(Moss_layer_depth),
            Vegetation_height = mean(Vegetation_height),
            Moss_layer_depth = mean(Moss_layer_depth),
            Total_vegetation_cover = mean(Total_vegetation_cover),
            Slope = mean(Slope),
            Aspect = mean(Aspect))




# Meta data
soiltempmeta <- soiltempdata %>% 
  group_by(Plotcode, destSiteID, turfID) %>% 
  mutate(minDate = min(Date_Time),
         maxDate = max(Date_Time),
         Start_date_year = year(minDate),
         Start_date_month = month(minDate),
         Start_date_day = day(minDate),
         End_date_year = year(maxDate),
         End_date_month = month(maxDate),
         End_date_day = day(maxDate)) %>% 
  distinct(Plotcode, Start_date_year, Start_date_month, Start_date_day, End_date_year, End_date_month, End_date_day) %>% 
  # Coordinates
  left_join(siteMetaData, by = "destSiteID") %>% 
  mutate(#Longitude,
    #Latitude,
    EPSG = 5776,
    GPS_accuracy = NA) %>% 
  
  # Logger
  mutate(Sensor_used = "MAXIM/DALLAS Semiconductor DS7505U+",
         Sensor_accuracy = 0.5,
         Sensor_notes = "Tomst logger TMS-4",
         Sensor_depth = -6) %>% 
  
  # Additional information
  mutate(Temporal_resolution = 15,
         UTC_Local = "Local",
         Species_composition = "No",
         Species_trait = "No",
         Plot_size = 0.25,
         Forest_canopy_cover = 0,
         Leaf_area_index = NA,
         Habitat_type = 4.1,
         Habitat_sub_type = NA,
         Disturbance_types = "grazing", 
         Disturbance_estimates = "",
         Soil_type = NA,
         Soil_moisture = NA,
         Data_open_access = "Yes",
         Meta_data_open_access = "Yes") %>% 
  left_join(community_data, by = c("turfID")) %>% 
  select(Plotcode,	Latitude,	Longitude,	EPSG,	GPS_accuracy,	Sensor_used:Sensor_depth,	Start_date_year:End_date_day,	Temporal_resolution:Forest_canopy_cover,	Total_vegetation_cover,	Moss_layer_depth,	Leaf_area_index,	Vegetation_height,	Habitat_type,	Habitat_sub_type,	Elevation,	Slope,	Aspect,	Disturbance_types:Meta_data_open_access) %>% 
  ungroup() %>% 
  select(-destSiteID, -turfID)


# For excel sheet
soiltempdata_final <- soiltempdata %>% 
select(Plotcode:Temperature)

sheets <- list("soil temp metadata" = soiltempmeta, "soil temp data" = soiltempdata_final) 
writexl::write_xlsx(x = sheets, path = "data_cleaned/SoilTemp/SoilTemp_data submission_Halbritter_2020_10_14.xlsx", col_names = TRUE)

