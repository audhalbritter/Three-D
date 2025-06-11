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
  )
  
)
