library(plyr)
library(tidyverse)
library(fuzzyjoin)


location <- "/home/jga051/Documents/01_PhD/05_data/01_summer2020" #location of datafiles
#import all squirrel files and select date/time and CO2_calc columns, merge them, name it fluxes
fluxes <-
  list.files(path = location , pattern = "*CO2*", full.names = T) %>% 
  map_df(~read_csv(., na = c("#N/A"), col_types = "ctcnnnn")) %>%
  rename(., CO2_calc = "CO2_calc (ppm)", CO2b = "CO2 (ppm)") %>% 
  mutate(Date = strptime(as.character(.$Date), "%d.%m.%Y"), CO2 = coalesce(CO2_calc, CO2b)) %>% #the name of the column for CO2 changed because I modified the logger settings between two campaigns
  mutate(Date = as.POSIXct(paste(Date, Time))) %>% 
  select(.,Date,CO2)
  # with(., as.POSIXct(paste(Date, Time)))
#import date/time and PAR columns from PAR file
PAR <-
  list.files(path = location, pattern = "*PAR*", full.names = T) %>% 
  #colnames <- c("a", "Date", "Time", "PAR")
  map_df(~read_table2(., "", na = c("NA"), col_names = paste0("V",seq_len(12)))) %>% #, n_max = 100 c("a", "Date", "Time", "PAR", "b", "c", "d", "e") , skip = 20
  rename(., Date = V2, Time = V3, PAR = V4) %>% 
  mutate(PAR = as.numeric(as.character(.$PAR)), Date = as.POSIXct(paste(Date, Time))) %>% 
  select(.,Date, PAR)
#import date/time and value column from iButton file
temp_air <-
  list.files(path = location , pattern = "*temp*", full.names = T) %>% 
  map_df(~read.table(text = gsub(",", "\t", readLines(.)), col.names = c("Date", "Time", "unit", "Temp_value", "Temp_dec"), skip = 20)) %>%  #(., delim = ",", col_names = T, col_types = cols(.default = "c"), skip = 18)) %>%
  mutate(Temperature = Temp_value + Temp_dec/1000, Date = strptime(as.character(.$Date), "%d.%m.%y")) %>%  #, Time = strptime(as.character(.$Time), "hh:mm:ss"
  mutate(Date = as.POSIXct(paste(Date, Time))) %>%
  select(.,Date, Temperature)
  
#join the df
combined <- join_all(list(fluxes, PAR, temp_air), by='Date', type='left')
#import the record file
#next part is specific for Three-D
interval <- 120
three_d <- read_csv("/home/jga051/Documents/01_PhD/05_data/01_summer2020/3drecord.csv") %>% 
  mutate(Start = as.POSIXct(paste(date, starting_time), format="%Y-%m-%d %H:%M:%S"), End = Start + interval)
#extract from fluxes the data that are between "starting_time" and +2mn, associate Turf_ID, type, replicate and campaign to each CO2_calc
#https://community.rstudio.com/t/tidy-way-to-range-join-tables-on-an-interval-of-dates/7881/2
fluxes_threed <- fuzzy_left_join(
  combined, three_d,
  by = c(
    "Date" = "Start",
    "Date" = "End"
  ),
  match_fun = list(`>=`, `<=`)
) %>% 
  drop_na(Start) %>% 
  select(.,Date, CO2, PAR, Temperature, Turf_ID, type, replicate, campaign, remark)

#need to do similar thing for INCLINE

#graph CO2_calc to visually check the data