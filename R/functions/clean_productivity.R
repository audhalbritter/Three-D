### Productivity 2022 ####

clean_productivity <- function(productivity_raw){
  
  productivity <- productivity_raw |> 
    # scale biomass that was cut on smaller square
    mutate(area_cm = if_else(area_cm == 625, 900, area_cm),
           biomass = if_else(area_cm == 625, biomass*625/900, biomass)) |> 
    # biomass per cm2
    mutate(productivity = biomass/area_cm) |> 
    mutate(duration = date_out - date_in) |> 
    rename(destSiteID = siteID) |> 
    # change site names
    mutate(destSiteID = case_when(destSiteID == "Joa" ~ "Joasete",
                                  destSiteID == "Lia" ~ "Liahovden",
                                  destSiteID == "Vik" ~ "Vikesland",
                                  TRUE ~ destSiteID)) |> 
    select(date_in, date_out, duration, destSiteID:plot_nr, area_cm2 = area_cm, productivity, remark)
  
}

# Check data
# productivity |> 
#   ggplot(aes(x = factor(date_out), y = productivity, fill = treatment)) +
#   geom_boxplot() +
#   facet_grid(~ siteID)
# 
# productivity |> 
#   mutate(siteID = factor(siteID, levels = c("Vik", "Joa", "Lia"))) |> 
#   ggplot(aes(x = siteID, y = productivity, fill = treatment)) +
#   geom_boxplot()
# 
# # test if cage and control differ
# fit <- lm(productivity ~ treatment*siteID, productivity)
# summary(fit)

