# clean root productivity and traits

clean_roots <- function(root_productivity21_raw, decom_meta_raw, root_productivity22_raw, root_traits_raw, metaTurfID){
  
  # roots 2021
  clean_root_biomass21 <- root_productivity21_raw |> 
    # change site names
    mutate(origSiteID = case_when(origSiteID == "Joa" ~ "Joasete",
                                  origSiteID == "Lia" ~ "Liahovden",
                                  TRUE ~ origSiteID),
           destSiteID = case_when(destSiteID == "Joa" ~ "Joasete",
                                  destSiteID == "Lia" ~ "Liahovden",
                                  destSiteID == "Vik" ~ "Vikesland",
                                  TRUE ~ destSiteID)) |> 
    mutate(root_biomass_dry_g = total_mass_g - alutray_mass_g, 
           volume_cm3 = pi*(1.75)^2*RIC_length_cm) %>% # calculate volume
    left_join(metaTurfID) |> 
    mutate(recover_date_2021 = ymd(recover_date_2021),
           burial_date = ymd(burial_date),
           days_buried = recover_date_2021 - burial_date,
           root_biomass_g_cm3 = root_biomass_dry_g/volume_cm3, 
           root_productivity_g_cm3_d = root_biomass_g_cm3/as.numeric(as.character(days_buried)),
           year = 2021) |> 
    pivot_longer(cols = c(root_productivity_g_cm3_d, root_biomass_g_cm3),
                 names_to = "variable", values_to = "value") |> 
    select(year, origSiteID:turfID, Namount_kg_ha_y, burial_date, recover_date = recover_date_2021, days_buried, variable, value, volume_cm3)
  
  # roots 2022
  # get dates
  dates21 <- decom_meta_raw |> 
    mutate(ric_date_buried = if_else(site == "VIK", "2021.06.04", ric_date_buried),
           ric_date_buried = ymd(ric_date_buried),
           tb.spring22.dateretrieved = ymd(tb.spring22.dateretrieved)) |> 
    select(turfID = plotID, burial_date = ric_date_buried, recover_date = tb.spring22.dateretrieved)

  clean_root_biomass22 <- root_productivity22_raw |> 
    select(-c("ferdig scanna":"...16")) |> 
    # remove one observation with NA
    filter(Prove_ID != "158WN2C199") |> 
    clean_names() |> 
    separate(col = lokasjon, into = c("destSiteID", "destBlockID"), sep = "_") |> 
    mutate(destBlockID = as.numeric(destBlockID),
           origPlotID = as.numeric(sub("\\D*(\\d+).*", "\\1", prove_id)),
           provelengde_cm = as.numeric(provelengde_cm),
           volume_cm3 = pi*(1.75)^2*provelengde_cm,
           rotvekt_for_g = as.numeric(rotvekt_for_g),
           rotvekt_etter_g = as.numeric(rotvekt_etter_g)) |> 
    mutate(destSiteID = case_when(destSiteID == "Joa" ~ "Joasete",
                                  destSiteID == "Lia" ~ "Liahovden",
                                  destSiteID == "Vik" ~ "Vikesland",
                                  TRUE ~ destSiteID)) |> 
    left_join(metaTurfID, by = c("destSiteID", "destBlockID", "origPlotID")) |> 
    # add burial dates
    left_join(dates21, by = "turfID") |> 
    rename(root_biomass_wet_g = rotvekt_for_g,
           root_biomass_dry_g = rotvekt_etter_g) |> 
    mutate(days_buried = recover_date - burial_date,
           root_biomass_g_cm3 = root_biomass_dry_g/volume_cm3, 
           root_productivity_g_cm3_d = root_biomass_g_cm3/as.numeric(as.character(days_buried))) |> 
    select(origPlotID:origBlockID, destSiteID, destBlockID, warming:Namount_kg_ha_y, prove_id, burial_date, recover_date, days_buried, root_productivity_g_cm3_d, root_biomass_g_cm3, root_biomass_dry_g, root_biomass_wet_g, volume_cm3)
  
  
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
                                   TRUE ~ soil_vol_m3)) |> 
    mutate(destSiteID = case_when(destSiteID == "Joa" ~ "Joasete",
                                  destSiteID == "Lia" ~ "Liahovden",
                                  destSiteID == "Vik" ~ "Vikesland",
                                  TRUE ~ destSiteID))
  
  
  roots_clean <- clean_root_trait |> 
    left_join(clean_root_biomass22, by = c("destSiteID", "destBlockID", "origPlotID", "prove_id")) |> 
    mutate(specific_root_length = (length_cm/100)/root_biomass_dry_g, # in m per g
           root_tissue_density = root_biomass_dry_g/root_volume_cm3,
           # mg per g
           root_dry_matter_content = root_biomass_dry_g*1000/root_biomass_wet_g,
           year = 2022) |> 
    pivot_longer(cols = c(root_productivity_g_cm3_d, root_biomass_g_cm3, specific_root_length, root_tissue_density, root_dry_matter_content),
                          names_to = "variable", values_to = "value") |> 
             select(year, origSiteID, origBlockID, origPlotID, destSiteID, destBlockID, destPlotID, turfID, warming:Nlevel, Namount_kg_ha_y, sampleID = prove_id, days_buried, variable, value) |> 
    bind_rows(clean_root_biomass21)
  
}


# roots_clean |> 
#   filter(trait == "root_biomass_g_cm3") |> 
#   ggplot(aes(x = Namount_kg_ha_y, y = value, colour = warming, shape = grazing)) +
#   geom_point() +
#   facet_grid(origSiteID ~ year)
