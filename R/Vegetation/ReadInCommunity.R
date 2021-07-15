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
  mutate(Year = as.numeric(stri_extract_last_regex(file, "\\d{4}")))


# Join data and meta
community <- metaComm %>% 
  left_join(comm, by = c("sheet_name", "Year")) %>% 
  select(origSiteID:origPlotID, destSiteID:turfID, warming:Nlevel, Date, Year, Species:Cover, Recorder, Scribe, Remark, file) %>% 
  
  # Remove rows, without species, subplot and cover is zero
  filter_at(vars("Species", "1":"Cover"), any_vars(!is.na(.))) %>% 

  # Remove species NA, are all rows where Ratio > 1.5 is wrong
  filter(!is.na(Species)) %>% 
  filter(Species != "Height / depth (cm)") %>% 
  
  # Remove white space after Species name
  mutate(Species = str_trim(Species, side = "right")) %>% 
  mutate(Recorder = recode(Recorder, "so" = "silje", "vv" = "vigdis", "lhv" = "linn")) %>%
  
  # Fix wrong turfID
  mutate(turfID = case_when(turfID == "87 WN1M 164" ~ "87 WN1N 164",
                            TRUE ~ turfID)) %>% 
  
  # Fix wrong species names
  mutate(Species = recode(Species, 
                          "Agrostis sp 1" = "Agrostis mertensii",
                          "Alchemilla sp." = "Alchemilla sp",
                          "Anntenaria alpina" = "Antennaria alpina",
                          "Bryophyes" = "Bryophytes", 
                          "Carex sp 1" = "Carex sp1",
                          "Carex sp 2" = "Carex sp2",
                          "Carex sp 3" = "Carex sp3",
                          "cerastium alpinum cf" = "Cerastium cerastoides",
                          "Cerastium cerasteoides" = "Cerastium cerastoides",
                          "Cerastium cerastoies" = "Cerastium cerastoides",
                          "Cerstium cerasteoides" = "Cerastium cerastoides",
                          "Cerastium fontana" = "Cerastium fontanum",
                          "Equiseum arvense" = "Equisetum arvense",
                          "Equisetum vaginatum" = "Equisetum variegatum",
                          "Galeopsis sp" = "Galeopsis tetrahit",
                          "Galeopsis tetrait" = "Galeopsis tetrahit",
                          "Gentiana nivalus" = "Gentiana nivalis",
                          "Gron or fjellkurle" = "Orchid sp",
                          "Hieraceum sp." = "Hieraceum sp",
                          "Hyperzia selago" = "Huperzia selago",
                          "Lycopodium sp" = "Lycopodium annotinum ssp alpestre cf",
                          "Lycopodium" = "Lycopodium annotinum ssp alpestre cf",
                          "Omalothrca supina" = "Omalotheca supina",
                          "Pyrola" = "Pyrola sp",
                          "Poa alpigena" = "Poa pratensis ssp alpigena",
                          "Ranunculus" = "Ranunculus",
                          "Rubus idaes" = "Rubus idaeus",
                          "Sagina saginoides" = "Sagina saginella",
                          "Snerote sp" = "Gentiana nivalis",
                          "Stellaria gramineae" = "Stellaria graminea",
                          "Unknown euphrasia sp?" = "Euphrasia sp1",
                          "Vaccinium myrtilis" = "Vaccinium myrtillus",
                          "Viola biflora" = "Veronica biflora",
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
                          "Carex atrata" = "Carex atrata cf",
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
  mutate(Species = ifelse(Species == "Unknown grass" & origSiteID == "Lia" & origBlockID == 8 & year(Date) == 2019, "Unknown graminoid1", Species),
         Species = ifelse(Species == "unknown graminoid" & origSiteID == "Lia" & origBlockID == 10 & year(Date) == 2019, "Unknown graminoid2", Species),
         Species = ifelse(Species == "unknown graminoid" & origSiteID == "Lia" & origBlockID == 6 & year(Date) == 2019, "Unknown graminoid3", Species),
         Species = ifelse(Species == "unknown poaceae" & origSiteID == "Lia" & origBlockID == 5 & year(Date) == 2019, "Unknown graminoid4", Species),
         
         Species = ifelse(Species == "unknown herb" & origSiteID == "Lia" & origBlockID == 1 & year(Date) == 2019, "Unknown herb1", Species),
         Species = ifelse(Species == "unknown herb" & origSiteID == "Lia" & origBlockID == 3 & year(Date) == 2019, "Unknown herb2", Species),
         Species = ifelse(Species == "unknown herb" & origSiteID == "Lia" & origBlockID == 5 & year(Date) == 2019, "Unknown herb3", Species),
         Species = ifelse(Species == "unknown herb" & origSiteID == "Lia" & origBlockID == 9 & year(Date) == 2019, "Unknown herb4", Species),
         Species = ifelse(Species == "Unknown herb" & origSiteID == "Lia" & origBlockID == 3 & year(Date) == 2019, "Unknown herb5", Species),
         
         Remark = ifelse(Species == "Unknown shrub, maybe salix" & origSiteID == "Lia" & origBlockID == 1 & year(Date) == 2019, "Maybe salix", Remark),
         Species = ifelse(Species == "Unknown shrub, maybe salix" & origSiteID == "Lia" & origBlockID == 1 & year(Date) == 2019, "Unknown shrub1", Species)) %>% 

  # Remove rows, with species, but where subplot and cover is zero
  filter_at(vars("1":"Cover"), any_vars(!is.na(.))) %>% 
  #Replace all NA in subplots with 0
  mutate_at(vars("1":"25"), ~replace_na(., 0)) %>% 
  mutate(Cover = as.numeric(Cover)) %>% 
  
  rename(date = Date, year = Year, species = Species, cover = Cover, recorder = Recorder, scribe = Scribe, remark = Remark) %>% 
  
  # # check for subplot level data
  # community %>%
  # # summarize cover from species that have been merged
  # group_by(origSiteID, origBlockID, origPlotID, destSiteID, destPlotID, destBlockID, turfID, warming, grazing, Nlevel, year, species) %>%
  # mutate(n = n()) %>% filter(n > 1) %>% View()
  
  # remove duplicate species that differ in cover. Duplcated because species name was changed (11 cases with very low cover (1-6), no need in changing cover estimate).
  anti_join(duplicate_problem, by = c("year", "turfID", "species", "cover")) %>% 
  group_by(origSiteID, origBlockID, origPlotID, destSiteID, destPlotID, destBlockID, turfID, warming, grazing, Nlevel, year, species, cover, recorder, scribe, remark, file) %>% 
  # remove 2 rows with same cover
  slice(1)


  
#### COVER ####
# Extract estimate of cover
cover <- community %>% 
  select(origSiteID:species, cover:file) %>% 
  filter(!species %in% c("Moss layer", "Vascular plant layer", "SumofCover", "Vascular plants", "Bryophytes", "Lichen", "Litter", "Bare soil", "Bare rock", "Poop", "Unknown seedlings"))

write_csv(cover, path = "data_cleaned/vegetation/THREE-D_Cover_2019_2020.csv", col_names = TRUE)



#### COMMUNITY STRUCTURE DATA ####
# Height
height <- community %>% 
  filter(species %in% c("Vascular plant layer", "Moss layer")) %>% 
  select(-c(`5`:`25`)) %>% 
  pivot_longer(cols = `1`:`4`, names_to = "subplot", values_to = "height") %>% 
  mutate(height = as.numeric(height)) %>% 
  group_by(turfID, year, species) %>% 
  summarise(height = mean(height, na.rm = TRUE)) %>% 
  rename("vegetation_layer" = "species")

write_csv(height, path = "data_cleaned/vegetation/THREE-D_Height_2019_2020.csv", col_names = TRUE)


# Cover from Functional Groups and Height
CommunityStructure <- community %>% 
  filter(species %in% c("SumofCover", "Vascular plants", "Bryophytes", "Lichen", "Litter", "Bare soil", "Bare rock", "Poop")) %>% 
  mutate(`24` = if_else(`24` == "Ratio > 1.5 is wrong", "0", `24`)) %>% 
  pivot_longer(cols = `1`:`25`, names_to = "subplot", values_to = "percentage") %>% 
  
  # make rows numeric
  mutate(percentage = as.numeric(percentage)) %>% 
  # calculate mean cover per turf
  group_by(origSiteID, origBlockID, origPlotID, destSiteID, destPlotID, destBlockID, turfID, warming, grazing, Nlevel, date, year, species, cover) %>% 
  summarise(mean = mean(percentage)) %>% 
  # fix whole plot vs. subplot cover estimate
  # 2019 whole plot for sum of cover and vascular plant cover
  # 2020 only sum of cover
  mutate(cover = case_when(year == 2019 & !species %in% c("Vascular plants", "SumofCover") ~ mean,
                           year == 2020 & !species %in% c("SumofCover") ~ mean)) %>% 
  ungroup() %>% 
  rename(functional_group = species) %>% 
  select(-mean)

write_csv(CommunityStructure, path = "data_cleaned/vegetation/THREE-D_CommunityStructure_2019_2020.csv", col_names = TRUE)


# 
# community %>% 
#   # summarize cover from species that have been merged
#   group_by(origSiteID, origBlockID, origPlotID, destSiteID, destPlotID, destBlockID, turfID, warming, grazing, Nlevel, year, species) %>% 
#   mutate(n = n()) %>% filter(n > 1) %>% View()


# subplot level data
CommunitySubplot <- community %>% 
  filter(!species %in% c("Moss layer", "Vascular plant layer", "SumofCover", "Vascular plants", "Bryophytes", "Lichen", "Litter", "Bare soil", "Bare rock", "Poop")) %>% 
  
  # make long table
  pivot_longer(cols = `1`:`25`, names_to = "subplot", values_to = "presence") %>% 
  # remove non-presence in subplot
  filter(presence != "0") %>% 
  
  # Unknown seedlings have sometimes counts, but not consistent. So make just presence.
  mutate(presence = ifelse(species == "Unknown seedlings", "s", presence),
         presence = recode(presence, "fd" = "df", "1j" = "j")) %>% 
  mutate(fertile = ifelse(presence %in% c("F", "f", "fd"), 1, 0),
         dominant = ifelse(presence %in% c("d", "fd", "dj"), 1, 0),
         juvenile = ifelse(presence %in% c("j", "dj"), 1, 0),
         seedling = ifelse(presence %in% c("s", "3"), 1, 0)) %>% 
  mutate(remark = if_else(presence %in% c("1?", "cf"), "species id uncertain", remark),
         remark = if_else(presence %in% c("3"), "probably 3 leontodon seedlings", remark),
         presence = if_else(presence %in% c("1", "1?", "cf", "3"), 1, 0)) %>% 
  pivot_longer(cols = c(presence:seedling), names_to = "variable", values_to = "value") %>% 
  select(year, date, origSiteID:Nlevel, subplot, species, variable, value, cover, remark, recorder) %>% 
  bind_rows(subplot_missing)

write_csv(CommunitySubplot, file = "data_cleaned/vegetation/THREE-D_CommunitySubplot_2019_2021.csv", col_names = TRUE)
