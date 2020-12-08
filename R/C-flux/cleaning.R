# This script is to clean raw data from various loggers into one datafile with calculated fluxes
library(fs)
library("dataDownloader")
library(broom)
source("R/Load packages.R")
source("https://raw.githubusercontent.com/jogaudard/common/master/fun-fluxes.R")


measurement <- 120 #the length of the measurement taken on the field in seconds
startcrop <- 30 #how much to crop at the beginning of the measurement in seconds
endcrop <- 0 #how much to crop at the end of the measurement in seconds

#download and unzip files from OSF
get_file(node = "pk4bg",
         file = "Three-D_cflux_2020.zip",
         path = "data/C-Flux/summer_2020",
         remote_path = "RawData/C-Flux")

get_file(node = "pk4bg",
         file = "Three-D_field-record_2020.csv",
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

three_d <- read_csv("data/C-Flux/summer_2020/Three-D_field-record_2020.csv", na = c(""), col_types = "ccntDnc") %>% 
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
co2_threed <- co2_threed %>% mutate(
  cut = case_when(
    datetime <= start_window | datetime >= end_window ~ "cut",
    ID == 1 & datetime > ymd_hms("2020-06-26T13:50:30") ~ "cut",
    ID == 4 & datetime < ymd_hms("2020-06-26T14:04:40") ~ "cut",
    ID == 5 & datetime < ymd_hms("2020-06-26T14:09:50") ~ "cut",
    ID == 6 & (datetime < ymd_hms("2020-06-26T14:14:50") | datetime > ymd_hms("2020-06-26T14:15:20")) ~ "cut",
    ID == 16 & datetime > ymd_hms("2020-06-26T18:18:40") ~ "cut",
    ID == 17 & datetime < ymd_hms("2020-06-26T18:21:40") ~ "cut",
    ID == 22 & datetime > ymd_hms("2020-06-26T14:40:40") ~ "cut",
    ID == 23 & datetime < ymd_hms("2020-06-26T14:43:40") ~ "cut",
    ID == 29 & datetime < ymd_hms("2020-06-26T19:17:30") ~ "cut",
    ID == 34 & datetime < ymd_hms("2020-06-26T13:25:40") ~ "cut",
    ID == 37 & datetime < ymd_hms("2020-06-27T11:24:40") ~ "cut",
    ID == 40 & datetime < ymd_hms("2020-06-27T11:38:00") ~ "cut",
    ID == 41 & datetime > ymd_hms("2020-06-27T11:42:50") ~ "cut",
    ID == 42 & (datetime < ymd_hms("2020-06-27T11:46:10") | datetime > ymd_hms("2020-06-27T11:47:20")) ~ "cut",
    ID == 43 & datetime < ymd_hms("2020-06-27T14:21:10") ~ "cut",
    ID == 50 & (datetime < ymd_hms("2020-06-27T14:50:40") | datetime > ymd_hms("2020-06-27T14:51:40")) ~ "cut",
    ID == 51 & datetime < ymd_hms("2020-06-27T14:55:10") ~ "cut",
    ID == 52 & datetime < ymd_hms("2020-06-27T14:59:10") ~ "cut",
    ID == 53 & datetime < ymd_hms("2020-06-27T15:03:10") ~ "cut",
    ID == 54 & (datetime < ymd_hms("2020-06-27T15:07:10") | datetime > ymd_hms("2020-06-27T15:08:10")) ~ "cut",
    ID == 56 & datetime < ymd_hms("2020-06-27T11:04:10") ~ "cut",
    ID == 57 & datetime < ymd_hms("2020-06-27T11:08:10") ~ "cut",
    ID == 58 & datetime < ymd_hms("2020-06-27T11:12:00") ~ "cut",
    ID == 63 & datetime < ymd_hms("2020-06-27T14:02:40") ~ "cut",
    ID == 64 & datetime < ymd_hms("2020-06-27T14:06:40") ~ "cut",
    ID == 65 & datetime < ymd_hms("2020-06-27T14:10:40") ~ "cut",
    ID == 67 & datetime < ymd_hms("2020-07-14T12:33:00") ~ "cut",
    ID == 69 & datetime < ymd_hms("2020-07-14T12:41:30") ~ "cut",
    ID == 70 & datetime < ymd_hms("2020-07-14T12:45:50") ~ "cut",
    ID == 71 & datetime < ymd_hms("2020-07-14T12:49:30") ~ "cut",
    ID == 72 & datetime < ymd_hms("2020-07-14T12:52:50") ~ "cut",
    ID == 73 & datetime < ymd_hms("2020-07-14T18:29:20") ~ "cut",
    ID == 74 & datetime < ymd_hms("2020-07-14T18:33:20") ~ "cut",
    ID == 75 & datetime < ymd_hms("2020-07-14T18:37:20") ~ "cut",
    ID == 76 & datetime < ymd_hms("2020-07-14T18:41:30") ~ "cut",
    ID == 77 & datetime < ymd_hms("2020-07-14T18:45:00") ~ "cut",
    ID == 78 & datetime < ymd_hms("2020-07-14T18:48:40") ~ "cut",
    ID == 79 & datetime < ymd_hms("2020-07-14T18:56:10") ~ "cut",
    ID == 80 & datetime < ymd_hms("2020-07-14T19:00:00") ~ "cut",
    ID == 81 & datetime < ymd_hms("2020-07-14T19:04:10") ~ "cut",
    ID == 82 & datetime < ymd_hms("2020-07-14T19:08:30") ~ "cut",
    ID == 83 & datetime < ymd_hms("2020-07-14T19:12:10") ~ "cut",
    ID == 84 & datetime < ymd_hms("2020-07-14T19:15:50") ~ "cut",
    ID == 85 & datetime < ymd_hms("2020-07-14T14:00:25") ~ "cut",
    ID == 86 & datetime < ymd_hms("2020-07-14T14:03:50") ~ "cut",
    ID == 87 & datetime < ymd_hms("2020-07-14T14:07:50") ~ "cut",
    ID == 88 & datetime < ymd_hms("2020-07-14T14:11:50") ~ "cut",
    ID == 89 & datetime < ymd_hms("2020-07-14T14:15:30") ~ "cut",
    ID == 90 & datetime < ymd_hms("2020-07-14T14:19:00") ~ "cut",
    ID == 91 & datetime < ymd_hms("2020-07-14T17:59:00") ~ "cut",
    ID == 92 & (datetime < ymd_hms("2020-07-14T18:04:10") | datetime > ymd_hms("2020-07-14T18:05:10")) ~ "cut",
    ID == 94 & datetime < ymd_hms("2020-07-14T18:14:00") ~ "cut",
    ID == 96 & datetime < ymd_hms("2020-07-14T18:21:20") ~ "cut",
    ID == 99 & datetime < ymd_hms("2020-07-14T12:01:50") ~ "cut",
    ID == 100 & datetime < ymd_hms("2020-07-14T12:05:30") ~ "cut",
    ID == 101 & datetime < ymd_hms("2020-07-14T12:08:50") ~ "cut",
    ID == 102 & datetime < ymd_hms("2020-07-14T12:13:40") ~ "cut",
    ID == 103 & datetime < ymd_hms("2020-07-15T11:11:40") ~ "cut",
    ID == 104 & datetime < ymd_hms("2020-07-15T11:15:20") ~ "cut",
    ID == 105 & (datetime < ymd_hms("2020-07-15T11:18:20") | datetime > ymd_hms("2020-07-15T11:19:20")) ~ "cut",
    ID == 106 & (datetime < ymd_hms("2020-07-15T11:23:40") | datetime %in% c(ymd_hms("2020-07-15T11:23:58"):ymd_hms("2020-07-15T11:23:59"))) ~ "cut", #peak in the middle of the flux, most likely a bubble of CO2 that got stuck in the tube du to moisture
    ID == 107 & datetime < ymd_hms("2020-07-15T11:27:00") ~ "cut",
    ID == 108 & datetime < ymd_hms("2020-07-15T11:30:40") ~ "cut",
    ID == 109 & datetime < ymd_hms("2020-07-15T10:45:10") ~ "cut",
    ID == 110 & datetime < ymd_hms("2020-07-15T10:49:00") ~ "cut",
    ID == 111 & datetime < ymd_hms("2020-07-15T10:52:20") ~ "cut",
    ID == 112 & datetime < ymd_hms("2020-07-15T10:55:45") ~ "cut",
    ID == 116 & datetime < ymd_hms("2020-07-15T11:45:55") ~ "cut",
    ID == 117 & datetime < ymd_hms("2020-07-15T11:50:50") ~ "cut",
    ID == 118 & datetime < ymd_hms("2020-07-15T11:55:20") ~ "cut",
    ID == 119 & datetime < ymd_hms("2020-07-15T11:59:20") ~ "cut",
    ID == 120 & datetime < ymd_hms("2020-07-15T12:03:00") ~ "cut",
    ID == 121 & datetime < ymd_hms("2020-07-16T10:53:50") ~ "cut",
    ID == 122 & datetime < ymd_hms("2020-07-16T10:57:20") ~ "cut",
    ID == 123 & datetime < ymd_hms("2020-07-16T11:01:10") ~ "cut",
    ID == 126 & datetime < ymd_hms("2020-07-16T11:13:00") ~ "cut",
    ID == 127 & datetime < ymd_hms("2020-07-16T10:26:00") ~ "cut",
    ID == 128 & datetime < ymd_hms("2020-07-16T10:29:40") ~ "cut",
    ID == 129 & datetime %in% c(ymd_hms("2020-07-16T10:33:15"):ymd_hms("2020-07-16T10:33:23")) ~ "cut",
    ID == 130 & datetime > ymd_hms("2020-07-16T10:39:00") ~ "cut",
    ID == 131 & (datetime < ymd_hms("2020-07-16T10:42:20") | datetime > ymd_hms("2020-07-16T10:43:20")) ~ "cut",
    ID == 132 & (datetime < ymd_hms("2020-07-16T10:45:55") | datetime > ymd_hms("2020-07-16T10:46:55")) ~ "cut",
    ID == 133 & datetime < ymd_hms("2020-07-16T09:55:50") ~ "cut",
    ID == 134 & datetime < ymd_hms("2020-07-16T10:00:30") ~ "cut",
    ID == 135 & datetime < ymd_hms("2020-07-16T10:05:00") ~ "cut",
    ID == 158 & datetime > ymd_hms("2020-08-02T12:55:00") ~ "cut",
    ID == 159 & datetime > ymd_hms("2020-08-02T12:58:20") ~ "cut",
    ID == 160 & datetime > ymd_hms("2020-08-02T13:02:00") ~ "cut",
    ID == 161 & datetime > ymd_hms("2020-08-02T13:06:00") ~ "cut",
    ID == 165 & (datetime > ymd_hms("2020-08-02T12:13:10") | datetime %in% c(ymd_hms("2020-08-02T12:12:35"):ymd_hms("2020-08-02T12:12:38"))) ~ "cut", #peak in the middle of the flux, most likely a bubble of CO2 that got stuck in the tube du to moisture
    ID == 169 & datetime > ymd_hms("2020-08-02T14:14:50") ~ "cut",
    ID == 180 & datetime > ymd_hms("2020-08-03T10:11:30") ~ "cut",
    ID == 191 & datetime > ymd_hms("2020-08-03T10:41:20") ~ "cut",
    ID == 192 & datetime > ymd_hms("2020-08-03T10:44:50") ~ "cut",
    ID == 206 & datetime > ymd_hms("2020-08-03T09:26:10") ~ "cut",
    ID == 208 & datetime > ymd_hms("2020-08-03T09:35:00") ~ "cut",
    ID == 221 & datetime > ymd_hms("2020-08-19T17:02:45") ~ "cut",
    ID == 229 & datetime > ymd_hms("2020-08-19T17:16:00") ~ "cut",
    ID == 243 & datetime > ymd_hms("2020-08-20T16:42:20") ~ "cut",
    ID == 244 & datetime > ymd_hms("2020-08-20T16:45:30") ~ "cut",
    ID == 246 & datetime > ymd_hms("2020-08-20T16:51:40") ~ "cut",
    ID == 247 & datetime > ymd_hms("2020-08-20T12:44:20") ~ "cut",
    ID == 248 & datetime > ymd_hms("2020-08-20T12:47:45") ~ "cut",
    ID == 262 & datetime > ymd_hms("2020-08-20T15:58:30") ~ "cut",
    ID == 264 & datetime < ymd_hms("2020-08-20T16:04:10") ~ "cut",
    ID == 267 & datetime > ymd_hms("2020-08-20T12:29:30") ~ "cut",
    ID == 268 & datetime > ymd_hms("2020-08-20T12:32:55") ~ "cut",
    ID == 278 & datetime > ymd_hms("2020-08-20T11:11:00") ~ "cut",
    TRUE ~ "keep"
  ),
  cut = as_factor(cut)
)

#plot each flux to look into details what to cut off
ggplot(co2_threed, aes(x = datetime, y = CO2, color = cut)) +
  geom_line(size = 0.2, aes(group = ID)) +
  scale_x_datetime(date_breaks = "1 min", minor_breaks = "10 sec", date_labels = "%e/%m \n %H:%M:%S") +
  # scale_x_date(date_labels = "%H:%M:%S") +
  facet_wrap(vars(ID), ncol = 36, scales = "free") +
  ggsave("threed_detail.png", height = 60, width = 126, units = "cm")


#graph CO2 fluxes to visually check the data
ggplot(co2_threed, aes(x=datetime, y=CO2, color = cut)) + 
  # geom_point(size=0.005) +
  geom_line(size = 0.2, aes(group = ID)) +
  # coord_fixed(ratio = 10) +
  scale_x_datetime(date_breaks = "10 min", minor_breaks = "30 sec", date_labels = "%e/%m \n %H:%M:%S") +
  facet_wrap(vars(date), ncol = 1, scales = "free") +
  # geom_line(size=0.05)
  ggsave("threed.png", height = 40, width = 100, units = "cm")

#calculation of flux
flux_threed <- filter(co2_threed, cut == "keep") %>% #cut out the discarded parts
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

#to remove poor quality data
# flux_threed_clean <- flux_threed %>% 
#   filter(
#     ((p.value <= 0.05 & r.squared >= 0.7) |
#       (p.value >0.05 & r.squared <= 0.2)) &
#       nobs >= 60
#   )
# count(flux_threed_clean)
  