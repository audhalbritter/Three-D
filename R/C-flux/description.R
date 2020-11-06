library(tidyverse)
library("dataDownloader")

get_file(node = "pk4bg",
         file = "Three-D_c-flux_2020.csv",
         path = "data/C-Flux/summer_2020",
         remote_path = "C-Flux")

flux <- read_csv("Three-D_c-flux_2020.csv")

flux.colnames <- flux %>% 
  colnames()

variables <- tibble(flux.colnames, "Variable type" = c(
  # Datetime
  "date and time",
  # ID
  "factor",
  # Turf_ID
  "factor",
  # Type
  "factor",
  # Replicate
  "factor",
  # Remarks
  "text",
  # Date
  "date",
  # PARavg
  "numeric",
  # Temp_airavg
  "numeric",
  # r.squared
  "numeric",
  # p.value
  "numeric",
  # flux
  "numeric",
  # Campaign
  "factor"
),
"Variable range or levels" = c(
  # Datetime
  paste(range(flux$Datetime), collapse = " - "),
  # ID
  "[flux ID]",
  # Turf_ID
  "[origin plotID]x[treatment]x[destination plotID]",
  # Type
  "[type]",
  # Replicate
  "[replicate]",
  # Remarks
  "Field observations",
  # Date
  paste(range(flux$Date), collapse = " - "),
  # PARavg
  paste(range(flux$PARavg), collapse = " - "),
  # Temp_airavg
  paste(range(flux$Temp_airavg), collapse = " - "),
  # r.squared
  paste(range(flux$r.squared), collapse = " - "),
  # p.value
  paste(range(flux$p.value), collapse = " - "),
  # flux
  paste(range(flux$flux), collapse = " - "),
  # Campaign
  paste(range(flux$Campaign), collapse = " - ")
),
"How measured" = c(
  # Datetime
  "",
  # ID
  "defined",
  # Turf_ID
  "defined",
  # Type
  "defined",
  # Replicate
  "defined",
  # Remarks
  "",
  # Date
  "",
  # PARavg
  "PAR sensor inside the chamber",
  # Temp_airavg
  "Thermocouple inside the chamber",
  # r.squared
  "calculated with linear model",
  # p.value
  "calculated with linear model",
  # flux
  "calculated from concentration vs time",
  # Campaign
  ""
),
"Units/formats/treatment level coding" = c(
  # Datetime
  "AC CET",
  # ID
  paste(range(flux$ID), collapse = " - "),
  # Turf_ID
  "??", #I am not sure what it is
  # Type
  paste(levels(as.factor(flux$Type)), collapse = ", "),
  # Replicate
  paste(levels(as.factor(flux$Replicate)), collapse = ", "),
  # Remarks
  " ",
  # Date
  "AC",
  # PARavg
  "micromol s^{-1} m^{-2}",
  # Temp_airavg
  "Kelvin",
  # r.squared
  " ",
  # p.value
  " ",
  # flux
  "mmol m^{-2} h^{-1}",
  # Campaign
  paste(levels(as.factor(flux$Campaign)), collapse = ", ")
)
) %>% 
  rename("Variable name" = flux.colnames)
			
