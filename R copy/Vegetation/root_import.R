library(tidyverse)
library(readxl)
library(tidyr)
library(janitor)

source("R_script/create_meta_data.R")
root_biomass_raw <- read_excel(path ="data/root_biomasse.xlsx", skip = 1)
root_trait_raw <- read_delim(file = "data/root_traits.txt")


clean_root_biomass <- root_biomass_raw |> 
  select(-c("...8":"...16")) |> 
  separate(col = Lokasjon, into = c("destSiteID", "destBlockID"), sep = "_") |> 
  mutate(destBlockID = as.numeric(destBlockID),
         origPlotID = as.numeric(sub("\\D*(\\d+).*", "\\1", Prove_ID))) |> 
  left_join(metaTurfID, by = c("destSiteID", "destBlockID", "origPlotID")) |> 
  left_join(NitrogenDictionary, by = "Nlevel") |> 
  mutate(biomass_per_soil_volume = as.numeric(Rotvekt_etter_g/Volum_cm3),
         Rotvekt_etter_mg = as.numeric(Rotvekt_etter_g*1000))


clean_root_trait <- root_trait_raw |> 
  slice(-c(1:4)) |> 
  select( "Sample_ID" = "RHIZO 2022a", "SoilVol(m3)", "Length(cm)", "ProjArea(cm2)",
         "SurfArea(cm2)", "AvgDiam(mm)", "RootVolume(cm3)") |> 
  clean_names() |> 
  filter(!row_number() %in% c(8, 9)) |>
  mutate(sample_id = if_else(sample_id == "Joa10_WN2I158", "Joa10_78WN2I158", sample_id)) |> 
  separate(col = sample_id, into = c("destSiteBlockID", "Prove_ID"), sep = "_") |> 
  separate(destSiteBlockID, c("destSiteID", "destBlockID"), 3) |> 
  mutate(origPlotID = as.numeric(sub("\\D*(\\d+).*", "\\1", Prove_ID)),
         destBlockID = as.numeric(destBlockID),
         soil_vol_m3 = as.numeric(soil_vol_m3),
         length_cm = as.numeric(length_cm),
         root_volume_cm3 = as.numeric(root_volume_cm3),
         avg_diam_mm = as.numeric(avg_diam_mm)) |> 
  mutate(soil_vol_m3 = case_when(origPlotID == 45 ~ 0.000093,
                                   origPlotID == 28 ~ 0.000101,
                                   TRUE ~ soil_vol_m3))

all_root_data <- clean_root_trait |> 
  left_join(clean_root_biomass, by = c("destSiteID", "destBlockID", "origPlotID", "Prove_ID")) |> 
  mutate(SRL = as.numeric(length_cm/Rotvekt_etter_g),
         RTD = as.numeric(Rotvekt_etter_g/root_volume_cm3),
         RDMC = as.numeric(Rotvekt_etter_mg/Rotvekt_for_g),
         grazing = recode(grazing, "C" = "Control", "I" = "Intensive", "M" = "Medium", "N" = "Natural"),
         grazing = factor(grazing, levels = c("Control", "Medium", "Intensive", "Natural"))
         )
