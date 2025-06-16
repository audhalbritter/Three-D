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
    command = make_data_dictionary(data = climate_clean,
                                   description_table = attribute_table,
                                   table_ID = NA_character_)
  ),
  
  # biomass data dic
  tar_target(
    name = biomass_dic,
    command = make_data_dictionary(data = biomass_clean,
                                   description_table = attribute_table,
                                   table_ID = "biomass")
  ),
  
  # productivity data dic
  tar_target(
    name = productivity_dic,
    command = make_data_dictionary(data = productivity_clean,
                                   description_table = attribute_table,
                                   table_ID = "productivity")
  ),

  tar_target(
    name = productivity_fg_dic,
    command = make_data_dictionary(data = productivity_fg_clean,
                                   description_table = attribute_table,
                                   table_ID = "productivity_fg")
  ),

  tar_target(
    name = productivity_sp_dic,
    command = make_data_dictionary(data = productivity_sp_clean,
                                   description_table = attribute_table,
                                   table_ID = "productivity_fg")
  ),

  # reflectance data dic
  tar_target(
    name = ndvi_dic,
    command = make_data_dictionary(data = ndvi_clean,
                                   description_table = attribute_table,
                                   table_ID = "reflectance")
  ),
  
  # root data dic
  tar_target(
    name = root_dic,
    command = make_data_dictionary(data = roots_clean,
                                   description_table = attribute_table,
                                   table_ID = "roots")
  ),
  
  # cover data dic
  tar_target(
    name = cover_dic,
    command = make_data_dictionary(data = cover_clean,
                                   description_table = attribute_table,
                                   table_ID = NA_character_)
  ),

  # subplot presence data dic
  tar_target(
    name = presence_dic,
    command = make_data_dictionary(data = subplot_presence_clean,
                                   description_table = attribute_table,
                                   table_ID = "subplot")
  ),

  # community structure data dic
  tar_target(
    name = comm_structure_dic,
    command = make_data_dictionary(data = comm_structure_clean,
                                   description_table = attribute_table,
                                   table_ID = "comm_structure")
  ),
  
  # soil characterdata dic
  tar_target(
    name = soil_char_dic,
    command = make_data_dictionary(data = soil_character,
                                   description_table = attribute_table,
                                   table_ID = "soil_char")
  ),
  
  # root data dic
  tar_target(
    name = nutrient_dic,
    command = make_data_dictionary(data = cn_clean,
                                   description_table = attribute_table,
                                   table_ID = "nutrient")
  ),
  
  # decomposition data dic
  tar_target(
    name = decompose_dic,
    command = make_data_dictionary(data = tbi_index,
                                   description_table = attribute_table,
                                   table_ID = "decomposition")
  ),

  tar_target(
    name = cflux_dic,
    command = make_data_dictionary(data = join_cflux,
                                   description_table = attribute_table,
                                   table_ID = "cflux")
  ),
  
  
  # merge data dictionaries
  tar_target(
    name = threeD_dic,
    command = write_xlsx(list(site = site_dic,
                              plot = plot_dic,
                              biomass = biomass_dic,
                              productivity = productivity_dic,
                              productivity_fg = productivity_fg_dic,
                              productivity_sp = productivity_sp_dic,
                              ndvi = ndvi_dic,
                              root = root_dic,
                              comm_cover = cover_dic,
                              subplot_presence_dic = presence_dic,
                              comm_structure = comm_structure_dic,
                              soil_char = soil_char_dic,
                              nutrients = nutrient_dic,
                              decomposition = decompose_dic,
                              cflux = cflux_dic
                              #climate = climate_dic
                              ),
                           path = "data_cleaned/Three-D_data_dictionary.xlsx"),
    format = "file"
    )
  )
