###########################
### READ IN DATA ###
###########################

source("R/Load packages.R")
source("R/Rgathering/ReadInPlotLevel.R")
source("R/Rgathering/ReadInCommunity.R")


#### CLIMATE DATA ####

# Read in meta data
metaTomst <- read_excel(path = "data/metaData/Three-D_ClimateLogger_Meta_2019.xlsx", col_names = TRUE, col_types = c("text", "numeric", "numeric", "text", "date", "date", "date", "text")) %>% 
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
  left_join(metaTomst, by = "LoggerID")


# Select Ievas data
TomstLogger_Ieva_2019 <- temp %>% 
  filter(LoggerID %in% c("5226", "5221", "5227", "5263", "5267", "5222", "5223", "5272", "5224", "5228", "5266", "5261")) %>%
  # Mark IEVAs data
  mutate(Treatment = case_when(LoggerID %in% c("5226", "5221", "5227", "5263", "5267") ~ "cage",
                               LoggerID %in% c("5222", "5223", "5224", "5228", "5266", "5272", "5261") ~ "no-cage")) %>% 
  mutate(Site = case_when(LoggerID == "5226" ~ "Inb",
                          LoggerID == "5221" ~ "Joa",
                          LoggerID == "5227" ~ "Lia",
                          LoggerID == "5263" ~ "Hog",
                          LoggerID == "5267" ~ "Vik",
                          LoggerID == "5222" ~ "Lia",
                          LoggerID == "5223" ~ "Joa",
                          LoggerID == "5272" ~ "Joa",
                          LoggerID == "5224" ~ "Lia",
                          LoggerID == "5228" ~ "Lia",
                          LoggerID == "5266" ~ "Joa",
                          LoggerID == "5261" ~ "Vik")) %>% 
  filter(Date_Time > earlyStart) %>% 
  select(-destSiteID, -destBlockID, -destPlotID)
#write_csv(TomstLogger_Ieva_2019, path = "data/iButton Ieva 2019/TomstLogger_Ieva_2019.csv", col_names = TRUE)


# Fix data
temp <- temp %>% 
  # Remove logger failure
  filter(ErrorFlag == 0) %>% 
  # Remove data before initial date time
  group_by(LoggerID) %>% 
  filter(Date_Time > InitialDate_Time)


# Check data
temp %>% 
  #filter(Date_Time < "2019-08-20 22:00:00") %>% 
  ggplot(aes(x = Date_Time, y = AirTemperature, colour = as.factor(LoggerID))) +
  geom_line() +
  facet_wrap(~ LoggerID) +
  theme(legend.position="none")

# Plot meta data
plotMetaData2 <- plotMetaData %>% 
  select(origSiteID, origBlockID, origPlotID, Slope, Exposure)


# Prepare data for soiltemperature lab
# Data
soiltempdata2 <- temp %>% 
  select(LoggerID, Date_Time, SoilTemperature) %>%  # add soilmoisture once I have converted !!!
  mutate(Year = year(Date_Time),
         Month = month(Date_Time),
         Day = day(Date_Time),
         Time = format(Date_Time,"%H:%M:%S")) %>% 
  rename("Plotcode" = "LoggerID", "Temperature" = "SoilTemperature") %>% 
  select(Plotcode, Year:Time, Temperature, Date_Time) %>% 
  left_join(metaTomst, by = c("Plotcode" = "LoggerID")) %>% 
  # join with meta and select control plots
  left_join(metaTurfID, by = c("destSiteID", "destBlockID", "destPlotID")) %>% 
  # filter ambient and Nlevel 0
  filter(warming == "A" & Nlevel %in% c(1, 2)) 

# select columns for soiltemperature data
soiltempdata <- soiltempdata2 %>% 
  select(Plotcode:Temperature)

# Extra data
extraData <- height %>% 
  filter(Year == 2019) %>% 
  pivot_wider(names_from = Layer, values_from = MeanHeight) %>% 
  rename("Moss_layer_depth" = `Moss layer`, "Vegetation_height" = `Vascular plant layer`) %>% 
  left_join(metaCommunity %>% 
              filter(FunctionalGroup == "SumofCover") %>% 
              select(turfID, MeanCover) %>% 
              rename("Total_vegetation_cover" = "MeanCover"), by = "turfID") %>% 
  # add plotMetaData once slope and exposure have been measured at dest site !!!
  #left_join(plotMetaData %>% 
              #select(origSiteID, origBlockID, origPlotID, Slope, Exposure) %>% 
              #left_join(metaTurfID, by = c("destSiteID", "destBlockID", "destPlotID")) %>% 
              #filter(warming == "A"), by = "turfID") %>% 
  select(turfID, Year, Moss_layer_depth, Vegetation_height, Total_vegetation_cover)
  



# Meta data
soiltempmeta <- soiltempdata2 %>% 
  group_by(Plotcode, destSiteID, turfID) %>% 
  ### THIS NEEDS FIXING ONCE THERE IS MORE THAN 1 YEAR OF DATA!!!
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
         #Total_vegetation_cover = ,
         #Moss_layer_depth = ,
         Leaf_area_index = NA,
         #Vegetation_height = ,
         Habitat_type = 4.1,
         Habitat_sub_type = NA,
         #Elevation = ,
         Slope = NA,
         Aspect	= NA,
         Disturbance_types = "grazing", 
         Disturbance_estimates = "",
         Soil_type = NA,
         Soil_moisture = NA,
         Data_open_access = "Yes",
         Meta_data_open_access = "Yes") %>% 
  left_join(extraData, by = c("turfID")) %>% 
  select(Plotcode,	Latitude,	Longitude,	EPSG,	GPS_accuracy,	Sensor_used:Sensor_depth,	Start_date_year:End_date_day,	Temporal_resolution:Forest_canopy_cover,	Total_vegetation_cover,	Moss_layer_depth,	Leaf_area_index,	Vegetation_height,	Habitat_type,	Habitat_sub_type,	Elevation,	Slope,	Aspect,	Disturbance_types:Meta_data_open_access) %>% 
  ungroup() %>% 
  select(-destSiteID, -turfID)


sheets <- list("soil temp metadata" = soiltempmeta, "soil temp data" = soiltempdata) 
writexl::write_xlsx(x = sheets, path = "SoilTemp_data submission_Halbritter_2020_01_13.xlsx", col_names = TRUE)

