# data dictionary plan

data_dic_plan <- list(
  
  # attribute table
  tar_target(
    name = attribute_table_file,
    command = "data_cleaned/Three-D_description_table.csv",
    format = "file"
  ),
  
  tar_target(
    name = attribute_table,
    command = read_csv(attribute_table_file)
  ),
  
  # site data dic
  tar_target(
    name = site_dic,
    command = make_data_dictionary(data = site, 
                                   description_table = attribute_table, 
                                   table_ID = NA_character_)
  ),
  
  # plot data dic
  tar_target(
    name = plot_dic,
    command = make_data_dictionary(data = plot_clean,
                                   description_table = attribute_table,
                                   table_ID = NA_character_)
  ),
  
  # climate data dic
  tar_target(
    name = climate_dic,
    command = make_data_dictionary(data =  climate_clean,
                                   description_table = attribute_table,
                                   table_ID = NA_character_)
  ),
  
  
  
  # merge data dictionaries
  tar_target(
    name = threeD_dic,
    command = write_xlsx(list(site = site_dic,
                              plot = plot_dic,
                              climate = climate_dic#,
                                # community_cover = cover_dic,
                                # subplot_presence = subplot_dic,
                                # community_structure = structure_dic,
                                # biomass = biomass_dic,
                                # ndvi = reflectance_dic,
                                # soil= soil_dic,
                                # soil_nutrients = prs_dic,
                                # decomposition = decompose_dic,
                                # cflux = cflux_dic,
                                # gridded_climate = climate_gridded_dic
                              ),
                           path = "data_cleaned/Three-D_data_dictionary.xlsx"),
    format = "file"
    )
  )
