# clean meta data

clean_plot <- function(plot_raw, metaTurfID){
  
  #### PLOT LEVEL META DATA ####
  plot_clean <- plot_raw %>% 
    # remove rows with data after transplant, duplicate
    filter(remark != "after transplant" | is.na(remark)) %>% 
    # change site names
    mutate(origSiteID = case_when(origSiteID == "Joa" ~ "Joasete",
                                  origSiteID == "Lia" ~ "Liahovden",
                                  TRUE ~ origSiteID),
           destSiteID = case_when(destSiteID == "Joa" ~ "Joasete",
                                  destSiteID == "Lia" ~ "Liahovden",
                                  destSiteID == "Vik" ~ "Vikesland",
                                  TRUE ~ destSiteID)) |> 
    left_join(metaTurfID, by = c("origSiteID", "origBlockID", "origPlotID", "destSiteID", "destPlotID", "destBlockID", "turfID")) %>% 
    # calculate mean soil depth
    mutate(soil_depth_cm = (soil_depth1 + soil_depth2 + soil_depth3 + soil_depth4) / 4,
           soil_depth_cm = if_else(origPlotID == 106, 36.1, soil_depth_cm),
           slope = if_else(slope == 280, 28, slope),
           year = 2019,
           date_slope = dmy(date_slope),
           date_depth =dmy(date_depth)) %>% 
    select(year, origSiteID:turfID, warming:Nlevel, Namount_kg_ha_y, date_slope:slope, aspect = exposure, date_depth, soil_depth_cm, remark)

}



# save data as csv
save_csv <- function(file, nr = "", name) {
  
  filepath <- paste0("data_cleaned/", nr, "Three-D_clean_", name, ".csv")
  output <- write_csv(x = file, file = filepath)
  filepath
}
