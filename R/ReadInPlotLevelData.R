#### PLOT LEVEL META DATA ####
plotMetaData <- read_excel(path = "data/metaData/Three-D_PlotLevel_MetaData_2019.xlsx")


#### SOIL SAMPLES
soilSamples <- read_excel(path = "data/metaData/ThreeD_SoilSamples_2019.xlsx")

soilSamples %>% 
  mutate(soil550 = dry_weight_550_plus_vial_g - Vial_weight_g,
         soil950 = dry_weight_950_plus_vial_g - Vial_weight_g) %>% 
  #calculate organic content
  mutate(LOI_550 = (soil550 - dry_weight_105_g)/dry_weight_105_g * 100,
         LOI_950 = (soil950 - dry_weight_105_g)/dry_weight_105_g * 100) %>% 
  ggplot(aes(y = LOI_550, x = Site, colour  = Layer)) +
  geom_boxplot() +
  facet_wrap( ~ Site)