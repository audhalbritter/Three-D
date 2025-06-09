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
    # end = start + measurement, #creating column End
    # start_window = start + startcrop, #cropping the start
    # end_window = end - endcrop #cropping the end of the measurement
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

slopes_exp_2021_flag |>
filter(
  f_fluxid %in% c(198, 19, 402, 562, 985, 91, 407, 403, 409, 570)
) |>
flux_plot(
  CO2,
  date_time,
  print_plot = "FALSE",
  output = "pdfpages",
  f_plotname = "plot_2021_check",
  f_ylim_lower = 300
  )

# flux_plot is time consuming so we keep it as comments to avoid running accidentally
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



plot_PAR <- function(slope_df, filter, filename, scale){
plot <- filter(slope_df, type == ((filter))) %>%
  ggplot(aes(x = date_time)) +
    geom_point(size = 0.2, aes(group = f_fluxID, y = PAR, color = f_cut)) +
    scale_x_date_time(date_breaks = "1 min", minor_breaks = "10 sec", date_labels = "%e/%m \n %H:%M") +
    do.call(facet_wrap_paginate,
      args = c(facets = ~f_fluxID, ncol = 5, nrow = 3, scales = ((scale)))
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
            facets = ~f_fluxID,
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
  flux_unit = "mmol",
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
    # .,
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
    # .,
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
      # & type == ("ER" | "NEE")
      ~ case_when(
        is.na(comments) ~ "PAR 3h period average",
        !is.na(comments) ~ paste0(comments,  " /", " PAR 3h period average")
      ),
      TRUE ~ comments
    ),
    # comments = str_replace_all(comments, "NA / ", ""),
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
    # .,
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
      # & type != "SoilR"
      # & type == ("ER" | "NEE")
      ~ case_when(
        is.na(comments) ~ "soil temp 3h period average",
        !is.na(comments) ~ paste0(comments,  " /", " soil temp 3h period average")
      ),
      TRUE ~ comments
    ),
    # comments = str_replace_all(comments, "NA / ", ""),
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

# let's compare

# old_fluxes2021 <- read_csv("data_cleaned/c-flux/Three-D_c-flux_2021_cleaned_old.csv") |>
#   mutate(
#     flux_campaign = as_factor(flux_campaign)
#   )

# old_fluxes2021 <- old_fluxes2021 |>
#   rename(
#     old_flux = "flux",
#     old_PAR = "PARavg",
#     old_tempair = "temp_airavg"
#   )

# str(old_fluxes2021)

# all_fluxes <- full_join(
#   fluxes2021,
#   old_fluxes2021,
#   by = c( # we do not use date_time because the cut might be different
#     "turfID",
#     "type",
#     "flux_campaign"
#     )
# )

# str(all_fluxes)

# ggplot(all_fluxes, aes(old_flux, flux, label = f_fluxID)) +
# geom_point() +
# geom_text() +
# geom_abline(slope = 1)


# str(fluxes2021)

# write_csv(fluxes2021, "data_cleaned/c-flux/Three-D_c-flux_2021_cleaned.csv")

# flux <- read_csv("data_cleaned/c-flux/Three-D_c-flux_2021_cleaned.csv")


#adding meta data
flux <- left_join(fluxes2021, metaTurfID, by = "turfID")

#LRC
lrc_flux <- flux %>% 
  filter(
    type == "LRC1"
    | type == "LRC2"
    | type == "LRC3" 
    | type == "LRC4" 
    | type == "LRC5"
    )

#plot each light response curves
# ggplot(lrc_flux, aes(x = PAR, y = flux, color = turfID)) +
#   geom_point(size = 0.1) +
#   facet_wrap(vars(flux_campaign)) +
#   # geom_smooth(method = "lm", se = FALSE)
#   geom_smooth(method = "lm", formula = y ~ poly(x, 2), se = FALSE)

#grouping per treatment instead of turf
# lrc_flux %>% mutate(
#   warming = str_replace_all(warming, c(
#     "W" = "Transplant",
#     "A" = "Ambient"
#   ))) %>% 
# ggplot(aes(x = PAR, y = flux, color = warming)) +
#   geom_point(size = 0.1) +
#   facet_wrap(vars(flux_campaign)) +
#   # geom_smooth(method = "lm", se = FALSE)
#   geom_smooth(method = "lm", formula = y ~ poly(x, 2), se = FALSE) +
#   labs(
#     title = "Light response curves (Three-D, 2021)",
#     # caption = bquote(~CO[2]~'Flux standardized at PAR = 300 mol/'*m^2*'/s for NEE and PAR = 0 mol/'*m^2*'/s for ER, and soil temperature = 15 °C'),
#     color = "Warming",
#     x = bquote("PAR [mol/"*m^2*"/s]"),
#     y = bquote(~CO[2]~'flux [mmol/'*m^2*'/h]')
#   ) +
#   scale_fill_manual(values = c(
#     "Ambient" = "#1e90ff",
#     "Transplant" = "#ff0800"
#   ))
#   ggsave("lrc.png", height = 10, width = 13, units = "cm")

# ggplot(lrc_flux, aes(x = PAR, y = flux, color = warming)) +
#   geom_point(size = 0.1) +
#   # facet_wrap(vars(flux_campaign)) +
#   # geom_smooth(method = "lm", se = FALSE)
#   geom_smooth(method = "lm", formula = y ~ poly(x, 2), se = FALSE)

#extract the equation and correct all the NEE fluxes for PAR = 300 micromol/s/m2

coefficients_lrc <- lrc_flux %>%
  group_by(warming, flux_campaign) %>% 
  nest %>% 
  mutate(lm = map(data, ~ lm(f_flux ~ PAR_ave + I(PAR_ave^2), data = .x)),
         table = map(lm, tidy),
         table = map(table, select, term, estimate),
         table = map(table, pivot_wider, names_from = term, values_from = estimate)
         
  ) %>% 
  unnest(table) %>% 
  select(warming, `(Intercept)`, PAR_ave, `I(PAR_ave^2)`, flux_campaign) %>% 
  rename(
    origin = "(Intercept)",
    a = "I(PAR_ave^2)",
    b = "PAR_ave"
  )


#origini is calculated with coefficients from the model and flux and PAR value of specific flux

PARfix <- 300 #PAR value at which we want the corrected flux to be for NEE
PARnull <- 0 #PAR value for ER

flux_corrected_PAR <- flux %>% 
  left_join(coefficients_lrc, by = c("warming", "flux_campaign")) %>% 
  mutate(
    PAR_corrected_flux = 
      case_when( #we correct only the NEE
        type == "NEE" ~ f_flux + a * (PARfix^2 - PAR_ave^2) + b * (PARfix - PAR_ave),
        type == "ER" ~ f_flux + a * (PARnull^2 - PAR_ave^2) + b * (PARnull - PAR_ave),
        type %in% c(
          "SoilR",
          "LRC1",
          "LRC2",
          "LRC3",
          "LRC4",
          "LRC5"
        ) ~ f_flux
      )
    # delta_flux = flux - corrected_flux
  )# %>% 
  # filter( #removing LRC now that we used them
  #   type == "NEE"
  #   | type == "ER"
  # )

#we can do the same for soil temperature
#let's have a look
# filter(flux_corrected_PAR,
#        type == "ER" |
#          type == "NEE") %>% 
# ggplot(aes(x = temp_soil, y = PAR_corrected_flux
#                            , color = type
#                            )) +
#   geom_point() +
#   geom_smooth(method = "lm", formula = y ~ poly(x, 2), se = FALSE) +
#   facet_wrap(vars(flux_campaign))

# filter(flux_corrected_PAR,
#        type == "ER" |
#          type == "NEE") %>%
#   ggplot(aes(x = temp_soil, y = PAR_corrected_flux
#              # , color = type
#              )) +
#   geom_point() +
#   geom_smooth(method = "lm", formula = y ~ poly(x, 2), se = FALSE, fullrange = TRUE) +
#   facet_grid(vars(warming), vars(flux_campaign))

coefficients_soiltemp <- filter(flux_corrected_PAR, 
                                type == "ER" |
                                  type == "NEE"
                                ) %>%
  group_by(warming, flux_campaign) %>% 
  nest %>% 
  mutate(lm = map(data, ~ lm(PAR_corrected_flux ~ temp_soil_ave + I(temp_soil_ave^2), data = .x)),
         table = map(lm, tidy),
         table = map(table, select, term, estimate),
         table = map(table, pivot_wider, names_from = term, values_from = estimate)
         
  ) %>% 
  unnest(table) %>% 
  select(warming, `(Intercept)`, temp_soil_ave, `I(temp_soil_ave^2)`, flux_campaign) %>% 
  rename(
    origin2 = "(Intercept)",
    c = "I(temp_soil_ave^2)",
    d = "temp_soil_ave"
  )

soiltempfix <- 15
flux_corrected <- flux_corrected_PAR %>% 
  left_join(coefficients_soiltemp, by = c("warming", "flux_campaign")) %>% 
  mutate(
    corrected_flux =
      PAR_corrected_flux + c * (soiltempfix^2 - temp_soil_ave^2) + d * (soiltempfix - temp_soil_ave),
      
    delta_flux = f_flux - corrected_flux
  ) %>% 
  select(!c(origin, a, b, origin2, c, d))

#visualize the difference between corrected and not corrected
# flux_corrected %>% 
#   filter( #removing LRC now that we used them
#     type == "NEE"
#     | type == "ER"
#   ) %>% 
# ggplot(aes(x = PARavg, y = delta_flux, color = warming)) +
#   geom_point() +
#   # geom_line() +
#   facet_grid(vars(flux_campaign), vars(type), scales = "free")

# flux_corrected %>% 
#   # filter( #removing LRC now that we used them
#   #   type == "NEE"
#   #   | type == "ER"
#   # ) %>% 
#   ggplot() +
#   geom_point(aes(x = PARavg, y = flux, color = warming)) +
#   geom_smooth(method = "lm", formula = y ~ poly(x, 2), se = FALSE, aes(x = PARavg, y = corrected_flux, color = warming))
  # geom_line() +
  # facet_grid(vars(flux_campaign), vars(type), scales = "free")
# flux_corrected %>% 
#   filter( #removing LRC now that we used them
#         type == "NEE"
#         | type == "ER"
#       ) %>%
#   ggplot(aes(x = flux, y = corrected_flux, color = warming)) +
#   geom_point() +
#   geom_smooth(method = "lm", formula = y ~ poly(x, 2), se = FALSE) +
#   facet_grid(vars(type), vars(flux_campaign))

# flux_corrected_PAR %>% 
#   filter( #removing LRC now that we used them
#         type == "NEE"
#         | type == "ER"
#       ) %>%
#   ggplot(aes(x = flux, y = PAR_corrected_flux, color = warming)) +
#   geom_point() +
#   geom_smooth(method = "lm", formula = y ~ poly(x, 2), se = FALSE) +
#   facet_grid(vars(type), vars(flux_campaign))

# write_csv(flux_corrected, "data_cleaned/c-flux/Three-D_c-flux_2021.csv")


flux_corrected %>% filter(type == "ER") %>% 
  reframe(
    rangeER = range(PAR_corrected_flux, na.rm = TRUE)
  )

# now we can calculate GEP

# str(flux_corrected_PAR)
# View(flux_corrected_PAR)

fluxes2021_par_corr <- flux_corrected_PAR |>
  # select(!flux) |> # we need to remove the flux col because there is a flux col created by flux_gpp
  flux_gpp(
    type,
    date_time,
    PAR_corrected_flux,
    id_cols = c("turfID", "flux_campaign"),
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

fluxes2021_par_nocorr <- flux_corrected_PAR |>
  # select(!flux) |> # we need to remove the flux col because there is a flux col created by flux_gpp
  flux_gpp(
    type,
    date_time,
    f_flux,
    id_cols = c("turfID", "flux_campaign"),
    cols_keep = c(
      "temp_soil_ave",
      "comments",
      "f_quality_flag",
      "plot_area",
      "f_temp_air_ave",
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

fluxes2021 <- left_join(fluxes2021_par_corr, fluxes2021_par_nocorr)

# str(fluxes2021)

# let's just plot it to check
fluxes2021 |>
  ggplot(aes(x = type, y = f_flux)) +
  geom_violin()

# fluxes2021 <- fluxes2021 |>
#   rename(
#     date_time = "date_time"
#   )

fluxes2021
}
