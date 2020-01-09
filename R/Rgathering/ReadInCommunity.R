###########################
 ### READ IN DATA ###
###########################

source("R/Load packages.R")
source("R/Rgathering/create meta data.R")

# file <- "data/community/2019/Lia/THREE-D_CommunityData_Lia_1_2019.xlsx"
# dd <- read_xlsx(path = file, sheet = 7, skip = 2, n_max = 61, col_types = "text")
# dd %>% pn
# read_xlsx(path = file, sheet = 5, n_max = 1, col_types = "text")


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
metaComm <- map_df(set_names(files), function(file) {
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
community <- metaComm %>% 
  right_join(comm, by = c("origSiteID", "origBlockID", "origPlotID")) %>%
  select(-turfID) %>% 
  left_join(metaTurfID, by = c("origSiteID", "origBlockID", "origPlotID")) %>% 
  select(origSiteID:origPlotID, destSiteID:turfID, warming:Nlevel, Date, Year, Species:Cover, Recorder, Scribe, Remark, file) %>% 
  
  # Remove rows, without species, subplot and cover is zero
  filter_at(vars("Species", "1":"Cover"), any_vars(!is.na(.))) %>% 

  # Remove species NA, are all these rows: Ratio > 1.5 is wrong
  filter(!is.na(Species)) %>% 
  # FIX!!!
  filter(Species != "Height / depth (cm)") %>% 
  
  # Remove white space after Species name
  mutate(Species = str_trim(Species, side = "right")) %>% 
  mutate(Recorder = recode(Recorder, "silje" = "so")) %>% 
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
         
         Species = ifelse(Species == "Unknown shrub, maybe salix" & origSiteID == "Lia" & origBlockID == 1 & year(Date) == 2019, "Unknown shrub1", Species)) %>% 
    
  # Remove rows, with species, but where subplot and cover is zero
  filter_at(vars("1":"Cover"), any_vars(!is.na(.))) %>% 
  #Replace all NA in subplots with 0
  mutate_at(vars("1":"25"), ~replace_na(., 0)) 

# A tibble: 4,075 x 37



#### COVER ####
# Extract estimate of cover
cover <- community %>% 
  select(origSiteID:Species, Cover, Recorder, Remark, file) %>% 
  filter(!Species %in% c("Moss layer", "Vascular plant layer", "SumofCover", "Vascular plants", "Bryophytes", "Lichen", "Litter", "Bare soil", "Bare rock", "Poop", "Unknown seedlings"))

write_csv(cover, path = "data/community/THREE-D_Cover_2019.csv", col_names = TRUE)


#### COMMUNITY META DATA ####
# Height
height <- community %>% 
  filter(Species %in% c("Vascular plant layer", "Moss layer")) %>% 
  select(-c(`5`:`25`)) %>% 
  pivot_longer(cols = `1`:`4`, names_to = "number", values_to = "Height") %>% 
  mutate(Height = as.numeric(Height)) %>% 
  group_by(turfID, Year, Species) %>% 
  summarise(MeanHeight = mean(Height, na.rm = TRUE)) %>% 
  rename("Layer" = "Species")

# Cover from Functional Groups
metaCommunity <- community %>% 
  filter(Species %in% c("SumofCover", "Vascular plants", "Bryophytes", "Lichen", "Litter", "Bare soil", "Bare rock", "Poop")) %>%
  pivot_longer(cols = `1`:`25`, names_to = "subplot", values_to = "percentage") %>% 
  # make rows numeric
  mutate(percentage = as.numeric(percentage)) %>% 
  group_by(turfID, Cover, Species) %>% 
  summarise(mean = mean(percentage)) %>% 
  mutate(MeanCover = ifelse(Species %in% c("Vascular plants", "SumofCover"), Cover, mean)) %>% 
  ungroup() %>% 
  rename(FunctionalGroup = Species) %>% 
  select(turfID, FunctionalGroup, MeanCover) %>% 
  left_join(metaTurfID, by = "turfID") #%>% 
  ### Should height be added??? !!!
  #left_join(height, by = "turfID")

write_csv(metaCommunity, path = "data/community/THREE-D_metaCommunity_2019.csv", col_names = TRUE)


# subplot level data
CommunitySubplot <- community %>% 
  filter(!Species %in% c("Moss layer", "Vascular plant layer", "SumofCover", "Vascular plants", "Bryophytes", "Lichen", "Litter", "Bare soil", "Bare rock", "Poop")) %>% 
  select(-Scribe) %>% 
  pivot_longer(cols = `1`:`25`, names_to = "Subplot", values_to = "Presence") %>%
  # Unknown seedlings have sometimes counts, but not consistent. So make just presence.
  mutate(Presence = ifelse(Species == "Unknown seedlings" & Presence != "0", "s", Presence),
         Presence = recode(Presence, "df" = "fd", "1j" = "j")) %>% 
  mutate(Fertile = ifelse(Presence %in% c("f", "fd"), 1, 0),
         Dominant = ifelse(Presence %in% c("d", "fd", "dj"), 1, 0),
         Juvenile = ifelse(Presence %in% c("j", "dj"), 1, 0),
         Seedling = ifelse(Presence == "s", 1, 0)) %>% 
  mutate(Presence = ifelse(Presence != "0", 1, 0))

write_csv(CommunitySubplot, path = "data/community/THREE-D_CommunitySubplot_2019.csv", col_names = TRUE)