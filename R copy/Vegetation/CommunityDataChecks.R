#############################
### COMMUNITY DATA CHECKS ###
#############################

source("R/Load packages.R")
source("R/Rgathering/create meta data.R")
source("R/ReadInCommunity.R")


# Do checks
# Species names, orig/dest Site, Block and PlotID, date
community %>% distinct(Species) %>% arrange(Species) %>% pn
community %>% filter(Species %in% c("Unknown shrub, maybe salix")) %>% as.data.frame()
community %>% filter(is.na(Species)) %>% as.data.frame()

# Check if Cover is larger than max possible cover
community %>% 
  filter(!Species %in% c("Moss layer", "Vascular plant layer", "SumofCover", "Vascular plants", "Bryophytes", "Lichen", "Litter", "Bare soil", "Bare rock", "Poop", "Unknown seedlings")) %>% 
  gather(key = subplot, value = presence, "1":"25") %>% 
  filter(!is.na(presence)) %>% 
  group_by(origSiteID, origBlockID, origPlotID, Year, Species, Cover) %>% 
  summarise(n = n()) %>% 
  mutate(MaxCover = n * 4,
         UpperLimit = MaxCover * 1.2) %>% 
  filter(MaxCover < Cover)


### META COMMUNITY
ggplot(metaCommunity, aes(x = origSiteID, y = MeanCover)) +
  geom_boxplot() +
  facet_wrap(~ FunctionalGroup, scales = "free_y")
  

#### SUBPLOT DATA ####
#devtools::install_github("Between-the-Fjords/turfmapper")
library("turfmapper")

#set up subturf grid
grid <- make_grid(ncol = 5)

CommunitySubplot %>% 
    mutate(subplot = as.numeric(subplot),
           year_recorder = paste(year, recorder, sep = "")) %>% 
    filter(variable == "presence",
           destSiteID == "Vik") %>% 
  left_join(cover) |> 
  select(-scribe, -file) |> 
  arrange(destSiteID, destPlotID, turfID) %>% 
  group_by(destSiteID, destPlotID, turfID) %>% 
    nest() %>% 
    {map2(
      .x = .$data, 
      .y = glue::glue("Site {.$destSiteID}: plot {.$destPlotID}: turf {.$turfID}"),
      .f = ~make_turf_plot(
        data = .x, 
        year = year_recorder, 
        species = species, 
        cover = cover, 
        subturf = subplot, 
        title = glue::glue(.y), 
        grid_long = grid)
    )} %>% 
    walk(print)


#### REOCRDER BIAS ####

# Graminoids
cover %>% 
  filter(Species %in% c("Agrostis capillaris", "Anthoxantum odoratum", "Avenella flexuosa", "Festuca rubra", "Phleum alpinum", "Poa alpina", "Poa pratensis"),
         Nlevel %in% c(1, 2, 3)) %>% 
  mutate(Year_temp = paste(Year, warming, sep = "_")) %>% 
  ggplot(aes(x = Recorder, y = Cover, fill = warming)) +
  geom_boxplot() +
  facet_grid(Species ~ destSiteID, scales = "free_y") +
  theme_bw()

# Forbs
cover %>% 
  filter(Species %in% c("Achillea millefolium", "Bistorta vivipara", "Leontodon autumnalis", "Rumex acetosa", "Thalictrum alpinum", "Taraxacum sp."),
         Nlevel %in% c(1, 2, 3)) %>% 
  ggplot(aes(x = Recorder, y = Cover, fill = warming)) +
  geom_boxplot() +
  facet_grid(Species ~ destSiteID) +
  theme_bw()


# species richness
cover %>% 
  ungroup() %>% 
  group_by(turfID, Recorder, warming, origSiteID) %>% 
  summarise(Richness = mean(n())) %>% 
  ggplot(aes(x = Recorder, y = Richness, fill = warming)) +
  geom_point() +
  facet_grid( ~ origSiteID) +
  theme_bw()



# LDA
dat.lda <- cover %>% dplyr::select(Cover, Recorder, Species, origSiteID)
recorder.lda <- MASS::lda(Cover ~., data = dat.lda)
recorder.lda.values <- predict(recorder.lda)
newdata <- data.frame(type = dat.lda[,1], lda = recorder.lda.values$x)
ggplot(newdata) + geom_point(aes(lda.LD1, lda.LD2, colour = Recorder), size = 2.5)


library("vegan")
library("ggvegan")
## ordination with recorder as predictor
cover_fat <- cover %>% 
  select(-c(destSiteID:destBlockID), -c(warming:Year), -Remark, -file) %>% 
  spread(key = Species, value = Cover, fill = 0) %>% 
  mutate(origBlockID = as.factor(origBlockID),
         origPlotID = as.factor(origPlotID))

# meta data
cover_fat_meta <- cover_fat %>% select(origSiteID:Recorder)
# community data
cover_fat_spp <- cover_fat %>% select(-(origSiteID:Recorder))

ord <- cca(formula = cover_fat_spp ~ Recorder + Condition(origSiteID), 
           data = cover_fat_meta)
anova(ord, perm.max = 2000)


# normal ordination
set.seed(32)
NMDS <- metaMDS(cover_fat_spp, noshare = TRUE, try = 30)

fNMDS <- fortify(NMDS) %>% 
  filter(Score == "sites") %>%
  bind_cols(cover_fat %>% select(origSiteID:Recorder))

ggplot(fNMDS, aes(x = NMDS1, y = NMDS2, colour = Recorder)) +
  geom_point()







