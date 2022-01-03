# Clean decomposition data

source("R/Load packages.R")
source("R/Rgathering/create meta data.R")

# mean weight of string & label
string_and_label <- mean(c(0.09177, 0.10385, 0.11177, 0.09002, 0.07527))


decomposition_raw <- read_excel("data/decomposition/ThreeD_raw_decomposition_2021-11-19.xlsx", sheet = "Teabag ID, weight, depth") %>% 
  rename(pre_date_weighed = 'date_weighed...7',
         pre_weight_of = 'weight_of...8',
         post_date_weighed = 'date_weighed...11',
         post_weight_of = 'weight_of...12')


meta <- read_excel("data/decomposition/ThreeD_raw_decomposition_2021-11-19.xlsx", sheet = "Plot + teabag info") %>% 
  select(destSiteID = site, destBlockID = blockID, turfID = plotID, fall_ID = tb.ID.fall21, fall_burialdate = tb.fall21.dateburied, fall_recoverdate = tb.fall21.dateretrieved, spring_ID = tb.ID.spring22, spring_burialdate = tb.spring22.dateburied, comment) %>% 
  mutate(fall_burialdate = ymd(fall_burialdate),
         fall_recoverdate = ymd(fall_recoverdate),
         spring_burialdate = ymd(spring_burialdate),
         destSiteID = recode(destSiteID, JOA = "Joa", VIK = "Vik", LIA = "Lia")) %>% 
  pivot_longer(cols = c(fall_ID, spring_ID, fall_burialdate, fall_recoverdate, spring_burialdate), 
               names_to = c("timing", ".value"), 
               names_pattern = "(.*)_(.*)") %>% 
  select(destSiteID:turfID, teabag_ID = ID, timing, burial_date = burialdate, recover_date = recoverdate) %>% 
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
  # fix burial depth
  mutate(tb_depth_cm = case_when(tb_depth_cm == "6,0/5,0" ~ "5.5",
                                 tb_depth_cm == "4,0/5,0" ~ "4.5",
                                 TRUE ~ tb_depth_cm),
         tb_depth_cm = as.numeric(tb_depth_cm)) %>% 
  # remove spring 2022 bags for now!!!
  tidylog::filter(!is.na(post_date_weighed)) %>% 
  # remove completely destroyed teabags.
  tidylog::filter(!comment_2 %in% c("totally destroyed")) %>% 
  mutate(preburial_weight_g = as.numeric(preburial_weight_g),
         post_burial_weight_g = as.numeric(post_burial_weight_g),
         # adjust weight for teabags that have lost string and label
         post_burial_weight_g = if_else(!is.na(weight_comment), post_burial_weight_g - string_and_label, post_burial_weight_g)) %>% 
  mutate(tea_type = recode(tea_type, "R" = "red", "G" = "green"))

  

decomposition <- metaTurfID %>% 
  left_join(NitrogenDictionary, by = "Nlevel") %>% 
  left_join(meta, by = c("destSiteID", "destBlockID", "turfID")) %>% 
  inner_join(decomposition, by = c("teabag_ID")) %>% 
  mutate(weight_loss_g = preburial_weight_g - post_burial_weight_g,
         incubation_time = recover_date - burial_date) %>% 
  #incubation_time = yday(recover_date) - yday(burial_date))
  tidylog::filter(!is.na(weight_loss_g)) %>% 
  select(origSiteID:Namount_kg_ha_y, teabag_ID, timing, tea_type, weight_loss_g, incubation_time, burial_depth_cm = tb_depth_cm, burial_date, preburial_weight_g, recover_date, post_burial_weight_g, comment_2)
  
write_csv(decomposition, file = "data_cleaned/decomposition/ThreeD_clean_decomposition_fall_2021.csv")

# Check data
decomposition %>% 
  ggplot(aes(x = Namount_kg_ha_y, y = weight_loss_g, shape = warming, color = tea_type)) +
  geom_point() +
  scale_color_manual(values = c("green", "red")) +
  scale_shape_manual(values = c(1, 16)) +
  facet_grid(origSiteID ~ grazing)
 





  
