# root data

root_plan <- list(
  
  # download data 2021
  tar_target(
    name = root_productivity21_download,
    command = get_file(node = "pk4bg",
                       file = "6_ThreeD_rootingrowthcores_2021.xlsx",
                       path = "data",
                       remote_path = "RawData"),
    format = "file"
  ),
  
  # download data 2022
  tar_target(
    name = root_productivity22_download,
    command = get_file(node = "pk4bg",
                       file = "6_Three-D_raw_root_productivity_2022.xlsx",
                       path = "data",
                       remote_path = "RawData"),
    format = "file"
  ),
  
  tar_target(
    name = root_traits_download,
    command = get_file(node = "pk4bg",
                       file = "6_Three-D_raw_root_traits_2022.txt",
                       path = "data",
                       remote_path = "RawData"),
    format = "file"
  ),
  
  # import data
  tar_target(
    name = root_productivity21_raw,
    command = read_excel(root_productivity21_download)
  ),
  
  tar_target(
    name = root_productivity22_raw,
    command = read_excel(root_productivity22_download, skip = 1)
  ),
  
  tar_target(
    name = root_traits_raw,
    command = read_delim(root_traits_download)
  ),
  
  # clean data
  tar_target(
    name = roots_clean,
    command = clean_roots(root_productivity21_raw, decom_meta_raw, root_productivity22_raw, root_traits_raw, metaTurfID)
  ),

    # save data
  tar_target(
    name = roots_out,
    command = save_csv(roots_clean,
                       nr = "6_",
                       name = "roots_2020_2022")
  )
  
  
)