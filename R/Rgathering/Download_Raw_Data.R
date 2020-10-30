## downloadData
#devtools::install_github("Between-the-Fjords/dataDownloader")
library("dataDownloader")

#Download community data from OSF
get_file(node = "pk4bg",
         file = "Three-D_Community_Joa_2019.zip",
         path = "data/community/2019/Joa",
         remote_path = "RawData/Community")

get_file(node = "pk4bg",
         file = "Three-D_Community_Lia_2019.zip",
         path = "data/community/2019/Lia",
         remote_path = "RawData/Community")

# Unzip files
zipFile <- "data/community/2019/Joa/Three-D_Community_Joa_2019.zip"
if(!file.exists(zipFile)){
  outDir <- "data/community/2019/Joa"
  unzip(zipFile, exdir = outDir)
}

zipFile <- "data/community/2019/Lia/Three-D_Community_Lia_2019.zip"
if(!file.exists(zipFile)){
  outDir <- "data/community/2019/Lia"
  unzip(zipFile, exdir = outDir)
}
