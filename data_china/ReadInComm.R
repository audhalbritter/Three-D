#Read China comm data

source("R/Load packages.R")
source("R/Rgathering/create meta data.R")


# turfID dic for wrong turfIDs in 2021

# # fix site names in meta data
meta_c <- metaTurfID_China %>%
  mutate(origSiteID = recode(origSiteID,  "Top" = "H", "Middle" = "M", "Low" = "L"),
         destSiteID = recode(destSiteID,  "Top" = "H", "Middle" = "M", "Low" = "L"))


# read in 2019 - 2021 data
files <- dir(path = "data_china/", pattern = "\\.xlsx$", full.names = TRUE, recursive = TRUE)

#Function to read in meta data
metaComm_raw <- map_df(set_names(files), function(file) {
  print(file)
  file %>% 
    excel_sheets() %>% 
    set_names() %>% 
    # exclude sheet to check data and taxonomy file
    discard(str_detect(., "Sheet\\d")) %>% 
    map_df(~ read_xlsx(path = file, sheet = .x, n_max = 1) %>% 
             mutate(destSiteID = as.character(destSiteID)), .id = "sheet_name")
}, .id = "file")


metaComm <- metaComm_raw %>% 
  select(file, sheet_name, Date, destSiteID, destBlockID, destPlotID, turfID, Recorder, Scribe) %>% 
  mutate(Year = year(Date)) %>% 
  filter(Year == 2019) %>% 
  # change dest to orig, because before transplant
  rename(origSiteID = destSiteID, origBlockID = destBlockID, origPlotID = destPlotID) %>% 
  mutate(turfID = gsub("_", " ", turfID),
         turfID = gsub("  ", " ", turfID),
         # fix wrong plotID, blockID and siteID
         origBlockID = case_when(turfID == "54 WN4C 134" ~ 7,
                                 turfID == "65 WN9I 146" ~ 9,
                                 turfID == "66 AN9M 66" ~ 9,
                                 turfID == "67 AN9I 67" ~ 9,
                                 turfID == "68 AN9C 68" ~ 9,
                                 turfID == "70 WN9M 150" ~ 9,
                                 turfID == "71 WN9N 152" ~ 9,
                                 turfID == "72 AN9N 72" ~ 9,
                                 turfID == "77 WN2M 157" ~ 10,
                                 turfID == "80 AN2N 80" ~ 10,
                                 TRUE ~ origBlockID),
         # fix wrong plotID
         origPlotID = if_else(turfID == "121 AN7M 121", 121, origPlotID),
         # siteID
         origSiteID = if_else(origSiteID == "L", "M", origSiteID),
         origSiteID = if_else(str_detect(file, "H-community") & origSiteID == "M", "H", origSiteID)) %>% 
  # join meta data
  left_join(meta_c, by = c("origSiteID", "origBlockID", "origPlotID", "turfID")) %>% 

  # bind rows with 2021 data
  bind_rows(
    metaComm_raw2 %>% 
      filter(Year == 2021) %>% 
      mutate(turfID = if_else(turfID == "9 WN6I 89" & destSiteID == "H", "11 AN6M 11", turfID),
           destPlotID = case_when(turfID == "101 WN5M 171" ~ 171,
                                  #turfID == "79 WN2N 159" ~ 159,
                                  #turfID == "160 AN2N 160" ~ 160,
                                  turfID == "74 AN2C 74" ~ 74,
                                  TRUE ~ destPlotID),
           destSiteID = if_else(turfID %in% c("34 AN10M 34", "36 AN10C 36", "38 AN10I 38", "39 AN10N 39"), "H", destSiteID)) %>% 
    left_join(meta_c, by = c("destSiteID", "destBlockID", "destPlotID", "turfID")))


# Read in community data
files <- dir(path = "data_china/", pattern = "\\.xlsx$", full.names = TRUE, recursive = TRUE)

comm_raw <- map_df(set_names(files), function(file) {
  file %>% 
    excel_sheets() %>% 
    set_names() %>% 
    discard(. == "Sheet1") %>% 
    map_df(~ read_xlsx(path = file, sheet = .x, skip = 2, n_max = 61, col_types = "text"), .id = "sheet_name")
}, .id = "file") %>% 
  rename("Cover" = `%`) 

comm <- comm_raw %>% 
  # remove empty rows
  filter(!is.na(Species)) %>% 
  # extract year from file path, first 4 digit
  mutate(Year = as.numeric(stri_extract_first_regex(file, "\\d{4}")),
         # remove underscore from sheet name
         sheet_name = gsub("_", " ", sheet_name),
         # extract site from file name and rename
         site = basename(file) %>% str_sub(., 1, 1),
         # 2019 is origin site, 2021 is dest site
         origSiteID = if_else(Year == 2019, site, NA_character_),
         destSiteID = if_else(Year == 2021, site, NA_character_),
         sheet_name = if_else(sheet_name == "98 WN5I 169", "98 AN5C 98", sheet_name),
         sheet_name = if_else(sheet_name == "118  AN10C 118", "118 AN10C 118", sheet_name)
         ) %>% 
  select(-site)



community <- metaComm %>% 
  # should be empty if all match
  #anti_join(comm %>% select(-file), by = c("turfID" = "sheet_name", "Year")) %>% View()
  left_join(comm %>% select(-file), by = c("turfID" = "sheet_name", "Year")) %>% 
  mutate(origSiteID = coalesce(origSiteID.x, origSiteID.y),
         destSiteID = coalesce(destSiteID.x, destSiteID.y)) %>% 
  select(-origSiteID.x, -origSiteID.y, -destSiteID.x, -destSiteID.y) %>% 
  rename(year = Year, date = Date, species = Species, cover = Cover, recorder = Recorder, scribe = Scribe, remark = Remark) %>% 
  select(origSiteID, origBlockID, origPlotID, destSiteID, destPlotID, destBlockID, turfID, warming, grazing, Nlevel, year, date, species, cover, "1":"25", recorder, scribe, remark, file) %>% 
  
  # check for duplicates
  # group_by(origSiteID, origBlockID, origPlotID, destSiteID, destPlotID, destBlockID, turfID, warming, grazing, Nlevel, year, species, cover, recorder, scribe, remark, file) %>%
  # mutate(n = n()) %>% filter(n > 1)
  
  # remove damaged plots in 2021 (no data)
  # 103 AN5N 103, 112 AN3N 112, 135 AN4N 135, 64 WN8N 143, 79 WN2N 159, 160 AN2N 160
  tidylog::filter(!species %in% c("Be destroyed", "样方未找到")) %>% 
  
  # remove empty rows
  filter(!species %in% c("Fertile (bud, flower, seed, fruit)", "Presence", "Subplot recording (highest level):")) %>% 
  
  # fix species names
  mutate(species = case_when(str_detect(species, "Anaphalis nepalensis") ~ "Anaphalis nepalensis",
                             species == "Caltha palustris Linnaeus" ~ "Caltha palustris",
                             species == "Carex atrofusca subsp.minor" ~ "Carex atrofusca subsp. minor",
                             species == "Crambe Linn" ~ "Crambe sp.",
                             species == "Cyperus rotundus L." ~ "Cyperus rotundus",
                             species == "Fragaria orientalis L" ~ "Fragaria orientalis",
                             species == "Galium spurium L" ~ "Galium spurium",
                             species == "Juncus allioides Franchet" ~ "Juncus allioides",
                             species == "oxytropis kansuensis" ~ "Oxytropis kansuensis",
                             species == "Pedicularis sima M" ~ "Pedicularis sima",
                             species == "Poa pratensis Linnaeus" ~ "Poa pratensis",
                             species == "Polygonum viviparum Linnaeus" ~ "Polygonum viviparum",
                             species == "Potentillaleuconota" ~ "Potentilla leuconota",
                             species == "Rhodiola" ~ "Rhodiola sp.",
                             species == "Rhodiola rosea Linn." ~ "Rhodiola rosea",
                             species == "Saussurea graminea Dunn" ~ "Saussurea graminea",
                             species == "Saussurea pachyneura Franch." ~ "Saussurea pachyneura",
                             species == "Stellaria decumbensvar. pulvinata" ~ "Stellaria decumbens var. pulvinata",
                             TRUE ~ species)) %>% 
  
  # fix cover
  mutate(cover = if_else(cover %in% c("<0.5", "<0.2", "《0.5"), "0.1", cover),
         cover = as.numeric(cover)) %>% 
  
  # fix cover in remark column
  mutate(cover = case_when(remark == "1" ~ 1,
                           remark == "10" ~ 10,
                           remark == "3" ~ 3,
                           remark == "5" ~ 5,
                           TRUE ~ cover),
         remark = if_else(remark %in% c("1", "10", "3", "5"), NA_character_, remark)) %>% 
          
  # add weather from scribe column
  mutate(weather = if_else(scribe %in% c("sunny", "cloudy", "Rain", "Sun"), scribe, NA_character_))

# needs fixing
community %>% filter(species == "Geranium pylzowianumAletris pauciflora")
# Geranium pylzowianumAletris pauciflora

# Cover data
cover <- community %>% 
  filter(!species %in% c("Bare rock", "Bare soil", "Bryophyes", "Lichen", "Litter", "Poop", "Vascular plants", "Total Cover (%)", "Height / depth (cm)", "Vascular plant layer", "Moss layer")) %>% 
  select(year, date, origSiteID:Nlevel, species, cover, weather, recorder, file)
write_csv(x = cover, file = "data_china/China_clean_cover_2019_2021.csv")

# Subplot community data
subplot_community <- community %>% 
  filter(!species %in% c("Bare rock", "Bare soil", "Bryophyes", "Lichen", "Litter", "Poop", "Vascular plants", "Total Cover (%)", "Height / depth (cm)", "Vascular plant layer", "Moss layer")) %>% 
  pivot_longer(cols = c("1":"25"), names_to = "subplot", values_to = "presence") %>% 
  filter(!is.na(presence)) %>% 
  mutate(fertile = if_else(presence == "F", "F", NA_character_),
         dominant = if_else(presence == "D", "D", NA_character_),
         seedling = if_else(presence == "S", "S", NA_character_),
         presence = if_else(!is.na(presence), "1", NA_character_)) %>% 
  pivot_longer(cols = c(fertile, dominant, seedling, presence), names_to = "variable", values_to = "value") %>% 
  filter(!is.na(value)) %>% 
  select(year, date, origSiteID:Nlevel, subplot, species, variable, value, weather, recorder, file)
write_csv(x = subplot_community, file = "data_china/China_clean_subplot_community_2019_2021.csv")


# functional group cover
community %>% 
  filter(species %in% c("Bare rock", "Bare soil", "Bryophyes", "Lichen", "Litter", "Poop", "Vascular plants", "Total Cover (%)")) %>% 
  filter(!is.na(cover))

                             
# height
community %>% 
  filter(species %in% c("Height / depth (cm)", "Vascular plant layer", "Moss layer")) %>% 
  rename(h1 = "1", h2 = "2", h3 = "3", h4 = "4", h5 = "5") %>% 
  filter(!is.na(h2))



  