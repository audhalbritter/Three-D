# Clean PRS probes

source("R/Load packages.R")
source("R/Rgathering/create meta data.R")


# read in data
prs_raw <- read_excel(path = "data/soil/ThreeD_raw_PRSresults_2021.xlsx", skip = 4) %>% 
  filter(`WAL #` != "Method Detection Limits (mdl):") %>% 
  rename(ID = `Sample ID`)

# detection limits for the elements
detection_limit <- read_excel(path = "data/soil/ThreeD_raw_PRSresults_2021.xlsx", skip = 4) %>% 
  slice(1) %>% 
  select(`NO3-N`:Cd) %>% 
  pivot_longer(cols = everything(), names_to = "elements", values_to = "detection_limit")

# sample IDs and meta data
meta <- read_excel(path = "data/soil/PRS_probes_sampleID.xlsx") %>% 
  filter(turfID != "blank")



prs_data <- metaTurfID %>% 
  inner_join(meta, by = c("destSiteID", "destBlockID", "turfID")) %>% 
  left_join(prs_raw, by = "ID") %>% 
  select(origSiteID:turfID, burial_date = `Burial Date`, retrieval_date = `Retrieval Date`, `NO3-N`:Cd, Notes) %>% 
  mutate(burial_date = ymd(burial_date),
         retrieval_date = ymd(retrieval_date),
         burial_length = retrieval_date - burial_date) %>% 
  pivot_longer(cols = `NO3-N`:Cd, names_to = "elements", values_to = "value") %>% 
  left_join(detection_limit, by = "elements") %>% 
  # remove values below detection limit
  filter(value > detection_limit) %>% 
  #left_join(NitrogenDictionary, by = "Nlevel") %>% 
  select(origSiteID:turfID, Namount_kg_ha_y, burial_length, elements, value, detection_limit, burial_date, retrieval_date, Notes)

write_csv(prs_data, file = "data_cleaned/soil/THREE-D_clean_nutrients_2021.csv")
  


### PRS probe report

prs_plot <- prs_data %>% 
  filter(!elements %in% c("Cu", "Pb")) %>% 
  mutate(warming = recode(warming, "A" = "ambient", "W" = "warm"),
         grazing = recode(grazing, "C" = "ungrazed", "I" = "intensive", "M" = "medium"),
         elements = factor(elements, levels = c("Ca", "NO3-N", "NH4-N", "K", "Mg", "P", "Mn", "S", "Zn", "Al", "Fe", "B"))) %>% 
  ggplot(aes(x = Namount_kg_ha_y, y = value, 
             colour = warming, shape = grazing,
             linetype = grazing)) +
  geom_point() +
  geom_smooth(method = "lm", se = FALSE) +
  labs(y = expression("Available soil nutrients (μg/10cm2/35 days)"),
       x = expression("Nitrogen addition (kg " *N*"/ha/y)")) +
  scale_color_manual(name = "temperature", values = c("grey", "red")) +
  scale_shape_manual(values = c(15, 16, 1)) +
  scale_linetype_manual(values = c("solid", "dashed", "dotted")) +
  facet_wrap( ~ elements, scales = "free_y")

ggsave(prs_plot, filename = "Pics/prs_plot.jpeg", dpi = 150, width = 10, height = 8)

library(broom)
prs_data %>%
  filter(!elements %in% c("Cu", "Pb")) %>% 
  mutate(warming = recode(warming, "A" = "ambient", "W" = "warm"),
         warming = factor(warming, levels = c("ambient", "warm"))) %>% 
  group_by(elements, grazing) %>%
  nest() %>%
  mutate(model = map(data, ~ lm(value ~ Namount_kg_ha_y * warming, data = .,)),
         result = map(model, tidy)) %>%
  unnest(result) %>% 
  filter(p.value <= 0.05, term != "(Intercept)") %>% 
  arrange(elements)
