#### NDVI DATA ####
source("R/Rgathering/create meta data.R")

# Read in ndvi data
ndvi.raw1 <- read_csv(file = "data/ndvi/THREE-D_NDVI_2020_joseph.csv") %>% 
  left_join(metaTurfID, by = c("destSiteID", "destBlockID", "turfID")) %>% 
  rename(measurement = nr) %>% 
  mutate(date = dmy(date))

ndvi <- read_csv(file = "data/ndvi/THREE-D_NDVI_2020_aud.csv") %>% 
  select(origSiteID:timing) %>% 
  mutate(date = dmy(date)) %>% 
  bind_rows(ndvi.raw1) %>% 
  # fix wrong data (comma forgotten)
  mutate(ndvi = if_else(ndvi > 1, ndvi/100, ndvi)) %>% 
  filter(!is.na(ndvi))

### NEEED TO MERGE WITH CUTTING DATE FROM BIOMASS TO SORT INTO BEFORE/AFTER CLIPPING !!!


ndvi %>% filter(is.na(date))
ndvi %>% filter(destSiteID == "Lia") %>% distinct(date, timing, destSiteID)

# Check data
ndvi %>% 
  filter(campaign == 3) %>% 
  ggplot(aes(x = factor(Nlevel), y = ndvi, fill = warming)) +
  geom_boxplot() +
  facet_grid( ~ origSiteID)
