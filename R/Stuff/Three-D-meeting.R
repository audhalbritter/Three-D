# ThreeD meeting 2021


ndvi <- read_csv(file = "data_cleaned/vegetation/THREE-D_Reflectance_2020.csv")
library("Hmisc")
# reflectance
# before after cutting
ndvi_aw <- ndvi %>% 
  filter(origSiteID == "Lia",
         timing %in% c("After 4. cut")) %>% 
  left_join(NitrogenDictionary, by = "Nlevel") %>% 
  ggplot(aes(x = factor(Namount_kg_ha_y), y = ndvi, fill = warming)) +
  geom_boxplot() +
  scale_fill_manual(values = c("grey", "red"), name = "", labels = c("Ambient", "Warming")) +
  labs(title = "End of growing season", x = expression(paste("Nitrogen in kg ", ha^-1, y^-1)), y = "Reflectance") +
  theme_minimal() +
  theme(text = element_text(size = 15))

ggsave(ndvi_aw, filename = "ndvi_aw.png", height = 6, width = 8)


# high vs low site and effect of warming and nitrogen
site.labs <- c("Alpine", "High alpine")
names(site.labs) <- c("Joa", "Lia")
ndvi_site <- ndvi %>% 
  filter(campaign == 3) %>% 
  left_join(NitrogenDictionary, by = "Nlevel") %>% 
  ggplot(aes(x = factor(Namount_kg_ha_y), y = ndvi, fill = warming)) +
  geom_boxplot() +
  scale_fill_manual(values = c("light blue", "orange"), name = "", labels = c("Ambient", "Warming")) +
  labs(x = expression(paste("Nitrogen in kg ", ha^-1, y^-1)), y = "Reflectance") +
  facet_grid( ~ origSiteID, labeller = labeller(origSiteID = site.labs)) +
  theme_minimal() +
  theme(text = element_text(size = 15))

ggsave(ndvi_site, filename = "ndvi_site.png", height = 6, width = 8)


biomass <- read_excel(path = "data/biomass/THREE_D_Biomass_Grazing_2020_Feb_2021.xlsx")


biomass %>% 
  select(turfID, destSiteID, fun_group, grazing, warming, cut, value) %>% 
  arrange(-value, destSiteID, grazing, warming) %>% 
  print(n = 40)
  
biomass %>% 
  filter(fun_group == "Graminoids_g", destBlockID == 3) %>% 
  select(turfID, destSiteID, grazing, warming, cut, value) %>% 
  arrange(destSiteID, grazing, warming) %>% 
  print(n = Inf)


biomass_plot <- biomass_sum %>% 
  mutate(warm.graz = paste(warming, grazing, sep = "_"),
         warm.graz = recode(warm.graz, A_I = 'A intensive', A_M = 'A medium', W_I = 'W intensive', W_M = 'W medium')) %>% 
  filter(!fun_group %in% c("Fungi_g")) %>% 
  left_join(NitrogenDictionary, by = "Nlevel") %>% 
  group_by(Namount_kg_ha_y, year, fun_group, origSiteID, warming, grazing, warm.graz) %>% 
  summarise(biomass = mean(sum)) %>% 
  mutate(N = as.factor(Namount_kg_ha_y),
         fun_group = factor(fun_group, levels = c("Litter_g", "Lichen_g", "Bryophytes_g", "Shrub_g", "Legumes_g", "Forbs_g", "Cyperaceae_g", "Graminoids_g"))) %>% 
  ggplot(aes(x = N, y = biomass, fill = fun_group)) +
  geom_col() +
  #geom_point(alpha = 0.6) +
  #geom_smooth(method = "lm", se = FALSE, formula = "y ~ x") +
  scale_fill_manual(values = c("peru", "orange", "tomato", "darkgreen", "plum2", "plum4", "lawngreen", "limegreen"), name = "") +
  labs(x = expression(paste("Nitrogen in kg ", ha^-1, y^-1)), y = "Biomass in g") +
  facet_grid(origSiteID ~ warm.graz, scales = "free_y", labeller = labeller(origSiteID = site.labs)) +
  theme_minimal() +
  theme(text = element_text(size = 15))
ggsave(biomass_plot, filename = "biomass_plot.png", height = 7, width = 6)


library(vegan)
CommunityStructure <- read_csv(file = "data_cleaned/vegetation/THREE-D_CommunityStructure_2019_2020.csv")
cover <- read_csv(file = "data_cleaned/vegetation/THREE-D_Cover_2019_2020.csv")

library("vegan")
library("ggvegan")
## ordination with recorder as predictor
cover_fat <- cover %>% 
  #select(-c(destSiteID:destBlockID), -c(warming:date), -file, -recorder) %>% 
  select(-date, -file, -recorder) %>% 
  spread(key = species, value = cover, fill = 0) %>% 
  mutate(origBlockID = as.factor(origBlockID),
         origPlotID = as.factor(origPlotID),
         destBlockID = as.factor(destBlockID),
         destPlotID = as.factor(destPlotID))

# meta data
cover_fat_meta <- cover_fat %>% select(origSiteID:year)
# community data
cover_fat_spp <- cover_fat %>% select(-(origSiteID:year))

# normal ordination
set.seed(32)
NMDS <- metaMDS(cover_fat_spp, noshare = TRUE, try = 30)

fNMDS <- fortify(NMDS) %>% 
  filter(Score == "sites") %>%
  bind_cols(cover_fat %>% select(origSiteID:year)) %>% 
  mutate(origSiteID = recode(origSiteID, "Lia" = "High alpine", "Joa" = "Alpine"),
         origSiteID = factor(origSiteID, levels = c("High alpine", "Alpine")),
         destSiteID = recode(destSiteID, "Lia" = "High alpine", "Joa" = "Alpine", "Vik" = "Lowland"),
         destSiteID = factor(destSiteID, levels = c("High alpine", "Alpine", "Lowland")),
         warming = if_else(year == 2019, "A", warming))

ordination <- ggplot(fNMDS, aes(x = NMDS1, y = NMDS2, shape = factor(year), colour = warming)) +
  geom_point() +
  scale_colour_manual(name = "Warming", values = c("light blue", "orange")) +
  scale_shape_manual(name = "Year", values = c(17, 16)) +
  theme_minimal()
ggsave(ordination, filename = "ordination.png", height = 6, width = 8)


richness <- cover %>% 
  filter(year == 2019) %>% 
  group_by(turfID, origBlockID, origSiteID) %>%  
  summarise(richness = n(), 
            diversity = diversity(cover), 
            evenness = diversity/log(richness)) %>% 
  pivot_longer(cols = c(richness, evenness), names_to = "metric", values_to = "value") %>%
  select(-diversity) %>% 
  mutate(metric = factor(metric, levels = c("richness", "evenness")),
         origSiteID = recode(origSiteID, "Lia" = "High alpine", "Joa" = "Alpine"),
         origSiteID = factor(origSiteID, levels = c("High alpine", "Alpine"))) %>% 
  ggplot(aes(x = origSiteID, y = value, fill = origSiteID)) +
  geom_boxplot() +
  labs(x = "", y = "") +
  scale_fill_manual(name = "Site", values = c("light blue", "orange")) +
  facet_wrap(~ metric, scales = "free_y") +
  theme_minimal()
ggsave(richness, filename = "richness.png", height = 4, width = 6)


height <- CommunityStructure %>% 
  select(-year.y) %>% 
  rename(year = year.x) %>% 
  filter(year == 2019) %>% 
  group_by(turfID, origBlockID, origSiteID, functional_group) %>%  
  summarise(height = mean(height), 
            cover = mean(cover)) %>% 
  mutate(origSiteID = recode(origSiteID, "Lia" = "High alpine", "Joa" = "Alpine"),
         origSiteID = factor(origSiteID, levels = c("High alpine", "Alpine"))) %>%
  ggplot(aes(x = origSiteID, y = height, fill = origSiteID)) +
  geom_boxplot()  +
  scale_fill_manual(name = "Site", values = c("light blue", "orange")) +
  theme_minimal()
ggsave(height, filename = "height.png", height = 4, width = 6)


CommunityStructure %>% 
  select(-year.y) %>% 
  rename(year = year.x) %>% 
  filter(year == 2019) %>% 
  group_by(turfID, origBlockID, origSiteID, functional_group) %>%  
  summarise(height = mean(height), 
            cover = mean(cover)) %>% 
  mutate(origSiteID = recode(origSiteID, "Lia" = "High alpine", "Joa" = "Alpine"),
         origSiteID = factor(origSiteID, levels = c("High alpine", "Alpine"))) %>%
  ggplot(aes(x = origSiteID, y = cover, fill = origSiteID)) +
  geom_boxplot()  +
  scale_fill_manual(name = "Site", values = c("light blue", "orange")) +
  facet_wrap(~ functional_group, scales = "free_y") +
  theme_minimal()




soil <- read_delim(file = "data_cleaned/soil/THREE-D_Soil_2019-2020.csv", delim = ",")
meta <- read_csv(file ="data_cleaned/soil/THREE-D_PlotLevel_Depth_2019.csv")

  

soil_plot <- soil %>% 
  left_join(meta %>% 
              mutate(destBlockID = as.character(destBlockID)) %>% 
              group_by(destSiteID, destBlockID, year) %>% 
              summarise(soil_depth_cm = mean(soil_depth_cm)), 
            by = c("destSiteID", "destBlockID", "year")) %>%
  pivot_longer(cols = c(pH, bulk_density_g_cm, soil_organic_matter, soil_depth_cm, C_percent, N_percent), 
               names_to = "variable", values_to = "value") %>% 
  mutate(variable = factor(variable, levels = c("soil_depth_cm", "bulk_density_g_cm", "pH", "soil_organic_matter", "C_percent", "N_percent")),
         Site = recode(destSiteID, Lia = "High alpine", Joa = "Alpine", Vik = "Lowland"),
         Site = factor(Site, levels = c("High alpine", "Alpine", "Lowland")),
         layer = factor(layer, levels = c("Top", "Bottom")),
         value = if_else(variable == "soil_depth_cm" & layer == "Bottom", NA_real_, value)) %>% 
  filter(!is.na(value)) %>% 
  ggplot(aes(x = Site, y = value, fill = layer)) +
  geom_boxplot() +
  scale_fill_manual(name = "", values = c("rosybrown1", "rosybrown")) +
  labs(x = "", y = "") +
  facet_wrap(~ variable, scales = "free_y") +
  theme_minimal() +
  theme(legend.position = "top")
ggsave(soil_plot, filename = "soil.png", height = 4, width = 6)



