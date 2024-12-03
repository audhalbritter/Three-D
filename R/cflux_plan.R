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
)