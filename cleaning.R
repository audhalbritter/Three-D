library(plyr)
library(tidyverse)
library(fuzzyjoin)

measurement <- 120 #the length of the measurement taken on the field in seconds
startcrop <- 0 #how much to crop at the beginning of the measurement in seconds
endcrop <- 0 #how much to crop at the end of the measurement in seconds

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
print("fluxes df created")
#import date/time and PAR columns from PAR file
PAR <-
  list.files(path = location, pattern = "*PAR*", full.names = T) %>% 
  #colnames <- c("a", "Date", "Time", "PAR")
  map_df(~read_table2(., "", na = c("NA"), col_names = paste0("V",seq_len(12)))) %>% #, n_max = 100 c("a", "Date", "Time", "PAR", "b", "c", "d", "e") , skip = 20
  rename(., Date = V2, Time = V3, PAR = V4) %>% 
  mutate(PAR = as.numeric(as.character(.$PAR)), Date = as.POSIXct(paste(Date, Time))) %>% 
  select(.,Date, PAR)
print("PAR df created")
#import date/time and value column from iButton file
temp_air <-
  list.files(path = location , pattern = "*temp*", full.names = T) %>% 
  map_df(~read.table(text = gsub(",", "\t", readLines(.)), col.names = c("Date", "Time", "unit", "Temp_value", "Temp_dec"), skip = 20)) %>%  #(., delim = ",", col_names = T, col_types = cols(.default = "c"), skip = 18)) %>%
  mutate(Temperature = Temp_value + Temp_dec/1000, Date = strptime(as.character(.$Date), "%d.%m.%y")) %>%  #, Time = strptime(as.character(.$Time), "hh:mm:ss"
  mutate(Date = as.POSIXct(paste(Date, Time))) %>%
  select(.,Date, Temperature)
print("temp_air df created")
  
#join the df
combined <- join_all(list(fluxes, PAR, temp_air), by='Date', type='left') #%>% 
  # fill(PAR, .direction = "up") %>% #temperature and PAR are being filled up because the logger is taking the average on the last 10 and 15 seconds
  # fill(Temperature, .direction = "up") filling is taking a lot of memory when doing the fuzzy join, and I am not sure it makes sense since afterwards I will anyway use the average for the flux calculation
print("combined df created")
#import the record file
#next part is specific for Three-D

three_d <- read_csv("/home/jga051/Documents/01_PhD/05_data/01_summer2020/3drecord.csv") %>% 
  mutate(Start = as.POSIXct(paste(date, starting_time), format="%Y-%m-%d %H:%M:%S") - startcrop, End = Start + measurement - endcrop)

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
  mutate(ID = group_indices(., date, Turf_ID, type, replicate)) %>% 
  select(.,Date, CO2, PAR, Temperature, Turf_ID, type, replicate, campaign, ID, remark, date)
print("fluxes_threed created")

#need to do similar thing for INCLINE
incline <- read_csv("/home/jga051/Documents/01_PhD/05_data/01_summer2020/InclineRecord.csv") %>% 
  mutate(date = strptime(as.character(.$date), "%d/%m/%Y")) %>% 
  mutate(Start = as.POSIXct(paste(date, starting_time), format="%Y-%m-%d %H:%M:%S") - startcrop, End = Start + measurement - endcrop)
#extract from fluxes the data that are between "starting_time" and +2mn, associate plot_ID, treatment, type, replicate and campaign to each CO2 flux
#https://community.rstudio.com/t/tidy-way-to-range-join-tables-on-an-interval-of-dates/7881/2
fluxes_incline <- fuzzy_left_join(
  combined, incline,
  by = c(
    "Date" = "Start",
    "Date" = "End"
  ),
  match_fun = list(`>=`, `<=`)
) %>% 
  drop_na(Start) %>% 
  mutate(ID = group_indices(., campaign, plot_ID, type, replicate)) %>% 
  select(.,Date, CO2, PAR, Temperature, plot_ID, treatment, type, replicate, campaign, remark, ID, date)
print("fluxes_incline created")

#need to do similar thing for the light response curves
lightresponse <- read_csv("/home/jga051/Documents/01_PhD/05_data/01_summer2020/light-responseRecord.csv") %>% 
  mutate(date = strptime(as.character(.$date), "%d/%m/%Y")) %>% 
  mutate(Start = as.POSIXct(paste(date, starting_time), format="%Y-%m-%d %H:%M:%S") - startcrop, End = Start + measurement - endcrop)
#extract from fluxes the data that are between "starting_time" and +2mn, associate Turf_ID and replicate to each CO2 flux
#https://community.rstudio.com/t/tidy-way-to-range-join-tables-on-an-interval-of-dates/7881/2
fluxes_lightresponse <- fuzzy_left_join(
  combined, lightresponse,
  by = c(
    "Date" = "Start",
    "Date" = "End"
  ),
  match_fun = list(`>=`, `<=`)
) %>% 
  drop_na(Start) %>% 
  select(.,Date, CO2, PAR, Temperature, Turf_ID, replicate)
print("fluxes_lightresponse created")


#graph CO2 fluxes to visually check the data

#graph for three-d

ggplot(fluxes_threed[fluxes_threed$date == "2020-06-27",], aes(x=Date, y=CO2)) + 
  # geom_point(size=0.005) +
  geom_line(size = 0.1, aes(group = ID)) +
  coord_fixed(ratio = 10) +
  scale_x_datetime(date_breaks = "30 min") +
  # geom_line(size=0.05)
  ggsave("threed.png", height = 5, width = 120, units = "cm")