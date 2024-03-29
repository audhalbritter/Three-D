###########################
 ### READ IN DATA ###
###########################

source("R/Load packages.R")
source("R/Rgathering/create meta data.R")
source("R/Vegetation/subplot_problems.R")

#Download community data from OSF
# run the code from L12-L33 if you need to download the data from OSF

# get_file(node = "pk4bg",
#          file = "Three-D_Community_Joa_2019.zip",
#          path = "data/community/2019/Joa",
#          remote_path = "RawData/Community")
# 
# get_file(node = "pk4bg",
#          file = "Three-D_Community_Lia_2019.zip",
#          path = "data/community/2019/Lia",
#          remote_path = "RawData/Community")
# 
# # Unzip files
# zipFile <- "data/community/2019/Joa/Three-D_Community_Joa_2019.zip"
# if(!file.exists(zipFile)){
#   outDir <- "data/community/2019/Joa"
#   unzip(zipFile, exdir = outDir)
# }
# 
# zipFile <- "data/community/2019/Lia/Three-D_Community_Lia_2019.zip"
# if(!file.exists(zipFile)){
#   outDir <- "data/community/2019/Lia"
#   unzip(zipFile, exdir = outDir)
# }


#### COMMUNITY DATA ####
### Read in files
files <- dir(path = "data/community/", pattern = "\\.xlsx$", full.names = TRUE, recursive = TRUE)

#Function to read in meta data
metaComm_raw <- map_df(set_names(files), function(file) {
  print(file)
  file %>% 
    excel_sheets() %>% 
    set_names() %>% 
    # exclude sheet to check data and taxonomy file
    discard(. %in% c("CHECK", "taxonomy")) %>% 
    map_df(~ read_xlsx(path = file, sheet = .x, n_max = 1, col_types = c("text", rep("text", 29))), .id = "sheet_name")
}, .id = "file")

# need to break the workflow here, otherwise tedious to find problems
metaComm <- metaComm_raw %>% 
  select(sheet_name, Date, origSiteID, origBlockID, origPlotID, turfID, destSiteID, destBlockID, destPlotID, Recorder, Scribe) %>% 
  # fix wrong dates
  mutate(Date = case_when(Date == "44025" ~ "13.7.2020",
                          Date == "44046" ~ "3.8.2020",
                          Date == "44047" ~ "5.8.2020",
                          Date == "44048" ~ "5.8.2020",
                          Date == "44049" ~ "6.8.2020",
                          TRUE ~ as.character(Date))) %>% 

  # make date
  mutate(Date = dmy(Date),
         Year = year(Date),
         origBlockID = as.numeric(origBlockID),
         destBlockID = as.numeric(destBlockID),
         origPlotID = as.numeric(origPlotID),
         destPlotID = as.numeric(destPlotID),
         turfID = gsub("_", " ", turfID)) %>% 
  
  # Fix mistake in PlotID
  mutate(origPlotID = ifelse(Date == "2019-07-02" & origPlotID == 83 & Recorder == "silje", 84, origPlotID)) %>% 
  
  # join for 2019 data
  left_join(metaTurfID %>% select(origSiteID, origBlockID, origPlotID, destSiteID, destPlotID, destBlockID, turfID), by = c("origSiteID", "origBlockID", "origPlotID")) %>% 
  mutate(destSiteID = coalesce(destSiteID.x, destSiteID.y),
         destBlockID = coalesce(destBlockID.x, destBlockID.y),
         destPlotID = coalesce(destPlotID.x, destPlotID.y),
         turfID = coalesce(turfID.x, turfID.y)) %>% 
  select(- c(destSiteID.x, destSiteID.y, destBlockID.x, destBlockID.y, destPlotID.x, destPlotID.y, turfID.x, turfID.y)) %>% 
  # join for 2020 data
  left_join(metaTurfID, by = c("destSiteID", "destBlockID", "destPlotID", "turfID")) %>% 
  mutate(origSiteID = coalesce(origSiteID.x, origSiteID.y),
         origBlockID = coalesce(origBlockID.x, origBlockID.y),
         origPlotID = coalesce(origPlotID.x, origPlotID.y)) %>% 
  select(- c(origSiteID.x, origSiteID.y, origBlockID.x, origBlockID.y, origPlotID.x, origPlotID.y))


# validate input
rules <- validator(Date = is.Date(Date),
                   Rec = is.character(Recorder),
                   Scr = is.character(Scribe))
out <- confront(metaComm, rules)
summary(out)


# Function to read in data
comm  <- map_df(set_names(files), function(file) {
  file %>% 
    excel_sheets() %>% 
    set_names() %>% 
    discard(. == "CHECK") %>% 
    map_df(~ read_xlsx(path = file, sheet = .x, skip = 2, n_max = 61, col_types = "text"), .id = "sheet_name")
}, .id = "file") %>% 
  select(file:Remark) %>% 
  rename("Cover" = `%`) %>% 
  mutate(Year = as.numeric(stri_extract_last_regex(file, "\\d{4}")))

  

# Join data and meta
community <- metaComm %>% 
  # anti join looses 18 turfs with NA as date, but its ok they are duplicates. Probably occur because of joining 2019 and 2020 data differently
  left_join(comm, by = c("sheet_name", "Year")) %>% 
  select(origSiteID:origPlotID, destSiteID:turfID, warming:Nlevel, Date, Year, Species:Cover, Recorder, Scribe, Remark, file) %>% 
  
  # Remove rows, without species, subplot and cover is zero
  filter_at(vars("Species", "1":"Cover"), any_vars(!is.na(.))) %>% 

  # Remove species NA, are all rows where Ratio > 1.5 is wrong
  filter(!is.na(Species)) %>% 
  filter(Species != "Height / depth (cm)") %>% 
  
  # Remove white space after Species name
  mutate(Species = str_trim(Species, side = "right")) %>%
  mutate(Recorder = recode(Recorder, "so" = "silje", "vv" = "vigdis", "lhv" = "linn", "kri" = "kari")) %>%
  
  # Fix wrong turfID
  mutate(turfID = case_when(turfID == "87 WN1M 164" ~ "87 WN1N 164",
                            TRUE ~ turfID)) %>% 
  
  # Fix wrong species names
  mutate(Species = recode(Species, 
                          "Agrostis sp 1" = "Agrostis mertensii",
                          "Alchemilla sp." = "Alchemilla sp",
                          "Anntenaria alpina" = "Antennaria alpina cf",
                          "Antennaria alpina" = "Antennaria alpina cf",
                          "Antennaria dioica" = "Antennaria dioica cf",
                          "Bryophyes" = "Bryophytes", 
                          "Carex sp 1" = "Carex sp1",
                          "Carex sp 2" = "Carex sp2",
                          "Carex sp 3" = "Carex sp3",
                          "cerastium alpinum cf" = "Cerastium cerastoides",
                          "Cerastium cerasteoides" = "Cerastium cerastoides",
                          "Cerastium cerastoies" = "Cerastium cerastoides",
                          "Cerstium cerasteoides" = "Cerastium cerastoides",
                          "Cerastium fontana" = "Cerastium fontanum",
                          "Epilobium ana cf" = "Epilobium anagallidifolium cf",
                          "Epilobium cf" = "Epilobium sp",
                          "Equiseum arvense" = "Equisetum arvense",
                          "Equisetum vaginatum" = "Equisetum variegatum",
                          "Galeopsis sp" = "Galeopsis tetrahit",
                          "Galeopsis tetrait" = "Galeopsis tetrahit",
                          "Gentiana nivalus" = "Gentiana nivalis",
                          "Gron or fjellkurle" = "Orchid sp",
                          "Hieraceum sp." = "Hieraceum sp",
                          "Hyperzia selago" = "Huperzia selago",
                          "Juniper communis" = "Juniperus communis",
                          "Luzula multiflora" = "Luzula multiflora cf",
                          "Luzula spicata" = "Luzula spicata cf",
                          "Lycopodium sp" = "Lycopodium annotinum ssp alpestre cf",
                          "Lycopodium" = "Lycopodium annotinum ssp alpestre cf",
                          "Omalothrca supina" = "Omalotheca supina",
                          "Pyrola" = "Pyrola sp",
                          "Poa alpigena" = "Poa pratensis", # did not distinguish in later years
                          "Ranunculus" = "Ranunculus",
                          "Rubus idaes" = "Rubus idaeus",
                          "Sagina saginoides" = "Sagina saginella",
                          "Snerote sp" = "Gentiana nivalis",
                          "Stellaria gramineae" = "Stellaria graminea",
                          "Taraxacum sp." = "Taraxacum sp",
                          "Unknown euphrasia sp?" = "Euphrasia sp",
                          "unknown juvenile" = "Unknown juvenile",
                          "Vaccinium myrtilis" = "Vaccinium myrtillus",
                          "Veronica biflora" = "Viola biflora",
                          "Total Cover (%)" = "SumofCover")) %>% 
  
  # Carex hell
  mutate(Species = ifelse(Species == "Carex sp3" & origSiteID == "Lia" & year(Date) == 2019 & Recorder == "so", "Carex small bigelowii", Species),
         Species = ifelse(Species == "Carex sp3" & origSiteID == "Lia" & year(Date) == 2019 & Recorder == "aud", "Carex wide v shaped dark", Species),
         Species = ifelse(Species == "Carex sp3" & origSiteID == "Joa" & year(Date) == 2019 & Recorder == "aud", "Carex vaginata", Species)) %>% 
  mutate(Species = recode(Species,
                          "Carex cap wide" = "Carex capillaris wide",
                          "Carex brei capillaris" = "Carex capillaris wide",
                          "Carex wide capillaris" = "Carex capillaris wide",
                          
                          # Carex atrata cf
                          "Carex m dgreen yellow wide" = "Carex atrata cf",
                          "Carex m wide green yellow" = "Carex atrata cf",
                          "Carex m yellow dgreen wide" = "Carex atrata cf",
                          "Carex m yellow dgreen wide" = "Carex atrata cf",
                          "Carex wide darkgreen yellow" = "Carex atrata cf",
                          "Carex wide m yellow dark green" = "Carex atrata cf",
                          "Carex yellow dark green m wide" = "Carex atrata cf",
                          "Carex atrata" = "Carex atrata cf", # PROBLEM CREATES A DUPLICATE
                          "Carex wide v dark green yellowish" = "Carex atrata cf",
                          "Carex v dgreen wide" = "Carex atrata cf",
                          "Carex v dgreen yellow" = "Carex atrata cf",
                          "Carex v dgreen yellow wide" = "Carex atrata cf",
                          "Carex v yellow d.green wide" = "Carex atrata cf",
                          "Carex v dark yellow wide" = "Carex atrata cf",
                          "Carex v green yellow wide" = "Carex atrata cf",
                          
                          # Carex small bigellowii
                          "Carex sp1" = "Carex small bigelowii",
                          "Carex small bigelowii v" = "Carex small bigelowii",
                          
                          # Carex saxatilis
                          "Carex saxatile" = "Carex saxatilis cf",
                          "Carex saxatile very small" = "Carex saxatilis cf",
                          "Carex saxifraga" = "Carex saxatilis cf",
                          "Carex light yellow m wide" = "Carex saxatilis cf",
                          "Carex lightgreen m" = "Carex saxatilis cf",
                          "Carex m lightgreen wide" = "Carex saxatilis cf",
                          "Carex m lightgreen wide, ca 3 mm" = "Carex saxatilis cf",
                          "Carex m yellow" = "Carex saxatilis cf",
                          "Carex m yellow very wide" = "Carex saxatilis cf",
                          "Carex m yellow wide" = "Carex saxatilis cf",
                          "Carex wide yellow m shape" = "Carex saxatilis cf",
                          "Carex v yellow wide" = "Carex saxatilis cf",
                          "Carex yellow m" = "Carex saxatilis cf",
                          "Carex yellow wide" = "Carex saxatilis cf",
                          "Carex sp4" = "Carex saxatilis cf",
                          "Carex m wide bigel flower but leafs are not" = "Carex saxatilis cf",
                          "Carex m yellowish soft wide, bigel flower" = "Carex saxatilis cf",
                          "Carex with fl from plot 67" = "Carex saxatilis cf",
                          
                          
                          # Carex brunnescens cf
                          "Carex sp2" = "Carex brunnescens cf",
                          "Carex Carex sp2 dark m" = "Carex brunnescens cf",
                          "Carex sp2 dark v thin" = "Carex brunnescens cf",
                          "Carex sp2" = "Carex brunnescens cf",
                          "Carex sp2 dark m" = "Carex brunnescens cf",
                          "Carex sp2 dark v thin" = "Carex brunnescens cf",
                          
                          # Carex canescense cf
                          "Carex canescens" = "Carex canescens cf",
                          "Carex canescense cf" = "Carex canescens cf",
                          "carex cannescence cf" = "Carex canescens cf",
                          
                          # Carex pilulifera cf
                          "Carex pilulifera" = "Carex pilulifera cf",
                          
                          # Carex norvegica cf
                          "Carex norwegica" = "Carex norvegica cf",
                          "Carex norvegica" = "Carex norvegica cf",
                          "Carex dark v thin" = "Carex norvegica cf",
                          "Carex v dark thin" = "Carex norvegica cf",
                          "Carex v darkgreen thin" = "Carex norvegica cf",
                          "Carex v dgreen thin" = "Carex norvegica cf",
                          "Carex v thin dgreen" = "Carex norvegica cf",
                          "Carex v green" = "Carex norvegica cf",
                          "Carex m dark thin" = "Carex norvegica cf",
                          "Carex m green thin" = "Carex norvegica cf",
                          
                          # Carex panicea cf
                          "Carex blueish" = "Carex panicea cf",
                          "Carex blue green" = "Carex panicea cf",
                          "Carex blue green thin bigelowii like" = "Carex panicea cf",
                          "Carex blue green v" = "Carex panicea cf",
                          "Carex bluegreen thin" = "Carex panicea cf",
                          "Carex thin bluegreen v short flowering stalk darkbrown fl" = "Carex panicea cf",
                          "Carex v bluegreen" = "Carex panicea cf",
                          "Carex v blue" = "Carex panicea cf",
                          "Carex sp5" = "Carex panicea cf",
                          "Carex m bluegreen wide" = "Carex panicea cf",
                          "Carex v blueish wide" = "Carex panicea cf",
                          "Carex blue" = "Carex panicea cf",
                          
                          # Unknown stuff
                          "Carex wide m" = "Carex wide",
                          "Carex wide v" = "Carex wide",
                          "Carex wide m dark" = "Carex wide",
                          "Carex m dark green wide" = "Carex wide",
                          "Carex m wide" = "Carex wide",
                          "Carex wide v shaped dark" = "Carex wide",
                          
                          "Carex v thin" = "Carex thin",
                          "Carex v thin leaf" = "Carex thin",
                          "Carex thin" = "Carex thin",
                          
                          "Carex bigelowii light green" = "Carex light green",
                          "Carex light green m rough thin leaves" = "Carex light green",
                          "Carex m yellowish thin" = "Carex light green",
                          "Carex m yellow thin" = "Carex light green",
                          "Carex v lightgreen" = "Carex light green",
                          "Carex thin light green pointy" = "Carex light green",
                          "Carex thin vaginatum like" = "Carex light green",
                          "Carex thin vaginata like" = "Carex light green",
                          "Carex flava?" = "Carex light green",
                          
                          "Carex v dark green soft leaf bigelowii tip" = "Carex dark green",
                          "Carex thin m darkgreen point all out" = "Carex dark green",
                          
                          "Carex vissen" = "Carex sp",
                          "Carex sp beitet" = "Carex sp",
                          "Carex nbr" = "Carex sp"
                          
                          )) %>% 
  
  # Fix special cases
  mutate(Species = ifelse(Species == "Euphrasia sp." & origSiteID == "Lia" & year(Date) == 2019, "Euphrasia wettsteinii", Species),
         Species = ifelse(Species == "Euphrasia sp." & origSiteID == "Joa" & year(Date) == 2019, "Euphrasia stricta", Species)) %>%
  mutate(Remark = ifelse(Species == "Orchid sp" & origSiteID == "Lia" & year(Date) == 2019, "Fjellhvitkurle or Gronnkurle", Remark)) %>% 
  
  # Unknown species
    
  ### 2022 CORRECTIONS:
  # unknown juvenile = I THINK UNKNOWN FORB
    
  mutate(Species = ifelse(Species == "Unknown grass" & origSiteID == "Lia" & origBlockID == 8 & year(Date) == 2019, "Unknown graminoid1", Species),
         Species = ifelse(Species == "unknown graminoid" & origSiteID == "Lia" & origBlockID == 10 & year(Date) == 2019, "Unknown graminoid2", Species),
         Species = ifelse(Species == "unknown graminoid" & origSiteID == "Lia" & origBlockID == 6 & year(Date) == 2019, "Unknown graminoid3", Species),
         Species = ifelse(Species == "unknown poaceae" & origSiteID == "Lia" & origBlockID == 5 & year(Date) == 2019, "Unknown graminoid4", Species),
         
         Species = ifelse(Species == "unknown herb" & origSiteID == "Lia" & origBlockID == 1 & year(Date) == 2019, "Ranunculus acris", Species), # was called Unknown herb1 before, but likely to be R. acris
         Species = ifelse(Species == "unknown herb" & origSiteID == "Lia" & origBlockID == 3 & year(Date) == 2019, "Unknown herb2", Species),
         Species = ifelse(Species == "unknown herb" & origSiteID == "Lia" & origBlockID == 5 & year(Date) == 2019, "Unknown herb3", Species),
         Species = ifelse(Species == "unknown herb" & origSiteID == "Lia" & origBlockID == 9 & year(Date) == 2019, "Unknown herb4", Species),
         Species = ifelse(Species == "Unknown herb" & origSiteID == "Lia" & origBlockID == 3 & year(Date) == 2019, "Unknown herb5", Species),
         
         Remark = ifelse(Species == "Unknown shrub, maybe salix" & origSiteID == "Lia" & origBlockID == 1 & year(Date) == 2019, "Maybe salix", Remark),
         # very likely S. herbaceae
         Species = ifelse(Species == "Unknown shrub, maybe salix" & origSiteID == "Lia" & origBlockID == 1 & year(Date) == 2019, "Salix herbaceae", Species)) |> 
  
  # Remove rows, with species, but where subplot and cover is NA
  filter_at(vars("1":"Cover"), any_vars(!is.na(.))) %>% 
  #Replace all NA in subplots with 0
  mutate(across("1":"25", ~ replace_na(.x, "0"))) |> 
  mutate(Cover = as.numeric(Cover)) %>% 
  
  rename(date = Date, year = Year, species = Species, cover = Cover, recorder = Recorder, scribe = Scribe, remark = Remark) %>% 
  
  # # check for subplot level data
  # community %>%
  # # summarize cover from species that have been merged
  # group_by(origSiteID, origBlockID, origPlotID, destSiteID, destPlotID, destBlockID, turfID, warming, grazing, Nlevel, year, species) %>%
  # mutate(n = n()) %>% filter(n > 1) %>% View()
  
  # remove duplicate species that differ in cover. Duplcated because species name was changed (11 cases with very low cover (1-6), no need in changing cover estimate).
  anti_join(duplicate_problem, by = c("year", "turfID", "species", "cover")) %>% 
  
  # remove duplicates
  group_by(origSiteID, origBlockID, origPlotID, destSiteID, destPlotID, destBlockID, turfID, warming, grazing, Nlevel, year, species, cover, recorder, scribe, remark, file) %>% 
  #mutate(n = n()) |> filter(n > 1) |> View()
  # remove 4 rows with same cover, cover stays the same, no fixing needed.
  # subplot presence is fixed in subplot_missing
  tidylog::slice(1)


# validate input
rules_comm <- validator(Sp = is.character(species),
                        Cov = is.numeric(cover),
                        Y = is.numeric(year),
                        Warming = grepl("A|W", turfID),
                        Site1 = origSiteID %in% c("Lia","Joa"),
                        Site2 = destSiteID %in% c("Lia","Joa", "Vik"))
out <- confront(community, rules_comm)
summary(out)

# find duplicate species
rule <- validator(is_unique(turfID, species, year))
out <- confront(community, rule)
# showing 7 columns of output for readability
summary(out)
violating(community, out) |> View()

# removing duplicates with different cover
remove_duplicates = tribble(
  ~year, ~turfID, ~species, ~cover,
  2019, "89 WN6I 165", "Poa pratensis", 1,
  2019, "92 WN6M 167", "Poa pratensis", 1,
  2019, "95 WN6N 168", "Poa pratensis", 2,
  2019, "96 AN6N 96", "Poa pratensis", 1,
  2019, "101 AN5I 101", "Poa pratensis", 1,
  2019, "106 WN3I 174", "Poa pratensis", 2,
  2019, "109 AN3C 109", "Poa pratensis", 2,
  2019, "117 AN10M 117", "Poa pratensis", 1,
  2019, "121 AN7M 121", "Poa pratensis", 1,
  2019, "124 AN7I 124", "Poa pratensis", 1,
  2019, "127 AN7N 127", "Poa pratensis", 1,
  2019, "132 WN4M 185", "Poa pratensis", 1,
  2019, "134 WN4I 187", "Poa pratensis", 1,
  2019, "135 WN4N 188", "Poa pratensis", 1,
  2019, "138 WN8I 189", "Poa pratensis", 1,
  2019, "141 WN8M 191", "Poa pratensis", 1,
  2019, "152 AN9N 152", "Poa pratensis", 1,
  2019, "8 WN1N 87", "Salix herbaceae", 1,
  2021, "34 WN10I 114", "Carex atrata cf", 2,
)

community <- community |> 
  tidylog::anti_join(remove_duplicates) |> 
  mutate(`4` = case_when(year == 2019 & turfID == "89 WN6I 165" & species == "Poa pratensis" ~ "f",
                         TRUE ~ `4`),
         `19` = case_when(year == 2019 & turfID == "92 WN6M 167" & species == "Poa pratensis" ~ "1",
                         TRUE ~ `19`),
         `13` = case_when(year == 2019 & turfID == "95 WN6N 168" & species == "Poa pratensis" ~ "1",
                         TRUE ~ `13`),
         `2` = case_when(year == 2019 & turfID == "96 AN6N 96" & species == "Poa pratensis" ~ "1",
                          TRUE ~ `2`),
         `16` = case_when(year == 2019 & turfID == "101 AN5I 101" & species == "Poa pratensis" ~ "1",
                          TRUE ~ `16`),
         `1` = case_when(year == 2019 & turfID == "106 WN3I 174" & species == "Poa pratensis" ~ "1",
                          TRUE ~ `1`),
         `1` = case_when(year == 2019 & turfID == "109 AN3C 109" & species == "Poa pratensis" ~ "1",
                          TRUE ~ `1`),
         `2` = case_when(year == 2019 & turfID == "109 AN3C 109" & species == "Poa pratensis" ~ "f",
                          TRUE ~ `2`),
         `21` = case_when(year == 2019 & turfID == "121 AN7M 121" & species == "Poa pratensis" ~ "1",
                          TRUE ~ `21`),
         `13` = case_when(year == 2019 & turfID == "124 AN7I 124" & species == "Poa pratensis" ~ "f",
                          TRUE ~ `13`),
         `10` = case_when(year == 2019 & turfID == "127 AN7N 127" & species == "Poa pratensis" ~ "1",
                          TRUE ~ `10`),
         `20` = case_when(year == 2019 & turfID == "138 WN8I 189" & species == "Poa pratensis" ~ "1",
                          TRUE ~ `20`),
         `21` = case_when(year == 2019 & turfID == "138 WN8I 189" & species == "Poa pratensis" ~ "1",
                          TRUE ~ `21`),
         `10` = case_when(year == 2019 & turfID == "141 WN8M 191" & species == "Poa pratensis" ~ "1",
                          TRUE ~ `10`),
         `7` = case_when(year == 2019 & turfID == "152 AN9N 152" & species == "Poa pratensis" ~ "1",
                          TRUE ~ `7`),
         `8` = case_when(year == 2019 & turfID == "152 AN9N 152" & species == "Poa pratensis" ~ "1",
                          TRUE ~ `8`),
         `9` = case_when(year == 2019 & turfID == "152 AN9N 152" & species == "Poa pratensis" ~ "1",
                          TRUE ~ `9`),
         `4` = case_when(year == 2019 & turfID == "8 WN1N 87" & species == "Salix herbaceae" ~ "1",
                          TRUE ~ `4`),
         `5` = case_when(year == 2021 & turfID == "34 WN10I 114" & species == "Carex atrata cf" ~ "cf",
                          TRUE ~ `5`),
         ) |> 
  # fix cover
  mutate(cover = case_when(year == 2019 & turfID == "89 WN6I 165" & species == "Poa pratensis" ~ 13,
                           year == 2019 & turfID == "92 WN6M 167" & species == "Poa pratensis" ~ 8,
                           year == 2019 & turfID == "95 WN6N 168" & species == "Poa pratensis" ~ 5,
                           year == 2019 & turfID == "96 AN6N 96" & species == "Poa pratensis" ~ 5,
                           year == 2019 & turfID == "101 AN5I 101" & species == "Poa pratensis" ~ 4,
                           year == 2019 & turfID == "106 WN3I 174" & species == "Poa pratensis" ~ 10,
                           year == 2019 & turfID == "109 AN3C 109" & species == "Poa pratensis" ~ 5,
                           year == 2019 & turfID == "117 AN10M 117" & species == "Poa pratensis" ~ 4,
                           year == 2019 & turfID == "121 AN7M 121" & species == "Poa pratensis" ~ 5,
                           year == 2019 & turfID == "124 AN7I 124" & species == "Poa pratensis" ~ 6,
                           year == 2019 & turfID == "127 AN7N 127" & species == "Poa pratensis" ~ 9,
                           year == 2019 & turfID == "132 WN4M 185" & species == "Poa pratensis" ~ 9,
                           year == 2019 & turfID == "134 WN4I 187" & species == "Poa pratensis" ~ 5,
                           year == 2019 & turfID == "135 WN4N 188" & species == "Poa pratensis" ~ 11,
                           year == 2019 & turfID == "138 WN8I 189" & species == "Poa pratensis" ~ 5,
                           year == 2019 & turfID == "141 WN8M 191" & species == "Poa pratensis" ~ 9,
                           year == 2019 & turfID == "152 AN9N 152" & species == "Poa pratensis" ~ 17,
                           year == 2019 & turfID == "8 WN1N 87" & species == "Salix herbaceae" ~ 6,
                           year == 2021 & turfID == "34 WN10I 114" & species == "Carex atrata cf" ~ 6,
                           TRUE ~ cover))

  
#### COVER ####
# Extract estimate of cover
cover <- community %>% 
  ungroup() %>% 
  select(origSiteID:species, cover:file) %>% 
  filter(!species %in% c("Moss layer", "Vascular plant layer", "SumofCover", "Vascular plants", "Bryophytes", "Lichen", "Litter", "Bare soil", "Bare rock", "Poop", "Unknown seedlings", "Wool")) %>% 
  
  # fix errors
  # fix wrong species
  left_join(fix_species, by = c("year", "turfID", "species")) %>% 
  mutate(species = if_else(!is.na(species_new), species_new, species)) %>%
  select(-species_new) %>% 
  # fix wrong cover
  left_join(fix_cover, by = c("year", "turfID", "species")) %>% 
  mutate(cover = if_else(!is.na(cover_new), cover_new, cover)) %>%
  select(-cover_new) %>% 
  # add cover
  bind_rows(add_cover) %>% 
  # remove species that have been replaced
  tidylog::anti_join(remove_wrong_species, by = c("year", "turfID", "species")) |> 
  # rename last carex
  mutate(species = if_else(species == "Carex sp1", "Carex sp", species),
         species = if_else(species == "Orchid sp", "Unknown orchid", species))

  
write_csv(cover, file = "data_cleaned/vegetation/Three-D_clean_cover_2019-2022.csv", col_names = TRUE)

### make species list
taxonomy <- read_csv("data/community/Three-D_Taxonomy_2019.csv") |> 
  rename(species = Species, family = Family, functional_group = functionalGroup) |> 
  separate(species, into = c("genus", "species"), sep = "\\s", extra = "merge") |> 
  select(-species) |> 
  distinct()

species_list <- cover |> 
  distinct(species) |> 
  separate(species, into = c("genus", "species"), sep = "\\s", extra = "merge") |> 
  left_join(taxonomy, by = "genus") |> 
  mutate(functional_group = case_when(genus == "Unknown" & grepl("graminoid", species) ~ "graminoid",
                                      genus == "Unknown" & grepl("herb", species) ~ "forb",
                                      genus == "Unknown" & grepl("orchid", species) ~ "forb",
                                      TRUE ~ functional_group))

write_csv(species_list, file = "data_cleaned/vegetation/Three-D_clean_taxonomy.csv", col_names = TRUE)



#### SUBPLOT PRECENSE ####
CommunitySubplot <- community %>% 
  filter(!species %in% c("Moss layer", "Vascular plant layer", "SumofCover", "Vascular plants", "Bryophytes", "Lichen", "Litter", "Bare soil", "Bare rock", "Poop", "Wool")) %>% 
  
  # make long table
  pivot_longer(cols = `1`:`25`, names_to = "subplot", values_to = "presence") %>% 
  # remove non-presence in subplot
  filter(presence != "0") %>% 
  
  # Unknown seedlings have sometimes counts, but not consistent. So make just presence.
  tidylog::mutate(presence = ifelse(species == "Unknown seedlings", "s", presence),
                  presence = recode(presence, "fd" = "df", "1j" = "j", "1f" = "f", "F" = "f")) %>% 
  mutate(fertile = ifelse(presence %in% c("f", "fd"), 1, 0),
         dominant = ifelse(presence %in% c("d", "fd", "dj"), 1, 0),
         juvenile = ifelse(presence %in% c("j", "dj"), 1, 0),
         seedling = ifelse(presence %in% c("s", "3"), 1, 0)) %>%
  mutate(remark = if_else(presence %in% c("1?", "cf", "j?"), paste(remark, "species id uncertain"), remark),
         remark = if_else(presence %in% c("3"), "probably 3 leontodon seedlings", remark),
         presence = 1) %>%  
  pivot_longer(cols = c(presence:seedling), names_to = "variable", values_to = "value") %>% 
  ungroup() %>% 
  select(year, date, origSiteID:Nlevel, subplot, species, variable, value, remark, recorder) %>% 
  # fix errors
  # add data of subplots that were removed due to duplicates
  bind_rows(subplot_missing) %>% 
  
  # fix wrong species
  left_join(fix_species, by = c("year", "turfID", "species")) %>% 
  mutate(species = if_else(!is.na(species_new), species_new, species)) %>%
  select(-species_new) %>% 

  # add rows with subplot info
  bind_rows(add_subplot) %>% 
  # remove rows with subplot info (e.g. species that changed name)
  anti_join(remove_subplot, by = c("year", "turfID", "species", "subplot")) %>% 
  # remove species that have been replaced
  tidylog::anti_join(remove_wrong_species, by = c("year", "turfID", "species")) |> 
  # remove duplicates
  tidylog::distinct() |> 
  # rename last carex
  mutate(species = if_else(species == "Carex sp1", "Carex sp", species),
         species = if_else(species == "Orchid sp", "Unknown orchid", species))

write_csv(CommunitySubplot, file = "data_cleaned/vegetation/Three-D_clean_community_subplot_2019-2022.csv", col_names = TRUE)



#### COMMUNITY STRUCTURE DATA ####
# Height
height <- community %>% 
  filter(species %in% c("Vascular plant layer", "Moss layer")) %>% 
  select(-c(`5`:`25`)) %>% 
  pivot_longer(cols = `1`:`4`, names_to = "subplot", values_to = "height") %>% 
  mutate(height = as.numeric(height)) %>% 
  group_by(turfID, year, species, recorder) %>% 
  summarise(height = mean(height, na.rm = TRUE)) %>% 
  rename("vegetation_layer" = "species") |> 
  # add missing height (average from all years)
  # all other NAs are real
  mutate(height = case_when(turfID == "67 AN9M 67" & vegetation_layer == "Moss layer" & year == 2020 ~ 0.675,
                            turfID == "67 AN9M 67" & vegetation_layer == "Vascular plant layer" & year == 2020 ~ 2.41,
                            turfID == "152 AN9N 152" & vegetation_layer == "Moss layer" & year == 2020 ~ NA_real_,
                            is.na(height) ~ NA_real_,
                            TRUE ~ height))

write_csv(height, file = "data_cleaned/vegetation/Three-D_clean_height_2019_2020.csv", col_names = TRUE)


# Cover from Functional Groups and Height
CommunityStructure <- community %>% 
  filter(species %in% c("SumofCover", "Vascular plants", "Bryophytes", "Lichen", "Litter", "Bare soil", "Bare rock", "Poop", "Wool")) %>% 
  mutate(`24` = if_else(`24` == "Ratio > 1.5 is wrong", "0", `24`)) %>% 
  pivot_longer(cols = `1`:`25`, names_to = "subplot", values_to = "percentage") %>% 
  ungroup() |> 
  # make rows numeric
  mutate(percentage = as.numeric(percentage),
         percentage = case_when(is.na(percentage) ~ 0,
                                percentage == 520 ~ 52,
                                TRUE ~ percentage)) |> 
  # calculate mean cover per turf
  group_by(origSiteID, origBlockID, origPlotID, destSiteID, destPlotID, destBlockID, turfID, warming, grazing, Nlevel, date, year, species, cover, recorder) %>% 
  summarise(mean = mean(percentage)) %>% 
  # In 2020 vascular plant cover was estimated per subplot, in the other years, only for the whole plot
  # all years except 2020 whole plot for sum of cover and vascular plant cover
  # 2020 no sum of cover, and subplot vascular plant cover
  mutate(cover = case_when(year == 2020 & species == "Vascular plants" ~ mean,
                           # sum of cover was not estimated for non controls in 2020
                           year == 2020 & species == "SumofCover" & !Nlevel %in% c(1, 2, 3)  ~ NA_real_,
                            species %in% c("SumofCover", "Vascular plants") ~ cover,
                            !species %in% c("SumofCover", "Vascular plants") ~ mean)) |> 
  # make NA if functional group is not there and then remove
  mutate(cover = if_else(cover == 0 & species %in% c("Bryophytes", "Lichen", "Litter", "Bare soil", "Bare rock", "Poop", "Wool"), NA_real_, cover)) |> 
  filter(!is.na(cover)) |> 
  ungroup()  |>  
  select(date, year, origSiteID:Nlevel, functional_group = species, cover, recorder)

write_csv(CommunityStructure, file = "data_cleaned/vegetation/Three-D_clean_community_structure_2019-2022.csv", col_names = TRUE)


# CommunityStructure |> 
#   filter(origSiteID == "Joa") |> 
#   ggplot(aes(x = Nlevel, y = cover, fill = functional_group)) +
#   geom_col() +
#   facet_grid(grazing ~ warming)
# 
# community %>% 
#   # summarize cover from species that have been merged
#   group_by(origSiteID, origBlockID, origPlotID, destSiteID, destPlotID, destBlockID, turfID, warming, grazing, Nlevel, year, species) %>% 
#   mutate(n = n()) %>% filter(n > 1) %>% View()
