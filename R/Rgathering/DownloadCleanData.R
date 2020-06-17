################################
#### download cleaned data ####
################################
#devtools::install_github("Between-the-Fjords/dataDownloader")
library("dataDownloader")

#Download community data from OSF
get_file(node = "pk4bg",
         file = "THREE-D_CommunitySubplot_2019.csv",
         path = "data_cleaned/",
         remote_path = "Community")

get_file(node = "pk4bg",
         file = "THREE-D_Cover_2019.csv",
         path = "data_cleaned/",
         remote_path = "Community")

get_file(node = "pk4bg",
         file = "THREE-D_CommunityStructure_2019.csv",
         path = "data_cleaned/",
         remote_path = "Community")
