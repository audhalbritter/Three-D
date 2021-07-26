library("dataDownloader")
library(broom)
library(fs)
source("R/Load packages.R")
# source("https://raw.githubusercontent.com/jogaudard/common/master/fun-fluxes.R")

#function to match the fluxes with the record file
match.flux <- function(raw_flux, field_record){
  co2conc <- full_join(raw_flux, field_record, by = c("datetime" = "start"), keep = TRUE) %>% #joining both dataset in one
    fill(PAR, temp_air, temp_soil, turfID, type, campaign, start, date, end, start_window, end_window) %>% #filling all rows (except Remarks) with data from above
    group_by(date, turfID, type) %>% #this part is to fill Remarks while keeping the NA (some fluxes have no remark)
    fill(comments) %>% 
    ungroup() %>% 
    mutate(ID = group_indices(., date, turfID, type)) %>% #assigning a unique ID to each flux, useful for plotting uzw
    filter(
      datetime <= end
      & datetime >= start) #%>% #cropping the part of the flux that is after the End and before the Start

  
  return(co2conc)
}


measurement <- 210 #the length of the measurement taken on the field in seconds
startcrop <- 10 #how much to crop at the beginning of the measurement in seconds
endcrop <- 40 #how much to crop at the end of the measurement in seconds

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

record <- read_csv("data/c-flux/summer_2021/Three-D_field-record_2021.csv", na = c(""), col_types = "cctDfc") %>% 
  drop_na(starting_time) %>% #delete row without starting time (meaning no measurement was done)
  mutate(
    start = ymd_hms(paste(date, starting_time)), #converting the date as posixct, pasting date and starting time together
    end = start + measurement, #creating column End
    start_window = start + startcrop, #cropping the start
    end_window = end - endcrop #cropping the end of the measurement
  ) 

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
    ID == 23 & datetime %in% c(ymd_hms("2021-06-04T14:12:30"):ymd_hms("2021-06-04T14:12:50")) ~ "cut",
    ID == 24 & datetime %in% c(ymd_hms("2021-06-04T14:07:30"):ymd_hms("2021-06-04T14:07:50")) ~ "cut",
    ID == 25 & datetime %in% c(ymd_hms("2021-06-04T14:23:30"):ymd_hms("2021-06-04T14:23:50")) ~ "cut",
    ID == 26 & datetime %in% c(ymd_hms("2021-06-04T14:17:20"):ymd_hms("2021-06-04T14:17:30")) ~ "cut",
    ID == 248 & datetime %in% c(ymd_hms("2021-06-22T14:19:45"):ymd_hms("2021-06-22T14:19:55")) ~ "cut",
    # ID ==  & datetime %in%  ~ "cut",
    # ID ==  & datetime %in%  ~ "cut",
    # ID ==  & datetime %in%  ~ "cut",
    TRUE ~ "keep"
  ),
  cut = as_factor(cut)
)
#plot each flux to look into details what to cut off
# ggplot(co2_cut, aes(x = datetime, y = CO2, color = cut)) +
#   geom_line(size = 0.2, aes(group = ID)) +
#   scale_x_datetime(date_breaks = "1 min", minor_breaks = "10 sec", date_labels = "%e/%m \n %H:%M") +
#   # scale_x_date(date_labels = "%H:%M:%S") +
#   facet_wrap(vars(ID), ncol = 30, scales = "free") +
#   ggsave("threed_2021_detailb.png", height = 60, width = 90, units = "cm")
#graph is too big, will need to do one per campaign or something...

theme_set(theme_grey(base_size = 5)) 

filter(co2_cut, campaign == 1) %>% 
  ggplot(aes(x = datetime, y = CO2, color = cut)) +
  geom_line(size = 0.2, aes(group = ID)) +
  scale_x_datetime(date_breaks = "1 min", minor_breaks = "10 sec", date_labels = "%e/%m \n %H:%M") +
  # scale_x_date(date_labels = "%H:%M:%S") +
  facet_wrap(vars(ID), ncol = 30, scales = "free") +
  ggsave("threed_2021_detail_1.png", height = 40, width = 80, units = "cm")

filter(co2_cut, campaign == 2) %>% 
  ggplot(aes(x = datetime, y = CO2, color = cut)) +
  geom_line(size = 0.2, aes(group = ID)) +
  scale_x_datetime(date_breaks = "1 min", minor_breaks = "10 sec", date_labels = "%e/%m \n %H:%M") +
  # scale_x_date(date_labels = "%H:%M:%S") +
  facet_wrap(vars(ID), ncol = 30, scales = "free") +
  ggsave("threed_2021_detail_2.png", height = 40, width = 80, units = "cm")



#Is there a more automated way to do one file per campaign??

# co2_cut <- filter(co2_cut, cut == "keep") #to keep only the part we want to keep

#need to clean PAR, temp_air, temp_soil

#temp_air and temp_soil: graph after the cleaning of CO2 and check if data are "normal"
#put NA for when the soil temp sensor was not pluged in
filter(co2_cut, campaign == 1) %>% 
  ggplot(aes(x = datetime, y = temp_air)) +
    geom_line(size = 0.2, aes(group = ID)) +
    scale_x_datetime(date_breaks = "1 min", minor_breaks = "10 sec", date_labels = "%e/%m \n %H:%M") +
    # scale_x_date(date_labels = "%H:%M:%S") +
    facet_wrap(vars(ID), ncol = 30, scales = "free") +
    ggsave("threed_2021_detail_tempair_1.png", height = 40, width = 80, units = "cm")

filter(co2_cut, campaign == 2) %>% 
  ggplot(aes(x = datetime, y = temp_air)) +
  geom_line(size = 0.2, aes(group = ID)) +
  scale_x_datetime(date_breaks = "1 min", minor_breaks = "10 sec", date_labels = "%e/%m \n %H:%M") +
  # scale_x_date(date_labels = "%H:%M:%S") +
  facet_wrap(vars(ID), ncol = 30, scales = "free") +
  ggsave("threed_2021_detail_tempair_2.png", height = 40, width = 80, units = "cm")

filter(co2_cut, campaign == 1) %>% 
  ggplot(aes(x = datetime, y = temp_soil)) +
  geom_line(size = 0.2, aes(group = ID)) +
  scale_x_datetime(date_breaks = "1 min", minor_breaks = "10 sec", date_labels = "%e/%m \n %H:%M") +
  # scale_x_date(date_labels = "%H:%M:%S") +
  facet_wrap(vars(ID), ncol = 30, scales = "free") +
  ggsave("threed_2021_detail_tempsoil_1.png", height = 40, width = 80, units = "cm")

filter(co2_cut, campaign == 2) %>% 
  ggplot(aes(x = datetime, y = temp_soil)) +
  geom_line(size = 0.2, aes(group = ID)) +
  scale_x_datetime(date_breaks = "1 min", minor_breaks = "10 sec", date_labels = "%e/%m \n %H:%M") +
  # scale_x_date(date_labels = "%H:%M:%S") +
  facet_wrap(vars(ID), ncol = 30, scales = "free") +
  ggsave("threed_2021_detail_tempsoil_2.png", height = 40, width = 80, units = "cm")

# ggplot(co2_cut, aes(x = datetime, y = temp_soil)) +
#   geom_line(size = 0.2, aes(group = ID)) +
#   scale_x_datetime(date_breaks = "1 min", minor_breaks = "10 sec", date_labels = "%e/%m \n %H:%M") +
#   # scale_x_date(date_labels = "%H:%M:%S") +
#   facet_wrap(vars(ID), ncol = 40, scales = "free") +
#   ggsave("threed_2021_detail_tempsoil.png", height = 60, width = 126, units = "cm")



co2_cut <- co2_cut %>% 
  mutate(
    temp_soil = case_when(
      # ID == c(120,119,123) ~ NA#for measurements when the sensor was not in the right place
      comments == "soilT logger not plugged in" ~ NA_real_,
      comments == "Soil T NA" ~ NA_real_,
      TRUE ~ temp_soil
    )
  )


#PAR: same + NA for soilR and ER

co2_cut <- co2_cut %>% 
  mutate(
    PAR = case_when(
      # type == "ER" ~ NA_real_, #no PAR for ecosystem respiration (but maybe I should keep it??)
      type == "SoilR" ~ NA_real_, #no PAR with soil respiration, the sensor was somewhere else anyway
      # datetime %in% c(ymd_hms("2020-08-02T12:12:35"):ymd_hms("2020-08-02T12:12:38")) # for when the sensor messed up because of the heat (should see a drop close to 0 or negative values)
      TRUE ~ as.numeric(PAR)
      )
  )

# filter(co2_cut, campaign == 1) %>% 
filter(co2_cut, type == "NEE") %>% 
  ggplot(aes(x = datetime, y = PAR)) +
    geom_line(size = 0.2, aes(group = ID)) +
    scale_x_datetime(date_breaks = "1 min", minor_breaks = "10 sec", date_labels = "%e/%m \n %H:%M") +
    # scale_x_date(date_labels = "%H:%M:%S") +
    facet_wrap(vars(ID), ncol = 40, scales = "free") +
    ggsave("threed_2021_detail_PAR_NEE.png", height = 40, width = 80, units = "cm")

filter(co2_cut, type == "ER") %>% 
  ggplot(aes(x = datetime, y = PAR)) +
  geom_line(size = 0.2, aes(group = ID)) +
  scale_x_datetime(date_breaks = "1 min", minor_breaks = "10 sec", date_labels = "%e/%m \n %H:%M") +
  # scale_x_date(date_labels = "%H:%M:%S") +
  facet_wrap(vars(ID), ncol = 40, scales = "free") +
  ggsave("threed_2021_detail_PAR_ER.png", height = 40, width = 80, units = "cm")

filter(co2_cut, type == c("LRC1", "LRC2", "LRC3", "LRC4", "LRC5")) %>% 
  ggplot(aes(x = datetime, y = PAR)) +
  geom_line(size = 0.2, aes(group = ID)) +
  scale_x_datetime(date_breaks = "1 min", minor_breaks = "10 sec", date_labels = "%e/%m \n %H:%M") +
  # scale_x_date(date_labels = "%H:%M:%S") +
  facet_wrap(vars(ID), ncol = 10, scales = "free") +
  ggsave("threed_2021_detail_PAR_LRC.png", height = 40, width = 80, units = "cm")


##Next part is for calculating the fluxes, once the data have been cleaned

#first, a function to calculate fluxes
flux.calc <- function(co2conc, # dataset of CO2 concentration versus time (output of match.flux)
                      chamber_volume = 24.5, # volume of the flux chamber in L, default for Three-D chamber (25x24.5x40cm)
                      tube_volume = 0.075, # volume of the tubing in L, default for summer 2020 setup
                      atm_pressure = 1, # atmoshperic pressure, assumed 1 atm
                      plot_area = 0.0625 # area of the plot in m^2, default for Three-D
)
{
  R = 0.082057 #gas constant, in L*atm*K^(-1)*mol^(-1)
  vol = chamber_volume + tube_volume
  fluxes_final <- co2conc %>% 
    # group_by(ID) %>% 
    nest(-ID) %>% 
    mutate(
      data = map(data, ~.x %>% 
                   mutate(time = difftime(datetime[1:length(datetime)],datetime[1] , units = "secs"), #add a column with the time difference between each measurements and the beginning of the measurement. Usefull to calculate the slope.
                          PARavg = mean(PAR, na.rm = TRUE), #mean value of PAR for each flux
                          temp_airavg = mean(temp_air, na.rm = TRUE)  #mean value of Temp_air for each flux
                          + 273.15, #transforming in kelvin for calculation
                          temp_soilavg = mean(temp_soil, na.rm = TRUE) #mean value of temp_soil for each flux
                   )), 
      fit = map(data, ~lm(CO2 ~ time, data = .)), #fit is a new column in the tibble with the slope of the CO2 concentration vs time (in secs^(-1))
      # slope = map_dbl(fit, "time")
      results = map(fit, glance), #to see the coefficients of the model
      slope = map(fit, tidy) #creates a tidy df with the coefficients of fit
    ) %>% 
    
    unnest(results, slope) %>% 
    unnest(data) %>% 
    filter(term == 'time'  #filter the estimate of time only. That is the slope of the CO2 concentration. We need that to calculate the flux.
           # & r.squared >= 0.7 #keeping only trendline with an r.squared above or equal to 0.7. Below that it means that the data are not good quality enough
           # & p.value < 0.05 #keeping only the significant fluxes
    ) %>% 
    # select(ID, Plot_ID, Type, Replicate, Remarks, Date, PARavg, Temp_airavg, r.squared, p.value, estimate, Campaign) %>% #select the column we need, dump the rest
    distinct(ID, turf_ID, type, commments, date, PARavg, temp_airavg, temp_soilavg, r.squared, p.value, estimate, campaign, .keep_all = TRUE) %>%  #remove duplicate. Because of the nesting, we get one row per Datetime entry. We only need one row per flux. Select() gets rid of Datetime and then distinct() is cleaning those extra rows.
    #calculate fluxes using the trendline and the air temperature
    mutate(flux = (estimate * atm_pressure * vol)/(R * temp_airavg * plot_area) #gives flux in micromol/s/m^2
           *3600 #secs to hours
           /1000 #micromol to mmol
    ) %>%  #flux is now in mmol/m^2/h, which is more common
    select(datetime, ID, turf_ID, type, comments, date, PARavg, temp_airavg, temp_soilavg, r.squared, p.value, nobs, flux, campaign)
  
  return(fluxes_final)
  
}

fluxes2021 <- flux.calc(co2_cut)

write_csv(fluxes2021, "data/c-flux/summer_2021/Three-D_c-flux_2021.csv")

