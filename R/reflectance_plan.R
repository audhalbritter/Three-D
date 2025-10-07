# reflectance plan

reflectance_plan <- list(
  
  # download data
  tar_target(
    name = ndvi20_download,
    command = get_file(node = "pk4bg",
                       file = "v_THREE-D_raw_NDVI_2020_aud.csv",
                       path = "data",
                       remote_path = "v_raw_reflectance"),
    format = "file"
  ),
  
  tar_target(
    name = ndvi20_2_download,
    command = get_file(node = "pk4bg",
                       file = "v_THREE-D_raw_NDVI_2020_joseph.csv",
                       path = "data",
                       remote_path = "v_raw_reflectance"),
    format = "file"
  ),
  
  tar_target(
    name = ndvi22_download,
    command = get_file(node = "pk4bg",
                       file = "v_THREE-D_raw_NDVI_2022_joseph.csv",
                       path = "data",
                       remote_path = "v_raw_reflectance"),
    format = "file"
  ),
  
  # import data
  tar_target(
    name = ndvi20_raw,
    command = read_csv(ndvi20_download)
  ),
  
  tar_target(
    name = ndvi20_2_raw,
    command = read_csv(ndvi20_2_download)
  ),
  
  tar_target(
    name = ndvi22_raw,
    command = read_csv(ndvi22_download)
  ),
  
  # clean data
  tar_target(
    name = ndvi_clean,
    command = clean_reflectance(ndvi20_raw, ndvi20_2_raw, ndvi22_raw, metaTurfID)
  ),
  
  # save data
  tar_target(
    name = ndvi_out,
    command = save_csv(ndvi_clean,
                       nr = "v_",
                       name = "reflectance_2020_2022")
  )
  
)