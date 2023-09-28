# root data

root_plan <- list(
  
  # download data
  tar_target(
    name = root_productivity_download,
    command = get_file(node = "pk4bg",
                       file = "Three-D_raw_root_productivity_2022.xlsx",
                       path = "data",
                       remote_path = "RawData/Vegetation"),
    format = "file"
  ),
  
  tar_target(
    name = root_traits_download,
    command = get_file(node = "pk4bg",
                       file = "Three-D_raw_root_traits_2022.txt",
                       path = "data",
                       remote_path = "RawData/Vegetation"),
    format = "file"
  ),
  
  # import data
  tar_target(
    name = root_productivity_raw,
    command = read_excel(root_productivity_download, skip = 1)
  ),
  
  tar_target(
    name = root_traits_raw,
    command = read_delim(root_traits_download)
  ),
  
  # clean data
  tar_target(
    name = roots_clean,
    command = clean_roots(root_productivity_raw, root_traits_raw, metaTurfID)
  )
  
  
)