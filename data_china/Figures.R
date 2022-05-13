# cover
cover %>% 
  filter(!is.na(cover),
         functional_group != "shrub") %>% # unknown seedlings
  #filter(!Nlevel %in% c(3, 2)) %>% 
  left_join(NitrogenDictionary, by = "Nlevel") %>%
  group_by(turfID, origBlockID, origSiteID, warming, grazing, Namount_kg_ha_y, functional_group, year) %>%
  summarise(cover = sum(cover, na.rm = TRUE)) %>% 
  pivot_wider(names_from = year, values_from = cover) %>% 
  mutate(delta = `2021` - `2019`,
         origSiteID = recode(origSiteID, "H" = "High", "M" = "Middle"),
         origSiteID = factor(origSiteID, levels = c("High", "Middle")),
         warming = recode(warming, "A" = "Ambient", "W" = "Warming"),
         grazing = factor(grazing, levels = c("C", "M", "I", "N")),
         grazing = recode(grazing, "C" = "Control", "M" = "Medium", "I" = "Intensive", "N" = "Natural")) %>% 
  #filter(functional_group %in% c("forb", "graminoid")) %>% 
  ggplot(aes(x = (Namount_kg_ha_y), y = delta, colour = functional_group, linetype = warming, shape = warming)) +
  geom_point() +
  geom_smooth(method = "lm", se = FALSE) +
  labs(x = "Nitrogen in kg ha^-1, y^-1", y = "Cover") +
  scale_colour_manual(name = "Func. group", values = c("plum4", "limegreen")) +
  scale_shape_manual(name = "warming", values = c(16, 1)) +
  facet_grid(origSiteID ~ grazing) +
  theme_minimal()


cover %>% 
  filter(!is.na(cover)) %>% # unknown seedlings
  #filter(!Nlevel %in% c(3, 2)) %>% 
  left_join(NitrogenDictionary, by = "Nlevel") %>%
  group_by(turfID, origBlockID, origSiteID, year, warming, grazing, Namount_kg_ha_y) %>%
  summarise(richness = n()) %>% 
  pivot_wider(names_from = year, values_from = richness) %>% 
  mutate(delta = `2021` - `2019`,
         origSiteID = recode(origSiteID, "H" = "High", "M" = "Middle"),
         origSiteID = factor(origSiteID, levels = c("High", "Middle")),
         warming = recode(warming, "A" = "Ambient", "W" = "Warming"),
         grazing = factor(grazing, levels = c("C", "M", "I", "N")),
         grazing = recode(grazing, "C" = "Control", "M" = "Medium", "I" = "Intensive", "N" = "Natural")) %>% 
  ggplot(aes(x = Namount_kg_ha_y, y = delta, colour = warming, linetype = warming)) +
  geom_point() +
  geom_smooth(method = "lm", se = FALSE) +
  labs(x = "Nitrogen in kg ha^-1, y^-1", y = "Difference in richness (2021 - 2019)") +
  scale_colour_manual(name = "Warming", values = c("light blue", "orange")) +
  scale_linetype_manual(name = "Warming", values = c("dashed", "solid")) +
  facet_grid(origSiteID ~ grazing) +
  theme_minimal()
