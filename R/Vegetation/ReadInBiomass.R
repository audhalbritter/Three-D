############################
### READ IN BIOMASS DATA ###
############################

source("R/Load packages.R")

read_excel(path = "data/biomass/THREE_D_Biomass_Cutting_2019_Leire.xlsx")


files <- dir(path = "data/biomass/", pattern = "\\.xlsx$", full.names = TRUE, recursive = TRUE)
files <- files[c(1, 3)]

map_df(set_names(files), function(file) {
  file %>% 
    set_names() %>% 
    map_df(~ read_excel(path = file))
}, .id = "File")

# , col_types = c("text", "numeric", "numeric", "text", "text", "numeric", "text", "numeric", "date", rep("numeric", 6), "text", "numeric", "numeric")

biomass_raw1 <- read_excel(path = "data/biomass/THREE_D_Biomass_Cutting_2019_Leire.xlsx", col_types = c("text", "numeric", "numeric", "text", "text", "numeric", "text", "numeric", "date", rep("numeric", 6), "text", "numeric", "numeric"))
biomass_raw2 <- read_excel(path = "data/biomass/THREE_D_Biomass_Cutting_2019_Selina.xlsx", col_types = c("text", "numeric", "numeric", "text", "text", "numeric", "text", "numeric", "date", rep("numeric", 6), "text", "numeric", "numeric", "numeric", "numeric"))

biomass <- biomass_raw1 %>%
  bind_rows(biomass_raw2) %>% 
  mutate(Bryophytes_g = coalesce(Bryophytes_g, Moss),
         Cyperaceae_g = coalesce(Cyperaceae_g, carex)) %>% 
  select(destSiteID:Date, Graminoids_g:Litter_g, Lichen_g, Shrub_g, Remark, Moss) %>% 
  pivot_longer(cols = c(Graminoids_g:Shrub_g), names_to = "FunGroup", values_to = "Value") %>% 
  filter(grazing %in% c("M", "I"),
         !is.na(Value)) %>% 
  distinct()

biomass %>% filter(turfID == "14 WN6I 92") %>% as.data.frame()
 # no date
biomass %>% filter(is.na(Date)) %>% distinct(turfID, Cut)

incomplete <- biomass %>% 
  group_by(destSiteID, turfID, FunGroup) %>% 
  mutate(n = n()) %>% 
  # all incomplete once
  filter((grazing == "M" & n < 2) | (grazing == "I" & n < 4)) %>% 
  select(Date, destSiteID, turfID, grazing, Cut, FunGroup, Value, Remark, n) %>% 
  arrange(destSiteID, turfID)

write_csv(incomplete, path = "Incomplete_Biomass_ThreeD_2020.csv")
