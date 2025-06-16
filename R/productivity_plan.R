# productivity plan

productivity_plan <- list(
  
  # download productivity
  tar_target(
    name = productivity_download,
    command = get_file(node = "pk4bg",
                       file = "4_Three-D_raw_productivity_2022-09-27.xlsx",
                       path = "data",
                       remote_path = "RawData"),
    format = "file"
  ),
  
  # import
  tar_target(
    name = productivity_raw,
    # warmings because there are NAs in date_in
    command = read_excel(productivity_download, col_types = c("date", "date", "text", "text", "numeric", "numeric", "numeric", "text", "text"))
  ),
  
  # import and clean data
  tar_target(
    name = productivity_clean,
    command = clean_productivity(productivity_raw)
  ),
  
  # save data
  tar_target(
    name = productivity_out,
    command =  save_csv(productivity_clean,
                        nr = "4_",
                        name = "productivity_2022")
  ),

  # Productivity and environmental data from master thesis

  # download productivity2
  tar_target(
    name = productivity2_download,
    command = get_file(node = "pk4bg",
                       file = "4_Three-D_raw_productivity_fg_sp_abiotic_2019.xlsx",
                       path = "data",
                       remote_path = "RawData"),
    format = "file"
  ),
  
  # import
  tar_target(
    name = productivity_fg2_raw,
    # warmings because there are NAs in date_in
    command = read_excel(path = productivity2_download, sheet = "productivity")
  ),

  tar_target(
    name = productivity_sp_raw,
    # warmings because there are NAs in date_in
    command = read_excel(path = productivity2_download, sheet = "productivtiy_sp")
  ),

  tar_target(
    name = ph_raw,
    # warmings because there are NAs in date_in
    command = read_excel(path = productivity2_download, sheet = "pH")
  ),

  tar_target(
    name = soilmoisture_raw,
    # warmings because there are NAs in date_in
    command = read_excel(path = productivity2_download, sheet = "soil moisture")
  ),
  
  # import and clean data
  tar_target(
    name = productivity_fg_clean,
    command = {

    prod <- productivity_fg2_raw |> 
      janitor::clean_names() |> 
      # join pH data
      tidylog::left_join(ph_raw |> 
        janitor::clean_names() |> 
        select(-x3), by = "plot_id") |> 
      mutate(date = dmy(date),
      # distinguish permanent and movable plots, extract campaign nr 
            type = str_extract(plot_id, "(\\d+|P)$"),
            type = if_else(is.na(type), "1", type),
            campaign = as.numeric(if_else(type %in% c("1", "2", "3"), type, NA_character_)),
            type = if_else(type == "P", "permanent", "temporary"),
            plot_id2 = str_remove(plot_id, "(\\d+|P)$")) |> 
      extract(plot_id2,
        into = c("destSiteID", "plot_nr", "treatment"),
        regex = "^([A-Z])([0-9]+)(Cage|C)",
        remove = FALSE) |> 

      # remove 2 extra sites
      filter(!destSiteID %in% c("H", "B")) |> 
      mutate(destSiteID = case_when(destSiteID == "V" ~ "Vikesland",
                                destSiteID == "J" ~ "Joasete",
                                destSiteID == "L" ~ "Liahovden",
                                TRUE ~ destSiteID),
             treatment = if_else(treatment == "C", "Control", treatment),
             plot_nr = as.numeric(plot_nr)) |> 
      pivot_longer(cols = c(graminoids:shrubs), names_to = "functional_group", values_to = "biomass_g") |> 
      tidylog::filter(!is.na(biomass_g)) |> 
      select(date, campaign, destSiteID, destPlotID = plot_id, plot_nr, type, treatment, functional_group, productivity = biomass_g, pH = p_h)
      
      # fix soil moisture data
      sm <- soilmoisture_raw |> 
        janitor::clean_names() |> 
        # remove 2 extra sites
        filter(!site %in% c("Hogsete", "In between")) |>
        mutate(date = dmy(date),
              across(c(m1, m2, m3, m4), as.numeric),
            # distinguish permanent and movable plots, extract campaign nr 
            type = str_extract(plot_id, "(\\d+|P)$"),
            type = if_else(is.na(type), "1", type),
            campaign = as.numeric(if_else(type %in% c("1", "2", "3"), type, NA_character_)),
            type = if_else(type == "P", "permanent", "temporary"),
            plot_id2 = str_remove(plot_id, "(\\d+|P)$"),
          # fix wrong site
            site = if_else(site == "Joesete", "Joasete", site)) |> 
        rename(destSiteID = site,
                date_sm = date) |> 
        pivot_longer(cols = c(m1:m4), names_to = "replicate", values_to = "soilmoisture") |> 
        mutate(replicate = as.numeric(str_remove(replicate, "m"))) |> 
        tidylog::select(date_sm, campaign, destSiteID, destPlotID = plot_id, type, treatment, replicate, soilmoisture, weather, recorder, comments)
      
      # join soilmoisture to productivity data
      prod |>  
        tidylog::left_join(sm, 
          by = c("campaign", "destSiteID", "destPlotID", "type", "treatment"))

      
    }
      
  ),

  tar_target(
    name = productivity_sp_clean,
    command = {

      prod_sp <- productivity_sp_raw |> 
        clean_names() |> 
        filter(!site %in% c("Hogsete", "In Between")) |>
        mutate(date = dmy(date),
                # distinguish permanent and movable plots, extract campaign nr 
                type = str_extract(plot_id, "(\\d+|P)$"),
                type = if_else(is.na(type), "1", type),
                campaign = as.numeric(if_else(type %in% c("1", "2", "3"), type, NA_character_)),
                type = if_else(type == "P", "permanent", "temporary"),
                plot_id2 = str_remove(plot_id, "(\\d+|P)$")) |> 
        extract(plot_id2,
            into = c("destSiteID", "plot_nr", "treatment"),
            regex = "^([A-Z])([0-9]+)(Cage|C)",
            remove = FALSE) |> 
        mutate(treatment = if_else(treatment == "C", "Control", treatment),
             plot_nr = as.numeric(plot_nr)) |> 
        pivot_longer(cols = c(agrostis_capillaris:pinguicula_vulgaris), 
                     names_to = "species", values_to = "biomass_g") |> 
        tidylog::filter(!is.na(biomass_g)) |> 
        select(date, campaign, destSiteID = site, destPlotID = plot_id, type, treatment, plot_nr, species, productivity = biomass_g)
      
      prod_sp |> 
        mutate(species = case_when(species == "c_nigra" ~ "carex_nigra",
                                    species == "carex_small_bigelowii" ~ "carex_sp1",
                                    species == "carex_sp" ~ "carex_sp1",
                                    species == "carex_yellow" ~ "carex_sp3",
                                    species == "ranunculus_repens_32" ~ "ranunculus_repens",
                                    species == "ranunculus_repens_66" ~ "ranunculus_repens",
                                    species == "rubus_idaeus_2" ~ "rubus_idaeus",
                                    species == "s_aizoides" ~ "saxifraga_aizoides",
                                    species == "t_cespitosum" ~ "unknown_rush",
                                    species == "vac_mytilus" ~ "vaccinium_mytilus",
                                    species == "vac_uliginosum" ~ "vaccinium_uliginosum",
                                    species == "vac_vitis_idea" ~ "vaccinium_vitis_idea",
                                  TRUE ~ species)) |> 
        mutate(species = str_replace_all(species, "_", " ") %>%
          str_to_sentence())
        

    }
  ),

  # save data
  tar_target(
    name = productivity_fg_out,
    command =  save_csv(productivity_fg_clean,
                        nr = "4_",
                        name = "productivity_fg_2019")
  ),

  tar_target(
    name = productivity_sp_out,
    command =  save_csv(productivity_sp_clean,
                        nr = "4_",
                        name = "productivity_sp_2019")
  )
  
)
