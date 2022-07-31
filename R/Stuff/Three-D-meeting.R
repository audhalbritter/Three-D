# ThreeD meeting 2021

source("R/Load packages.R")
source("R/Rgathering/create meta data.R")

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


biomass <- read_excel(path = "data/biomass/THREE_D_Biomass_Grazing_2020_March_2021.xlsx", 
                      col_types = c("text", "numeric", "numeric", "text", "text", "numeric", "text", "numeric", "date", rep("numeric", 6), "text", rep("numeric", 4))) %>% 
  pivot_longer(cols = c(Graminoids_g:Litter_g, Lichen_g:Fungi_g), names_to = "fun_group", values_to = "value") %>% 
  filter(grazing %in% c("M", "I"),
         !is.na(value)) %>% 
  rename(date = Date, cut = Cut, remark = Remark) %>% 
  left_join(metaTurfID, by = c("destSiteID", "destBlockID", "destPlotID", "turfID", "warming", "Nlevel", "grazing")) %>% 
  mutate(year = year(date))


biomass %>% 
  select(turfID, destSiteID, fun_group, grazing, warming, cut, value) %>% 
  arrange(-value, destSiteID, grazing, warming) %>% 
  print(n = 40)
  
biomass %>% 
  filter(fun_group == "Graminoids_g", destBlockID == 3) %>% 
  select(turfID, destSiteID, grazing, warming, cut, value) %>% 
  arrange(destSiteID, grazing, warming) %>% 
  print(n = Inf)


biomass_plot <- biomass %>% 
  mutate(year = 2020) %>% 
  bind_rows(biomass21_raw) %>% 
  filter(!Nlevel %in% c(3, 1),
         grazing %in% c("I", "M"),
         value < 200) %>%
  mutate(warm.graz = paste(warming, grazing, sep = "_"),
         warm.graz = recode(warm.graz, A_I = 'A intensive', A_M = 'A medium', W_I = 'W intensive', W_M = 'W medium'),
         warm.graz = factor(warm.graz, levels = c('A medium', 'W medium', 'A intensive', 'W intensive')),
         origSiteID = recode(origSiteID, "Lia" = "High alpine", "Joa" = "Alpine"),
         origSiteID = factor(origSiteID, levels = c("High alpine", "Alpine"))) %>% 
  filter(fun_group %in% c("Litter_g", "Forbs_g", "Graminoids_g")) %>% 
  left_join(NitrogenDictionary, by = "Nlevel") %>% 
  group_by(Namount_kg_ha_y, year, fun_group, origSiteID, warming, grazing, warm.graz) %>% # ADD YEAR
  summarise(biomass = sum(value)) %>% 
  mutate(N = as.factor(Namount_kg_ha_y),
         #fun_group = factor(fun_group, levels = c("Litter_g", "Lichen_g", "Bryophytes_g", "Shrub_g", "Legumes_g", "Forbs_g", "Cyperaceae_g", "Graminoids_g"))) %>% 
         fun_group = factor(fun_group, levels = c("Litter_g", "Forbs_g", "Graminoids_g"))) %>% 
  ggplot(aes(x = Namount_kg_ha_y, y = biomass, colour = fun_group, linetype = factor(year), shape = factor(year))) +
  geom_point() +
  #geom_point(alpha = 0.6) +
  geom_smooth(method = "lm", se = FALSE, formula = "y ~ x") +
  #scale_colour_manual(values = c("peru", "darkgreen", "plum2", "plum4", "lawngreen", "limegreen"), name = "") +
  scale_colour_manual(values = c("peru", "plum4", "limegreen"), name = "") +
  scale_shape_manual(values = c(1, 16), name = "Year") +
  scale_linetype_manual(values = c("dotted", "solid"), name = "Year") +
  labs(x = expression(paste("Nitrogen in kg ", ha^-1, y^-1)), y = "Biomass in g") +
  facet_grid(origSiteID ~ warm.graz, scales = "free_y") +
  theme_minimal() +
  theme(text = element_text(size = 15))
ggsave(biomass_plot, filename = "biomass_plot_2.png", height = 7, width = 8, bg = "white")



library(vegan)
CommunityStructure <- read_csv(file = "data_cleaned/vegetation/THREE-D_CommunityStructure_2019_2020.csv")
cover <- read_csv(file = "data_cleaned/vegetation/THREE-D_Cover_2019-2021.csv")

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


cover %>% ungroup() %>% distinct(species) %>% write_csv(file = "species_list.csv")

sp_list <- read_csv(file = "species_list.csv")

richness <- cover %>% 
  filter(!is.na(origSiteID),
         year != 2020,
         !str_detect(species, "Carex"),
         !Nlevel %in% c(3, 2)) %>% 
  left_join(NitrogenDictionary, by = "Nlevel") %>%
  ungroup() %>% 
  group_by(turfID, origBlockID, origSiteID, year, warming, grazing, Namount_kg_ha_y) %>%  
  summarise(richness = n()) %>% 
            #diversity = diversity(cover), 
            #evenness = diversity/log(richness)) %>% 
  pivot_wider(names_from = year, values_from = richness) %>% 
  mutate(delta = `2021` - `2019`,
         origSiteID = recode(origSiteID, "Lia" = "High alpine", "Joa" = "Alpine"),
         origSiteID = factor(origSiteID, levels = c("High alpine", "Alpine")),
         grazing = factor(grazing, levels = c("C", "M", "I", "N")),
         grazing = recode(grazing, "C" = "Control", "M" = "Medium", "I" = "Intensive", "N" = "Natural")) %>% 
  ggplot(aes(x = Namount_kg_ha_y, y = delta, colour = warming, linetype = origSiteID)) +
  geom_point() +
  geom_smooth(method = "lm", se = FALSE) +
  labs(x = "Nitrogen in kg ha^-1, y^-1", y = "Difference in richness (2021 - 2019)") +
  scale_colour_manual(name = "Warming", values = c("light blue", "orange")) +
  scale_linetype_manual(name = "", values = c("dashed", "solid")) +
  facet_grid(origSiteID ~ grazing) +
  theme_minimal()
ggsave(richness, filename = "richness.png", height = 4, width = 6, bg = "white")


# cover
cover_plot <- cover %>% 
  filter(year %in% c(2019, 2021), 
         !is.na(origSiteID),
         !Nlevel %in% c(3, 2)) %>% 
  left_join(NitrogenDictionary, by = "Nlevel") %>%
  left_join(sp_list, by = "species") %>%
  ungroup() %>% 
  group_by(turfID, origBlockID, origSiteID, warming, grazing, Namount_kg_ha_y, functional_group, year) %>%  
  summarise(cover = sum(cover)) %>% 
  pivot_wider(names_from = year, values_from = cover) %>% 
  mutate(delta = `2021` - `2019`,
         origSiteID = recode(origSiteID, "Lia" = "High alpine", "Joa" = "Alpine"),
    origSiteID = factor(origSiteID, levels = c("High alpine", "Alpine")),
    warming = recode(warming, "A" = "Ambient", "W" = "Warming"),
    grazing = factor(grazing, levels = c("C", "M", "I", "N")),
    grazing = recode(grazing, "C" = "Control", "M" = "Medium", "I" = "Intensive", "N" = "Natural")) %>% 
  filter(functional_group %in% c("forb", "graminoid")) %>% 
  ggplot(aes(x = Namount_kg_ha_y, y = delta, colour = functional_group, linetype = warming, shape = warming)) +
  geom_point() +
  geom_smooth(method = "lm", se = FALSE) +
  labs(x = "Nitrogen in kg ha^-1, y^-1", y = "Cover") +
  scale_colour_manual(name = "Func. group", values = c("plum4", "limegreen")) +
  scale_shape_manual(name = "warming", values = c(16, 1)) +
  facet_grid(origSiteID ~ grazing) +
  theme_minimal()
ggsave(cover_plot, filename = "cover.png", height = 4, width = 6, bg = "white")


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



