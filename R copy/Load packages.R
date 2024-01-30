#### LOAD PACKAGES ####

library("tidyverse")
library("lubridate")
library("stringi")
library("readxl")
library("writexl")
#devtools::install_github("Between-the-Fjords/dataDownloader")
library("dataDownloader")
library(validate)
library(usethis)
library(dataDocumentation)
library(janitor)


# Stuff
pn <- . %>% print(n = Inf)


# Colours
# The palette with grey:
cbPalette <- c("#999999", "#E69F00", "#56B4E9", "#009E73", "#F0E442", "#0072B2", "#D55E00", "#CC79A7")