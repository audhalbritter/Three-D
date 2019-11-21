###########################
 ### READ IN DATA ###
###########################

source("R/Load packages.R")

#### PLOT LEVEL META DATA ####
plotMeta <- read_excel(path = "data/metaData/Three-D_PlotLevel_MetaData_2019.xlsx")


file <- "data/community/2019/Lia/THREE-D_CommunityData_Lia_1_2019.xlsx"
dd <- read_xlsx(path = file, sheet = 7, skip = 2, n_max = 61, col_types = "text")
dd %>% pn
read_xlsx(path = file, sheet = 5, n_max = 1, col_types = "text")

#### COMMUNITY DATA ####
### Read in files
files <- dir(path = "data/community", pattern = "\\.xlsx$", full.names = TRUE, recursive = TRUE)

# Function to read in data
comm <- map_df(set_names(files), function(file) {
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
         Cover = as.numeric(Cover))

#Function to read in meta data
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
  right_join(comm, by = c("origSiteID", "origBlockID", "origPlotID")) %>%
  
  # Remove rows, without species, subplot and cover is zero
  filter_at(vars("Species", "1":"Cover"), any_vars(!is.na(.))) %>% 

  # Remove species NA, are all these rows: Ratio > 1.5 is wrong
  filter(!is.na(Species)) %>% 
  # FIX!!!
  filter(Species != "Height / depth (cm)") %>% 
  
  # Remove white space after Species name
  mutate(Species = str_trim(Species, side = "right")) %>% 
  # Fix wrong species names
  mutate(Species = recode(Species, 
                          "Agrostis sp 1" = "Agrostis mertensii cf",
                          "Alchemilla sp." = "Alchemilla sp",
                          "Bryophyes" = "Bryophytes", 
                          "Carex sp 1" = "Carex sp1",
                          "Carex sp 2" = "Carex sp2",
                          "Carex sp 3" = "Carex sp3",
                          "cerastium alpinum cf" = "Cerastium cerastoides",
                          "Cerastium cerasteoides" = "Cerastium cerastoides",
                          "Cerastium cerastoies" = "Cerastium cerastoides",
                          "Cerstium cerasteoides" = "Cerastium cerastoides",
                          "Cerstium fontana" = "Cerastium fontanum",
                          "Equiseum arvense" = "Equisetum arvense",
                          "Equiseum vaginatum" = "Equisetum variegatum",
                          "Gentiana nivalus" = "Gentiana nivalis",
                          "Gron or fjellkurle" = "Orchid sp",
                          "Hieraceum sp." = "Hieraceum sp",
                          "Lycopodium sp" = "Lycopodium annotinum ssp alpestre cf",
                          "Lycopodium" = "Lycopodium annotinum ssp alpestre cf",
                          "Omalothrca supina" = "Omalotheca supina",
                          "Pyrola" = "Pyrola sp",
                          "Poa alpigena" = "Poa pratensis ssp alpigena",
                          "Ranunculus" = "Ranunculus",
                          "Rubus idaes" = "Rubus idaeus",
                          "Snerote sp" = "Gentiana nivalis",
                          "Stellaria gramineae" = "Stellaria graminea",
                          "Unknown euphrasia sp?" = "Euphrasia sp1",
                          "Vaccinium myrtilis" = "Vaccinium myrtillus",
                          "Total Cover (%)" = "SumofCover")) %>% 
  
  # Fix special cases
  mutate(Species = ifelse(Species == "Euphrasia sp." & origSiteID == "Lia" & year(Date) == 2019, "Euphrasia wettsteinii", Species),
         Species = ifelse(Species == "Euphrasia sp." & origSiteID == "Joa" & year(Date) == 2019, "Euphrasia stricta", Species)) %>%
  mutate(Remark = ifelse(Species == "Orchid sp" & origSiteID == "Lia" & year(Date) == 2019, "Fjellhvitkurle or Gronnkurle", Remark)) %>% 
  
  # Unknown species
  mutate(Species = ifelse(Species == "Unknown grass" & origSiteID == "Lia" & origBlockID == 8 & year(Date) == 2019, "Unknown graminoid1", Species),
         Species = ifelse(Species == "unknown graminoid" & origSiteID == "Lia" & origBlockID == 10 & year(Date) == 2019, "Unknown graminoid2", Species),
         Species = ifelse(Species == "unknown graminoid" & origSiteID == "Lia" & origBlockID == 6 & year(Date) == 2019, "Unknown graminoid3", Species),
         Species = ifelse(Species == "unknown poaceae" & origSiteID == "Lia" & origBlockID == 5 & year(Date) == 2019, "Unknown graminoid4", Species),
         
         Species = ifelse(Species == "unknown herb" & origSiteID == "Lia" & origBlockID == 1 & year(Date) == 2019, "Unknown herb1", Species),
         Species = ifelse(Species == "unknown herb" & origSiteID == "Lia" & origBlockID == 3 & year(Date) == 2019, "Unknown herb2", Species),
         Species = ifelse(Species == "unknown herb" & origSiteID == "Lia" & origBlockID == 5 & year(Date) == 2019, "Unknown herb3", Species),
         Species = ifelse(Species == "unknown herb" & origSiteID == "Lia" & origBlockID == 9 & year(Date) == 2019, "Unknown herb4", Species),
         Species = ifelse(Species == "Unknown herb" & origSiteID == "Lia" & origBlockID == 3 & year(Date) == 2019, "Unknown herb5", Species),
         
         Species = ifelse(Species == "Unknown shrub, maybe salix" & origSiteID == "Lia" & origBlockID == 1 & year(Date) == 2019, "Unknown shrub1", Species)) %>% 
    
    # Remove rows, with species, but where subplot and cover is zero
    filter_at(vars("1":"Cover"), any_vars(!is.na(.)))

# A tibble: 4,075 x 37
  
# Do I need to replace NA with 0 in subplots?
# mutate_at(.vars = c("1":"25"), .funs = list(~ ifelse(is.na(.), 0, .)))


# FIX!!! duplicates
community %>% group_by(Date, origSiteID, origBlockID, origPlotID, turfID, Year, Species, Cover) %>% 
  mutate(n = n()) %>% 
  filter(n > 1)



# Do checks
community %>% distinct(Species) %>% arrange(Species) %>% pn
community %>% filter(Species %in% c("Unknown shrub, maybe salix")) %>% as.data.frame()
community %>% filter(is.na(Species)) %>% as.data.frame()

  

#### COMMUNITY META DATA ####
# Extract estimate of cover
cover <- community %>% 
  select(Date:Species, Cover, Remark) %>% 
  filter(!Species %in% c("Moss layer", "Vascular plant layer", "SumofCover", "Vascular plants", "Bryophytes", "Lichen", "Litter", "Bare soil", "Bare rock", "Poop", "Unknown seedlings"))



# Cover from Functional Groups
community %>% 
  filter(Species %in% c("SumofCover", "Vascular plants", "Bryophytes", "Lichen", "Litter", "Bare soil", "Bare rock", "Poop")) %>% 
  mutate_at(.vars = c("1":"25"), .funs = list(~ ifelse(is.na(.), 0, .))) %>% 
  # make rows numeric
  mutate_at(.vars = c("1":"25"), .funs = as.numeric) %>% 
  mutate(Mean = rowMeans(select(., "1":"15"), na.rm = TRUE))
### Cannot convert row 21-25 to 0, and row 16-25 are not numeric!!!


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
