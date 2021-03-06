#######################################################
 ### READ IN BIOMASS DATA FROM GRAZING TREATEMENTS ###
#######################################################

source("R/Load packages.R")
source("R/Rgathering/create meta data.R")

# Download raw data from OSF
get_file(node = "pk4bg",
         file = "THREE_D_Biomass_Grazing_2020_March_2021.xlsx",
         path = "data/biomass",
         remote_path = "RawData/Vegetation")


biomass <- read_excel(path = "data/biomass/THREE_D_Biomass_Grazing_2020_March_2021.xlsx", 
                          col_types = c("text", "numeric", "numeric", "text", "text", "numeric", "text", "numeric", "date", rep("numeric", 6), "text", rep("numeric", 4))) %>% 
  pivot_longer(cols = c(Graminoids_g:Litter_g, Lichen_g:Fungi_g), names_to = "fun_group", values_to = "value") %>% 
  filter(grazing %in% c("M", "I"),
         !is.na(value)) %>% 
  rename(date = Date, cut = Cut, remark = Remark) %>% 
  left_join(metaTurfID, by = c("destSiteID", "destBlockID", "destPlotID", "turfID", "warming", "Nlevel", "grazing")) %>% 
  mutate(year = year(date))

write_csv(biomass, path = "data_cleaned/vegetation/THREE-D_Biomass_2020.csv")

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
