# cflux plan

cflux_plan <- list(
  tar_target(
    name = cflux2020_download,
    command = get_file(node = "pk4bg",
                       file = "Three-D_cflux_2020.zip",
                       path = "data/C-Flux/summer_2020",
                       remote_path = "RawData/C-Flux"),
    format = "file"
  ),
  tar_target(
    name = cfluxrecord2020_download,
    command = get_file(node = "pk4bg",
                       file = "Three-D_field-record_2020.csv",
                       path = "data/C-Flux/summer_2020",
                       remote_path = "RawData/C-Flux"),
    format = "file"
  ),
  tar_target(
    name = cflux2021_download,
    command = get_file(node = "pk4bg",
                       file = "Three-D_cflux_2021.zip",
                       path = "data/c-flux/summer_2021",
                       remote_path = "RawData/C-Flux"),
    format = "file"
  ),
  tar_target(
    name = cfluxrecord2021_download,
    command = get_file(node = "pk4bg",
                       file = "Three-D_field-record_2021.csv",
                       path = "data/c-flux/summer_2021",
                       remote_path = "RawData/C-Flux"),
    format = "file"
  ),
  tar_target(
    name = soilRchambersize_download,
    command = get_file(node = "pk4bg",
                       file = "Three-D_soilR-chambers-size.csv",
                       path = "data/c-flux/summer_2021",
                       remote_path = "RawData/C-Flux"),
    format = "file"
  ),
)