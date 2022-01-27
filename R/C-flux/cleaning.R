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
# flux_threed <- filter(co2_threed_cut, cut == "keep") %>% #cut out the discarded parts
#   flux.calc() %>% 
#   rename(
#     turfID = plot_ID, #because in Three-D they are turfs but the function uses plots
#     fluxID = ID, #ID is already in use in the Three-D project
#     date_time = datetime,
#     remark = remarks
#   )

#we will use a better function than the previous one
flux.calc2 <- function(co2conc, # dataset of CO2 concentration versus time (output of match.flux)
                       chamber_volume = 24.5, # volume of the flux chamber in L, default for Three-D chamber (25x24.5x40cm)
                       tube_volume = 0.075, # volume of the tubing in L, default for summer 2020 setup
                       atm_pressure = 1, # atmoshperic pressure, assumed 1 atm
                       plot_area = 0.0625 # area of the plot in m^2, default for Three-D
)
{
  R = 0.082057 #gas constant, in L*atm*K^(-1)*mol^(-1)
  vol = chamber_volume + tube_volume
  # co2conc <- co2_cut
  slopes <- co2conc %>% 
    group_by(ID) %>% 
    mutate(
      time = difftime(datetime[1:length(datetime)],datetime[1] , units = "secs")
    ) %>% 
    select(ID, time, CO2) %>%
    do({model = lm(CO2 ~ time, data=.)    # create your model
    data.frame(tidy(model),              # get coefficient info
               glance(model))}) %>%          # get model info
    filter(term == "time") %>% 
    rename(slope = estimate) %>% 
    select(ID, slope, p.value, r.squared, adj.r.squared, nobs) %>% 
    ungroup()
  
  means <- co2conc %>% 
    group_by(ID) %>% 
    summarise(
      PARavg = mean(PAR, na.rm = TRUE), #mean value of PAR for each flux
      temp_airavg = mean(temp_air, na.rm = TRUE)  #mean value of temp_air for each flux
      + 273.15 #transforming in kelvin for calculation
    ) %>% 
    ungroup()
  
  fluxes_final <- left_join(slopes, means, by = "ID") %>% 
    left_join(
      co2conc,
      by = "ID"
    ) %>% 
    select(ID, slope, p.value, r.squared, adj.r.squared, nobs, PARavg, temp_airavg, plot_ID, type, campaign, remarks, start_window) %>% 
    distinct() %>% 
    rename(
      datetime = start_window
    ) %>% 
    mutate(
      flux = (slope * atm_pressure * vol)/(R * temp_airavg * plot_area) #gives flux in micromol/s/m^2
      *3600 #secs to hours
      /1000 #micromol to mmol
    ) %>% #flux is now in mmol/m^2/h, which is more common
    arrange(datetime) %>% 
    select(!slope)
  
  return(fluxes_final)
  
}

flux_threed <- filter(co2_threed_cut, cut == "keep") %>% #cut out the discarded parts
    flux.calc2() %>%
    rename(
      turfID = plot_ID, #because in Three-D they are turfs but the function uses plots
      fluxID = ID, #ID is already in use in the Three-D project
      comments = remarks
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
  