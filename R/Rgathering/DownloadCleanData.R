################################
#### download cleaned data ####
################################
#devtools::install_github("Between-the-Fjords/dataDownloader")
library("dataDownloader")

### VEGETATION
dir.create("data_cleaned/vegetation")
get_file(node = "pk4bg",
         file = "THREE-D_CommunitySubplot_2019_2020.csv",
         path = "data_cleaned/vegetation",
         remote_path = "Vegetation")

get_file(node = "pk4bg",
         file = "THREE-D_Cover_2019_2020.csv",
         path = "data_cleaned/vegetation",
         remote_path = "Vegetation")

get_file(node = "pk4bg",
         file = "THREE-D_CommunityStructure_2019_2020.csv",
         path = "data_cleaned/vegetation",
         remote_path = "Vegetation")

get_file(node = "pk4bg",
         file = "THREE-D_Reflectance_2020.csv",
         path = "data_cleaned/vegetation",
         remote_path = "Vegetation")

get_file(node = "pk4bg",
         file = "THREE-D_Biomass_2020.csv",
         path = "data_cleaned/vegetation",
         remote_path = "Vegetation")


### SITE
dir.create("data_cleaned/site")
get_file(node = "pk4bg",
         file = "THREE-D_metaSite.csv",
         path = "data_cleaned/site/",
         remote_path = "Site")

### SOIL
dir.create("data_cleaned/soil")
get_file(node = "pk4bg",
         file = "THREE-D_PlotLevel_Depth_2019.csv",
         path = "data_cleaned/soil/",
         remote_path = "Soil")

get_file(node = "pk4bg",
         file = "THREE-D_Soil_2019-2020.csv",
         path = "data_cleaned/soil/",
         remote_path = "Soil")


### C-FLUX
dir.create("data_cleaned/c-flux")
get_file(node = "pk4bg",
         file = "Three-D_c-flux_2020.csv",
         path = "data_cleaned/c-flux",
         remote_path = "C-Flux")

### CLIMATE
dir.create("data_cleaned/climate")
get_file(node = "pk4bg",
         file = "THREE_D_Gridded_DailyClimate_2009-2019.csv",
         path = "data_cleaned/climate",
         remote_path = "Climate")

# get_file(node = "pk4bg",
#          file = "THREE-D_TomstLogger_2019_2020.csv",
#          path = "data_cleaned/climate",
#          remote_path = "Climate")
