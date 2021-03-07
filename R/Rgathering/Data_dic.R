#### CREATE DATA DIC FOR READMEFILE ####

source("R/Load packages.R")
#source("R/Rgathering/DownloadCleanData.R")

# get attribute table
attribute_table <- read_csv(file = "data_cleaned/Three-D_data_dic.csv")

#***********************************************************************************************
### SITE

# read in data
site <- read_csv("data_cleaned/soil/THREE-D_metaSite.csv")

range_site <- site %>% 
  summarise(
    across(where(is.character), ~ paste(min(., na.rm = TRUE), max(., na.rm = TRUE), sep = " - ")),
    across(where(is.numeric), ~paste(min(., na.rm = TRUE), max(., na.rm = TRUE), sep = " - "))
  ) %>% 
  pivot_longer(cols = everything(), names_to = "Variable name", values_to = "Variable range or levels")


site_dic <- map_df(site %>% as_tibble, class) %>% 
  pivot_longer(cols = everything(), names_to = "Variable name", values_to = "Variable type") %>% 
  mutate(`Variable type` = case_when(`Variable type` == "character" ~ "categorical",
                                     `Variable type` %in% c("integer", "numeric") ~ "numeric")) %>% 
  left_join(range_site, by = "Variable name") %>% 
  left_join(attribute_table, by = c("Variable name" = "attribute"))



#***********************************************************************************************
### COMMUNITY - turf

# read in data
cover <- read_csv("data_cleaned/vegetation/THREE-D_Cover_2019_2020.csv")

range_cover <- cover %>% 
  summarise(
    across(where(is.character), ~ paste(min(.), max(.), sep = " - ")),
    across(where(is.numeric), ~paste(min(.), max(.), sep = " - "))
  ) %>% 
  pivot_longer(cols = everything(), names_to = "Variable name", values_to = "Variable range or levels")


cover_dic <- map_df(cover %>% as_tibble, class) %>% 
  pivot_longer(cols = everything(), names_to = "Variable name", values_to = "Variable type") %>% 
  mutate(`Variable type` = case_when(`Variable type` == "character" ~ "categorical",
                                     `Variable type` %in% c("integer", "numeric") ~ "numeric")) %>% 
  left_join(range_cover, by = "Variable name") %>% 
  left_join(attribute_table, by = c("Variable name" = "attribute"))


#***********************************************************************************************
### COMMUNITY - subplot

# read in data
community_subplot <- read_csv("data_cleaned/vegetation/THREE-D_CommunitySubplot_2019_2020.csv")

range_comm_subplot <- community_subplot %>% 
  summarise(
    across(where(is.character), ~ paste(min(.), max(.), sep = " - ")),
    across(where(is.numeric), ~paste(min(.), max(.), sep = " - "))
  ) %>% 
  pivot_longer(cols = everything(), names_to = "Variable name", values_to = "Variable range or levels")


subplot_dic <- map_df(community_subplot %>% as_tibble, class) %>% 
  pivot_longer(cols = everything(), names_to = "Variable name", values_to = "Variable type") %>% 
  mutate(`Variable type` = case_when(`Variable type` == "character" ~ "categorical",
                                     `Variable type` %in% c("integer", "numeric") ~ "numeric")) %>% 
  left_join(range_comm_subplot, by = "Variable name") %>% 
  left_join(attribute_table, by = c("Variable name" = "attribute"))



#***********************************************************************************************
### COMMUNITY STRUCTURE

# read in data
community_structure <- read_csv("data_cleaned/vegetation/THREE-D_CommunityStructure_2019_2020.csv")

range_structure <- community_structure %>% 
  summarise(
    across(where(is.character), ~ paste(min(.), max(.), sep = " - ")),
    across(where(is.numeric), ~paste(min(.), max(.), sep = " - "))
  ) %>% 
  pivot_longer(cols = everything(), names_to = "Variable name", values_to = "Variable range or levels")


structure_dic <- map_df(community_structure %>% as_tibble, class) %>% 
  pivot_longer(cols = everything(), names_to = "Variable name", values_to = "Variable type") %>% 
  mutate(`Variable type` = case_when(`Variable type` == "character" ~ "categorical",
                                     `Variable type` %in% c("integer", "numeric") ~ "numeric")) %>% 
  left_join(range_structure, by = "Variable name") %>% 
  left_join(attribute_table, by = c("Variable name" = "attribute"))



#***********************************************************************************************
### BIOMASS

# read in data
# biomass <- read_csv("data_cleaned/vegetation/THREE-D_Biomass_2020.csv")
# 
# range_biomass <- biomass %>% 
#   summarise(
#     across(where(is.character), ~ paste(min(.), max(.), sep = " - ")),
#     across(where(is.numeric), ~paste(min(.), max(.), sep = " - "))
#   ) %>% 
#   pivot_longer(cols = everything(), names_to = "Variable name", values_to = "Variable range or levels")
# 
# 
# biomass_dic <- map_df(biomass %>% as_tibble, class) %>% 
#   pivot_longer(cols = everything(), names_to = "Variable name", values_to = "Variable type") %>% 
#   mutate(`Variable type` = case_when(`Variable type` == "character" ~ "categorical",
#                                      `Variable type` %in% c("integer", "numeric") ~ "numeric")) %>% 
#   left_join(range_biomass, by = "Variable name") %>% 
#   left_join(attribute_table, by = c("Variable name" = "attribute"))


#***********************************************************************************************
### REFLECTANCE

# read in data
reflectance <- read_csv("data_cleaned/vegetation/THREE-D_Reflectance_2020.csv")

range_reflectance <- reflectance %>% 
  summarise(
    across(where(is.character), ~ paste(min(.), max(.), sep = " - ")),
    across(where(is.numeric), ~paste(min(.), max(.), sep = " - "))
  ) %>% 
  pivot_longer(cols = everything(), names_to = "Variable name", values_to = "Variable range or levels")


reflectance_dic <- map_df(reflectance %>% as_tibble, class) %>% 
  pivot_longer(cols = everything(), names_to = "Variable name", values_to = "Variable type") %>% 
  mutate(`Variable type` = case_when(`Variable type` == "character" ~ "categorical",
                                     `Variable type` %in% c("integer", "numeric") ~ "numeric")) %>% 
  left_join(range_reflectance, by = "Variable name") %>% 
  left_join(attribute_table, by = c("Variable name" = "attribute"))


#***********************************************************************************************
### SOIL

# read in data
depth <- read_csv("data_cleaned/soil/THREE-D_PlotLevel_Depth_2019.csv")

range_depth <- depth %>% 
  summarise(
    across(where(is.character), ~ paste(min(.), max(.), sep = " - ")),
    across(where(is.numeric), ~paste(min(.), max(.), sep = " - "))
  ) %>% 
  pivot_longer(cols = everything(), names_to = "Variable name", values_to = "Variable range or levels")


depth_dic <- map_df(depth %>% as_tibble, class) %>% 
  pivot_longer(cols = everything(), names_to = "Variable name", values_to = "Variable type") %>% 
  mutate(`Variable type` = case_when(`Variable type` == "character" ~ "categorical",
                                     `Variable type` %in% c("integer", "numeric") ~ "numeric")) %>% 
  left_join(range_depth, by = "Variable name") %>% 
  left_join(attribute_table, by = c("Variable name" = "attribute"))


#***********************************************************************************************
### SOIL

# read in data
soil <- read_csv("data_cleaned/soil/THREE-D_Soil_2019-2020.csv")

range_soil <- soil %>% 
  summarise(
    across(where(is.character), ~ paste(min(.), max(.), sep = " - ")),
    across(where(is.numeric), ~paste(min(.), max(.), sep = " - "))
  ) %>% 
  pivot_longer(cols = everything(), names_to = "Variable name", values_to = "Variable range or levels")


soil_dic <- map_df(soil %>% as_tibble, class) %>% 
  pivot_longer(cols = everything(), names_to = "Variable name", values_to = "Variable type") %>% 
  mutate(`Variable type` = case_when(`Variable type` == "character" ~ "categorical",
                                     `Variable type` %in% c("integer", "numeric") ~ "numeric")) %>% 
  left_join(range_soil, by = "Variable name") %>% 
  left_join(attribute_table, by = c("Variable name" = "attribute"))



#***********************************************************************************************
### C-FLUX

# read in data
cflux <- read_csv("data_cleaned/c-flux/Three-D_c-flux_2020.csv")

range_cflux <- cflux %>% 
  summarise(
    across(where(is.character), ~ paste(min(.), max(.), sep = " - ")),
    across(where(is.numeric), ~paste(min(.), max(.), sep = " - "))
  ) %>% 
  pivot_longer(cols = everything(), names_to = "Variable name", values_to = "Variable range or levels")


cflux_dic <- map_df(cflux %>% as_tibble, class) %>% 
  pivot_longer(cols = everything(), names_to = "Variable name", values_to = "Variable type") %>% 
  mutate(`Variable type` = case_when(`Variable type` == "character" ~ "categorical",
                                     `Variable type` %in% c("integer", "numeric") ~ "numeric")) %>% 
  left_join(range_cflux, by = "Variable name") %>% 
  left_join(attribute_table, by = c("Variable name" = "attribute"))


#***********************************************************************************************
### CLIMATE - TOMST

# read in data
# climate_tomst <- read_csv("data_cleaned/climate/THREE-D_TomstLogger_2019_2020.csv")
# 
# range_climate_tomst <- climate_tomst %>% 
#   summarise(
#     across(where(is.character), ~ paste(min(.), max(.), sep = " - ")),
#     across(where(is.numeric), ~paste(min(.), max(.), sep = " - "))
#   ) %>% 
#   pivot_longer(cols = everything(), names_to = "Variable name", values_to = "Variable range or levels")
# 
# 
# climate_tomst_dic <- map_df(climate_tomst %>% as_tibble, class) %>% 
#   pivot_longer(cols = everything(), names_to = "Variable name", values_to = "Variable type") %>% 
#   mutate(`Variable type` = case_when(`Variable type` == "character" ~ "categorical",
#                                      `Variable type` %in% c("integer", "numeric") ~ "numeric")) %>% 
#   left_join(range_climate_tomst, by = "Variable name") %>% 
#   left_join(attribute_table, by = c("Variable name" = "attribute"))


#***********************************************************************************************
### CLIMATE - GRIDDED

# read in data
climate_gridded <- read_csv("data_cleaned/climate/THREE_D_Gridded_DailyClimate_2009-2019.csv")

range_climate_gridded <- climate_gridded %>% 
  summarise(
    across(where(is.character), ~ paste(min(.), max(.), sep = " - ")),
    across(where(is.numeric), ~paste(min(.), max(.), sep = " - "))
  ) %>% 
  pivot_longer(cols = everything(), names_to = "Variable name", values_to = "Variable range or levels")


climate_gridded_dic <- map_df(climate_gridded %>% as_tibble, class) %>% 
  pivot_longer(cols = everything(), names_to = "Variable name", values_to = "Variable type") %>% 
  mutate(`Variable type` = case_when(`Variable type` == "character" ~ "categorical",
                                     `Variable type` %in% c("integer", "numeric") ~ "numeric")) %>% 
  left_join(range_climate_gridded, by = "Variable name") %>% 
  left_join(attribute_table, by = c("Variable name" = "attribute"))