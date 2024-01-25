# clean soil

clean_soil <- function(soil_raw){

  # diameter of soil corer was 5 cm
  soil_core_diameter <- 5
  # stone density is assumed 2.65 g cm^3^
  stone_density <-  2.65
  
  soil_clean <- soil_raw %>% 
    mutate(year = year(date)) %>% 
    # calculate soil core volume, stone volume and bulk density
    mutate(core_volume = height_soil_core_cm * (soil_core_diameter/2)^2 * pi,
           stone_volume = stone_weight_g * stone_density,
           bulk_density_g_cm = (dry_weight_soil_g - stone_weight_g) / (core_volume - stone_volume)) |> 
           # remove unrealistic samples with very high stone weight
    mutate(bulk_density_g_cm = if_else(bulk_density_g_cm > 1.8 | bulk_density_g_cm < 0, NA_real_, bulk_density_g_cm)) %>% 
    # calculate soil organic matter
    mutate(pore_water_content = (wet_weight_soil_g - dry_weight_soil_g) / wet_weight_soil_g,
           weight_550_g = dry_weight_550_plus_vial_g - vial_weight_g,
           weight_950_g = dry_weight_950_plus_vial_g - vial_weight_g,
           soil_organic_matter = (dry_weight_105_g - weight_550_g) / dry_weight_105_g,
           carbon_content = (weight_550_g - weight_950_g) / dry_weight_105_g) |> 
    select(year, date, destSiteID, destBlockID, layer, sand_percent, silt_percent, clay_percent, pH, bulk_density_g_cm, soil_organic_matter, carbon_content, pore_water_content) |> 
    # change site names
    mutate(destSiteID = case_when(destSiteID == "Joa" ~ "Joasete",
                                  destSiteID == "Lia" ~ "Liahovden",
                                  destSiteID == "Vik" ~ "Vikesland",
                                  TRUE ~ destSiteID)) |> 
    pivot_longer(cols = c(sand_percent:pore_water_content), names_to = "variable", values_to = "value") |> 
    filter(!is.na(value))
  
}


clean_soil_nutrients <- function(cn19_20_raw, cn22_raw, cn22_meta_raw, metaTurfID, som21_raw, soil_clean, prs_raw, prs_meta_raw){
  
  # 2019 data
  cn19_20 <- cn19_20_raw %>% 
    select(-c("...16", "...17", "Memo", "...19", "Humidity", "C/N ratio")) %>% 
    rename(input_weight_g = Weight,
           sample_ID = Name,
           N_area = `N-area`,
           C_area = `C-area`,
           N_percent = `N%`,
           C_percent = `C%`,
           N_factor = `N factor`,
           C_factor = `C factor`,
           date = Date) %>% 
    mutate(CN_ratio = C_percent / N_percent) |> 
    select(year, destSiteID, destBlockID, sample_ID, layer, N_percent, C_percent, CN_ratio) |> 
    # change site names
    mutate(destSiteID = case_when(destSiteID == "Joa" ~ "Joasete",
                                  destSiteID == "Lia" ~ "Liahovden",
                                  destSiteID == "Vik" ~ "Vikesland",
                                  TRUE ~ destSiteID))
  
  
  cn19 <- cn19_20 |> 
    filter(year == 2019) |> 
    mutate(destBlockID = as.numeric(destBlockID)) |> 
    left_join(metaTurfID |> 
                distinct(destSiteID, destBlockID, Nlevel, Namount_kg_ha_y), 
              by = c("destSiteID", "destBlockID")) |> 
    select(year, destSiteID, destBlockID, Nlevel, Namount_kg_ha_y, sample_ID, N_percent:CN_ratio) |> 
    mutate(destBlockID = as.character(destBlockID))
  
  cn20 <- cn19_20 |> 
    filter(year == 2020)
  
  # 2022 data
  cn22 <- cn22_meta_raw |> 
    mutate(turfID = if_else(turfID == "159 WN2C 199", "158 WN2C 199", turfID)) |> 
    # join data
    left_join(cn22_raw |> 
                # remove test data
                filter(!Name %in% c("RunIn", "Test", "Blank", "acetanilid")) |> 
                mutate(Name = as.numeric(Name)), 
              by = c("Eppendorf_ID" = "Name")) |> 
    select(sample_ID = Eppendorf_ID, destSiteID = Site, destBlockID = Block, turfID, N_percent = `N%`, C_percent = `C%`, CN_ratio = `C/N ratio`) |> 
    mutate(destBlockID = as.numeric(str_remove(destBlockID, "B"))) |> 
    # change site names
    mutate(destSiteID = case_when(destSiteID == "Joa" ~ "Joasete",
                                  destSiteID == "Lia" ~ "Liahovden",
                                  destSiteID == "Vik" ~ "Vikesland",
                                  TRUE ~ destSiteID)) |> 
    left_join(metaTurfID, by = c("destSiteID", "destBlockID", "turfID")) |> 
    mutate(destBlockID = as.character(destBlockID),
           year = 2022)
  
  cn <- bind_rows(cn19, cn20, cn22) |> 
    pivot_longer(cols = c(N_percent, C_percent, CN_ratio),
                 names_to = "variable", values_to = "value")
  
  # som 2021 data
  som <- som21_raw |> 
    # removing unwanted columns and fixing weird ones 
    select(-c(turfID, ...14, ...15, ...16, ...17, ...18)) %>%
    mutate(alutray_ID = str_replace(alutray_ID, "  ", " ")) %>% 
    mutate(burn_mass1 = if_else(
      alutray_ID == "Vik W B5 I" & burn_mass1 == 11.5771, 12.5771, burn_mass1)) %>% 
    separate(col = alutray_ID, # separate column into several
             into = c("destSiteID", "warming", "destBlockID", "grazing"), " ") %>% 
    mutate(destBlockID = as.numeric(str_remove(destBlockID, "B"))) %>% 
    # change site names
    mutate(destSiteID = case_when(destSiteID == "Joa" ~ "Joasete",
                                  destSiteID == "Lia" ~ "Liahovden",
                                  destSiteID == "Vik" ~ "Vikesland",
                                  TRUE ~ destSiteID)) |> 
    left_join(metaTurfID) |> 
    filter(!is.na(destSiteID)) %>% # remove empty row
    
    # change column names to informative names
    rename(alutray_mass = alutray_weight, # new name = old name
           wetmass = wet_mass_g,
           drymass_1_55 = dry_mass1, 
           drymass_2_sieved = dry_mass2, 
           drymass_3_sieved_105 = dry_mass3, 
           drymass_4_87 = dry_mass4, 
           porcelain_mass = porcelain_weight,
           burnmass_1_550 = burn_mass1, 
           burnmass_2_950 = burn_mass2,
           root_stone_mass = total_cf_mass) %>%
    # removing container weight from mass weights 
    mutate(drymass_4_87 = drymass_4_87 - porcelain_mass,
           burnmass_1_550 = burnmass_1_550 - porcelain_mass,
           burnmass_2_950 = burnmass_2_950 - porcelain_mass) %>% 
    # removing 2 impossible values i.e. typos from dataset 
    tidylog::filter(!drymass_4_87 < burnmass_1_550) |> 
    tidylog::filter(!burnmass_1_550 < burnmass_2_950) |>
    mutate(prop_sample_left = burnmass_1_550 / drymass_4_87) %>% 
    mutate(value = 1 - prop_sample_left,
           variable = "soil_organic_matter",
           year = 2021) |> 
    select(year, origSiteID, origBlockID, origPlotID, turfID, destPlotID, destBlockID, destSiteID, warming, grazing, Nlevel, Namount_kg_ha_y, variable, value) |> 
    mutate(destBlockID = as.character(destBlockID)) |>
    bind_rows(soil_clean |> 
                filter(variable %in% c("soil_organic_matter", "carbon_content")))
  

  
  # prs data
  # read in data
  prs_raw <- prs_raw %>% 
    filter(`WAL #` != "Method Detection Limits (mdl):") %>% 
    rename(ID = `Sample ID`)
  
  # detection limits for the elements
  detection_limit <- prs_raw %>% 
    slice(1) %>% 
    select(`NO3-N`:Cd) %>% 
    pivot_longer(cols = everything(), names_to = "variable", values_to = "detection_limit")
  
  # sample IDs and meta data
  meta <- prs_meta_raw %>% 
    filter(turfID != "blank") |> 
    # change site names
    mutate(destSiteID = case_when(destSiteID == "Joa" ~ "Joasete",
                                  destSiteID == "Lia" ~ "Liahovden",
                                  destSiteID == "Vik" ~ "Vikesland",
                                  TRUE ~ destSiteID))
  
  prs_data <- metaTurfID %>% 
    inner_join(meta, by = c("destSiteID", "destBlockID", "turfID")) %>% 
    left_join(prs_raw, by = "ID") %>% 
    select(origSiteID:turfID, Namount_kg_ha_y, burial_date = `Burial Date`, retrieval_date = `Retrieval Date`, `NO3-N`:Cd, Notes) %>% 
    mutate(burial_date = ymd(burial_date),
           retrieval_date = ymd(retrieval_date),
           duration = retrieval_date - burial_date) %>% 
    pivot_longer(cols = `NO3-N`:Cd, names_to = "variable", values_to = "value") %>% 
    left_join(detection_limit, by = "variable") %>% 
    # remove values below detection limit
    filter(value > detection_limit) %>% 
    select(origSiteID:turfID, Namount_kg_ha_y, duration, variable, value, detection_limit, burial_date, retrieval_date, Notes) |> 
    mutate(destBlockID = as.character(destBlockID),
           year = 2021)
  
  nutrient_data <- bind_rows(cn, som, prs_data)
  
}