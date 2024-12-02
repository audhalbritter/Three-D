# meta data plan

meta_plan <- list(
  
  # download site data
  tar_target(
    name = site_download,
    command = get_file(node = "pk4bg",
                       file = "Three-D_meta_site.csv",
                       path = "data",
                       remote_path = "Site"),
    format = "file"
  ),
  
  # import site data
  tar_target(
    name = site,
    command = read_csv(site_download)
  ),
  
  # download plot data
  tar_target(
    name = plot_download,
    command = get_file(node = "pk4bg",
                       file = "Three-D_PlotLevel_MetaData_2019.csv",
                       path = "data",
                       remote_path = "RawData/Soil"),
    format = "file"
  ),
  
  # import plot data
  tar_target(
    name = plot_raw,
    command = read_csv(plot_download)
  ),
  
  # clean plot data
  tar_target(
    name = plot_clean,
    command = clean_plot(plot_raw, metaTurfID)
  ),
  
  # save clean plot data
  tar_target(
    name = plot_out,
    command = save_csv(plot_clean, 
                       name = "slope_aspect_soil_depth_2019")
  ),
  
  # meta turfID
  tar_target(
    name = metaTurfID,
    command = create_threed_meta_data() |> 
      distinct()
  )
  
  
  
)