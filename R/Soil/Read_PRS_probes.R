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
         retrieval_date = ymd(retrieval_date)) %>% 
  pivot_longer(cols = `NO3-N`:Cd, names_to = "elements", values_to = "value") %>% 
  left_join(detection_limit, by = "elements") %>% 
  # remove values below detection limit
  filter(value > detection_limit) %>% 
  left_join(NitrogenDictionary, by = "Nlevel")
  
prs_data %>% 
  filter(elements == "K") %>% 
  ggplot(aes(x = Namount_kg_ha_y, y = value, colour = warming)) +
  geom_point() +
  facet_grid(grazing ~ origSiteID)
