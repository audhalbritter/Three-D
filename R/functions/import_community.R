# import community
import_community <- function(metaTurfID){
  
  #### COMMUNITY DATA ####
  ### Read in files
  files <- dir(path = "data/community", pattern = "\\.xlsx$", full.names = TRUE, recursive = TRUE)
  
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
    
    # change site names
    mutate(origSiteID = case_when(origSiteID == "Joa" ~ "Joasete",
                                  origSiteID == "Lia" ~ "Liahovden",
                                  TRUE ~ origSiteID),
           destSiteID = case_when(destSiteID == "Joa" ~ "Joasete",
                                  destSiteID == "Lia" ~ "Liahovden",
                                  destSiteID == "Vik" ~ "Vikesland",
                                  TRUE ~ destSiteID)) |> 
    
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
  # rules <- validator(Date = is.Date(Date),
  #                    Rec = is.character(Recorder),
  #                    Scr = is.character(Scribe))
  # out <- confront(metaComm, rules)
  # summary(out)
  
  
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
    select(origSiteID:origPlotID, destSiteID:turfID, warming:Nlevel, Date, Year, Species:Cover, Recorder, Scribe, Remark, file)
  
}