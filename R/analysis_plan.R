### analysis plan

analysis_plan <- list(
  
  # climate data
  tar_target(
    name = daily_temp,
    command = climate_clean %>%
      mutate(date = dmy(format(date_time, "%d.%b.%Y"))) |>
      # daily temperature
      group_by(date, destSiteID, destBlockID, destPlotID, origSiteID, origBlockID, warming, Nlevel, grazing, Namount_kg_ha_y) %>%
      summarise(air_temperature = mean(air_temperature, na.rm = TRUE),
                ground_temperature = mean(ground_temperature, na.rm = TRUE),
                soil_temperature = mean(soil_temperature, na.rm = TRUE),
                soilmoisture = mean(soilmoisture, na.rm = TRUE)) |>
      pivot_longer(cols = c(air_temperature:soilmoisture), names_to = "variable", values_to = "value") |>
      filter(!is.na(value)) |>
      # prettify
      mutate(warming = recode(warming, A = "Ambient", W = "Warming"),
             grazing = recode(grazing, C = "Control", M = "Medium", I = "Intensive"),
             grazing = factor(grazing, levels = c("Control", "Medium", "Intensive")),
             origSiteID = recode(origSiteID, Joasete = "Sub-alpine", Liahovden = "Alpine"),
             variable = recode(variable, air_temperature = "air", ground_temperature = "ground", soil_temperature = "soil"))
    
  ),
  
  # summer temp
  # remove 2019 because data starts in August
  tar_target(
    name = summer_temp,
    command = {
      
      dat <- daily_temp |>
        mutate(month = month(date),
               year = year(date)) %>%
        filter(month %in% c(5, 6, 7, 8, 9),
               year %in% c(2020, 2021),
               # only controls
               Nlevel %in% c(1, 2, 3),
               grazing == "Control")
      
      dat %>%
        group_by(origSiteID, variable, warming) %>%
        summarise(mean = mean(value),
                  se = sd(value)/sqrt(n())) |>
        pivot_wider(names_from = warming, values_from = c(mean, se)) |>
        mutate(diff = round((mean_Warming - mean_Ambient), 2),
               se_diff = round((sqrt(se_Warming^2+se_Ambient^2)), 3))
      
    }
  ),
  
  # plot level data
  tar_target(
    name = plot_level_summary,
    command = plot_clean |> 
      group_by(destSiteID) |> 
      summarize(mean_slope = mean(slope),
                se_slope = sd(slope)/n(),
                mean_aspect = mean(aspect), 
                se_aspect = sd(aspect)/n(), 
                depth = mean(soil_depth_cm),
                se = sd(soil_depth_cm)/n())
  ),
  
  
  
  # productivity
  tar_target(
    name = productivity,
    command = productivity_clean |> 
        # average first round with no cage
        group_by(destSiteID, date_out, treatment, plot_nr) |>
        summarise(productivity = mean(productivity), .groups = "drop") |> 
        pivot_wider(names_from = treatment, values_from = productivity) |> 
        filter(!is.na(Cage)) |> 
        mutate(Consumption = Cage - Control) |> 
        pivot_longer(cols = c(Cage, Control, Consumption), names_to = "treatment", values_to = "value")
  ),
  
  tar_target(
    name = productivity_summary,
    command = productivity |> 
      # sum biomass for the whole year
      group_by(destSiteID, treatment, plot_nr) |> 
      summarise(sum = sum(value), .groups = "drop") |> 
      pivot_wider(names_from = treatment, values_from = sum) |> 
      mutate(Consumption = Cage - Control) |> 
      pivot_longer(cols = c(Cage, Control, Consumption), names_to = "treatment", values_to = "value") |> 
      # average per site and treatment
      group_by(destSiteID, treatment) |> 
      summarise(mean(value), sd(value)/sqrt(n()))
    
  ),
  
  tar_target(
    name = productivity_analysis,
    command = {
      
      productivity |> 
        group_by(treatment) |> 
        nest() |> 
        mutate(fit_site = map(.x = data, .f = ~lm(value ~ destSiteID, data = .)),
               fit_time = map(.x = data, .f = ~lm(value ~ date_out * destSiteID, data = .)),
               res_site = map(.x = fit_site, .f = tidy),
               res_time = map(.x = fit_time, .f = tidy)) |> 
        unnest(res_site)
      
      }

  ),
  
  # reflectance
  tar_target(
    name = reflectance_summary,
    command = ndvi_clean |> 
      filter(year == 2020) |> 
      group_by(date) |> 
      summarise(min(ndvi),
                max(ndvi),
                mean(ndvi),
                sd(ndvi)/sqrt(n()))
    
  ),
  
  # roots
  tar_target(
    name = root_days_summary,
    command = roots_clean |> 
      mutate(days = as.numeric(as.character(days_buried))) |> 
      group_by(year) |> 
      summarise(mean = mean(days),
                se = sd(days)/sqrt(n()))
  ),
  
  tar_target(
    name = root_summary,
    command = roots_clean |> 
      filter(warming == "A", grazing == "C", Namount_kg_ha_y == 0) |> 
      filter(variable == "root_productivity_g_cm3_y") |> 
      mutate(value = 1000 * value) |> 
      group_by(period, destSiteID) |> 
      summarise(mean = mean(value),
                se = sd(value)/sqrt(n()))
  ),
  
  tar_target(
    name = root_traits_summary,
    command = roots_clean |> 
      filter(warming == "A", grazing == "C", Namount_kg_ha_y == 0) |> 
      filter(variable != "root_productivity_g_cm3_y") |> 
      group_by(period, variable, destSiteID) |> 
      summarise(mean = mean(value),
                se = sd(value)/sqrt(n()))
  ),
  
  tar_target(
    name = root_analysis,
    command = {
      
      roots_clean |> 
        filter(warming == "A", grazing == "C", Namount_kg_ha_y == 0) |> 
        filter(variable != "root_productivity_g_cm3_y") |>
        group_by(variable) |> 
        nest() |> 
        mutate(fit = map(.x = data, .f = ~lm(value ~ destSiteID, data = .)),
               res = map(.x = fit, .f = tidy)) |> 
        unnest(res)
      
      roots_clean |> 
        filter(warming == "A", grazing == "C", Namount_kg_ha_y == 0) |> 
        filter(variable == "root_productivity_g_cm3_y") |>
        group_by(variable) |> 
        nest() |> 
        mutate(fit = map(.x = data, .f = ~lm(value ~ destSiteID*period, data = .)),
               res = map(.x = fit, .f = tidy)) |> 
        unnest(res)
    }
    
  ),
  
  
  # community
  tar_target(
    name = nr_species,
    command = cover_clean |> 
      distinct(species) |> 
      arrange(species) |> 
      filter(!grepl("Unknown", species)) |> 
      filter(!grepl("Antennaria alpina cf|Antennaria dioica cf|Carex capillaris cf|Carex leporina cf|Carex rupestris cf|Carex vaginata cf|Carex sp|Carex sp3|Epilobium anagallidifolium cf|Euphrasia sp|Luzula multiflora cf|Luzula sp|Taraxacum sp.", species)) |> 
      print(n = Inf)
  ),
  
  tar_target(
    name = cover_summary,
    command = cover_clean |> 
      group_by(year, origSiteID, warming, grazing, Namount_kg_ha_y, turfID) |> 
      summarise(n = n()) |> 
      group_by(origSiteID) |> 
      summarise(mean = mean(n), 
                se = sd(n)/sqrt(n()),
                min = min(n), 
                max = max(n))
  ),
  
  tar_target(
    name = cover_summary2,
    command = cover_clean |> 
      filter(Namount_kg_ha_y %in% c(0, 10, 150), grazing %in% c("C", "N"),
             year == 2022) |> 
      group_by(origSiteID, warming, grazing, Nlevel, Namount_kg_ha_y) |> 
      summarise(richness = n()) |> 
      group_by(origSiteID, warming, grazing, Namount_kg_ha_y) |> 
      summarise(richness = mean(richness))
  ),
  
  tar_target(
    name = pca,
    command = {
      
      set.seed(32)
      
      comm_wide <- cover_clean %>%
        mutate(cover = sqrt(cover),
               warming = recode(warming, A = "Ambient", W = "Warming"),
               grazing = recode(grazing, C = "Control", M = "Medium", I = "Intensive", N = "Natural")) |>
        filter(year == 2022) |> 
        select(origSiteID:cover) |> 
        group_by(turfID, species) |> 
        mutate(n = 1:n()) |> 
        filter(n == 1) |> 
        select(-n) |> 
        pivot_wider(names_from = species,
                    values_from = cover,
                    values_fill = 0) |> 
        ungroup()
      
      comm_sp <- comm_wide %>%
        select(-c(origSiteID:Namount_kg_ha_y))
      
      # meta data
      comm_info <- comm_wide %>%
        select(origSiteID:Namount_kg_ha_y)
      
      # make pca
      res <- rda(comm_sp)
      
      out <- bind_cols(comm_info, fortify(res) |>
                         filter(score == "sites"))
      
      sp <- fortify(res) |>
        filter(score == "species")
      
      e_B <- eigenvals(res)/sum(eigenvals(res))
      
      important_species <- sp |>
        mutate(length = sqrt(PC1^2 + PC2^2)) |>
        filter(length > 1.2) |>
        select(label, length, PC1, PC2)
      
      pca <- out |>
        ggplot(aes(x = PC1, y = PC2, colour = warming, shape = grazing, size = Namount_kg_ha_y)) +
        geom_point() +
        coord_equal() +
        labs(x = glue("PCA1 ({round(e_B[1] * 100, 1)}%)"),
             y = glue("PCA2 ({round(e_B[2] * 100, 1)}%)"),
             tag = "a)") +
        scale_colour_manual(values = c("grey30", "#FD6467")) +
        scale_shape_manual(values = c(16, 0, 2, 3)) +
        theme_bw() +
        theme(aspect.ratio = 1,
              legend.position = "top",
              plot.tag.position = c(0, 0.9),
              plot.tag = element_text(vjust = -1.5, hjust = -0.5, size = 10))
      
      # species names
      species <- out |>
        ggplot(aes(x = PC1, y = PC2)) +
        coord_equal() +
        geom_segment(data = sp |>
                       mutate(length = sqrt(PC1^2 + PC2^2)),
                     aes(x = 0, y = 0, xend = PC1, yend = PC2),
                     arrow = arrow(length = unit(0.2,"cm")),
                     alpha = 0.75,
                     color = 'grey70') +
        geom_text(data = sp |>
                    inner_join(important_species) |>
                    mutate(PC1 = case_when(label == "Silene acaulis" ~ 2,
                                           label == "Agrostis capillaris" ~ -1.5,
                                           TRUE ~ PC1)),
                  aes(x = PC1, y = PC2, label = label),
                  size = 2, col = 'black') +
        labs(x = glue("PCA1 ({round(e_B[1] * 100, 1)}%)"),
             y = glue("PCA2 ({round(e_B[2] * 100, 1)}%)"),
             tag = "b)") +
        theme_bw() +
        theme(aspect.ratio = 1,
              plot.tag.position = c(0, 0.9),
              plot.tag = element_text(vjust = -1.5, hjust = -0.5, size = 10))
      
      plot_layout <- "
  12
  12
  33
  "
      
      pca + species + guide_area() + plot_layout(design = plot_layout, guides = "collect") &
        theme(legend.box = "vertical")
      
      
      
    }
      )
  
  
  
  # cover_clean |> 
  #   filter(grepl("Unknown", species))
  # 13*100/8966
  # cover_clean |> 
  #   filter(grepl(" sp", species))
  # 557*100/8966
  # 
  # subplot_presence_clean |> 
  #   filter(variable == "dominant", value == 1)
  # group_by(year, origSiteID, turfID, variable) |> 
  #   summarise(mean = mean(value))
  # fertile: 7947*100/83978
  # fertile: 1049*100/83970
  # juvenile: 782*100/83971
  # seedling: 264*100/83970
  
  
  
)
