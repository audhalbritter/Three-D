###########################
 ### READ IN DATA ###
###########################

source("R/Load packages.R")

#### PLOT LEVEL META DATA ####
plotMeta <- read_excel(path = "data/metaData/Three-D_PlotLevel_MetaData_2019.xlsx")

#dd <- read_xlsx(path = file, sheet = 8, skip = 2, n_max = 61, col_types = "text")
#dd %>% pn
#check date for plot 88!!!

#### COMMUNITY DATA ####
### Read in files
files <- dir(path = "data/community", pattern = "\\.xlsx$", full.names = TRUE)
dat <- map_df(set_names(files), function(file) {
  file %>% 
    excel_sheets() %>% 
    set_names() %>% 
    discard(. == "CHECK") %>% 
    map_df(~ read_xlsx(path = file, sheet = .x, skip = 2, n_max = 61, col_types = "text"), .id = "sheet_name")
}, .id = "file") %>% 
  select(file:Remark) %>% 
  rename("Cover" = `%`) %>% 
  separate(col = sheet_name, into = c("origSiteID", "origBlockID", "origPlotID")) %>% 
  # Fix format
  mutate(origBlockID = as.numeric(origBlockID),
         origPlotID = as.numeric(origPlotID),
         Cover = as.numeric(Cover)) %>% 
  # Replace NA in subplot with 0 !!! not sure if this is right, give 0 and NAs...
  mutate_at(.vars = c("1":"25"), .funs = list(~ ifelse(is.na(.), 0, .)))

# Read in meta data
meta <- map_df(set_names(files), function(file) {
  file %>% 
    excel_sheets() %>% 
    set_names() %>% 
    discard(. == "CHECK") %>% 
    map_df(~ read_xlsx(path = file, sheet = .x, n_max = 1, col_types = "text"), .id = "sheet_name")
}, .id = "file") %>% 
  select(Date, origSiteID, origBlockID, origPlotID, turfID, Recorder, Scribe, sheet_name) %>% 
  separate(col = sheet_name, into = c("origSiteID2", "origBlockID2", "origPlotID2")) %>% 
  # Fix format
  mutate(Date = dmy(Date),
         Year = year(Date),
         origBlockID = as.numeric(origBlockID),
         origPlotID = as.numeric(origPlotID)) %>% 
  # Fix mistakes
  mutate(origPlotID = ifelse(Date == "2019-07-02" & origPlotID == 83 & Recorder == "silje", 84, origPlotID)) %>% 
#Date = ifelse(is.na(Date) & origBlockID == 1, "2019-07-02", Date)
  select(-origSiteID2, -origBlockID2, -origPlotID2)


# Join data and meta
# Warning message: 1 failed to parse. Ok, because one date is NA
community <- meta %>% 
  right_join(dat, by = c("origSiteID", "origBlockID", "origPlotID")) %>% 
  filter(Species != "Height / depth (cm)") %>% 
  # Fix wrong species names
  mutate(Species = recode(Species, 
                          "Bryophyes" = "Bryophytes", 
                          "Alchemilla sp." = "Alchemilla sp",
                          "Carex sp 1" = "Carex sp1",
                          "Carex sp 2" = "Carex sp2",
                          "Carex sp 3" = "Carex sp3",
                          "Cerastium cerasteoides" = "Cerastium cerastoides",
                          "Cerastium cerastoies" = "Cerastium cerastoides",
                          "Cerstium cerasteoides" = "Cerastium cerastoides",
                          "Equiseum arvense" = "Equisetum arvense",
                          "Rubus idaes" = "Rubus idaeus",
                          "Stellaria gramineae" = "Stellaria graminea",
                          "Vaccinium myrtilis" = "Vaccinium myrtillus",
                          "Total Cover (%)" = "SumofCover"))
# need to check if cover is missing!!!
# Agrostis sp 1???
# cerastium alpinum cf should be cerastoides?
community %>% distinct(Species) %>% arrange(Species) %>% pn

# Extract estimate of cover
cover <- community %>% 
  select(Date:Species, Cover, Remark) %>% 
  filter(!is.na(Cover)) %>% 
  filter(!Species %in% c("Moss layer", "Vascular plant layer", "SumofCover", "Vascular plants", "Bryophytes", "Lichen", "Litter", "Bare soil", "Bare rock", "Poop"))

# Cover of FG
dd <- community %>% 
  filter(Species %in% c("SumofCover", "Vascular plants", "Bryophytes", "Lichen", "Litter", "Bare soil", "Bare rock", "Poop")) %>% 
  # make numeric !!!
  mutate_at(.vars = c("25"), .funs = as.numeric) %>% 
  select(Date:Species, Cover, Remark)


# subplot level data
#subplotSpecies <- 
community %>% 
  filter(!Species %in% c("Moss layer", "Vascular plant layer", "SumofCover", "Vascular plants", "Bryophytes", "Lichen", "Litter", "Bare soil", "Bare rock", "Poop")) %>% 
  select(-Cover) %>% 
  gather(key = Subplot, value = Presence, -c(Date:Species, Remark)) %>% 
  filter(Presence != 0) %>% ### remove 0 or NA?!!!
  filter(Presence != "Ratio > 1.5 is wrong") %>% # not sure why this is here...
  # rename
  mutate(Presence = recode(Presence, "df" = "fd", "1j" = "j")) %>% 
  mutate(Fertile = ifelse(Presence == "f"|"fd", 1, 0),
         Dominant = ifelse(Presence == "d"|"fd"|"dj", 1, 0),
         Juvenile = ifelse(Presence == "j"|"dj", 1, 0),
         Seedling = ifelse(Presence == "s"|"Unknown seedlings", 1, 0))



library("vegan")
library("ggvegan")

## ordination
cover_fat <- cover %>% 
  select(-Date, -Year, -turfID, -Recorder, -Scribe, -file, -Remark) %>% 
  spread(key = Species, value = Cover, fill = 0) %>% 
  mutate(origBlockID = as.factor(origBlockID))

cover_fat_spp <- cover_fat %>% select(-(origSiteID:origPlotID))

set.seed(32)
NMDS <- metaMDS(cover_fat_spp, noshare = TRUE, try = 30)#DNC

fNMDS <- fortify(NMDS) %>% 
  filter(Score == "sites") %>%
  bind_cols(cover_fat %>% select(origSiteID:origPlotID))

ggplot(fNMDS, aes(x = NMDS1, y = NMDS2, colour = origBlockID)) +
  geom_point()
