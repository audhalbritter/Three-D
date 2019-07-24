###################################
### CREATE TURFID AND RANDOMIZE ###
###################################

source("R/Load packages.R")

# make meta data

origSiteID <-  c("Lia", "Joa")
origBlockID <-  c(1:10)
origPlotID <- tibble(origPlotID = 1:160)
warming <-  c("A", "W")
grazing <-  c("C", "M", "I", "N")
#set.seed(2)
#nitrogen <- tibble(Nlevel = rep(rep(sample(1:10, 10), each = 8), 2))
nitrogen <- tibble(Nlevel = rep(rep(c(1,6,5,3,10,7,4,8,9,2), each = 8), 2))

meta <- crossing(origSiteID, origBlockID, warming, grazing) %>% 
  bind_cols(nitrogen)

# Vik
vik <- tibble(
  origSiteID = factor("Vik", levels = c("Lia", "Joa", "Vik")),
  origBlockID = rep(1:10, each = 4),
  origPlotID = 161:200,
  destSiteID = factor(NA, levels = c("Lia", "Joa", "Vik")),
  Nlevel = rep(c(1,6,5,3,10,7,4,8,9,2), each = 4),
  warming = "W",
  grazing = rep(c("notN", "notN", "notN", "N"), 10),
  fence = if_else(grazing == "N", "out", "in"))


set.seed(32)
meta2 <- meta %>% 
  mutate(fence = if_else(grazing == "N", "out", "in")) %>% 
  mutate(origSiteID = factor(origSiteID, levels = c("Lia", "Joa", "Vik"))) %>%
  arrange(origSiteID) %>% 
  group_by(origSiteID, origBlockID, Nlevel, fence) %>%
  sample_frac() %>% 
  ungroup() %>% 
  bind_cols(origPlotID) %>% 
  mutate(destSiteID = case_when(
           origSiteID == "Lia" & warming == "A" ~ "Lia",
           origSiteID == "Joa" & warming == "W" ~ "Vik",
           TRUE ~ "Joa")) %>%
  mutate(destSiteID = factor(destSiteID, levels = c("Lia", "Joa", "Vik"))) %>%
  bind_rows(vik) %>% 
  group_by(origSiteID, origBlockID, warming, fence) %>% 
  mutate(rownr = row_number())


# join the meta2 to warmed plots
ExperimentalDesign <- left_join(
  meta2 %>% filter(origPlotID < 161), # remove plots from vik
  meta2 %>% filter(warming == "W") %>% select(-grazing, -destSiteID, destPlotID = origPlotID), 
            by = c("destSiteID" = "origSiteID", "origBlockID" = "origBlockID", "rownr" = "rownr", "fence" = "fence", "Nlevel" = "Nlevel", "warming" = "warming"), 
            suffix = c("", "_dest")) %>% 
  mutate(destBlockID = origBlockID,
         destPlotID = ifelse(is.na(destPlotID), origPlotID, destPlotID),
         turfID = paste0(origPlotID, " ", warming, "N", Nlevel, grazing,  " ", destPlotID)) %>% 
  ungroup() %>% 
  select(-fence)

#write_xlsx(ExperimentalDesign, path = "ExperimentalDesign_24-7-19.xlsx", col_names = TRUE)
  
  
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
