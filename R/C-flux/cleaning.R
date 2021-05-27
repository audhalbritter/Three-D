# This script is to clean raw data from various loggers into one datafile with calculated fluxes
library(fs)
library("dataDownloader")
library(broom)
source("R/Load packages.R")
source("https://raw.githubusercontent.com/jogaudard/common/master/fun-fluxes.R")


measurement <- 180 #the length of the measurement taken on the field in seconds
startcrop <- 10 #how much to crop at the beginning of the measurement in seconds
endcrop <- 60 #how much to crop at the end of the measurement in seconds

#download and unzip files from OSF
get_file(node = "pk4bg",
         file = "Three-D_cflux_2020.zip",
         path = "data/C-Flux/summer_2020",
         remote_path = "RawData/C-Flux")

get_file(node = "pk4bg",
         file = "Three-D_field-record_2020.csv",
         path = "data/C-Flux/summer_2020",
         remote_path = "RawData/C-Flux")

get_file(node = "pk4bg",
         file = "Three-D_cutting_2020.csv",
         path = "data/C-Flux/summer_2020",
         remote_path = "RawData/C-Flux")

# Unzip files
zipFile <- "data/C-Flux/summer_2020/Three-D_cflux_2020.zip"
if(file.exists(zipFile)){
  outDir <- "data/C-Flux/summer_2020"
  unzip(zipFile, exdir = outDir)
}

location <- "data/C-Flux/summer_2020/rawData" #location of datafiles
#import all squirrel files and select date/time and CO2_calc columns, merge them, name it fluxes
fluxes <-
  dir_ls(location, regexp = "*CO2*") %>% 
  map_dfr(read_csv,  na = c("#N/A", "Over")) %>% 
  rename(CO2 = "CO2 (ppm)") %>%  #rename the column to get something more practical without space
  mutate(
    date = dmy(Date), #convert date in POSIXct
    datetime = as_datetime(paste(date, Time))  #paste date and time in one column
    ) %>%
  select(datetime,CO2)

#import date/time and PAR columns from PAR file
PAR <-
  list.files(path = location, pattern = "*PAR*", full.names = T) %>% 
  map_df(~read_table2(., "", na = c("NA"), col_names = paste0("V",seq_len(12)))) %>% #need that because logger is adding columns with useless information
  rename(date = V2, time = V3, PAR = V4) %>% 
  mutate(
    PAR = as.numeric(as.character(.$PAR)), #removing any text from the PAR column (again, the logger...)
    datetime = paste(date, time),
    datetime = ymd_hms(datetime)
    ) %>% 
  select(datetime, PAR)

#import date/time and value column from iButton file

temp_air <-dir_ls(location, regexp = "*temp*") %>% 
  map_dfr(read_csv,  na = c("#N/A"), skip = 20, col_names = c("datetime", "unit", "temp_value", "temp_dec"), col_types = "ccnn") %>%
  mutate(temp_dec = replace_na(temp_dec,0),
    temp_air = temp_value + temp_dec/1000, #because stupid iButtons use comma as delimiter AND as decimal point
    datetime = dmy_hms(datetime)
    ) %>% 
  select(datetime, temp_air)


#join the df


combined <- fluxes %>% 
  left_join(PAR, by = "datetime") %>% 
  left_join(temp_air, by = "datetime")

#import the record file
#next part is specific for Three-D

three_d <- read_csv("data/C-Flux/summer_2020/Three-D_field-record_2020.csv", na = c(""), col_types = "ccntDfc") %>% 
  drop_na(starting_time) %>% #delete row without starting time (meaning no measurement was done)
  mutate(
    start = ymd_hms(paste(date, starting_time)), #converting the date as posixct, pasting date and starting time together
    end = start + measurement, #creating column End
    start_window = start + startcrop, #cropping the start
    end_window = end - endcrop #cropping the end of the measurement
  ) %>% 
  rename(plot_ID = turf_ID)



# three_d <- read_csv("data/C-Flux/summer_2020/Three-D_field-record_2020.csv", na = c(""), col_types = "ccntDnc") %>% 
#   mutate(
#     Start = as_datetime(paste(Date, Starting_time)), #converting the date as posixct, pasting date and starting time together
#     # Datetime = Start, #useful for left_join
#     End = Start + measurement - endcrop, #creating column End and cropping the end of the measurement
#     Start = Start + startcrop #cropping the start
#   ) %>%  
#   rename(Plot_ID = Turf_ID) %>% 
#   select(Plot_ID,Type,Replicate,Starting_time,Date,Campaign,Remarks,Start,End)
  
#matching fluxes


co2_threed <- match.flux(combined,three_d)


#adjusting the time window with the actual fluxes

# import cutting
cutting <- read_csv("data/C-Flux/summer_2020/Three-D_cutting_2020.csv", na = "", col_types = "dtt")

co2_threed_cut <- co2_threed %>% 
  left_join(cutting, by = "ID") %>% 
  mutate(
    start_cut = ymd_hms(paste(date, .$start_cut)),
    end_cut = ymd_hms(paste(date, .$end_cut))
  )

# adjusting the time window with manual cuts
co2_threed_cut <- co2_threed_cut %>% mutate(
  start_window = case_when(
    is.na(start_cut) == FALSE ~ start_cut,
    # start_cut > start_window ~ start_cut,
    # start_cut = NA ~ start_window,
    TRUE ~ start_window
  ),
  end_window = case_when(
    is.na(end_cut) == FALSE ~ end_cut,
    # end_cut < end_window ~ end_cut,
    TRUE ~ end_window
  ),
  cut = case_when(
    datetime <= start_window | datetime >= end_window ~ "cut",
    # ID == 185 & datetime %in% c(ymd_hms("2020-08-02T12:12:35"):ymd_hms("2020-08-02T12:12:38")) ~ "cut",
    ID == 139 & datetime %in% c(ymd_hms("2020-07-16T10:33:15"):ymd_hms("2020-07-16T10:33:23")) ~ "cut",
    ID == 111 & datetime %in% c(ymd_hms("2020-07-15T11:23:58"):ymd_hms("2020-07-15T11:23:59")) ~ "cut",
    # ID ==  & datetime %in%  ~ "cut",
    # ID ==  & datetime %in%  ~ "cut",
    # ID ==  & datetime %in%  ~ "cut",
    
   
    
    
    # ID ==  & (datetime < ymd_hms("") | datetime > ymd_hms("")) ~ "cut",
    TRUE ~ "keep"
  ),
  cut = as_factor(cut)
)



#plot each flux to look into details what to cut off
ggplot(co2_threed_cut, aes(x = datetime, y = CO2, color = cut)) +
  geom_line(size = 0.2, aes(group = ID)) +
  scale_x_datetime(date_breaks = "1 min", minor_breaks = "10 sec", date_labels = "%e/%m \n %H:%M") +
  # scale_x_date(date_labels = "%H:%M:%S") +
  facet_wrap(vars(ID), ncol = 36, scales = "free") +
  ggsave("threed_detail.png", height = 60, width = 126, units = "cm")


#graph CO2 fluxes to visually check the data
ggplot(co2_threed_cut, aes(x=datetime, y=CO2, color = cut)) + 
  # geom_point(size=0.005) +
  geom_line(size = 0.2, aes(group = ID)) +
  # coord_fixed(ratio = 10) +
  scale_x_datetime(date_breaks = "10 min", minor_breaks = "30 sec", date_labels = "%e/%m \n %H:%M:%S") +
  facet_wrap(vars(date), ncol = 1, scales = "free") +
  # geom_line(size=0.05)
  ggsave("threed.png", height = 40, width = 100, units = "cm")

#calculation of flux
flux_threed <- filter(co2_threed_cut, cut == "keep") %>% #cut out the discarded parts
  flux.calc() %>% 
  rename(
    turf_ID = plot_ID #because in Three-D they are turfs but the function uses plots
  )

# count(flux_threed)
write_csv(flux_threed, "data/C-Flux/summer_2020/Three-D_c-flux_2020.csv")

#make a freq hist about length of fluxes
ggplot(flux_threed, aes(nobs)) +
  geom_bar() +
  scale_x_binned()

# #to remove poor quality data
# flux_threed_clean <- flux_threed %>%
#   filter(
#     ((p.value <= 0.05 & r.squared >= 0.7) |
#       (p.value >0.05 & r.squared <= 0.2)) &
#       nobs >= 60
#   )
# 
# a <- count(flux_threed_clean)
# b <- count(flux_threed)
# a
# b
# a/b
  