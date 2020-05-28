library("vegan")

cover_wide <- cover %>%
  ungroup() %>% 
  pivot_wider(names_from = Species, values_from = Cover, values_fill = list(Cover = 0)) 

cover_wide_spp <- cover_wide %>% 
  select(`Achillea millefolium`:`Cerastium fontana`)

set.seed(32)
NMDS <- metaMDS(comm = cover_wide_spp, 
                distance = "bray",
                noshare = TRUE,
                try = 30)

fNMDS <- fortify(NMDS) %>% 
  filter(Score == "sites") %>%
  bind_cols(cover_wide %>% select(origSiteID:Year))



## Calculate responses
cover %>% 
  group_by(turfID, origBlockID, origSiteID) %>%  
  summarise(richness = n(),
            diversity = diversity(Cover), 
            evenness = diversity/log(richness),
            sumCover = sum(Cover)
            #propGraminoid = sum(cover[functionalGroup %in% c("gramineae", "sedge")])/sumCover,
            #total_vascular = first(totalVascular),
            #vegetationHeight = mean(vegetationHeight)
  ) %>% 
  group_by(origSiteID) %>% 
  summarise(mean(richness))
