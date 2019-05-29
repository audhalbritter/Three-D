###################################
### CREATE TURFID AND RANDOMIZE ###
###################################

library("tidyverse")
library("writexl")

# make meta data
set.seed(32)

origSite <-  c("Joa", "Lia")
block <-  c(1,2,3,4,5)
climate <-  c("A", "W")
Nlevel <- c("N1", "N2")
grazing <-  c("C", "M", "I", "N")

nitrogen <- tibble(nitrogen = replicate(n = 4, sample(1:10, 10), simplify = FALSE) %>% unlist()) 

meta <- crossing(origSite, block, climate, Nlevel) %>% 
  arrange(origSite, climate, block) %>% 
  bind_cols(nitrogen) %>% 
  select(-Nlevel) %>% 
  crossing(grazing) %>% 
  mutate(turfID = paste0(origSite, block, climate, nitrogen, grazing))

# randomize the grazing treatments and nitrogen level, within site, climate and block. Natural grazing plots are separate.

ExperimentalDesign <- meta %>% 
  mutate(sorter = if_else(grazing == "N", "out", "in")) %>% 
  group_by(origSite, block, climate, sorter) %>%
  sample_frac() %>% 
  group_by(origSite, block, climate) %>%
  select(-sorter) %>% 
  mutate(plotID = 1:8)

write_xlsx(ExperimentalDesign, path = "ExperimentalDesign.xlsx", col_names = TRUE)
