#######################################################
 ### READ IN BIOMASS DATA FROM GRAZING TREATEMENTS ###
#######################################################

source("R/Load packages.R")
source("R/Rgathering/create meta data.R")

# Run this code if you need to download raw data from OSF
# get_file(node = "pk4bg",
#          file = "THREE_D_Biomass_Grazing_2020_March_2021.xlsx",
#          path = "data/biomass",
#          remote_path = "RawData/Vegetation")

# 2020 data
biomass20 <- read_excel(path = "data/biomass/THREE_D_Biomass_Grazing_2020_March_2021.xlsx", 
                          col_types = c("text", "numeric", "numeric", "text", "text", "numeric", "text", "numeric", "date", rep("numeric", 6), "text", rep("numeric", 4))) %>% 
  pivot_longer(cols = c(Graminoids_g:Litter_g, Lichen_g:Fungi_g), names_to = "fun_group", values_to = "value") %>% 
  filter(grazing %in% c("M", "I"),
         !is.na(value)) %>% 
  rename(date = Date, cut = Cut, remark = Remark) %>% 
  left_join(metaTurfID, by = c("destSiteID", "destBlockID", "destPlotID", "turfID", "warming", "Nlevel", "grazing")) %>% 
  mutate(year = year(date))

#write_csv(biomass, path = "data_cleaned/vegetation/THREE-D_Biomass_2020.csv")

# 2021 data
biomass21_raw <- read_excel(path = "data/biomass/THREE_D_Raw_Biomass_2021_10_21.xlsx",
           col_types = c("text", "numeric", "text", "text", "numeric", "numeric", "text", "numeric", "numeric", "text", "numeric", "date", rep("numeric", 9), "text", "text", rep("numeric", 6))) %>% 
  pivot_longer(cols = c(Graminoids_g:Fungi_g), names_to = "fun_group", values_to = "value") %>% 
  filter(!is.na(value)) %>% 
  rename(date = Date, cut = Cut, remark = Remark, collector = Collector) %>% 
  mutate(year = year(date)) %>% 
  #### REMOVE CUT 2 BECAUSE THERE IS SOME PROBLEM WITH THE DATA!!!
  filter(cut != 2)

# biomass for L shaped plots
dd <- biomass21_raw %>% 
  filter(!is.na(top)) %>% 
  # outer square minus inner square
  mutate(area_L = top * r_side - inner_l_side * inner_top)



biomass %>% 
  filter(fun_group %in% c("Graminoids_g", "Forbs_g")) %>% 
  group_by(turfID, grazing) %>% 
  count(cut) %>% View()



biomass21 %>% distinct(fun_group)
biomass21 %>% View()
biomass21 %>% filter(Cut == 3, origSiteID == "Joa") %>% distinct(grazing, Date) %>% arrange(grazing)

# find cutting date for cut 4 turfID 110 AN3I 110

# get unique cutting dates
cutting_date <- biomass %>% 
  group_by(year, destSiteID, turfID, grazing, cut) %>% 
  distinct(date) %>% 
  rename(cutting_date = date)


# sum biomass up per plot
biomass_sum <- biomass %>% 
  group_by(turfID, year, fun_group, origSiteID, warming, grazing, Nlevel) %>% 
  summarise(sum = mean(value, na.rm = TRUE))



# check data
biomass %>% 
  filter(cut == 1) %>% 
  ggplot(aes(x = as.factor(Nlevel), y = value, fill = warming)) +
  geom_boxplot() +
  facet_grid(origSiteID ~ fun_group)



biomass %>% 
  mutate(warm.graz = paste(warming, grazing, sep = "_")) %>% 
  filter(fun_group %in% c("Graminoids_g", "Forbs_g")) %>% 
  ggplot(aes(x = as.factor(Nlevel), y = sum, fill = warm.graz)) +
  geom_boxplot() +
  facet_grid(fun_group ~ origSiteID, scales = "free_y")



biomass %>% 
  filter(!Nlevel %in% c(2, 3)) %>% 
  left_join(NitrogenDictionary) %>% 
  mutate(warm.graz = paste(warming, grazing, sep = "_")) %>% 
  ggplot(aes(x = as.factor(Namount_kg_ha_y), y = value, fill = fun_group)) +
  geom_col(position = "stack") +
  facet_grid(warm.graz ~ origSiteID)
