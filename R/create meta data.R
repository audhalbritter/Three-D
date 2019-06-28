###################################
### CREATE TURFID AND RANDOMIZE ###
###################################

source("R/Load packages.R")

# make meta data

origSiteID <-  c("Lia", "Joa")
destSiteID <-  c("Lia", "Joa", "Vik")
origBlockID <-  c(1:10)
destBlockID <-  c(1:10)
origPlotID <- tibble(plotID = rep(1:160))
warming <-  c("A", "W")
grazing <-  c("C", "M", "I", "N")
set.seed(32)
nitrogen <- tibble(Nlevel = rep(rep(sample(1:10, 10), each = 8), 2))

meta <- crossing(origSiteID, origBlockID, warming, grazing) %>% 
  bind_cols(nitrogen) %>% 
  mutate(origSiteID = factor(origSiteID, levels = c("Lia", "Joa"))) %>% 
  arrange(origSiteID)

  
ExperimentalDesign <- meta %>% 
  mutate(fence = if_else(grazing == "N", "out", "in")) %>% 
  group_by(origBlockID, origSiteID, Nlevel, fence) %>%
  sample_frac() %>% 
  ungroup() %>% 
  select(-fence) %>% 
  bind_cols(origPlotID)

write_xlsx(ExperimentalDesign, path = "ExperimentalDesign.xlsx", col_names = TRUE)
  
  
#Old code
nitrogen <- tibble(nitrogen = rep(rep(sample(1:10, 10), each = 2), 2))
meta <- crossing(origSiteID, blockID, warming, Nlevel) %>% 
  arrange(origSiteID, blockID, Nlevel) %>% 
  bind_cols(nitrogen) %>% 
  select(-Nlevel) %>% 
  crossing(grazing) %>% 
  mutate(turfID = paste0(origSiteID, blockID, warming, nitrogen, grazing)) %>% 
  mutate(destSiteID = case_when(origSiteID == "Lia" & warming == "A" ~ "Lia",
                                origSiteID == "Lia" & warming == "W" ~ "Joa",
                                origSiteID == "Joa" & warming == "A" ~ "Joa",
                                origSiteID == "Joa" & warming == "W" ~ "Vik"))

# randomize the grazing treatments and nitrogen level, within site, climate and block. Natural grazing plots are separate.
ExperimentalDesign <- meta %>% 
  mutate(sorter = if_else(grazing == "N", "out", "in")) %>% 
  group_by(blockID, destSiteID, sorter) %>%
  sample_frac() %>% 
  group_by(destSiteID, blockID, warming) %>%
  select(-sorter) %>% 
  bind_cols(plotID)
