# clean soil

clean_soil <- function(soil_raw){

  # diameter of soil corer was 5 cm
  soil_core_diameter <- 5
  # stone desnsity is assumed 2.65 g cm^3^
  stone_density <-  2.65
  
  soil_clean <- soil_raw %>% 
    mutate(year = year(date)) %>% 
    # calculate soil core volume, stone volume and bulk density
    mutate(core_volume = height_soil_core_cm * (soil_core_diameter/2)^2 * pi,
           stone_volume = stone_weight_g * stone_density,
           bulk_density_g_cm = (dry_weight_soil_g - stone_weight_g) / (core_volume - stone_volume),
           # remove unrealistic samples with very high stone weight
           bulk_density_g_cm = if_else(bulk_density_g_cm > 1.8 | bulk_density_g_cm < 0, NA_real_, bulk_density_g_cm)) %>% 
    # calculate soil organic matter
    mutate(pore_water_content = (wet_weight_soil_g - dry_weight_soil_g) / wet_weight_soil_g,
           weight_550_g = dry_weight_550_plus_vial_g - vial_weight_g,
           weight_950_g = dry_weight_950_plus_vial_g - vial_weight_g,
           soil_organic_matter = (dry_weight_105_g - weight_550_g) / dry_weight_105_g,
           carbon_content = (weight_550_g - weight_950_g) / dry_weight_105_g) |> 
    mutate(destBlockID = as.numeric(destBlockID)) |> 
    select(year, date, destSiteID, destBlockID, layer, sand_percent, silt_percent, clay_percent, pH, bulk_density_g_cm, soil_organic_matter, carbon_content, pore_water_content)
  
}


clean_soil_nutrients <- function(cn19_20_raw, cn22_raw, cn22_meta_raw, metaTurfID, prs_raw, prs_meta_raw){
  
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
    select(year, destSiteID, destBlockID, sample_ID, layer, N_percent, C_percent, CN_ratio)
  
  
  cn19 <- cn19_20 |> 
    filter(year == 2019) |> 
    mutate(destBlockID = as.numeric(destBlockID)) |> 
    left_join(metaTurfID) |> 
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
    left_join(metaTurfID, by = c("destSiteID", "destBlockID", "turfID")) |> 
    mutate(destBlockID = as.character(destBlockID))
  
  cn <- bind_rows(cn19, cn20, cn22) |> 
    pivot_longer(cols = c(N_percent, C_percent, CN_ratio),
                 names_to = "nutrient", values_to = "value")
  
  # prs data
  # read in data
  prs_raw <- prs_raw %>% 
    filter(`WAL #` != "Method Detection Limits (mdl):") %>% 
    rename(ID = `Sample ID`)
  
  # detection limits for the elements
  detection_limit <- prs_raw %>% 
    slice(1) %>% 
    select(`NO3-N`:Cd) %>% 
    pivot_longer(cols = everything(), names_to = "nutrient", values_to = "detection_limit")
  
  # sample IDs and meta data
  meta <- prs_meta_raw %>% 
    filter(turfID != "blank")
  
  prs_data <- metaTurfID %>% 
    inner_join(meta, by = c("destSiteID", "destBlockID", "turfID")) %>% 
    left_join(prs_raw, by = "ID") %>% 
    select(origSiteID:turfID, Namount_kg_ha_y, burial_date = `Burial Date`, retrieval_date = `Retrieval Date`, `NO3-N`:Cd, Notes) %>% 
    mutate(burial_date = ymd(burial_date),
           retrieval_date = ymd(retrieval_date),
           burial_length = retrieval_date - burial_date) %>% 
    pivot_longer(cols = `NO3-N`:Cd, names_to = "nutrient", values_to = "value") %>% 
    left_join(detection_limit, by = "nutrient") %>% 
    # remove values below detection limit
    filter(value > detection_limit) %>% 
    select(origSiteID:turfID, Namount_kg_ha_y, burial_length, nutrient, value, detection_limit, burial_date, retrieval_date, Notes) |> 
    mutate(destBlockID = as.character(destBlockID))
  
  nutrient_data <- bind_rows(cn, prs_data)
  
}