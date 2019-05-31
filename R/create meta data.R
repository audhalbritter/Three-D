###################################
### CREATE TURFID AND RANDOMIZE ###
###################################

library("tidyverse")
library("writexl")

pn <- . %>% print(n = Inf)

# make meta data
set.seed(32)

origSiteID <-  c("Joa", "Lia")
blockID <-  c(1,2,3,4,5)
plotID <- tibble(plotID = rep(1:16, 10))
warming <-  c("A", "W")
Nlevel <- c("N1", "N2")
grazing <-  c("C", "M", "I", "N")

#nitrogen <- tibble(nitrogen = replicate(n = 4, sample(1:10, 10), simplify = FALSE) %>% unlist())

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

write_xlsx(ExperimentalDesign, path = "ExperimentalDesign.xlsx", col_names = TRUE)
