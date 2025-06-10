# reflectance plan

decomposition_plan <- list(
  
  # download data
  tar_target(
    name = decomp_download,
    command = get_file(node = "pk4bg",
                       file = "12_ThreeD_raw_decomposition_2022-07-11.xlsx",
                       path = "data",
                       remote_path = "RawData"),
    format = "file"
  ),
  
  # import data
  tar_target(
    name = decomp_raw,
    command = read_excel(decomp_download, sheet = "Teabag ID, weight, depth")
  ),
  
  tar_target(
    name = decom_meta_raw,
    command = read_excel(decomp_download, sheet = "Plot + teabag info")
  ),
  
  # clean data
  tar_target(
    name = decomp_clean,
    command = clean_decomposition(decomp_raw, decom_meta_raw, metaTurfID)
  ),
  
  tar_target(
    name = tbi_index,
    command = calc_TBI_index(decomp_clean)
  ),
  
  # save data
  tar_target(
    name = decomposition_out,
    command = save_csv(decomp_clean,
                       nr = "12_",
                       name = "decomposition_2021-2022")
  )
  
)