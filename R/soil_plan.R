# soil plan

soil_plan <- list(
  
  ## SOIL CHARACTERISTICS
  tar_target(
    name = soil_download,
    command = get_file(node = "pk4bg",
                       file = "ThreeD_SoilSamples_2019.xlsx",
                       path = "data",
                       remote_path = "RawData/Soil"),
    format = "file"
  ),
  
  # import data
  tar_target(
    name = soil_raw,
    command = read_excel(soil_download)
  ),
  
  # clean data
  tar_target(
    name = soil_clean,
    command = clean_soil(soil_raw)
  ),
  
  # save data (remove som, will be added to soil nutrient data)
  tar_target(
    name = soil_out,
    command = save_csv(soil_clean |> 
                         filter(!variable %in% c("soil_organic_matter", "carbon_content")),
                       name = "clean_soil_characteristics_2019-2020")
  ),
  
  ## SOIL NUTRIENTS
  tar_target(
    name = cn19_20_download,
    command = get_file(node = "pk4bg",
                       file = "ThreeD_2019_2020_CN_resultater.xlsx",
                       path = "data",
                       remote_path = "RawData/Soil"),
    format = "file"
  ),
  
  tar_target(
    name = som21_download,
    command = get_file(node = "pk4bg",
                       file = "ThreeD_soilcores_2021.csv",
                       path = "data",
                       remote_path = "RawData/Soil"),
    format = "file"
  ),
  
  tar_target(
    name = cn22_download,
    command = get_file(node = "pk4bg",
                       file = "CN resultater Aud_22.xlsx",
                       path = "data",
                       remote_path = "RawData/Soil"),
    format = "file"
  ),
  
  tar_target(
    name = cn22_meta_download,
    command = get_file(node = "pk4bg",
                       file = "THREE-D_soil_CN_sample_2022.xlsx",
                       path = "data",
                       remote_path = "RawData/Soil"),
    format = "file"
  ),
  
  # import data
  tar_target(
    name = cn19_20_raw,
    command = read_excel(cn19_20_download)
  ),
  
  tar_target(
    name = som21_raw,
    command = read_csv2(som21_download)
  ),
  
  tar_target(
    name = cn22_raw,
    command = read_excel(cn22_download)
  ),
  
  tar_target(
    name = cn22_meta_raw,
    command = read_excel(cn22_meta_download)
  ),
  
  # PRS probes
  tar_target(
    name = prs_download,
    command = get_file(node = "pk4bg",
                       file = "ThreeD_raw_PRSresults_2021.xlsx",
                       path = "data",
                       remote_path = "RawData/Soil"),
    format = "file"
  ),
  
  tar_target(
    name = prs_meta_download,
    command = get_file(node = "pk4bg",
                       file = "PRS_probes_sampleID.xlsx",
                       path = "data",
                       remote_path = "RawData/Soil"),
    format = "file"
  ),
  
  tar_target(
    name = prs_raw,
    command = read_excel(prs_download, skip = 4)
  ),
  
  tar_target(
    name = prs_meta_raw,
    command = read_excel(prs_meta_download)
  ),
  
  # clean soil nutrients
  tar_target(
    name = cn_clean,
    command = clean_soil_nutrients(cn19_20_raw, cn22_raw, cn22_meta_raw, metaTurfID, som21_raw, soil_clean, prs_raw, prs_meta_raw)
  ),
  
  # save data
  tar_target(
    name = cn_out,
    command = save_csv(cn_clean,
                       name = "clean_soil_nutrients_2019-2022")
  )
)