#### NDVI DATA ####

source("R/Load packages.R")
source("R/Rgathering/create meta data.R")

# Download raw data from OSF
get_file(node = "pk4bg",
         file = "THREE-D_NDVI_2020_aud.csv",
         path = "data/reflectance",
         remote_path = "RawData/Vegetation")

get_file(node = "pk4bg",
         file = "THREE-D_NDVI_2020_joseph.csv",
         path = "data/reflectance",
         remote_path = "RawData/Vegetation")


# Read in ndvi data
ndvi.raw1 <- read_csv(file = "data/ndvi/THREE-D_NDVI_2020_joseph.csv") %>% 
  left_join(metaTurfID, by = c("destSiteID", "destBlockID", "turfID")) %>% 
  rename(measurement = nr) %>% 
  mutate(date = dmy(date))

ndvi <- read_csv(file = "data/ndvi/THREE-D_NDVI_2020_aud.csv") %>% 
  select(origSiteID:timing) %>% 
  mutate(date = dmy(date),
         year = year(date)) %>% 
  bind_rows(ndvi.raw1) %>% 
  # fix wrong data (comma forgotten)
  mutate(ndvi = if_else(ndvi > 1, ndvi/100, ndvi)) %>% 
  # remove empty rows
  filter(!is.na(ndvi)) %>% 
  # convert campaign nr to timing
  mutate(timing = case_when(origSiteID %in% c("Joa", "Lia") & campaign == 2 ~ "After 1. cut",
                            origSiteID == "Lia" & campaign == 3 ~ "After 1. cut",
                            origSiteID == "Vik" & campaign == 2 ~ "After 2. cut",
                            origSiteID %in% c("Joa", "Vik") & campaign == 3 ~ "After 2. cut",
                            campaign == 4 ~ "After 3. cut",
                            TRUE ~ timing))
  

# save clean data file
write_csv(ndvi, path = "data_cleaned/Vegetation/THREE-D_Reflectance_2020.csv")


# Check data
ndvi %>% 
  filter(timing == c("After 3. cut")) %>% 
  ggplot(aes(x = factor(Nlevel), y = ndvi, fill = warming)) +
  geom_boxplot() +
  facet_grid( ~ origSiteID)


