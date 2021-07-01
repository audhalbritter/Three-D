library("dataDownloader")
library(broom)
source("R/Load packages.R")
source("https://raw.githubusercontent.com/jogaudard/common/master/fun-fluxes.R")


measurement <- 240 #the length of the measurement taken on the field in seconds
startcrop <- 10 #how much to crop at the beginning of the measurement in seconds
endcrop <- 60 #how much to crop at the end of the measurement in seconds

#download and unzip files from OSF
get_file(node = "pk4bg",
         file = "Three-D_cflux_2021.zip",
         path = "data/c-flux/summer_2021",
         remote_path = "RawData/C-Flux")

get_file(node = "pk4bg",
         file = "Three-D_field-record_2021.csv",
         path = "data/c-flux/summer_2021",
         remote_path = "RawData/C-Flux")

get_file(node = "pk4bg",
         file = "Three-D_cutting_2021.csv",
         path = "data/c-flux/summer_2021",
         remote_path = "RawData/C-Flux")

# Unzip files
zipFile <- "data/c-flux/summer_2021/Three-D_cflux_2021.zip"
if(file.exists(zipFile)){
  outDir <- "data/c-flux/summer_2021"
  unzip(zipFile, exdir = outDir)
}

#importing fluxes data
location <- "data/c-flux/summer_2021/rawData" #location of datafiles

fluxes <-
  dir_ls(location, regexp = "*CO2*") %>% 
  map_dfr(read_csv,  na = c("#N/A", "Over")) %>% 
  rename( #rename the column to get something more practical without space
    CO2 = "CO2 (ppm)",
    temp_air = "Temp_air ('C)",
    temp_soil = "Temp_soil ('C)",
    PAR = "PAR (umolsm2)",
    datetime = "Date/Time"
    ) %>%  
  mutate(
    datetime = dmy_hms(datetime)
  ) %>%
  select(datetime,CO2, PAR, temp_air, temp_soil)


#import the record file from the field

record <- read_csv("data/c-flux/summer_2021/Three-D_field-record_2021.csv", na = c(""), col_types = "ccntDfc") %>% 
  drop_na(starting_time) %>% #delete row without starting time (meaning no measurement was done)
  mutate(
    start = ymd_hms(paste(date, starting_time)), #converting the date as posixct, pasting date and starting time together
    end = start + measurement, #creating column End
    start_window = start + startcrop, #cropping the start
    end_window = end - endcrop #cropping the end of the measurement
  ) %>% 
  rename(plot_ID = turf_ID) #because the function to calculate fluxes takes plot_ID, but I might change that

#matching the CO2 concentration data with the turfs using the field record
co2_fluxes <- match.flux(fluxes,record)

#adjusting the time window with the actual fluxes

# import cutting
cutting <- read_csv("data/c-flux/summer_2021/Three-D_cutting_2021.csv", na = "", col_types = "dtt")

co2_cut <- co2_fluxes %>% 
  left_join(cutting, by = "ID") %>% 
  mutate(
    start_cut = ymd_hms(paste(date, .$start_cut)),
    end_cut = ymd_hms(paste(date, .$end_cut))
  )

# adjusting the time window with manual cuts
co2_cut <- co2_cut %>% mutate(
  start_window = case_when(
    is.na(start_cut) == FALSE ~ start_cut,
    TRUE ~ start_window
  ),
  end_window = case_when(
    is.na(end_cut) == FALSE ~ end_cut,
    TRUE ~ end_window
  ),
  cut = case_when(
    datetime <= start_window | datetime >= end_window ~ "cut",
    # ID == 185 & datetime %in% c(ymd_hms("2020-08-02T12:12:35"):ymd_hms("2020-08-02T12:12:38")) ~ "cut",
    # ID ==  & datetime %in%  ~ "cut",
    # ID ==  & datetime %in%  ~ "cut",
    # ID ==  & datetime %in%  ~ "cut",
    TRUE ~ "keep"
  ),
  cut = as_factor(cut)
)
#plot each flux to look into details what to cut off
ggplot(co2_cut, aes(x = datetime, y = CO2, color = cut)) +
  geom_line(size = 0.2, aes(group = ID)) +
  scale_x_datetime(date_breaks = "1 min", minor_breaks = "10 sec", date_labels = "%e/%m \n %H:%M") +
  # scale_x_date(date_labels = "%H:%M:%S") +
  facet_wrap(vars(ID), ncol = 40, scales = "free") +
  ggsave("threed_2021_detail.png", height = 60, width = 126, units = "cm")


# co2_cut <- filter(co2_cut, cut == "keep") #to keep only the part we want to keep

#need to clean PAR, temp_air, temp_soil

#temp_air and temp_soil: graph after the cleaning of CO2 and check if data are "normal"
#put NA for when the soil temp sensor was not pluged in
ggplot(co2_cut, aes(x = datetime, y = temp_air)) +
  geom_line(size = 0.2, aes(group = ID)) +
  scale_x_datetime(date_breaks = "1 min", minor_breaks = "10 sec", date_labels = "%e/%m \n %H:%M") +
  # scale_x_date(date_labels = "%H:%M:%S") +
  facet_wrap(vars(ID), ncol = 40, scales = "free") +
  ggsave("threed_2021_detail_tempair.png", height = 60, width = 126, units = "cm")

ggplot(co2_cut, aes(x = datetime, y = temp_soil)) +
  geom_line(size = 0.2, aes(group = ID)) +
  scale_x_datetime(date_breaks = "1 min", minor_breaks = "10 sec", date_labels = "%e/%m \n %H:%M") +
  # scale_x_date(date_labels = "%H:%M:%S") +
  facet_wrap(vars(ID), ncol = 40, scales = "free") +
  ggsave("threed_2021_detail_tempsoil.png", height = 60, width = 126, units = "cm")

co2_cut <- co2_cut %>% 
  mutate(
    temp_soil = case_when(
      ID == XX ~ NA#for measurements when the sensor was not in the right place
      
    )
  )


#PAR: same + NA for soilR and ER



