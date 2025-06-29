# cflux plan

cflux_plan <- list(
  tar_target(
    name = cflux2020_download,
    command = get_file(node = "pk4bg",
                       file = "Three-D_cflux_2020.zip",
                       path = "data/C-Flux/summer_2020",
                       remote_path = "RawData/13_Three-D_raw_C-Flux"),
    format = "file"
  ),
  tar_target(
    name = cfluxrecord2020_download,
    command = get_file(node = "pk4bg",
                       file = "Three-D_field-record_2020.csv",
                       path = "data/C-Flux/summer_2020",
                       remote_path = "RawData/13_Three-D_raw_C-Flux"),
    format = "file"
  ),
  tar_target(
    name = cflux2021_download,
    command = get_file(node = "pk4bg",
                       file = "Three-D_cflux_2021.zip",
                       path = "data/c-flux/summer_2021",
                       remote_path = "RawData/13_Three-D_raw_C-Flux"),
    format = "file"
  ),
  tar_target(
    name = cfluxrecord2021_download,
    command = get_file(node = "pk4bg",
                       file = "Three-D_field-record_2021.csv",
                       path = "data/c-flux/summer_2021",
                       remote_path = "RawData/13_Three-D_raw_C-Flux"),
    format = "file"
  ),
  tar_target(
    name = soilRchambersize_download,
    command = get_file(node = "pk4bg",
                       file = "Three-D_soilR-chambers-size.csv",
                       path = "data/c-flux/summer_2021",
                       remote_path = "RawData/13_Three-D_raw_C-Flux"),
    format = "file"
  ),
  tar_target(
    name = cflux2021_clean,
    command = clean_cflux2021(soilRchambersize_download, cflux2021_download, cfluxrecord2021_download, metaTurfID)
  ),
  tar_target(
    name = cflux2020_clean,
    command = clean_cflux2020(cflux2020_download, cfluxrecord2020_download, metaTurfID)
  ),
  tar_target(
    name = cflux2020_flags,
    command = cflux2020_clean |>
      filter(type != "GPP") |>
      rowid_to_column("rowid") |>
      flux_flag_count(rowid) |>
      select(!ratio) |>
      rename(
        `Quality flag` = "f_quality_flag",
        `2020 dataset` = "n"
      )
      # save_csv(name = "cflux2020_flags")
  ),
  tar_target(
    name = cflux2021_flags,
    command = cflux2021_clean |>
      filter(type != "GPP") |>
      rowid_to_column("rowid") |>
      flux_flag_count(rowid) |>
      select(!ratio) |>
      rename(
        `Quality flag` = "f_quality_flag",
        `2021 dataset` = "n"
      )
      # save_csv(name = "cflux2021_flags")
  ),
  tar_target(
    name = cflux_flags,
    command = left_join(cflux2020_flags, cflux2021_flags) |>
      save_csv(nr = "13_", 
               name = "cflux_flags")
  ),
  tar_target(
    name = join_cflux,
    command = full_join(cflux2021_clean, cflux2020_clean)
  ),
  tar_target(
    name = cflux_out,
    command = save_csv(join_cflux,
                       nr = "13_",
                       name = "cflux_clean")
  )
)
