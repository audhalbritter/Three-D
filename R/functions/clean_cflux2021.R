clean_cflux2021 <- function(soilRchambersize_download, cflux2021_download, cfluxrecord2021_download, metaTurfID) {

# just for debugging
# library(tidyverse)
# library(fluxible)
# library(fs)
#   soilRchambersize_download <- "data/c-flux/summer_2021/Three-D_soilR-chambers-size.csv"
#   cflux2021_download <- "data/c-flux/summer_2021/Three-D_cflux_2021.zip"
#   cfluxrecord2021_download <- "data/c-flux/summer_2021/Three-D_field-record_2021.csv"

soilR_chamber <- read_csv(soilRchambersize_download) |>
  mutate(
    soil_chamber_area = pi * (0.05 ^2), # are in m2
    soil_chamber_vol = soil_chamber_area * depth_above_cm * 10, # vol in L
    type = "SoilR"
  ) |>
  select(!comments)

# Unzip files
zipFile <- cflux2021_download
if(file.exists(zipFile)){
  outDir <- "data/c-flux/summer_2021"
  unzip(zipFile, exdir = outDir)
}

#importing fluxes data
location <- "data/c-flux/summer_2021" #location of datafiles

conc_raw <- dir_ls(location, regexp = "*CO2*") %>% 
  map_dfr(read_csv,  na = c("#N/A", "Over")) %>% 
  rename( #rename the column to get something more practical without space
    CO2 = "CO2 (ppm)",
    temp_air = "Temp_air ('C)",
    temp_soil = "Temp_soil ('C)",
    PAR = "PAR (umolsm2)",
    date_time = "Date/Time"
    ) %>%  
  mutate(
    date_time = dmy_hms(date_time)
  ) %>%
  select(date_time, CO2, PAR, temp_air, temp_soil)


#import the record file from the field

record <- read_csv(cfluxrecord2021_download, na = c(""), col_types = "cctDfc") %>% 
  drop_na(starting_time) %>% #delete row without starting time (meaning no measurement was done)
  mutate(
    start = ymd_hms(paste(date, starting_time)) #converting the date as posixct, pasting date and starting time together
  )  |>
  rename(
    flux_campaign = "campaign"
  ) |>
  distinct(start, .keep_all = TRUE) # some replicates were also marked as LRC and that is not correct

#matching the CO2 concentration data with the turfs using the field record
conc <- flux_match(
  conc_raw,
  record,
  date_time,
  start,
  measurement_length = 180
  )

# str(conc)

# fitting fluxes

slopes_exp_2021 <- flux_fitting(
  conc,
  CO2,
  date_time,
  fit_type = "exp_zhao18",
  end_cut = 30
)

slopes_exp_2021_flag <- flux_quality(
  slopes_exp_2021,
  CO2,
  error = 400, # the gas analyser was off but the slope is ok
  force_ok = c(
    198 # looks ok despite b above threshold
  ),
  force_discard = c(
    19, # bump at start messing up the fit
    402, # slope is off
    562, # slope in opposite direction
    985 # slope is off
  ),
  force_lm = c(
    91, # bump messing up the exp fit, but lm fits well
    407 # lm is ok
  )
  # force_zero = c(
  # )
)

# slopes_exp_2021_flag |>
# filter(
#   f_fluxid %in% c(198, 19, 402, 562, 985, 91, 407, 403, 409, 570)
# ) |>
# flux_plot(
#   CO2,
#   date_time,
#   print_plot = "FALSE",
#   output = "pdfpages",
#   f_plotname = "plot_2021_check",
#   f_ylim_lower = 300
#   )

# flux_plot is time consuming so we keep it as comments to avoid running accidentally

# flux_plot is a bit faster since fluxible 1.2.10


# slopes_exp_2021_flag |>
# filter(
#   f_fluxid %in% (1:250)
# ) |>
# flux_plot(
#   CO2,
#   date_time,
#   print_plot = "FALSE",
#   output = "pdfpages",
#   f_plotname = "plot_2021_1",
#   f_ylim_lower = 300
#   )

# slopes_exp_2021_flag |>
# filter(
#   f_fluxid %in% (251:500)
# ) |>
# flux_plot(
#   CO2,
#   date_time,
#   print_plot = "FALSE",
#   output = "pdfpages",
#   f_plotname = "plot_2021_2",
#   f_ylim_lower = 300
#   )

# slopes_exp_2021_flag |>
# filter(
#   f_fluxid %in% (501:750)
# ) |>
# flux_plot(
#   CO2,
#   date_time,
#   print_plot = "FALSE",
#   output = "pdfpages",
#   f_plotname = "plot_2021_3",
#   f_ylim_lower = 300
#   )

# slopes_exp_2021_flag |>
# filter(
#   f_fluxid %in% (751:1000)
# ) |>
# flux_plot(
#   CO2,
#   date_time,
#   print_plot = "FALSE",
#   output = "pdfpages",
#   f_plotname = "plot_2021_4",
#   f_ylim_lower = 300
#   )

# slopes_exp_2021_flag |>
# filter(
#   f_fluxid %in% (1001:1250)
# ) |>
# flux_plot(
#   CO2,
#   date_time,
#   print_plot = "FALSE",
#   output = "pdfpages",
#   f_plotname = "plot_2021_5",
#   f_ylim_lower = 300
#   )

# slopes_exp_2021_flag |>
# filter(
#   f_fluxid %in% (1251:1500)
# ) |>
# flux_plot(
#   CO2,
#   date_time,
#   print_plot = "FALSE",
#   output = "pdfpages",
#   f_plotname = "plot_2021_6",
#   f_ylim_lower = 300
#   )

#need to clean PAR, temp_air, temp_soil

#put NA for when the soil temp sensor was not pluged in

slopes_exp_2021_flag <- slopes_exp_2021_flag %>% 
  mutate(
    temp_soil = case_when(
      comments == "soilT logger not plugged in" ~ NA_real_,
      comments == "Soil T NA" ~ NA_real_,
      TRUE ~ temp_soil
    )
  )


# str(slopes_exp_2021_flag)


#PAR: same + NA for soilR and ER

slopes_exp_2021_flag <- slopes_exp_2021_flag |>
  mutate(
    PAR =
      case_when(
        type == "ER" & PAR < 0 ~ 0,
        type == "LRC5" & PAR > 10 ~ NA_real_, # PAR sensor had faulty contact
        type == "LRC5" & PAR < 0 ~ 0, # when covering chamber after strong light, sensor can go negative but it is 0
        type == "ER" & PAR > 10 ~ NA_real_,
        type == "NEE" & PAR < 70 ~ NA_real_, # PAR sensor had faulty contact
        type == "SoilR" ~ NA_real_, # no PAR data collected when doing soil respiration, but sensor connected
        TRUE ~ PAR
      )
  )


# function to plot the PAR for each flux to visually check
plot_PAR <- function(slope_df, filter, filename, scale){
plot <- filter(slope_df, type == ((filter))) %>%
  ggplot(aes(x = date_time)) +
    geom_point(size = 0.2, aes(group = f_fluxid, y = PAR, color = f_cut)) +
    scale_x_datetime(date_breaks = "1 min", minor_breaks = "10 sec", date_labels = "%e/%m \n %H:%M") +
    do.call(facet_wrap_paginate,
      args = c(facets = ~f_fluxid, ncol = 5, nrow = 3, scales = ((scale)))
    ) +
    scale_color_manual(values = c(
      "cut" = "#D55E00",
      "keep" = "#009E73"
    ))

    pdf(((filename)), paper = "a4r", width = 11.7, height = 8.3)


 pb <- progress_bar$new(
      format =
        "Printing plots in pdf document [:bar] :current/:total (:percent)",
      total = n_pages(plot)
    )
    pb$tick(0)
    Sys.sleep(3)
    for (i in 1:n_pages(plot)) {
      pb$tick()
      Sys.sleep(0.1)
      print(plot +
        do.call(facet_wrap_paginate,
          args = c(
            facets = ~f_fluxid,
            page = i,
            ncol = 5, nrow = 3, scales = ((scale))
          )
        ))
    }
    quietly(dev.off())

}

# passing plots as comment to save time
# plot_PAR(slopes_exp_2021_flag, "NEE", "plot_NEE_PAR.pdf", "free")
# plot_PAR(slopes_exp_2021_flag, "ER", "plot_ER_PAR.pdf", "free")
# plot_PAR(slopes_exp_2021_flag, "LRC1", "plot_LRC1_PAR.pdf", "free")
# plot_PAR(slopes_exp_2021_flag, "LRC2", "plot_LRC2_PAR.pdf", "free")
# plot_PAR(slopes_exp_2021_flag, "LRC3", "plot_LRC3_PAR.pdf", "free")
# plot_PAR(slopes_exp_2021_flag, "LRC4", "plot_LRC4_PAR.pdf", "free")
# plot_PAR(slopes_exp_2021_flag, "LRC5", "plot_LRC5_PAR.pdf", "free")

# we need to include soil respiration chamber volume
slopes_2021 <- left_join(slopes_exp_2021_flag, soilR_chamber) |>
  mutate(
    chamber_vol = case_when(
      type == "SoilR" ~ soil_chamber_vol,
      type != "SoilR" ~ 24.5
    ),
    chamber_vol = chamber_vol + 0.075, # adding tube volume
    plot_area = case_when(
      type == "SoilR" ~ soil_chamber_area,
      type != "SoilR" ~ 0.0625
    )
  )

# str(slopes_2021)

fluxes2021 <- flux_calc(
  slopes_2021,
  f_slope_corr,
  date_time,
  temp_air,
  setup_volume = chamber_vol,
  atm_pressure = 1,
  plot_area = plot_area,
  conc_unit = "ppm",
  flux_unit = "mmol/m2/h",
  cols_keep = c(
    "turfID",
    "type",
    "flux_campaign",
    "comments",
    "f_quality_flag"
  ),
  cols_ave = c(
    "PAR",
    "temp_soil"
  )
)

fluxes2021 <- fluxes2021 |>
  mutate(
    PAR_ave = case_when(
      is.nan(PAR_ave) == TRUE ~ NA_real_, #mean(PAR_ave) returned NaN when PAR_ave was all NAs but it is missing values
      TRUE ~ as.numeric(PAR_ave)
    )
  )

# str(fluxes2021)


  
#replacing PAR Na by the average PAR of the 3h period in which the measurement is
roll_period <- 3

PAR_ave_ER <- filter(fluxes2021, type == "ER") %>%
  slide_period_dfr(
    .$date_time,
    "hour",
    .every = roll_period,
    ~data.frame(
      date_time = max(.x$date_time),
      PAR_ave_roll_ER = mean(.x$PAR_ave, na.rm = TRUE)
    )
  )

PAR_ave_NEE <- filter(fluxes2021, type == "NEE") %>%
  slide_period_dfr(
    .$date_time,
    "hour",
    .every = roll_period,
    ~data.frame(
      date_time = max(.x$date_time),
      PAR_ave_roll_NEE = mean(.x$PAR_ave, na.rm = TRUE)
    )
  )



fluxes2021 <- left_join(fluxes2021, PAR_ave_ER) %>% 
  left_join(PAR_ave_NEE) %>% 
  fill(PAR_ave_roll_NEE, .direction = "up") %>% 
  fill(PAR_ave_roll_ER, .direction = "up") %>% 
  mutate(
    comments = case_when(
      is.na(PAR_ave) == TRUE
      ~ case_when(
        is.na(comments) ~ "PAR 3h period average",
        !is.na(comments) ~ paste0(comments,  " /", " PAR 3h period average")
      ),
      TRUE ~ comments
    ),
    PAR_ave = case_when(
      is.na(PAR_ave) == TRUE
      & type == "ER"
      ~ PAR_ave_roll_ER,
      is.na(PAR_ave) == TRUE
      & type == "NEE"
      ~ PAR_ave_roll_NEE,
      TRUE ~ PAR_ave
    )

    
  ) %>% 
  select(!c(PAR_ave_roll_NEE, PAR_ave_roll_ER))
  

#replace soil temp Na with average of measurements in the same 3h period
# roll_period <- 3

soiltemp_ER <- filter(fluxes2021, type == "ER") %>%
  slide_period_dfr(
    # .,
    .$date_time,
    "hour",
    .every = roll_period,
    ~data.frame(
      date_time = max(.x$date_time),
      soiltemp_roll_ER = mean(.x$temp_soil_ave, na.rm = TRUE)
    )
  )

soiltemp_NEE <- filter(fluxes2021, type == "NEE") %>%
  slide_period_dfr(
    .$date_time,
    "hour",
    .every = roll_period,
    ~data.frame(
      date_time = max(.x$date_time),
      soiltemp_roll_NEE = mean(.x$temp_soil_ave, na.rm = TRUE)
    )
  )



fluxes2021 <- left_join(fluxes2021, soiltemp_ER) %>% 
  left_join(soiltemp_NEE) %>% 
  fill(soiltemp_roll_NEE, .direction = "up") %>% 
  fill(soiltemp_roll_ER, .direction = "up") %>% 
  mutate(
    comments = case_when(
      is.na(temp_soil_ave) == TRUE
      ~ case_when(
        is.na(comments) ~ "soil temp 3h period average",
        !is.na(comments) ~ paste0(comments,  " /", " soil temp 3h period average")
      ),
      TRUE ~ comments
    ),
    temp_soil_ave = case_when(
      is.na(temp_soil_ave) == TRUE
      & type == "ER"
      ~ soiltemp_roll_ER,
      is.na(temp_soil_ave) == TRUE
      & type == "NEE"
      ~ soiltemp_roll_NEE,
      TRUE ~ temp_soil_ave
    )

    
  ) %>% 
  select(!c(soiltemp_roll_NEE, soiltemp_roll_ER))


# for debugging only
# metaTurfID <- dataDocumentation::create_threed_meta_data() |> 
#       distinct()
#adding meta data
flux <- left_join(fluxes2021, metaTurfID, by = "turfID")

# correcting for PAR

flux <- flux |>
  mutate(
    type = case_when(
      type %in% c("LRC1", "LRC2", "LRC3", "LRC4", "LRC5") ~ "LRC",
      .default = type
    )
  )

flux_corrected_PAR <- flux |>
  flux_lrc(
    type,
    par_ave = PAR_ave,
    lrc_group = c("warming", "flux_campaign")
  )

# this part is to correct for soil temperature but it was not a good idea, not in the final dataset
# coefficients_soiltemp <- filter(flux_corrected_PAR, 
#                                 type == "ER" |
#                                   type == "NEE"
#                                 ) %>%
#   group_by(warming, flux_campaign) %>% 
#   nest %>% 
#   mutate(lm = map(data, ~ lm(f_flux ~ temp_soil_ave + I(temp_soil_ave^2), data = .x)),
#          table = map(lm, tidy),
#          table = map(table, select, term, estimate),
#          table = map(table, pivot_wider, names_from = term, values_from = estimate)
         
#   ) %>% 
#   unnest(table) %>% 
#   select(warming, `(Intercept)`, temp_soil_ave, `I(temp_soil_ave^2)`, flux_campaign) %>% 
#   rename(
#     origin2 = "(Intercept)",
#     c = "I(temp_soil_ave^2)",
#     d = "temp_soil_ave"
#   )

# soiltempfix <- 15
# flux_corrected <- flux_corrected_PAR %>% 
#   left_join(coefficients_soiltemp, by = c("warming", "flux_campaign")) %>% 
#   mutate(
#     corrected_flux =
#       f_flux + c * (soiltempfix^2 - temp_soil_ave^2) + d * (soiltempfix - temp_soil_ave),
      
#     delta_flux = f_flux - corrected_flux
#   ) %>% 
#   select(!c(origin2, c, d))




# flux_corrected %>% filter(type == "ER") %>% 
#   reframe(
#     rangeER = range(f_flux, na.rm = TRUE)
#   )

# now we can calculate GEP

# str(flux_corrected_PAR)
# View(flux_corrected_PAR)

fluxes2021 <- flux_corrected_PAR |>
  flux_gpp(
    type,
    date_time,
    f_flux,
    id_cols = c("turfID", "flux_campaign", "par_correction"),
    cols_keep = c(
      "temp_soil_ave",
      "comments",
      "f_quality_flag",
      "plot_area",
      "f_temp_air_ave",
      "chamber_vol",
      "origSiteID",
      "origBlockID",
      "warming",
      "grazing",
      "Nlevel",
      "origPlotID",
      "destSiteID",
      "destPlotID",
      "destBlockID",
      "Namount_kg_ha_y",
      "PAR_ave"
      )
  )


# str(fluxes2021)

# let's just plot it to check
fluxes2021 |>
  ggplot(aes(x = type, y = f_flux)) +
  geom_violin()



fluxes2021
}
