library("tidyverse")
library("vegan")
library("ggvegan")

cover <- read_csv(file = "data/community/THREE-D_Cover_2019.csv")
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


ggplot(fNMDS, aes(x = NMDS1, y = NMDS2, shape = origSiteID, colour = origSiteID)) +
  geom_point() +
  coord_equal() +
  scale_colour_manual(values = treat_colours, limits = levels(cover_fat$TTtreat), labels=c("Control", "Local transplant", "Transplant", "OTC")) +
  scale_fill_manual(values = treat_colours, limits = levels(cover_fat$TTtreat), labels=c("Control", "Local transplant", "Transplant", "OTC")) +
  scale_shape_manual(values = c(24, 22, 23, 25), limits = levels(cover_fat$originSiteID), labels=c("High alpine", "Alpine", "Middle", "Low")) +
  guides(shape = guide_legend(override.aes = list(fill = "black"))) +
  labs(colour = "Treatment", fill = "Treatment", shape = "Site", size = "Year") 


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
