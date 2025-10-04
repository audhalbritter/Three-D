# meta data plan

meta_plan <- list(
  
  # download site data
  tar_target(
    name = site_download,
    command = get_file(node = "pk4bg",
                       file = "i_Three-D_clean_elevation_coordinates_2019.csv",
                       path = "data_cleaned"),
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
                       file = "ii_Three-D_raw_PlotLevel_MetaData_2019.csv",
                       path = "data",
                       remote_path = "ii_raw_slope_aspect_soil depth"),
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
                       nr = "ii_",
                       name = "slope_aspect_soil_depth_2019")
  ),
  
  # meta turfID
  tar_target(
    name = metaTurfID,
    command = create_threed_meta_data() |> 
      distinct()
  )
  
  
  
)