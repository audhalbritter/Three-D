### analysis




# biomass
biomass_clean |> 
  group_by(year, grazing) |> 
  summarise(sum = sum(biomass))

bio <- biomass_clean |> 
  group_by(year, turfID, origSiteID, destSiteID, destBlockID, destPlotID, warming, grazing, Namount_kg_ha_y) |> 
  summarise(biomass = sum(biomass)) |>
  mutate(grazing_num = case_when(grazing == "C" ~ 0,
                                 grazing == "M" ~ 2,
                                 grazing == "I" ~4))

library(broom)
bio |> 
  group_by(year, origSiteID) |> 
  nest() |> 
  mutate(fit = map(data, ~lm(data = ., biomass ~ warming*Namount_kg_ha_y*grazing_num)),
         result = map(fit, tidy)) |> 
  unnest(result) |> 
  filter(p.value <= 0.05)
  
  
  






comm_structure_clean |> 
  group_by(origSiteID, variable, functional_group) |> 
  summarise(mean = mean(value, na.rm = TRUE),
            se = sd(value, na.rm = TRUE)/sqrt(n()),
            min = min(value, na.rm = TRUE),
            max = max(value, na.rm = TRUE)) |> 
  arrange(variable, functional_group) |> 
  print(n = Inf)
library(broom)
comm_structure_clean |> 
  filter(!functional_group %in% c("wool")) |> 
  group_by(functional_group) |> 
  nest() |> 
  mutate(model = map(data, ~lm(value ~ origSiteID, data = .)),
         result = map(model, tidy),
         anova = map(model, car::Anova),
         anova_tidy = map(anova, tidy)) |> 
  unnest(anova_tidy)
dd <- comm_structure_clean |> 
  filter(!functional_group %in% c("lichen"))
fit <- lm(value ~ origSiteID, data = dd)
anova(fit)
ggplot(comm_structure_clean, aes(x = origSiteID, y = value)) +
  geom_boxplot() +
  facet_wrap( ~ functional_group, scales = "free")

# soil
soil_character |> 
  group_by(variable, destSiteID) |> 
  summarise(mean = mean(value),
            se = sd(value)/sqrt(n()),
            min = min(value),
            max = max(value))

cn_clean |> 
  group_by(variable, destSiteID) |> 
  summarise(mean = mean(value),
            se = sd(value)/sqrt(n()),
            min = min(value),
            max = max(value)) |> 
  print(n = Inf)

dd <- cn_clean |> 
  filter(variable == "soil_organic_matter",
         year == 2021) |> 
  mutate(destSiteID = factor(destSiteID, levels = c("Vikesland", "Joasete", "Liahovden")))
fit <- lm(value ~ destSiteID, dd)
summary(fit)


# decomposition
tbi_index |> 
  group_by(timing) |> 
  summarise(ming = min(fraction_remaining_green, na.rm = TRUE), maxg = max(fraction_remaining_green, na.rm = TRUE),
            minr = min(fraction_remaining_red, na.rm = TRUE), maxr = max(fraction_remaining_red, na.rm = TRUE),
            meank = mean(k, na.rm = TRUE), mink = min(k, na.rm = TRUE), maxk = max(k, na.rm = TRUE),
            meanS = mean(S, na.rm = TRUE), minS = min(S, na.rm = TRUE), maxS = max(S, na.rm = TRUE))


fit <- lm(k ~ origSiteID*timing, tbi_index)
summary(fit)
fit <- lm(S ~ origSiteID*timing, tbi_index)
summary(fit)
