# library(tidyverse)
# library("dataDownloader")


# Plant species composition -----------------------------------------------



# Measure Reflectance with Greenseeker ------------------------------------



# Aboveground biomass -----------------------------------------------------



# CN stocks, pH, soil organic matter --------------------------------------


# Ecosystem fluxes --------------------------------------------------------
get_file(node = "pk4bg",
         file = "Three-D_c-flux_2020.csv",
         path = "data/C-Flux/summer_2020",
         remote_path = "C-Flux")

flux <- read_csv("data/C-Flux/summer_2020/Three-D_c-flux_2020.csv")

flux.colnames <- flux %>% 
  colnames()

variables.cflux <- tibble(flux.colnames, "Variable type" = c(
  # Datetime
  # "date and time",
  paste(class(flux$Datetime), collapse = " "),
  # ID
  # "factor",
  class(flux$ID),
  # Turf_ID
  class(flux$Turf_ID),
  # "factor",
  # Type
  class(flux$Type),
  # "factor",
  # Replicate
  class(flux$Replicate),
  # "factor",
  # Remarks
  class(flux$Remarks),
  # "text",
  # Date
  class(flux$Date),
  # "date",
  # PARavg
  class(flux$PARavg),
  # "numeric",
  # Temp_airavg
  class(flux$Temp_airavg),
  # "numeric",
  # r.squared
  class(flux$r.squared),
  # "numeric",
  # p.value
  class(flux$p.value),
  # "numeric",
  # flux
  class(flux$flux),
  # "numeric",
  # Campaign
  class(flux$Campaign)
  # "factor"
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
  "Ex.: 158 WN2C 199", #I am not sure what it is
  # Type
  paste(levels(as.factor(flux$Type)), collapse = ", "),
  # Replicate
  paste(levels(as.factor(flux$Replicate)), collapse = ", "),
  # Remarks
  " ",
  # Date
  "AC",
  # PARavg
  "micromol s⁻¹ m⁻²",
  # Temp_airavg
  "Kelvin",
  # r.squared
  " ",
  # p.value
  " ",
  # flux
  "mmol m⁻² h⁻¹",
  # Campaign
  paste(levels(as.factor(flux$Campaign)), collapse = ", ")
)
) %>% 
  rename("Variable name" = flux.colnames)


# Soil pH measurement -----------------------------------------------------



# Soil organic matter -----------------------------------------------------



# Climate data ------------------------------------------------------------





#### 		