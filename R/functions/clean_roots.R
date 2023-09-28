# clean root productivity and traits

clean_roots <- function(root_productivity_raw, root_traits_raw, metaTurfID){
  
  clean_root_biomass <- root_productivity_raw |> 
    select(-c("ferdig scanna":"...16")) |> 
    # remove one observation with NA
    filter(Prove_ID != "158WN2C199") |> 
    clean_names() |> 
    separate(col = lokasjon, into = c("destSiteID", "destBlockID"), sep = "_") |> 
    mutate(destBlockID = as.numeric(destBlockID),
           origPlotID = as.numeric(sub("\\D*(\\d+).*", "\\1", prove_id)),
           provelengde_cm = as.numeric(provelengde_cm),
           volum_cm3 = as.numeric(volum_cm3),
           volum_m3 = as.numeric(volum_m3),
           rotvekt_for_g = as.numeric(rotvekt_for_g),
           rotvekt_etter_g = as.numeric(rotvekt_etter_g)) |> 
    left_join(metaTurfID, by = c("destSiteID", "destBlockID", "origPlotID")) |> 
    rename(root_biomass_wet_g = rotvekt_for_g,
           root_biomass_dry_g = rotvekt_etter_g,
           core_length_cm = provelengde_cm) |> 
    mutate(root_productivity_g_cm3 = root_biomass_dry_g/volum_cm3)
  
  
  clean_root_trait <- root_traits_raw |> 
    slice(-c(1:4)) |> 
    select( "Sample_ID" = "RHIZO 2022a", "SoilVol(m3)", "Length(cm)", "ProjArea(cm2)",
            "SurfArea(cm2)", "AvgDiam(mm)", "RootVolume(cm3)") |> 
    clean_names() |> 
    filter(!row_number() %in% c(8, 9)) |>
    mutate(sample_id = if_else(sample_id == "Joa10_WN2I158", "Joa10_78WN2I158", sample_id)) |> 
    separate(col = sample_id, into = c("destSiteBlockID", "prove_id"), sep = "_") |> 
    separate(destSiteBlockID, c("destSiteID", "destBlockID"), 3) |> 
    mutate(origPlotID = as.numeric(sub("\\D*(\\d+).*", "\\1", prove_id)),
           destBlockID = as.numeric(destBlockID),
           soil_vol_m3 = as.numeric(soil_vol_m3),
           length_cm = as.numeric(length_cm),
           root_volume_cm3 = as.numeric(root_volume_cm3),
           avg_diam_mm = as.numeric(avg_diam_mm)) |> 
    mutate(soil_vol_m3 = case_when(origPlotID == 45 ~ 0.000093,
                                   origPlotID == 28 ~ 0.000101,
                                   TRUE ~ soil_vol_m3))
  
  
  roots_clean <- clean_root_trait |> 
    left_join(clean_root_biomass, by = c("destSiteID", "destBlockID", "origPlotID", "prove_id")) |> 
    mutate(specific_root_length = length_cm/root_biomass_dry_g,
           root_tissue_density = root_biomass_dry_g/root_volume_cm3,
           # mg per g
           root_dry_matter_content = root_biomass_dry_g*1000/root_biomass_wet_g,
           year = 2022) |> 
    pivot_longer(cols = c(root_productivity_g_cm3, specific_root_length, root_tissue_density, root_dry_matter_content),
                          names_to = "trait", values_to = "value") |> 
             select(year, origSiteID, origBlockID, origPlotID, destSiteID, destBlockID, destPlotID, turfID, warming:Nlevel, Namount_kg_ha_y, sampleID = prove_id, trait, value)
  
  
}