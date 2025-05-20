# Created by use_targets().
# Follow the comments below to fill in this target script.
# Then follow the manual to check and run the pipeline:
#   https://books.ropensci.org/targets/walkthrough.html#inspect-the-pipeline # nolint

# Load packages required to define the pipeline:
library(targets)
library(tarchetypes)

# Set target options:
tar_option_set(
  packages = c(
    "dataDownloader",
    "dataDocumentation",
    "tidyverse",
    "readxl",
    "lubridate",
    "writexl",
    "tibble",
    "stringi",
    "janitor",
    "fluxible",
    "fs",
    "slider",
    "generics",
    "data.table", 
    "broom", 
    "glue", 
    "vegan", 
    "ggvegan", 
    "patchwork"
    ))

# tar_make_clustermq() configuration (okay to leave alone):
options(clustermq.scheduler = "multicore")

# tar_make_future() configuration (okay to leave alone):
# Install packages {{future}}, {{future.callr}}, and {{future.batchtools}} to allow use_targets() to configure tar_make_future() options.

# Run the R scripts in the R/ folder with your custom functions:
tar_source()
# source("other_functions.R") # Source other scripts as needed. # nolint

# Replace the target list below with your own:
#Combine target plans
combined_plan <- c(
  meta_plan,
  climate_plan,
  biomass_plan,
  productivity_plan,
  community_plan,
  reflectance_plan,
  root_plan,
  soil_plan,
  decomposition_plan,
  data_dic_plan,
  analysis_plan,
  figure_plan,
  cflux_plan
)
