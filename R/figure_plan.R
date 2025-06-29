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
    
  ),
  
  tar_target(
    name = biomass_figure,
    command = {
      
      biomass_clean |> 
        # calculate area in m2 and scale biomass to m2
        mutate(area_m2 = area_cm2 / 10000,
               biomass_scaled = biomass / area_m2
        ) |> 
        # prettify
        mutate(origSiteID = recode(origSiteID, "Liahovden" = "Alpine", "Joasete" = "Sub-alpine"),
               origSiteID = factor(origSiteID, levels = c("Alpine", "Sub-alpine")),
               grazing = factor(grazing, levels = c("C", "M", "I")),
               grazing = recode(grazing, "C" = "Control", "M" = "Medium", "I" = "Intensive"),
               warming = recode(warming, "A" = "Ambient", "W" = "Warming")) |> 
        # filter only 2022. Filter for only one cut at peak growing season.
        filter(year == 2022,
               grazing == "Control" & cut == 3|
                 grazing %in% c("Medium", "Intensive") & cut == 4) |>
        mutate(warm_site = paste(origSiteID, warming, sep = " "),
               fun_group = factor(fun_group, levels = c("shrub", "graminoids", "cyperaceae", "forbs", "legumes", "bryophytes", "litter"))) |>
        ggplot(aes(x = factor(Namount_kg_ha_y), y = biomass_scaled, fill = fun_group)) +
        geom_col(position = "fill") +
        scale_fill_manual(values = c("darkgreen", "limegreen", "lawngreen", "plum4", "plum2", "orange", "peru"), name = "") +
        labs(y = "Proportional functional group composition",
             x = bquote(Nitrogen~(kg~ha^-1~y^-1))) +
        facet_grid(origSiteID * warming ~ grazing) +
        theme_bw() +
        theme(legend.position = "top",
              text = element_text(size = 12))
      
    }
  ),
  tar_target(
    name = cflux_figure2020,
    command = {
      join_cflux |>
      filter(
        type %in% c("ER", "NEE", "GPP")
        & lubridate::year(date_time) == 2020
      ) |>
      mutate(
        origSiteID = recode(origSiteID, "Liahovden" = "Alpine", "Joasete" = "Sub-alpine"),
        origSiteID = factor(origSiteID, levels = c("Alpine", "Sub-alpine")),
        grazing = factor(grazing, levels = c("C", "M", "I")),
        grazing = recode(grazing, "C" = "Control", "M" = "Medium", "I" = "Intensive"),
        warming = recode(warming, "A" = "Ambient", "W" = "Warming")
        ) |>
        ggplot(aes(x = date_time, y = f_flux, color = warming, shape = origSiteID, linetype = origSiteID)) +
        theme_bw() +
        geom_point() +
        # geom_violin() +
        facet_grid(type ~ ., scales = "free") +
        geom_smooth(method = "lm",
                    formula = y ~ poly(x, 3),
                    se = TRUE, linewidth = 0.5, fullrange = FALSE) +
        scale_color_manual(values = c(
          "Ambient" = "#1762ad",
          "Warming" = "#c8064a"
        )) +
        # scale_shape_manual(values = c(
        #   "Sub-alpine" = 1,
        #   "Alpine" = 16
        # )) +
        geom_hline(yintercept = 0, linewidth = 0.3) +
        labs(
          title = bquote(~CO[2]~ "fluxes in 2020"),
          # caption = bquote(~CO[2]~'flux standardized at PAR = 300 '*mu*mol/m^2/s*' for NEE and PAR = 0 '*mu*mol/m^2/s*' for ER'),
          color = "Warming",
          shape = "Site",
          linetype = "Site",
          x = "Date",
          y = bquote(~CO[2]~'flux [mmol/'*m^2*'/h]')
        ) +
        theme(
      legend.position="none"
    )
        # facet_grid(type ~ origSiteID, scales = "free")
      # ggsave("cflux_figure2020.png", dpi = 300, width = 8, height = 6)
    }
  ),
  tar_target(
    name = cflux_figure2021,
    command = {
      join_cflux |>
      filter(
        type %in% c("ER", "NEE", "GPP")
        & lubridate::year(date_time) == 2021
      ) |>
      mutate(
        origSiteID = recode(origSiteID, "Liahovden" = "Alpine", "Joasete" = "Sub-alpine"),
        origSiteID = factor(origSiteID, levels = c("Alpine", "Sub-alpine")),
        grazing = factor(grazing, levels = c("C", "M", "I", "N")),
        grazing = recode(grazing, "C" = "Control", "M" = "Medium", "I" = "Intensive", "N" = "Natural"),
        warming = recode(warming, "A" = "Ambient", "W" = "Warming")
        # Namount_kg_ha_y = factor(Namount_kg_ha_y)
        ) |>
        # ggplot(aes(x = date_time, y = PAR_corrected_flux, color = warming, shape = origSiteID, linetype = origSiteID)) +
        ggplot(aes(x = Namount_kg_ha_y, y = PAR_corrected_flux, color = warming, shape = origSiteID, linetype = origSiteID)) +
        theme_bw() +
        geom_point() +
        # geom_violin() +
        facet_grid(type ~ grazing, scales = "free") +
        geom_smooth(method = "lm",
                    # formula = y ~ poly(x, 3),
                    se = TRUE, linewidth = 0.5, fullrange = FALSE) +
        scale_color_manual(values = c(
          "Ambient" = "#1762ad",
          "Warming" = "#c8064a"
        )) +
        # scale_shape_manual(values = c(
        #   "Sub-alpine" = 1,
        #   "Alpine" = 16
        # )) +
        geom_hline(yintercept = 0, linewidth = 0.3) +
        scale_x_continuous(trans = pseudo_log_trans(base = 10), breaks = c(0, 1, 10, 100)) +
        # scale_x_continuous(trans = "log10") +
        labs(
          title = bquote(~CO[2]~ "fluxes in 2021"),
          # caption will need to go in the manuscript specifying that it is for 2021 fluxes
          # caption = bquote(~CO[2]~'flux standardized at PAR = 300 '*mu*mol/m^2/s*' for NEE and PAR = 0 '*mu*mol/m^2/s*' for ER'),
          color = "Warming",
          shape = "Site",
          linetype = "Site",
          x = "N addition",
          y = bquote(~CO[2]~'flux [mmol/'*m^2*'/h]')
        ) +
        theme(
          legend.position = "bottom"
        )
        # facet_grid(type ~ origSiteID, scales = "free")
      # ggsave("cflux_figure2021.png", dpi = 300, width = 8, height = 6)
    }
  ),
  tar_target(
    name = cflux_figure_all,
    command = {
      join_cflux |>
      filter(
        type %in% c("ER", "NEE", "GPP")
      ) |>
      mutate(
        origSiteID = recode(origSiteID, "Liahovden" = "Alpine", "Joasete" = "Sub-alpine"),
        origSiteID = factor(origSiteID, levels = c("Alpine", "Sub-alpine")),
        grazing = factor(grazing, levels = c("C", "M", "I", "N")),
        grazing = recode(grazing, "C" = "Control", "M" = "Medium", "I" = "Intensive", "N" = "Natural"),
        warming = recode(warming, "A" = "Ambient", "W" = "Warming")
        # Namount_kg_ha_y = factor(Namount_kg_ha_y)
        ) |>
        # ggplot(aes(x = date_time, y = PAR_corrected_flux, color = warming, shape = origSiteID, linetype = origSiteID)) +
        ggplot(aes(x = Namount_kg_ha_y, y = f_flux, color = warming, shape = origSiteID, linetype = origSiteID)) +
        theme_bw() +
        geom_point() +
        # geom_violin() +
        facet_grid(type ~ grazing, scales = "free") +
        geom_smooth(method = "lm",
                    # formula = y ~ poly(x, 3),
                    se = TRUE, linewidth = 0.5, fullrange = FALSE) +
        scale_color_manual(values = c(
          "Ambient" = "#1762ad",
          "Warming" = "#c8064a"
        )) +
        # scale_shape_manual(values = c(
        #   "Sub-alpine" = 1,
        #   "Alpine" = 16
        # )) +
        geom_hline(yintercept = 0, linewidth = 0.3) +
        scale_x_continuous(trans = scales::pseudo_log_trans(base = 10), breaks = c(0, 1, 10, 100)) +
        labs(
          title = bquote(~CO[2]~ "fluxes in 2020 and 2021"),
          # caption = bquote(~CO[2]~'flux standardized at PAR = 300 '*mu*mol/m^2/s*' for NEE and PAR = 0 '*mu*mol/m^2/s*' for ER'),
          color = "Warming",
          shape = "Site",
          linetype = "Site",
          x = "N addition",
          y = bquote(~CO[2]~'flux [mmol/'*m^2*'/h]')
        )
        # facet_grid(type ~ origSiteID, scales = "free")
      # ggsave("cflux_figure_all.png", dpi = 300, width = 8, height = 6)
    }
  ),
  tar_target(
    name = cflux_patchwork,
    command = {
      patchwork <- cflux_figure2020 + cflux_figure2021 +
      plot_layout(
        # guides = "collect",
        ncol = 1,
        nrow = 2
      ) +
      plot_annotation(tag_levels = "a")
      ggsave("cflux_figure_all.png", plot = patchwork, dpi = 300, width = 8, height = 12)
    }
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
