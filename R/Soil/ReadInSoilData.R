#############################################
### READ IN PLOT AND SITE LEVEL META DATA ###
#############################################

source("R/Load packages.R")
source("R/Rgathering/create meta data.R")

# Download raw data from OSF
# get_file(node = "pk4bg",
#          file = "Three-D_PlotLevel_MetaData_2019.csv",
#          path = "data/soil",
#          remote_path = "RawData/Soil")
# 
# get_file(node = "pk4bg",
#          file = "ThreeD_SoilSamples_2019.csv",
#          path = "data/soil",
#          remote_path = "RawData/Soil")


#### PLOT LEVEL META DATA ####
plotMetaData <- read_csv(file = "data/soil/Three-D_PlotLevel_MetaData_2019.csv") %>% 
  # remove rows with data after transplant, duplicate
  filter(remark != "after transplant" | is.na(remark)) %>% 
  left_join(metaTurfID, by = c("origSiteID", "origBlockID", "origPlotID", "destSiteID", "destPlotID", "destBlockID", "turfID")) %>% 
  # calculate mean soil depth
  mutate(soil_depth_cm = (soil_depth1 + soil_depth2 + soil_depth3 + soil_depth4) / 4,
         soil_depth_cm = if_else(origPlotID == 106, 36.1, soil_depth_cm),
         year = 2019) %>% 
  select(-soil_depth1, -soil_depth2, -soil_depth3, -soil_depth4)

write_csv(plotMetaData, path = "data_cleaned/soil/THREE-D_PlotLevel_Depth_2019.csv")


#### SOIL SAMPLES
soilSamples_raw <- read_csv(file = "data/soil/ThreeD_SoilSamples_2019.csv")

# diameter of soil corer was 5 cm
soil_core_diameter <- 5
# stone desnsity is assumed 2.65 g cm^3^
stone_density = 2.65

soil <- soilSamples_raw %>% 
  mutate(date = dmy(date),
         year = year(date)) %>% 
  # calculate soil core volume, stone volume and bulk density
  mutate(core_volume = height_soil_core_cm * (soil_core_diameter/2)^2 * pi,
         stone_volume = stone_weight_g * stone_density,
         bulk_density_g_cm = (dry_weight_soil_g - stone_weight_g) / (core_volume - stone_volume),
         # remove unrealistic samples with very high stone weight
         bulk_density_g_cm = if_else(bulk_density_g_cm > 1.8 | bulk_density_g_cm < 0, NA_real_, bulk_density_g_cm)) %>% 
  # calculate soil organic matter
  mutate(pore_water_content = (wet_weight_soil_g - dry_weight_soil_g) / wet_weight_soil_g,
         weight_550_g = dry_weight_550_plus_vial_g - vial_weight_g,
         weight_950_g = dry_weight_950_plus_vial_g - vial_weight_g,
         soil_organic_matter = (dry_weight_105_g - weight_550_g) / dry_weight_105_g,
         carbon_content = (weight_550_g - weight_950_g) / dry_weight_105_g) %>% 
  select(date, year, destSiteID, destBlockID, layer, wet_weight_soil_g:pH, bulk_density_g_cm, pore_water_content, soil_organic_matter, carbon_content)

write_csv(soil, path = "data_cleaned/soil/THREE-D_Soil_2019-2020.csv")
  
# check data
soil %>% #filter(soil_organic_matter < 0) %>% as.data.frame()
  ggplot(aes(x = destSiteID, y = soil_organic_matter, colour = layer)) +
  geom_boxplot() +
  facet_wrap( ~ destSiteID)
  

# bulk density by layer and destSiteID
BD <- soil %>% 
  filter(!is.na(bulk_density_g_cm)) %>% 
  group_by(destSiteID, layer) %>% 
  summarise(bulk_density_g_cm = mean(bulk_density_g_cm),
            bulk_density_se = sd(bulk_density_g_cm) / sqrt(n()))

# SOM
SOM <- soil %>% 
  filter(!is.na(soil_organic_matter)) %>% 
  group_by(destSiteID, layer) %>% 
  summarise(soil_organic_matter = mean(soil_organic_matter),
            soil_organic_matter_se = sd(soil_organic_matter) / sqrt(n()),
            carbon_content = mean(carbon_content),
            carbon_content_se = sd(carbon_content) / sqrt(n()))

# pH
pH <- soil %>% 
  ungroup() %>% 
  filter(!is.na(pH)) %>% 
  group_by(destSiteID) %>% 
  summarise(pH = mean(pH),
            pH_se = sd(pH) / sqrt(n()))



#### SITE LEVEL META DATA ####
siteMetaData <- tibble(destSiteID = c("Vik", "Vik", "Joa", "Joa", "Lia", "Lia"),
                       Latitude_N = c(60.88019, 60.88019, 60.86183, 60.86183, 60.85994, 60.85994),
                       Longitude_E = c(7.16990, 7.16990, 7.16800, 7.16800, 7.19504, 7.19504),
                       Elevation_m_asl = c(469, 469, 920, 920, 1290, 1290),
                       layer = c(rep(c("Top", "Bottom"), 3))) %>% 
  left_join(pH, by = "destSiteID") %>% 
  left_join(BD, by = c("destSiteID", "layer")) %>% 
  left_join(SOM, by = c("destSiteID", "layer")) %>% 
  select(-carbon_content, -carbon_content_se)



# check data
# dd %>% 
#   group_by(destSiteID) %>% 
#   summarise(BD = mean(pH, na.rm = TRUE))
#   ggplot(aes(x = destSiteID, y = bulk_density_g_cm, fill = bulk_density_g_cm < 0)) +
#   geom_boxplot() +
#   geom_point() +
#   facet_grid(layer ~ year)
