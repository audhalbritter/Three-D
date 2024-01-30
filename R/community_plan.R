# community plan

community_plan <- list(
  
  # download community
  tar_target(
    name = community_download,
    command = {
      get_file(node = "pk4bg",
               file = "Three-D_raw_community_2019-2022.zip",
               path = "data",
               remote_path = "RawData/Vegetation")
      
      unzip("data/Three-D_raw_community_2019-2022.zip", 
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
                        name = "clean_cover_2019-2022")
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
                        name = "clean_community_subplot_2019-2022")
  ),
  
  # clean community structure data
  tar_target(
    name = comm_structure_clean,
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
      ungroup()  |>  
      select(date, year, origSiteID:Nlevel, functional_group = species, cover, recorder)
  ),
  
  # save data
  tar_target(
    name =  comm_structure_out,
    command =  save_csv(comm_structure_clean,
                        name = "clean_community_structure_2019-2022")
  ),
  
  
  # clean height data
  tar_target(
    name = height_clean,
    command = community_clean %>% 
      filter(species %in% c("Vascular plant layer", "Moss layer")) %>% 
      select(-c(`5`:`25`)) %>% 
      pivot_longer(cols = `1`:`4`, names_to = "subplot", values_to = "height") %>% 
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
                                TRUE ~ height))
  ),
  
  # save data
  tar_target(
    name =  height_out,
    command =  save_csv(height_clean,
                        name = "clean_height_2019_2022")
  ),
  
  # taxonomy
  tar_target(
    name =  taxonomy_file,
    command =  "data/Three-D_Taxonomy_2019.csv",
    format = "file"
  ),

  # make species list
  tar_target(
    name =  taxonomy_clean,
    command =  {
      
      taxonomy <- read_csv(taxonomy_file) |> 
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
                                            TRUE ~ functional_group))
      
      }
  ),
  
  # save data
  tar_target(
    name =  taxonomy_out,
    command =  save_csv(taxonomy_clean,
                        name = "clean_taxonomy")
  )
)
