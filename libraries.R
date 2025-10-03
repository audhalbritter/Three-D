# Load all required libraries for the Three-D project
# This file loads all packages used in the targets pipeline

# Core targets packages
library(targets)
library(tarchetypes)

# Data manipulation and analysis packages
library(tidyverse)
library(readxl)
library(writexl)
library(tibble)
library(data.table)
library(janitor)
library(stringi)
library(broom)
library(glue)

# Date and time handling
library(lubridate)

# File system and data management
library(fs)
library(dataDownloader)
library(dataDocumentation)

# Ecological analysis packages
library(vegan)
library(ggvegan)

# Visualization packages
library(patchwork)
library(scales)

# Specialized packages
library(fluxible)
library(slider)
library(generics)
