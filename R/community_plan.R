# community plan

community_plan <- list(
  
  # download community
  tar_target(
    name = community_download,
    command = {
      get_file(node = "pk4bg",
               file = "vii-ix_Three-D_raw_community_2019-2022.zip",
               path = "data",
               remote_path = "vii-ix_raw_plant_community_composition")
      
      unzip("data/7-9_Three-D_raw_community_2019-2022.zip", 
            exdir = "data/")
      
      },
    format = "file"
  ),
  
  # import community data
  tar_target(
    name = community_raw,
    command = import_community(metaTurfID)
  ),
  
  # clean community data
  tar_target(
    name = community_clean,
    command = clean_community(community_raw)
  ),

  # clean cover data
  tar_target(
    name = cover_clean,
    command = clean_cover(community_clean, metaTurfID)
  ),

  # save data
  tar_target(
    name = cover_out,
    command =  save_csv(cover_clean,
                        nr = "vi_",
                        name = "cover_2019-2022")
  ),

  # clean subplot presence data
  tar_target(
    name = subplot_presence_clean,
    command = clean_comm_structure(community_clean, metaTurfID)
  ),

  # save data
  tar_target(
    name =  subplot_precense_out,
    command =  save_csv(subplot_presence_clean,
                        nr = "viii_",
                        name = "community_subplot_2019-2022")
  ),

  # clean community structure data
  tar_target(
    name = structure_clean,
    command = community_clean %>%
      filter(species %in% c("SumofCover", "Vascular plants", "Bryophytes", "Lichen", "Litter", "Bare soil", "Bare rock", "Poop", "Wool")) %>%
      mutate(`24` = if_else(`24` == "Ratio > 1.5 is wrong", "0", `24`)) %>%
      pivot_longer(cols = `1`:`25`, names_to = "subplot", values_to = "percentage") %>%
      ungroup() |>
      # make rows numeric
      mutate(percentage = as.numeric(percentage),
             percentage = case_when(is.na(percentage) ~ 0,
                                    percentage == 520 ~ 52,
                                    TRUE ~ percentage)) |>
      # calculate mean cover per turf
      group_by(origSiteID, origBlockID, origPlotID, destSiteID, destPlotID, destBlockID, turfID, warming, grazing, Nlevel, date, year, species, cover, recorder) %>%
      summarise(mean = mean(percentage)) %>%
      # In 2020 vascular plant cover was estimated per subplot, in the other years, only for the whole plot
      # all years except 2020 whole plot for sum of cover and vascular plant cover
      # 2020 no sum of cover, and subplot vascular plant cover
      mutate(cover = case_when(year == 2020 & species == "Vascular plants" ~ mean,
                               # sum of cover was not estimated for non controls in 2020
                               year == 2020 & species == "SumofCover" & !Nlevel %in% c(1, 2, 3)  ~ NA_real_,
                               species %in% c("SumofCover", "Vascular plants") ~ cover,
                               !species %in% c("SumofCover", "Vascular plants") ~ mean)) |>
      # make NA if functional group is not there and then remove
      mutate(cover = if_else(cover == 0 & species %in% c("Bryophytes", "Lichen", "Litter", "Bare soil", "Bare rock", "Poop", "Wool"), NA_real_, cover)) |> 
      filter(!is.na(cover)) |>
      ungroup() |> 
      mutate(variable = if_else(species == "SumofCover", "sum_cover", "cover"),
             species = tolower(species)) |> 
      select(date, year, origSiteID:Nlevel, variable, functional_group = species, value = cover, recorder)
  ),

  # clean height data
  tar_target(
    name = height_clean,
    command = community_clean %>%
      filter(species %in% c("Vascular plant layer", "Moss layer")) %>%
      select(-c(`5`:`25`)) %>%
      pivot_longer(cols = `1`:`4`, names_to = "subplot", values_to = "height") %>% 
      # many warnings because na in data
      mutate(height = as.numeric(height)) %>% 
      group_by(turfID, year, species, recorder) %>%
      summarise(height = mean(height, na.rm = TRUE)) %>%
      rename("vegetation_layer" = "species") |>
      # add missing height (average from all years)
      # all other NAs are real
      mutate(height = case_when(turfID == "67 AN9M 67" & vegetation_layer == "Moss layer" & year == 2020 ~ 0.675,
                                turfID == "67 AN9M 67" & vegetation_layer == "Vascular plant layer" & year == 2020 ~ 2.41,
                                turfID == "152 AN9N 152" & vegetation_layer == "Moss layer" & year == 2020 ~ NA_real_,
                                is.na(height) ~ NA_real_,
                                TRUE ~ height)) |> 
      mutate(vegetation_layer = recode(vegetation_layer,
                                       "Moss layer" = "bryophyte",
                                       "Vascular plant layer" = "vegetation"),
             variable = if_else(vegetation_layer == "bryophyte", "depth", "height")) |> 
      left_join(metaTurfID) |> 
      select(year, origSiteID, origBlockID, origPlotID, turfID, destSiteID:destBlockID, warming:Nlevel, Namount_kg_ha_y, variable, functional_group = vegetation_layer, value = height)
  ),

  # bind height and functional group cover
  tar_target(
    name =  comm_structure_clean,
    command =  bind_rows(structure_clean, height_clean) |> 
      select(year, date, origSiteID:Nlevel, Namount_kg_ha_y, variable:recorder)
  ),
  
  # save data
  tar_target(
    name =  comm_structure_out,
    command =  save_csv(comm_structure_clean,
                        nr = "ix_",
                        name = "community_structure_2019-2022")
  ),

  # taxonomy
  # download community
  tar_target(
    name = taxonomy_download,
    command = get_file(node = "pk4bg",
               file = "vii-ix_Three-D_raw_Taxonomy_2019.csv",
               path = "data",
               remote_path = "vii-ix_raw_plant_community_composition"),
    format = "file"
  ),

  # make species list
  tar_target(
    name =  taxonomy_clean,
    command =  {

      taxonomy <- read_csv(taxonomy_download) |>
      rename(species = Species, family = Family, functional_group = functionalGroup) |>
      separate(species, into = c("genus", "species"), sep = "\\s", extra = "merge") |>
      select(-species) |>
      distinct()

      sp_list <- cover_clean |>
        distinct(species) |>
        separate(species, into = c("genus", "species"), sep = "\\s", extra = "merge") |>
        left_join(taxonomy, by = "genus") |>
        mutate(functional_group = case_when(genus == "Unknown" & grepl("graminoid", species) ~ "graminoid",
                                            genus == "Unknown" & grepl("herb", species) ~ "forb",
                                            genus == "Unknown" & grepl("orchid", species) ~ "forb",
                                            TRUE ~ functional_group)) |> 
        select(functional_group, family, genus, species) |> 
        arrange(functional_group, family, genus, species)

      }
  ),

  # save data
  tar_target(
    name =  taxonomy_out,
    command =  save_csv(taxonomy_clean,
                        nr = "vii_",
                        name = "species_list")
  )
)
