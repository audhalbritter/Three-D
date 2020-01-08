###################################
### CREATE TURFID AND RANDOMIZE ###
###################################

source("R/Load packages.R")

# Create meta data
# Lia and Joa
origSiteID <-  c("Lia", "Joa")
origBlockID <-  c(1:10)
origPlotID <- tibble(origPlotID = 1:160)
warming <-  c("A", "W")
grazing <-  c("C", "M", "I", "N")
# Nitrogen level needs to be in a certain order
nitrogen <- tibble(Nlevel = rep(rep(c(1,6,5,3,10,7,4,8,9,2), each = 8), 2))

# cross site, block warm and grazing treatment
meta <- crossing(origSiteID, origBlockID, warming, grazing) %>% 
  bind_cols(nitrogen)

# Vik (is done separately because it is only destination site)
vik <- tibble(
  origSiteID = factor("Vik", levels = c("Lia", "Joa", "Vik")),
  origBlockID = rep(1:10, each = 4),
  origPlotID = 161:200,
  destSiteID = factor(NA, levels = c("Lia", "Joa", "Vik")),
  Nlevel = rep(c(1,6,5,3,10,7,4,8,9,2), each = 4),
  warming = "W",
  grazing = rep(c("notN", "notN", "notN", "N"), 10),
  fence = if_else(grazing == "N", "out", "in"))

# randomize warming and grazing treatment
set.seed(32) # seed is needed to replicate sample_frac
#set.seed(33) # for Chinese experiment
meta2 <- meta %>% 
  # create variable for grazing treatment inside or outside fence
  mutate(fence = if_else(grazing == "N", "out", "in")) %>% 
  mutate(origSiteID = factor(origSiteID, levels = c("Lia", "Joa", "Vik"))) %>%
  arrange(origSiteID) %>% # site needs to be arranged, because transplant goes only in one direction
  group_by(origSiteID, origBlockID, Nlevel, fence) %>%
  sample_frac() %>% # randomization
  ungroup() %>% 
  bind_cols(origPlotID) %>% # add plotID
  mutate(destSiteID = case_when(
           origSiteID == "Lia" & warming == "A" ~ "Lia",
           origSiteID == "Joa" & warming == "W" ~ "Vik",
           TRUE ~ "Joa")) %>%
  mutate(destSiteID = factor(destSiteID, levels = c("Lia", "Joa", "Vik"))) %>%
  bind_rows(vik) %>% # add Vik
  group_by(origSiteID, origBlockID, warming, fence) %>% 
  mutate(rownr = row_number())


# Join meta2 to warmed plots
metaTurfID <- left_join(
  meta2 %>% filter(origPlotID < 161), # remove plots from vik
  # only warmed plots, remove unused rows
  meta2 %>% filter(warming == "W") %>% select(-grazing, -destSiteID, destPlotID = origPlotID), 
            by = c("destSiteID" = "origSiteID", "origBlockID" = "origBlockID", "rownr" = "rownr", "fence" = "fence", "Nlevel" = "Nlevel", "warming" = "warming"), 
            suffix = c("", "_dest")) %>% 
  mutate(destBlockID = origBlockID,
         destPlotID = ifelse(is.na(destPlotID), origPlotID, destPlotID),
         turfID = paste0(origPlotID, " ", warming, "N", Nlevel, grazing,  " ", destPlotID)) %>% 
  ungroup() %>% 
  select(-fence, -rownr) %>% 
  # CHANGE PLOTID 23-103 TO 23 AMBIENT, AND 24 TO 24-103 WARMING (wrong turf was transplanted!)
  mutate(warming = ifelse(origSiteID == "Lia" & origPlotID == 23, "A", warming),
         destPlotID = ifelse(origSiteID == "Lia" & origPlotID == 23, 23, destPlotID),
         turfID = ifelse(origSiteID == "Lia" & origPlotID == 23, "23 AN5N 23", turfID),
         
         warming = ifelse(origSiteID == "Lia" & origPlotID == 24, "W", warming),
         destPlotID = ifelse(origSiteID == "Lia" & origPlotID == 24, 103, destPlotID),
         turfID = ifelse(origSiteID == "Lia" & origPlotID == 24, "24 WN5N 103", turfID)) %>% 
  mutate(destSiteID = as.character(destSiteID)) %>% 
  mutate(destSiteID = case_when(turfID == "23 AN5N 23" ~ "Lia",
                                turfID == "24 WN5N 103" ~ "Joa",
                                TRUE ~ destSiteID))

#write_xlsx(metaTurfID, path = "metaTurfID_24-7-19.xlsx", col_names = TRUE)