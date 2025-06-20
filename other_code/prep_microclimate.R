# prep soil temp data

# read in data and template files
climate <- read_csv("data_cleaned/Three-D_clean_microclimate_temp_2019-2022.csv")
site <- read_csv("data_cleaned/site/THREE-D_metaSite.csv") |> 
  distinct(destSiteID, latitude_N, longitude_E, elevation_m_asl) |> 
  select(Site_id = destSiteID, Elevation = elevation_m_asl, Latitude = latitude_N, Longitude = longitude_E)

#template_meta <- read_csv2("csv/METADATA.csv")
#template_data <- read_csv2("csv/RAW-TIME-SERIES-DATA.csv")
template_veg <- read_csv2("csv/VEGETATION-DATA.csv")
template_veg_meta <- read_csv2("csv/VEGETATION-METADATA.csv")


# filter data
all_data <- climate |> 
  filter(warming == "A", 
         grazing == "C",
         Namount_kg_ha_y == 0) |> 
  # get date and time right
  mutate(Year = year(date_time),
         Month = month(date_time),
         Day = day(date_time),
         `Time (24h)` = format(as.POSIXct(date_time),
                               format = "%H:%M"),
         ID = paste0(loggerID, "_", turfID, "_", destSiteID)) |> 
  rename(Raw_data_identifier = ID, T1 = soil_temperature, T2 = ground_temperature, T3 = air_temperature, Soil_moisture_raw = raw_soilmoisture)
  
# Prepare raw microclimate data file
raw_data <- all_data |> 
  select(Raw_data_identifier, 
         Year, Month, Day, `Time (24h)`, 
         T1, T2, T3, Soil_moisture_raw)
write_csv(raw_data, "soiltemp/ThreeD_raw-time-series_2019-2022.csv")


# start and end date
dates <- all_data %>% 
  group_by(Raw_data_identifier) |> 
  summarise(minDate = min(date_time),
         maxDate = max(date_time),
         Start_date_year = year(minDate),
         Start_date_month = month(minDate),
         Start_date_day = day(minDate),
         End_date_year = year(maxDate),
         End_date_month = month(maxDate),
         End_date_day = day(maxDate))


# make meta data
meta_data <- all_data |> 
  select(Raw_data_identifier, Logger_code = loggerID, Logger_serial_number = loggerID, destSiteID, turfID, Year, T1, T2, T3, Soil_moisture_raw) |> 
  pivot_longer(cols = c(T1, T2, T3, Soil_moisture_raw), names_to = "Sensor_code", values_to = "Value") |> 
  distinct(Raw_data_identifier, destSiteID, turfID, Year, Sensor_code, Logger_code, Logger_serial_number) |> 
  mutate(meta_id = 1:n(),
         Site_id = paste0(destSiteID, "_", turfID, "_", Year)) |> 
  left_join(dates, by = "Raw_data_identifier") |> 
  left_join(site, by = "Site_id") |> 
  mutate(Country_code = "NO",
         Experiment_name = "ThreeD",
         Experimental_manipulation = "No",
         Experiment_insitu = "Yes",
         Experiment_climate = "No",
         Experiment_citizens = "No",
         Experiment_design = NA,
         Experiment_doi = NA,
         Experiment_comment = NA,
         #Site_id,
         #Elevation,
         Habitat_type = 4,
         Habitat_sub_type = 1,
         Site_comments = NA, 
         #Logger_code,
         #Raw_data_identifier,
         #Latitude,
         #Longitude,
         EPSG = 9883,
         GPS_accuracy = NA,
         #Logger_serial_number,
         Logger_brand = "TOMST",
         Logger_type = "TMS4",
         Logger_age = Start_date_year,
         Logger_comment = NA,
         #Sensor_code,
         Sensor_shielding = if_else(Sensor_code == "T1", "Yes", "No"),
         Sensor_shielding_type = NA,
         Microclimate_measurement = if_else(Sensor_code == "Soil_moisture_raw", "Soil_moisture", "Temperature"),
         Unit = if_else(Sensor_code == "Soil_moisture_raw", "%", "°C"),
         Sensor_accuracy = if_else(Sensor_code == "Soil_moisture_raw", "1", "0.5"),
         Temporal_resolution = 15,
         Sensor_height = case_when(Sensor_code == "T2" ~ 0,
                                   Sensor_code == "T3" ~ 15,
                                   TRUE ~ -6),
         Sensor_length = if_else(Sensor_code == "Soil_moisture_raw", "15", "0"),
         # Start_date_year,
         # Start_date_month,
         # Start_date_day,
         # End_date_year,
         # End_date_month,
         # End_date_day,
         Timezone = "UTC",
         Time_difference = "+2",
         Licence = "CC-BY", 
         Sensor_comments = NA,
         Species_composition = "Yes",
         Species_trait = "No") |> 
  tidylog::select(meta_id, Country_code:Experiment_comment, Site_id, Elevation, Habitat_type:Site_comments, Logger_code,
         Raw_data_identifier, Latitude, Longitude, EPSG, GPS_accuracy, Logger_serial_number, Logger_brand:Logger_comment, Sensor_code, Sensor_shielding:Sensor_length, Start_date_year:End_date_day, Timezone:Species_trait)
  
write_csv(meta_data, "soiltemp/ThreeD_meta-data.csv")



# Vegetation data

comm <- read_csv("data_cleaned/Three-D_clean_cover_2019-2022.csv") |> 
  # select plots
  inner_join(all_data |> 
               distinct(turfID)) |> 
  mutate(Site_id = paste0(destSiteID, "_", turfID, "_", year))

comm_structure <- read_csv("data_cleaned/Three-D_clean_community_structure_2019-2022.csv") |> 
  # select plots
  inner_join(all_data |> 
               distinct(turfID)) |> 
  filter(functional_group %in% c("Bryophytes", "Bare soil")) |> 
  mutate(Site_id = paste0(destSiteID, "_", turfID, "_", year)) |> 
  select(Site_id, functional_group, cover) |> 
  pivot_wider(names_from = functional_group, values_from = cover, values_fill = 0) |> 
  rename("Cover E0: moss layer" = Bryophytes, "Cover baresoil" = `Bare soil`)


height <- read_csv("data_cleaned/Three-D_clean_height_2019_2022.csv") |> 
  # select plots
  inner_join(all_data |> 
               distinct(turfID)) |> 
  filter(vegetation_layer == "Vascular plant layer") |> 
  mutate(destSiteID = if_else(turfID %in% c("81 AN1C 81", "156 AN2C 156"), "Joa", "Lia"),
         Site_id = paste0(destSiteID, "_", turfID, "_", year),
         # conver to m
         "Height E1: herb layer" = height / 100) |> 
  select(Site_id, "Height E1: herb layer")

biomass <- read_csv("data_cleaned/vegetation/Three-D_clean_biomass_2020-2022.csv") |> 
  # select plots
  inner_join(all_data |> 
               distinct(turfID)) |> 
  filter(year == 2022,
         fun_group != "litter") |> 
  group_by(destSiteID, turfID, year) |> 
  summarise(biomass = sum(biomass)) |> 
  mutate(Site_id = paste0(destSiteID, "_", turfID, "_", year),
         # convert from g to kg per m2
         "Total biomass" = biomass / 1000 * 16) |>
  ungroup() |> 
  select(Site_id, "Total biomass")

total_cover <- veg_data |> 
  group_by(Site_id) |> 
  summarise("Cover E1: herb layer" = sum(Cover))

vegetation_meta <- comm |> 
  select(Site_id, Observation_date_year = year) |> 
  inner_join(comm |> 
              distinct(Site_id)) |> 
   distinct() |> 
# Observation_date_month = month(date)
# Observation_date_day = day(date)
  left_join(biomass, by = "Site_id") |> 
  left_join(total_cover, by = "Site_id") |> 
  left_join(comm_structure, by = "Site_id") |> 
  left_join(height, by = "Site_id") |> 
  mutate(Plot_size = 0.0625,
         Survey_method_short = "Vascular plant",
         Survey_method_long = "Plant species composition was recorded annually at peak growing season in all plots between 2019 and 2022. We visually estimated the percentage cover of all vascular plant species to the nearest 1 %. The total coverage in each plot can exceed 100, due to layering of the vegetation. For species identification we followed the nomenclature from Lid & Lid (2010).",
         "Multilayer vegetation" = "No",
         "Taxonomic reference" = "Lid, J., & Lid, D. T. (2010). Norsk flora. Det Norske Samlaget, Oslo.",
         #"Total biomass",
         "Total biomass unit" = "kg/m2",
         "Cover unit" = "%",
         "Total plant cover" = "Cover E1: herb layer",
         "Cover E3: tree layer" = 0,
         "Cover E2: shrub layer" = 0,
         #"Cover E1: herb layer",
         #"Cover E0: moss layer",
         "Cover rock" = 0,
         #"Cover baresoil",
         "LAI" = NA,                 
         "LAI unit" = NA,
         "Species richness",
         "Height E3: tree layer" = NA, 
         "Height E2: shrub layer" = NA,
         #"Height E1: herb layer",
         "Soil bulk density" = NA,  
         "Soil bulk density unit" = NA,
         "Other" = NA,
         "Other unit" = NA,            
         "DOI" = NA,
         "Licence" = "CC-BY",
         "Comment" = NA) |> 
  mutate(survey_id = 1:n()) |> 
  tidylog::select(survey_id, Site_id:Observation_date_year, Plot_size:"Taxonomic reference", "Total biomass", "Total biomass unit":"Cover E2: shrub layer", "Cover E1: herb layer", "Cover E0: moss layer", "Cover rock", "Cover baresoil", "LAI":"Height E2: shrub layer", "Height E1: herb layer", "Soil bulk density":"Comment")
            
write_csv(vegetation_meta, "soiltemp/ThreeD_vegetation-metadata.csv")


veg_data <- comm |> 
  select(Site_id, Species_name = species, Cover = cover) |> 
  mutate(Cover_unit = "percentage",
         Vegetation_layer = 6) |> 
  left_join(vegetation_meta |> 
              distinct(survey_id, Site_id)) |> 
  select(survey_id, everything())
  
write_csv(veg_data, "soiltemp/ThreeD_vegetation-data.csv")


raw_data <- read_csv("soiltemp/ThreeD_raw-time-series_2019-2022.csv")
raw_data |> 
  #filter(date(date_time) != "2019-10-23") |> 
  # mutate(T1 = if_else(loggerID == "94195255" & date_time > "2019-10-23 00:00:00" & date_time < "2019-10-26 03:00:00" & T1 < -40, NA_real_, T1)
  #        #T2 = if_else(loggerID == "94195255" & date_time > "2019-10-24 02:00:00" & date_time < "2019-10-24 03:00:00", NA_real_, T2)
  #        ) |> 
  # filter(date_time > "2019-10-20 00:00:00" &
  #          date_time < "2019-10-27 03:00:00",
  #        loggerID == "94195255") |> select(date_time, T1) |> View()
  ggplot(aes(x = `Time (24h)`, y = T2)) +
  geom_point()

  

