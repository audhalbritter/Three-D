# Clean decomposition data

source("R/Load packages.R")
source("R/Rgathering/create meta data.R")


decomposition_raw <- read_excel("data/decomposition/ThreeD_raw_decomposition_2021-11-19.xlsx", sheet = "Teabag ID, weight, depth") %>% 
  rename(pre_date_weighed = 'date_weighed...7',
         pre_weight_of = 'weight_of...8',
         post_date_weighed = 'date_weighed...11',
         post_weight_of = 'weight_of...12')


meta <- read_excel("data/decomposition/ThreeD_raw_decomposition_2021-11-19.xlsx", sheet = "Plot + teabag info") %>% 
  select(destSiteID = site, destBlockID = blockID, turfID = plotID, fall_ID = tb.ID.fall21, fall_burialdate = tb.fall21.dateburied, spring_ID = tb.ID.spring22, spring_burialdate = tb.spring22.dateburied, comment) %>% 
  mutate(fall_burialdate = ymd(fall_burialdate),
         spring_burialdate = ymd(spring_burialdate),
         destSiteID = recode(destSiteID, JOA = "Joa", VIK = "Vik", LIA = "Lia")) %>% 
  pivot_longer(cols = c(fall_ID, spring_ID, fall_burialdate, spring_burialdate), 
               names_to = c("timing", ".value"), 
               names_pattern = "(.*)_(.*)") %>% 
  select(destSiteID:turfID, teabag_ID = ID, timing, burial_date = burialdate) %>% 
  # just for now!!!
  filter(timing == "fall")


decomposition <- decomposition_raw %>% 
  mutate(comment_2 = tolower(comment_2),
         weight_comment = str_extract(comment_2, "no string"),
         comment_3 = if_else(str_detect(comment_2, "wrong number"), comment_2, NA_character_),
         comment_2 = case_when(str_detect(comment_2, "holes in the teabag") ~ "holes in the teabag",
                               str_detect(comment_2, "little|small") ~ "small hole",
                               str_detect(comment_2, "big") ~ "big hole",
                               str_detect(comment_2, "totally|empty|completely|completly|no teabag") ~ "totally destroyed",
                               TRUE ~ NA_character_)) %>% 
  # remove spring 2022 bags
  tidylog::filter(!is.na(post_date_weighed)) %>% 
  # DO THESE NEED REMOVING?
  #tidylog::filter(comment_2 == "totally destroyed") %>% 
  mutate(preburial_weight_g = as.numeric(preburial_weight_g),
         post_burial_weight_g = as.numeric(post_burial_weight_g))
# need to adjust for loss of string and label
  

metaTurfID %>% 
  left_join(meta, by = c("destSiteID", "destBlockID", "turfID")) %>% 
  inner_join(decomposition, by = c("teabag_ID"))
  





  
