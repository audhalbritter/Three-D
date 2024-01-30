# biomass plan

biomass_plan <- list(
  
  # download biomass
  tar_target(
    name = biomass20_download,
    command = get_file(node = "pk4bg",
                       file = "Three-D_raw_Biomass_2020_March_2021.xlsx",
                       path = "data",
                       remote_path = "RawData/Vegetation"),
    format = "file"
  ),
  
  tar_target(
    name = biomass21_download,
    command = get_file(node = "pk4bg",
                       file = "Three-D_raw_Biomass_2021_12_09.xlsx",
                       path = "data",
                       remote_path = "RawData/Vegetation"),
    format = "file"
  ),
  
  tar_target(
    name = biomass22_download,
    command = get_file(node = "pk4bg",
                       file = "Three-D_raw_Biomass_2022-09-27.csv",
                       path = "data",
                       remote_path = "RawData/Vegetation"),
    format = "file"
  ),
  
  # import and clean data
  tar_target(
    name = biomass_clean,
    command = clean_biomass(metaTurfID, biomass20_download, biomass21_download, biomass22_download)
  ),
  
  # save data
  tar_target(
    name = biomass_out,
    command = save_csv(biomass_clean,
                        name = "clean_biomass_2020-2022")
  )
  
)
