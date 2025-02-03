### figures

figure_plan <- list(
  
  # plot level data
  tar_target(
    name = soil_figure,
    command = {
      
      soil_dat <- bind_rows(plot_clean |> 
                              select(year:Namount_kg_ha_y, soil_depth_cm) |> 
                              mutate(destBlockID = as.character(destBlockID),
                                     variable = "soil_depth") |> 
                              rename(value = soil_depth_cm),
                            soil_character |> 
                              filter(variable %in% c("bulk_density_g_cm", "pH"),
                                     year == 2019), 
                            cn_clean |> 
                              filter((variable == "soil_organic_matter" & year == 2021) | 
                                       (variable %in% c("C_percent", "N_percent") & year == 2022))|>  
                              mutate(destBlockID = as.character(destBlockID))) |> 
        mutate(site = recode(destSiteID,
                             "Vikesland" = "Boreal",
                             "Joasete" = "Sub-alpine",
                             "Liahovden" = "Alpine"),
               site = factor(site, levels = c("Boreal", "Sub-alpine", "Alpine")),
               destSiteID = factor(destSiteID, levels = c("Vikesland", "Joasete", "Liahovden")),
               layer = if_else(is.na(layer), "Total", layer),
               variable = recode(variable,
                                 "bulk_density_g_cm" = "Bulk density (g cm3)",
                                 "C_percent" = "Carbon content (%)",
                                 "N_percent" = "Nitrogen content (%)",
                                 "soil_depth" = "Soil depth (cm)",
                                 "soil_organic_matter" = "Soil organic matter (g cm3)"),
               variable = factor(variable, levels = c("Soil depth (cm)", "Bulk density (g cm3)", "pH", "Carbon content (%)", "Nitrogen content (%)", "Soil organic matter (g cm3)")))
      
      
      ggplot(soil_dat, aes(x = site, y = value, fill = layer)) +
        geom_boxplot() +
        scale_fill_manual(name = "", values = c("burlywood1", "lightsalmon4", "grey40")) +
        facet_wrap(~ variable, scales = "free") +
        labs(x = "", y = "") +
        theme_bw()
      
      
    }
  ),
  
  
  tar_target(
    name = productivity_figure,
    command = productivity |>
      filter(treatment != "Control") |> 
      mutate(destSiteID = recode(destSiteID, Vikesland = "Boreal", Joasete = "Sub-alpine", Liahovden = "Alpine"),
             destSiteID = factor(destSiteID, levels = c("Boreal", "Sub-alpine", "Alpine")),
             treatment = recode(treatment, Cage = "Productivity")) |>
      group_by(destSiteID, treatment, date_out) |>
      summarise(mean = mean(value),
                se = sd(value)/sqrt(n())) |>
      ggplot(aes(x = date_out, y = mean, colour = treatment,
                 ymin = mean - se, ymax = mean + se)) +
      geom_point() +
      geom_errorbar() +
      scale_colour_manual(values = c("#D55E00", "#009E73"))+
      labs(x = "", y = bquote(Biomass~(g~cm^-2))) +
      facet_wrap(~ destSiteID) +
      theme_bw()
    
  )
  
  
)

# roots_clean |> 
#   mutate(origSiteID = recode(origSiteID, Joasete = "Sub-alpine", Liahovden = "Alpine")) |> 
#   filter(warming == "A", grazing == "C", Namount_kg_ha_y == 0) |> 
#   ggplot(aes(x = origSiteID, y = value, fill = period)) +
#   geom_boxplot() +
#   facet_wrap(~ variable, scale = "free")


# biomass_figure <- biomass_clean |> 
#   group_by(year, turfID, origSiteID, destSiteID, warming, Namount_kg_ha_y, grazing) |> 
#   summarise(biomass = sum(biomass)) |> 
#   # prettify
#   mutate(warming = recode(warming, A = "Ambient", W = "Warming"),
#          grazing = recode(grazing, C = "Control", M = "Medium", I = "Intensive"),
#          grazing = factor(grazing, levels = c("Control", "Medium", "Intensive")),
#          origSiteID = recode(origSiteID, Joa = "Sub-alpine", Lia = "Alpine")) |> 
#   ggplot(aes(x = log(Namount_kg_ha_y + 1), y = biomass, colour = warming, shape = grazing, linetype = grazing)) +
#   geom_point() +
#   geom_smooth(method = "lm", size = 0.8) +
#   scale_colour_manual(name = "Warming", values = c("grey30", "#FD6467")) +
#   scale_linetype_manual(name = "Grazing", values = c("solid", "dashed", "dotted")) +
#   scale_shape_manual(name = "Grazing", values = c(16, 0, 2)) +
#   # change labels to real values
#   scale_x_continuous(breaks = c(log(1), log(5), log(25), log(150)),
#                      labels = c(1, 5, 25, 150)) +
#   labs(x = bquote(log(Nitrogen)~kg~ha^-1~y^-1),
#        y = "Biomass (g)") +
#   facet_grid(origSiteID ~ year, scales = "free") +
#   theme_bw()
# 
# ggsave("biomass.png", biomass_figure, dpi = 300, width = 8, height = 8)
# 
# 
# tbi_index |> 
#   filter(k < 0.07) |> 
#   ggplot(aes(x = S, y = k, colour = origSiteID)) +
#   geom_point(alpha = 0.3) +
#   scale_colour_manual(name = "", values = c("grey30", "#FD6467")) +
#   #scale_shape_manual(name = "Grazing", values = c(16, 17)) +
#   facet_wrap(~ year)
# 
# 
# 
# 
# 
# dd <- soil_character |>
#   filter(variable == "bulk_density_g_cm") |> 
#   mutate(destSiteID = factor(destSiteID, levels = c("Vikesland", "Joasete", "Liahovden")))
# fit <- lm(value ~ destSiteID, dd)
# summary(fit)
