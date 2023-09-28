# clean reflectance data

clean_reflectance <- function(ndvi20_raw, ndvi20_2_raw, ndvi22_raw, metaTurfID){
  
  # 2020 data
  ndvi20 <- ndvi20_raw %>% 
    rename(nr = measurement) %>% 
    mutate(date = dmy(date),
           year = year(date)) |> 
    left_join(metaTurfID)
  
  ndvi20_2 <- ndvi20_2_raw %>% 
    mutate(date = dmy(date),
           year = year(date)) %>% 
    select(year, date, destSiteID:turfID, nr, campaign, ndvi) |> 
    left_join(metaTurfID)
    
  # 2022 data
  ndvi22 <- ndvi22_raw %>% 
    filter(!is.na(ndvi)) |> 
    mutate(year = year(date)) |> 
    left_join(metaTurfID)
  
  bind_rows(ndvi20, ndvi20_2, ndvi22) |> 
    # fix wrong data (comma forgotten)
    mutate(ndvi = if_else(ndvi > 1, ndvi/100, ndvi)) %>% 
    # remove empty rows
    filter(!is.na(ndvi)) %>% 
    # convert campaign nr to timing
    mutate(timing = case_when(destSiteID == "Lia" & campaign == 2 ~ "After 1. cut",
                              destSiteID == "Lia" & campaign == 3 ~ "After 1. cut",
                              destSiteID == "Lia" & campaign == 4 ~ "After 2. cut",
                              
                              destSiteID == "Joa" & campaign == 2 ~ "After 1. cut",
                              destSiteID == "Joa" & campaign == 3 ~ "After 2. cut",
                              destSiteID == "Joa" & campaign == 4 ~ "After 3. cut",
                              
                              destSiteID == "Vik" & campaign == 2 ~ "After 2. cut",
                              destSiteID == "Vik" & campaign == 3 ~ "After 2. cut",
                              destSiteID == "Vik" & campaign == 4 ~ "After 3. cut",
                              
                              year == 2022 ~ "after 2. cut",
                              TRUE ~ timing)) |> 
    mutate(timing = tolower(timing)) |> 
    select(year, date, origSiteID:Nlevel, Namount_kg_ha_y, origPlotID:turfID, timing, replicate = nr, ndvi, remark, flux_campaign = campaign)
  
}


# Check data
# ndvi %>% 
#   filter(timing == c("After 3. cut")) %>% 
#   ggplot(aes(x = factor(Nlevel), y = ndvi, fill = warming)) +
#   geom_boxplot() +
#   facet_grid( ~ origSiteID)