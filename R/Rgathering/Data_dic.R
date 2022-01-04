#### CREATE DATA DIC FOR READMEFILE ####

source("R/Load packages.R")
source("R/Rgathering/DownloadCleanData.R")

# data dictionary function
source("R/Rgathering/make_data_dic.R")

# get attribute table
attribute_table <- read_csv(file = "data_cleaned/Three-D_data_dic.csv") %>%
  mutate(TableID = as.character(TableID))

#***********************************************************************************************
### SITE

# read in data
site <- read_csv("data_cleaned/soil/THREE-D_metaSite.csv")

site_dic <- make_data_dictionary(data = site,
                                description_table = attribute_table,
                                table_ID = NA_character_)


#***********************************************************************************************
### COMMUNITY - turf

# read in data
cover <- read_csv("data_cleaned/vegetation/THREE-D_Cover_2019_2020.csv")

cover_dic <- make_data_dictionary(data = cover,
                                 description_table = attribute_table,
                                 table_ID = NA_character_)


#***********************************************************************************************
### COMMUNITY - subplot

# read in data
community_subplot <- read_csv("data_cleaned/vegetation/THREE-D_CommunitySubplot_2019_2020.csv")

subplot_dic <- make_data_dictionary(data = community_subplot,
                                  description_table = attribute_table,
                                  table_ID = NA_character_)


#***********************************************************************************************
### COMMUNITY STRUCTURE

# read in data
community_structure <- read_csv("data_cleaned/vegetation/THREE-D_CommunityStructure_2019_2020.csv")

structure_dic <- make_data_dictionary(data = community_structure,
                                    description_table = attribute_table,
                                    table_ID = NA_character_)


#***********************************************************************************************
### BIOMASS

# read in data
biomass <- read_csv("data_cleaned/vegetation/THREE-D_Biomass_2020.csv")

biomass_dic <- make_data_dictionary(data = biomass,
                                      description_table = attribute_table,
                                      table_ID = NA_character_)


#***********************************************************************************************
### REFLECTANCE

# read in data
reflectance <- read_csv("data_cleaned/vegetation/THREE-D_Reflectance_2020.csv")

reflectance_dic <- make_data_dictionary(data = reflectance,
                                    description_table = attribute_table,
                                    table_ID = NA_character_)


#***********************************************************************************************
### SOIL DEPTH

# read in data
depth <- read_csv("data_cleaned/soil/THREE-D_PlotLevel_Depth_2019.csv")

depth_dic <- make_data_dictionary(data = depth,
                                        description_table = attribute_table,
                                        table_ID = NA_character_)


#***********************************************************************************************
### SOIL

# read in data
soil <- read_csv("data_cleaned/soil/THREE-D_Soil_2019-2020.csv") %>% 
  mutate(date = as.Date(date))

soil_dic <- make_data_dictionary(data = soil,
                                  description_table = attribute_table,
                                  table_ID = NA_character_)


#***********************************************************************************************
### SOIL NUTRIENTS - PRS

# read in data
prs <- read_csv("data_cleaned/soil/THREE-D_clean_nutrients_2021.csv")

prs_dic <- make_data_dictionary(data = prs,
                                description_table = attribute_table,
                                table_ID = "prs")

#***********************************************************************************************
### DECOMPOSITION

# read in data
decompose <- read_csv("data_cleaned/decomposition/THREE-D_clean_decomposition_fall_2021.csv")

decompose_dic <- make_data_dictionary(data =  decompose,
                                      description_table = attribute_table,
                                      table_ID = NA_character_)


#***********************************************************************************************
### C-FLUX

# read in data
cflux <- read_csv("data_cleaned/c-flux/Three-D_c-flux_2020.csv")

cflux_dic <- make_data_dictionary(data =  cflux,
                                 description_table = attribute_table,
                                 table_ID = NA_character_)





#***********************************************************************************************
### CLIMATE - TOMST

# read in data
climate <- read_csv("data_cleaned/climate/THREE-D_clean_microclimate_2019-2021.csv")

climate_dic <- make_data_dictionary(data =  climate,
                                            description_table = attribute_table,
                                            table_ID = NA_character_)




#***********************************************************************************************
### CLIMATE - GRIDDED

# read in data
climate_gridded <- read_csv("data_cleaned/climate/THREE_D_Gridded_DailyClimate_2009-2019.csv")

climate_gridded_dic <- make_data_dictionary(data =  climate_gridded,
                                      description_table = attribute_table,
                                      table_ID = NA_character_)



#************************************************************************

##merge all dics together to one xlsx, with each parameter as a single sheet

# write_xlsx(list(site = site_dic,
#                 community_cover = cover_dic,
#                 subplot_presence = subplot_dic,
#                 community_structure = structure_dic,
#                 biomass = biomass_dic,
#                 ndvi = reflectance_dic,
#                 soil_depth = depth_dic,
#                 soil= soil_dic,
#                 soil_nutrients = prs_dic,
#                 decomposition = decompose_dic,
#                 cflux = cflux_dic,
#                 climate = climate_dic,
#                 gridded_climate = climate_gridded_dic),
#            path = "R/data_dic/data_dictionary.xlsx")
