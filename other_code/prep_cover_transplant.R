# prep data for Transplant database

tar_load(cover_clean)
cover_clean |> 
  # remove nitrogen and grazing treatments
  filter(Namount_kg_ha_y == 0, grazing == "C") |> 
  select(-grazing, -Nlevel, -Namount_kg_ha_y, -scribe, -remark, -file) %>%
  write_csv(., file = "ThreeD_clean_community_transplant_2019-2022.csv")
