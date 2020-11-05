library(tidyverse)
library("dataDownloader")

get_file(node = "pk4bg",
         file = "Three-D_c-flux_2020.csv",
         path = "data/C-Flux/summer_2020",
         remote_path = "C-Flux")

flux.colnames <- read_csv("Three-D_c-flux_2020.csv") %>% 
  colnames()

variables <- tibble(flux.colnames, description = c(
  # Datetime
  ""
  # ID
  # Turf_ID
  # Type
  # Replicate
  # Remarks
  # Date
  # PARavg
  # Temp_airavg
  # r.squared
  # p.value
  # flux
  # Campaign
))
