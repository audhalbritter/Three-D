# library(dplyr)
library(tidyverse)
library(fs)

location <- "/home/jga051/Documents/01_PhD/05_data/01_summer2020/rawData" #location of raw datafiles

fluxes <- dir_ls(location, regexp = "*CO2*") %>% 
  map_dfr(read_csv,  na = c("#N/A", "Over")) %>% 
  write_csv("/home/jga051/Documents/01_PhD/05_data/01_summer2020/summer2020_fluxes_raw.csv")

PAR <-
  list.files(path = location, pattern = "*PAR*", full.names = T) %>% 
  map_df(~read_table2(., "", na = c("NA"), col_names = paste0("V",seq_len(12)))) %>%
  rename(., Date = V2, Time = V3, PAR = V4) %>% 
  write_csv("/home/jga051/Documents/01_PhD/05_data/01_summer2020/summer2020_PAR_raw.csv")

temp_air <-dir_ls(location, regexp = "*temp*") %>% 
  map_dfr(read_csv,  na = c("#N/A"), skip = 20, col_names = c("Date/Time", "Unit", "Value", "decimal"), col_types = "ccnn") %>%
  # mutate(Temp_dec = replace_na(Temp_dec,0),
  #   Value = Temp_value + Temp_dec/1000) %>% #because stupid iButtons use comma as delimiter AND as decimal point
  # 
  write_csv("/home/jga051/Documents/01_PhD/05_data/01_summer2020/summer2020_tempair_raw.csv")
