#Read China comm data

source("R/Load packages.R")
source("R/Rgathering/create meta data.R")


# turfID dic for wrong turfIDs in 2021

# fix site names in meta data
meta_c <- metaTurfID_China %>% 
  mutate(origSiteID = recode(origSiteID,  "Top" = "H", "Middle" = "M", "Low" = "L"),
         destSiteID = recode(destSiteID,  "Top" = "H", "Middle" = "M", "Low" = "L"))

turfID_2021_dic <- bind_cols(
  meta_c %>% 
    filter(origSiteID == "H", warming == "W") %>% 
    select(turfID) %>% 
    rename(correct_turfID = turfID),
  meta_c %>% 
    filter(origSiteID == "M", warming == "W") %>% 
    select(turfID) %>% 
    rename(wrong_turfID = turfID)
) %>% 
  mutate(destSiteID = "M")

write_csv(turfID_2021_dic, file = "data_china/turfID_2021_dic.csv")

# read in 2019 - 2021 data
files <- dir(path = "data_china/Data-Community/", pattern = "\\.xlsx$", full.names = TRUE, recursive = TRUE)

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


metaComm_raw2 <- metaComm_raw %>% 
  select(file, sheet_name, Date, destSiteID, destBlockID, destPlotID, turfID, Recorder, Scribe) %>% 
  mutate(Year = year(Date))

metaComm <- metaComm_raw2 %>% 
  filter(Year == 2019) %>% 
  # change dest to orig, because before transplant
  rename(origSiteID = destSiteID, origBlockID = destBlockID, origPlotID = destPlotID) %>% 
  mutate(turfID = gsub("_", " ", turfID),
         turfID = gsub("  ", " ", turfID),
         # fix wrong blockID
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
         origPlotID = if_else(turfID == "121 AN7M 121", 121, origPlotID)) %>% 
  left_join(meta_c, by = c("origSiteID", "origBlockID", "origPlotID", "turfID")) %>% 

  # bind rows with 2021 data
  bind_rows(
    metaComm_raw2 %>% 
      filter(Year == 2021) %>% 
      mutate(destSiteID = as.character(destSiteID),
             # recode site names to match 2019 data
             destSiteID = recode(destSiteID,  "4400" = "H", "4000" = "M", "3500" = "L")) %>% 
    # fix wrong turfIDs
    left_join(turfID_2021_dic, by = c("turfID" = "wrong_turfID", "destSiteID")) %>% 
    mutate(turfID = if_else(!is.na(correct_turfID), correct_turfID, turfID)) %>% 
    select(-correct_turfID) %>% 
    # fix wrong turfID, destplotID and destBlockID
    mutate(turfID = if_else(turfID == "9 WN6I 89" & destSiteID == "H", "11 AN6M 11", turfID),
           destPlotID = case_when(turfID == "101 WN5M 171" ~ 171,
                                  turfID == "79 WN2N 159" ~ 159,
                                  turfID == "160 AN2N 160" ~ 160,
                                  turfID == "74 AN2C 74" ~ 74,
                                  TRUE ~ destPlotID),
           destBlockID = case_when(turfID == "79 WN2N 159" ~ 10,
                                   turfID == "160 AN2N 160" ~ 10,
                                   turfID == "1 AN1I 1" ~ 1,
                                   turfID == "3 AN1C 3" ~ 1,
                                   turfID == "5 AN1M 5" ~ 1,
                                   turfID == "7 AN1N 7" ~ 1,
                                   turfID == "11 AN6M 11" ~ 2,
                                   turfID == "12 AN6I 12" ~ 2,
                                   turfID == "14 AN6C 14" ~ 2,
                                   turfID == "16 AN6N 16" ~ 2,
                                  TRUE ~ destBlockID)) %>% 
    left_join(meta_c, by = c("destSiteID", "destBlockID", "destPlotID", "turfID"))
    )

  
# no data in 2021, are they missing?
# 159 WN2N 200
# 160 AN2N 160


# Read in community data
files <- dir(path = "data_china/Data-Community", pattern = "\\.xlsx$", full.names = TRUE, recursive = TRUE)

comm <- map_df(set_names(files), function(file) {
  file %>% 
    excel_sheets() %>% 
    set_names() %>% 
    discard(. == "Sheet1") %>% 
    map_df(~ read_xlsx(path = file, sheet = .x, skip = 2, n_max = 61, col_types = "text"), .id = "sheet_name")
}, .id = "file") %>% 
  rename("Cover" = `%`) 

comm2 <- comm %>% 
  # remove empty rows
  filter(!is.na(Species)) %>% 
  # extract year from file path, first 4 digit
  mutate(Year = as.numeric(stri_extract_first_regex(file, "\\d{4}")),
         # remove underscore from sheet name
         sheet_name = gsub("_", " ", sheet_name),
         # extract site from file name and rename
         site = dirname(file) %>% str_remove("^.*Site_") %>% recode(., "4400m" = "H", "4000m" = "M", "3500m" = "L"),
         # 2019 is origin site, 2021 is dest site
         origSiteID = if_else(Year == 2019, site, NA_character_),
         destSiteID = if_else(Year == 2021, site, NA_character_)) %>% 
  select(-site) %>% 
  # fix wrong turfIDs in 2021
  left_join(turfID_2021_dic, by = c("sheet_name" = "wrong_turfID", "destSiteID")) %>% 
  mutate(sheet_name = if_else(!is.na(correct_turfID), correct_turfID, sheet_name)) %>% 
  select(-correct_turfID)

duplicates <- metaComm %>% 
  rename(sheet_name2 = sheet_name) %>% 
  left_join(comm2 %>% select(-file), by = c("turfID" = "sheet_name", "Year")) %>% 
  mutate(origSiteID = coalesce(origSiteID.x, origSiteID.y),
         destSiteID = coalesce(destSiteID.x, destSiteID.y)) %>% 
  select(-origSiteID.x, -origSiteID.y, -destSiteID.x, -destSiteID.y) %>% 
  rename(date = Date, year = Year, species = Species, cover = Cover, recorder = Recorder, scribe = Scribe, remark = Remark) %>% 
  select(origSiteID, origBlockID, origPlotID, destSiteID, destPlotID, destBlockID, turfID, warming, grazing, Nlevel, year, date, species, cover, "1":"25", recorder, scribe, remark, file) %>% 
  group_by(turfID, year, species) %>% 
  
  # Need to fix duplicates!!!
  #group_by(origSiteID, origBlockID, origPlotID, destSiteID, destPlotID, destBlockID, turfID, warming, grazing, Nlevel, year, species, cover, recorder, scribe, remark, file) %>% 
  mutate(n = n()) %>% filter(n > 1)
  # remove 2 rows with same cover
  #slice(1)

write_csv(duplicates, file = "data_china/duplicates.csv")

### 2 datasheets are called the same! 2021, H, bl 10: 4 AN2C 74
  
# problems that need fixing:
# duplicate species per plot, some with same cover, some have not the same cover
# species was missing in one sheet
# check sheet name and turfIDs, site, plot and block names
# turfID and sheet name is wrong in 2021 for plots that were moved from H to M.

  
