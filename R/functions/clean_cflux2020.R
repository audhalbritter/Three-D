clean_cflux2020 <- function(cflux2020_download, cfluxrecord2020_download, metaTurfID) {
  
# Unzip files
zipFile <- cflux2020_download
if(file.exists(zipFile)){
  outDir <- "data/C-Flux/summer_2020"
  unzip(zipFile, exdir = outDir)
}

location <- "data/C-Flux/summer_2020/rawData" #location of datafiles
#import all squirrel files and select date/time and CO2_calc columns, merge them, name it fluxes
fluxes <- dir_ls(location, regexp = "*CO2*") %>% 
  map_dfr(read_csv,  na = c("#N/A", "Over")) %>% 
  rename(conc = "CO2 (ppm)") %>%  #rename the column to get something more practical without space
  mutate(
    date = dmy(Date), #convert date in POSIXct
    date_time = as_datetime(paste(date, Time))  #paste date and time in one column
    ) %>%
  drop_na(conc) |>
  select(date_time, conc)

#import date/time and PAR columns from PAR file
PAR <- list.files(path = location, pattern = "*PAR*", full.names = TRUE) %>% 
  map_df(~read_table2(., "", na = c("NA"), col_names = paste0("V",seq_len(12)))) %>% #need that because logger is adding columns with useless information
  rename(date = V2, time = V3, PAR = V4) %>% 
  mutate(
    PAR = as.numeric(as.character(.$PAR)), #removing any text from the PAR column (again, the logger...)
    date_time = paste(date, time),
    date_time = ymd_hms(date_time)
    ) %>% 
  drop_na(PAR) |>
  select(date_time, PAR)


#import date/time and value column from iButton file

temp_air <- dir_ls(location, regexp = "*temp*") %>%
  map_dfr(read_csv,  na = c("#N/A"), skip = 20, col_names = c("date_time", "unit", "temp_value", "temp_dec"), col_types = "ccnn") %>%
  mutate(temp_dec = replace_na(temp_dec,0),
    temp_air = temp_value + temp_dec/1000, #because stupid iButtons use comma as delimiter AND as decimal point
    date_time = dmy_hms(date_time)
    ) %>% 
  drop_na(temp_air) |>
  select(date_time, temp_air)


#join the df


conc_raw <- fluxes %>% 
  left_join(PAR, by = "date_time") %>% 
  left_join(temp_air, by = "date_time")



#import the record file

record2020 <- read_csv(cfluxrecord2020_download, na = c(""), col_types = "ccntDfc") %>% 
  drop_na(starting_time) %>% #delete row without starting time (meaning no measurement was done)
  mutate(
    start = ymd_hms(paste(date, starting_time)) #converting the date as posixct, pasting date and starting time together
  ) %>% 
  rename(
    turfID = "turf_ID",
    flux_campaign = "campaign"
    ) |>
  distinct(start, .keep_all = TRUE) # some replicates were also marked as LRC and that is not correct

# matching

conc2020 <- flux_match(
  conc_raw,
  record2020,
  date_time,
  start,
  measurement_length = 120 # 2020 was 2 minutes
  )

slopes_exp_2020 <- flux_fitting(
    conc2020,
    conc,
    date_time,
    fit_type = "exp_zhao18"
    # start_cut = 20,
    # end_cut = 60
    )

slopes_exp_2020_flag <- flux_quality(
  slopes_exp_2020,
  conc,
  error = 150, #there were some calibration issues, leading to the instrument being off in absolute values
  force_discard = c(
    69, # unclear, flux U shaped
    80, # not zero, u shaped
    83, # U shaped, unclear
    118 # influence from disturbance at the start
  ),
  force_lm = c(
    124 # exponential goes opposite direction as flux, but lm fits
  ),
  force_zero = c(
    200 # bump at the start gives it a negative slope, but really it is flat
  )
  )

# slopes_exp_2020_flag |>
# filter(
#   f_fluxid %in% c(55, 69, 80, 83, 118, 124, 200)
# ) |>
# flux_plot(
#   conc,
#   date_time,
#   print_plot = "FALSE",
#   output = "pdfpages",
#   f_plotname = "plot_2020_check",
#   f_ylim_lower = 250
# )

# str(slopes_exp_2020_flag)

# we keep flux plot as comments because it takes quite long to run
# flux_plot(
#   slopes_exp_2020_flag,
#   conc,
#   date_time,
#   print_plot = "FALSE",
#   output = "pdfpages",
#   f_plotname = "plot_2020_cuts",
#   f_ylim_lower = 250
# )

# calculations

fluxes2020 <- flux_calc(
  slopes_exp_2020_flag,
  f_slope_corr,
  date_time,
  temp_air,
  setup_volume = 24.575,
  atm_pressure = 1,
  plot_area = 0.0625,
  conc_unit = "ppm",
  flux_unit = "mmol/m2/h",
  cols_keep = c(
    "turfID",
    "type",
    "replicate",
    "flux_campaign",
    "remarks",
    "f_quality_flag"
  ),
  cols_ave = c(
    "PAR"
  )
)

# str(fluxes2020)

# let's just compare with what was done previously



# old_fluxes2020 <- read_csv("data_cleaned/c-flux/Three-D_c-flux_2020_version_2022-02-09.csv")

# old_fluxes2020 <- old_fluxes2020 |>
#   rename(
#     old_flux = "flux",
#     old_PAR = "PARavg",
#     old_tempair = "temp_airavg"
#   )

# str(old_fluxes2020)

# all_fluxes <- full_join(
#   fluxes2020,
#   old_fluxes2020,
#   by = c( # we do not use date_time because the cut might be different
#     "turfID" = "turfID",
#     "type",
#     "flux_campaign",
#     "replicate"
#   )
# )

# str(all_fluxes)

# ggplot(all_fluxes, aes(old_flux, flux, label = f_fluxID)) +
# geom_point() +
# geom_text() +
# geom_abline(slope = 1)

# count(fluxes2020, type)

# calculating GPP

fluxes2020gpp <- fluxes2020 |>
  flux_gpp(
    type,
    date_time,
    id_cols = c("turfID", "flux_campaign", "replicate"),
    cols_keep = c("remarks", "f_quality_flag", "f_temp_air_ave", "PAR_ave")
  )

# str(fluxes2020gpp)

# let's just plot it to check
fluxes2020gpp |>
  ggplot(aes(x = type, y = flux)) +
  geom_violin()

fluxes2020gpp <- left_join(fluxes2020gpp, metaTurfID, by = "turfID") |>
  rename(
    # date_time = "date_time",
    comments = "remarks"
  )

fluxes2020gpp

}
