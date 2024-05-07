### SOIL CN data
# load packages
source("R/Load packages.R")

# make meta data
source("R/Rgathering/create meta data.R")



meta <- read_xlsx(path = "data/soil/THREE-D_soil_CN_sample_2022.xlsx") |> 
  mutate(turfID = if_else(turfID == "159 WN2C 199", "158 WN2C 199", turfID))

soilCN_22_raw <- read_xlsx(path = "data/soil/CN resultater Aud_22.xlsx") |> 
  # remove test data
  filter(!Name %in% c("RunIn", "Test", "Blank", "acetanilid")) |> 
  mutate(Name = as.numeric(Name))


soil_CN_22 <- meta |> 
  left_join(soilCN_22_raw, by = c("Eppendorf_ID" = "Name")) |> 
  select(sample_ID = Eppendorf_ID, destSiteID = Site, destBlockID = Block, turfID, N_percentage = `N%`, C_percentage = `C%`, CN_ratio = `C/N ratio`) |> 
  mutate(destBlockID = as.numeric(str_remove(destBlockID, "B"))) |> 
  left_join(metaTurfID, by = c("destSiteID", "destBlockID", "turfID")) |> 
  select(origSiteID, origBlockID, origPlotID, warming:Nlevel, destSiteID, destBlockID, destPlotID, turfID, sample_ID, N_percentage:CN_ratio)


soil_CN_22 |> 
  ggplot(aes(x = Nlevel, y = C_percentage, pch = warming, colour = warming)) +
  geom_point() +
  geom_smooth(method = "lm") +
  scale_color_manual(values = c("grey", "red")) +
  facet_grid(origSiteID ~ grazing, scales = "free_y")


soil_CN_22 |> 
  ggplot(aes(x = Nlevel, y = N_percentage, pch = warming, colour = warming)) +
  geom_point() +
  geom_smooth(method = "lm") +
  scale_color_manual(values = c("grey", "red")) +
  facet_grid(origSiteID ~ grazing, scales = "free_y")
