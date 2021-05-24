#############################################
### READ IN PLOT AND SITE LEVEL META DATA ###
#############################################

source("R/Load packages.R")
source("R/Rgathering/create meta data.R")

# Run this code if you need to download raw data from OSF
# get_file(node = "pk4bg",
#          file = "Three-D_PlotLevel_MetaData_2019.csv",
#          path = "data/soil",
#          remote_path = "RawData/Soil")
# 
# get_file(node = "pk4bg",
#          file = "ThreeD_SoilSamples_2019.csv",
#          path = "data/soil",
#          remote_path = "RawData/Soil")

# get_file(node = "pk4bg",
#          file = "TThreeD_2019_2020_CN_resultater.xlsx",
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
  select(year, origSiteID:turfID, warming:Nlevel, date_slope:date_depth, soil_depth_cm, remark)

write_csv(plotMetaData, path = "data_cleaned/soil/THREE-D_PlotLevel_Depth_2019.csv")


#### SOIL SAMPLES
# cn samples
cn_raw <- read_excel(path = "data/soil/ThreeD_2019_2020_CN_resultater.xlsx")
cn_data <- cn_raw %>% 
  select(-c("...16", "...17", "Memo", "...19", "Humidity", "C/N ratio")) %>% 
  rename(input_weight_g = Weight,
         sample_ID = Name,
         N_area = `N-area`,
         C_area = `C-area`,
         N_percent = `N%`,
         C_percent = `C%`,
         N_factor = `N factor`,
         C_factor = `C factor`,
         date = Date) %>% 
  mutate(CN_ratio = C_percent / N_percent)

# soil data
soilSamples_raw <- read_excel(path = "data/soil/ThreeD_SoilSamples_2019.xlsx")

# diameter of soil corer was 5 cm
soil_core_diameter <- 5
# stone desnsity is assumed 2.65 g cm^3^
stone_density = 2.65

soil <- soilSamples_raw %>% 
  mutate(year = year(date)) %>% 
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
  # cn data
  left_join(cn_data %>% 
              select(destSiteID, destBlockID, layer, year, C_percent, N_percent), 
            by = c("destSiteID", "destBlockID", "layer", "year")) %>% 
  select(date, year, destSiteID, destBlockID, layer, wet_weight_soil_g:pH, bulk_density_g_cm, pore_water_content, soil_organic_matter, carbon_content, C_percent, N_percent)

#write_csv(soil, file = "data_cleaned/soil/THREE-D_Soil_2019-2020.csv")
  
# check data
# soil %>% #filter(soil_organic_matter < 0) %>% as.data.frame()
#   ggplot(aes(x = destSiteID, y = soil_organic_matter, colour = layer)) +
#   geom_boxplot() +
#   facet_wrap( ~ destSiteID)



# Site level soil data
soil_site <- soil %>% 
  group_by(destSiteID, layer) %>% 
  summarise(bulk_density_se = sd(bulk_density_g_cm, na.rm = TRUE) / sqrt(n()),
            bulk_density_g_cm = mean(bulk_density_g_cm, na.rm = TRUE),
            sand_se = sd(sand_percent, na.rm = TRUE) / sqrt(n()),
            sand_percent = mean(sand_percent, na.rm = TRUE),
            silt_se = sd(silt_percent, na.rm = TRUE) / sqrt(n()),
            silt_percent = mean(silt_percent, na.rm = TRUE),
            clay_se = sd(clay_percent, na.rm = TRUE) / sqrt(n()),
            clay_percent = mean(clay_percent, na.rm = TRUE),
            soil_organic_matter_se = sd(soil_organic_matter, na.rm = TRUE) / sqrt(n()),
            soil_organic_matter = mean(soil_organic_matter, na.rm = TRUE),
            carbon_content_se = sd(carbon_content, na.rm = TRUE) / sqrt(n()),
            carbon_content = mean(carbon_content, na.rm = TRUE),
            C_percent_se = sd(C_percent, na.rm = TRUE) / sqrt(n()),
            C_percent = mean(C_percent, na.rm = TRUE),
            N_percent_se = sd(N_percent, na.rm = TRUE) / sqrt(n()),
            N_percent = mean(N_percent, na.rm = TRUE),
            pH_se = sd(pH, na.rm = TRUE) / sqrt(n()),
            pH = mean(pH, na.rm = TRUE))



#### SITE LEVEL META DATA ####
siteMetaData <- tibble(destSiteID = c("Vik", "Vik", "Joa", "Joa", "Lia", "Lia"),
                       latitude_N = c(60.88019, 60.88019, 60.86183, 60.86183, 60.85994, 60.85994),
                       longitude_E = c(7.16990, 7.16990, 7.16800, 7.16800, 7.19504, 7.19504),
                       elevation_m_asl = c(469, 469, 920, 920, 1290, 1290),
                       layer = c(rep(c("Top", "Bottom"), 3))) %>% 
  left_join(soil_site, by = c("destSiteID", "layer"))

#write_csv(siteMetaData, "data_cleaned/soil/THREE-D_metaSite.csv")

siteMetaData_pretty <- siteMetaData %>% 
  mutate("Bulk density" = paste(round(bulk_density_g_cm, 2), "±", round(bulk_density_se, 2)),
         "Sand %" = paste(round(sand_percent, 2), "±", round(sand_se, 2)),
         "Silt %" = paste(round(silt_percent, 2), "±", round(silt_se, 2)),
         "Clay %" = round(clay_percent, 2),
         SOM = paste(round(soil_organic_matter, 2), "±", round(soil_organic_matter_se, 2)),
         "Carbon content" = paste(round(carbon_content, 2), "±", round(carbon_content_se, 2)),
         "C%" = paste(round(C_percent, 2), "±", round(C_percent_se, 2)),
         "N%" = paste(round(N_percent, 2), "±", round(N_percent_se, 2)),
         pH = paste(round(pH, 2), "±", round(pH_se, 2))) %>% 
  mutate(pH = if_else(pH == "NaN ± NA", NA_character_, pH)) %>% 
  select(Site = destSiteID, Elevation = elevation_m_asl, Latitude = latitude_N, Longitude = longitude_E, Layer = layer, `Bulk density`:`N%`, pH)



# check data
# dd %>% 
#   group_by(destSiteID) %>% 
#   summarise(BD = mean(pH, na.rm = TRUE))
#   ggplot(aes(x = destSiteID, y = bulk_density_g_cm, fill = bulk_density_g_cm < 0)) +
#   geom_boxplot() +
#   geom_point() +
#   facet_grid(layer ~ year)
