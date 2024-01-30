#######################################################
 ### READ IN BIOMASS DATA FROM GRAZING TREATEMENTS ###
#######################################################

source("R/Load packages.R")

# make metadata and N dictionary
metaTurfID <- create_threed_meta_data()

NitrogenDictionary <- metaTurfID |> 
  distinct(Nlevel, Namount_kg_ha_y)

# Run this code if you need to download raw data from OSF
# get_file(node = "pk4bg",
#          file = "THREE_D_Biomass_Grazing_2020_March_2021.xlsx",
#          path = "data/biomass",
#          remote_path = "RawData/Vegetation")

# 2020 data
biomass20 <- read_excel(path = "data/biomass/Three-D_raw_Biomass_2020_March_2021.xlsx", 
                          col_types = c("text", "numeric", "numeric", "text", "text", "numeric", "text", "numeric", "date", rep("numeric", 6), "text", rep("numeric", 4))) %>% 
  pivot_longer(cols = c(Graminoids_g:Litter_g, Lichen_g:Fungi_g), names_to = "fun_group", values_to = "value") %>% 
  filter(grazing %in% c("M", "I"),
         !is.na(value)) %>% 
  # fill in missing date
  mutate(Date = as.character(Date),
         Date = if_else(destSiteID == "Joa" & Cut == 4 & is.na(Date), "2020-09-09", Date),
         Date = if_else(destSiteID == "Vik" & Cut == 4 & is.na(Date), "2020-09-10", Date),
         Date = ymd(Date),
         year = year(Date),
         area = 2500) |> 
  rename(date = Date, cut = Cut, remark = Remark) |> 
  # add metadata
  left_join(metaTurfID, by = c("destSiteID", "destBlockID", "destPlotID", "turfID",     
                               "warming", "Nlevel", "grazing"))



# 2021 data
biomass21_raw <- read_excel(path = "data/biomass/Three-D_raw_Biomass_2021_12_09.xlsx",
           col_types = c("text", "numeric", "text", "text", "numeric", "numeric", "text", "numeric", "numeric", "text", "numeric", "date", rep("numeric", 9), "text",  "text", rep("numeric", 6))) %>% 
  pivot_longer(cols = c(Graminoids_g:Fungi_g), names_to = "fun_group", values_to = "value") %>% 
  filter(!is.na(value)) %>% 
  rename(date = Date, cut = Cut, remark = Remark, collector = Collector) %>% 
  mutate(year = year(date))

# get mean area for missing measurements
mean_area <- biomass21_raw %>% 
  filter(!is.na(top)) %>% 
  mutate(area = (top * r_side - inner_l_side * inner_top)) %>%
  summarise(mean_area = mean(area, na.rm = TRUE))


# Add area and calculate for L shaped plots
biomass21 <- biomass21_raw %>% 
  # outer square minus inner square
  mutate(inner_l_side = if_else(is.na(inner_l_side), r_side - l_side, inner_l_side),
         area = case_when(remark == "corner" & !is.na(top) ~ (top * r_side - inner_l_side * inner_top),
                          remark == "corner" & is.na(top) ~ as.numeric(mean_area),
                          cut == 3 & grazing %in% c("C", "N") ~ (top * r_side - inner_l_side * inner_top),
                          TRUE ~ 2500)) |> 
  # join Nitrogen in kg ha y
  left_join(NitrogenDictionary, by = "Nlevel")



### Check area scaling is correct
# Scaling of the plot biomass just from the corner is not great!!!
# I only get 54% of the biomass!!!
biomass21 |> 
  mutate(corner = if_else(is.na(top), "all", "corner")) |>
  select(origSiteID, turfID, corner, fun_group, area, value, remark) |> 
  group_by(origSiteID, turfID, corner, area) |> 
  summarise(biomass = sum(value)) |> 
  ungroup() |> 
  group_by(turfID) |> 
  mutate(n = n()) |> 
  filter(n > 1,
         !turfID %in% c("107 WN3M 175", "73 WN2M 153")) |> 
  # calculate total biomass for larger plot
  mutate(biomass = if_else(corner == "all", sum(biomass), biomass)) |> 
  # calculate area in m2 and scale biomass to m2
  mutate(area_m2 = area / 10000,
         biomass_scaled = biomass / area_m2) |> 
  select(-area, -area_m2, -biomass, -n) |> 
  pivot_wider(names_from = corner, values_from = biomass_scaled) |> 
  mutate(p = corner / all * 100)
  
              
# 2022 data
# Cut 1 Lia is missing due to late snowmelt
biomass22 <- read_csv(file = "data/biomass/Three-D_raw_Biomass_2022-09-27.csv") |> 
  mutate(Date = case_when(Date == "15-16.08.2022" ~ "15.08.2022",
                          Date == "x" ~ "15.08.2022",
                          TRUE ~ as.character(Date)),
         Date = dmy(Date)) |> 
  
  # Fix wrong values
  mutate(Forbs_g = if_else(turfID == "78 WN2I 158", 1.4981, Forbs_g),
         Litter_g = if_else(turfID == "61 WN8I 140", 0.604, Litter_g),
         Bryophytes_g = if_else(turfID == "94 AN6I 94", 0.932, Bryophytes_g)) |> 
  # remove empty rows
  filter(!is.na(Date)) |> 
  # make long table
  pivot_longer(cols = c(Graminoids_g:Fungi_g), names_to = "fun_group", values_to = "value") |> 
  filter(!is.na(value)) |> 
  rename(date = Date, cut = Cut, remark = Remark, collector = Collector) |> 
  mutate(year = year(date),
         area = 2500) |> 
  # join Nitrogen in kg ha y
  left_join(NitrogenDictionary, by = "Nlevel")

# merge all files
biomass <- biomass20 %>% 
  bind_rows(biomass21 %>% select(-c(top:l_side)),
            biomass22) %>% 
  mutate(fun_group = tolower(fun_group),
         fun_group = str_remove(fun_group, "_g"),
         unit = "g") %>% 
  select(origSiteID, origBlockID, origPlotID, turfID, destSiteID, destBlockID, destPlotID, warming, Nlevel, Namount_kg_ha_y, grazing, cut, year, date, fun_group, biomass = value, unit, area_cm2 = area, collector, remark)


write_csv(biomass, file = "data_cleaned/vegetation/Three-D_clean_biomass_2020-2022.csv")


biomass %>% filter(is.na(turfID)) %>% distinct(year)

# cleaning steps
biomass %>% View()
biomass %>% filter(biomass > 100) %>% as.data.frame()
biomass %>% distinct(fun_group) %>% pn
biomass %>% filter(cut == 3, destSiteID == "Joa") %>% distinct(grazing, date) %>% arrange(grazing) %>% pn


# get unique cutting dates
cutting_date <- biomass %>% 
  group_by(year, destSiteID, turfID, grazing, cut) %>% 
  distinct(date) %>% 
  rename(cutting_date = date)


# sum biomass up per plot
productivity <- biomass %>% 
  # average for controls
  group_by(year, cut, fun_group, origSiteID, destSiteID, warming, grazing, Namount_kg_ha_y) %>% 
  summarise(biomass = mean(biomass, na.rm = TRUE)) |> 
  ungroup() |> 
  # sum over time
  group_by(year, fun_group, origSiteID, destSiteID, warming, grazing, Namount_kg_ha_y) %>% 
  summarise(biomass = sum(biomass, na.rm = TRUE))

biomass |> filter(is.na(date)) |> View()

productivity |> 
  filter(origSiteID == "Joa") |> 
  ggplot(aes(x = log(Namount_kg_ha_y + 1), y = biomass, fill = fun_group)) +
  geom_col() +
  facet_grid(warming ~ year)

# check data
biomass %>% 
  filter(cut == 1) %>% 
  ggplot(aes(x = as.factor(Nlevel), y = biomass, fill = warming)) +
  geom_boxplot() +
  facet_grid(origSiteID ~ fun_group)



biomass %>% 
  mutate(warm.graz = paste(warming, grazing, sep = "_")) %>% 
  filter(fun_group %in% c("graminoids", "forbs")) %>% 
  ggplot(aes(x = as.factor(Nlevel), y = biomass, fill = warm.graz)) +
  geom_boxplot() +
  facet_grid(fun_group ~ origSiteID, scales = "free_y")



biomass %>% 
  filter(!Nlevel %in% c(2, 3)) %>% 
  left_join(NitrogenDictionary) %>% 
  mutate(warm.graz = paste(warming, grazing, sep = "_")) %>% 
  ggplot(aes(x = as.factor(Namount_kg_ha_y), y = value, fill = fun_group)) +
  geom_col(position = "stack") +
  facet_grid(warm.graz ~ origSiteID)
