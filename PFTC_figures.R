source("https://raw.githubusercontent.com/jogaudard/Three-D/fluxes2021/R/C-flux/analysis2021.R")

PFTC_3d <- flux2021 %>% 
  mutate(
    warming = as.factor(warming),
    site = str_replace(
      site,
      "Joasete",
      "Sub-alpine"),
    site = str_replace(
      site,
      "Liahovden",
      "Alpine"),
    corrected_flux = case_when(
      type == "GEP" &
        corrected_flux >= 0 ~ 0,
      type == "ER" &
        corrected_flux <= 0 ~ 0,
      TRUE ~ corrected_flux
    )
  ) %>%
  filter(type != "NEE") %>%
  ggplot(aes(x = date, y = corrected_flux, color = warming, shape = site, linetype = site)) +
  geom_point() +
  facet_grid(row = vars(type), scales = "free") +
  geom_smooth(method = "lm",
              formula = y ~ poly(x, 2),
              se = TRUE, size = 0.5, fullrange = TRUE) +
  scale_color_manual(values = c(
    "Ambient" = "#1e90ff",
    "Transplant" = "#ff0800"
  )) +
  scale_shape_manual(values = c(
    "Sub-alpine" = 1,
    "Alpine" = 16
  )) +
  geom_hline(yintercept=0, size = 0.3) +
  labs(
    title = "2021 fluxes",
    caption = bquote(atop(~CO[2]~'flux standardized at PAR = 300 mol/'*m^2*'/s for NEE and PAR = 0 mol/'*m^2*'/s for ER, and soil temperature = 15 °C', 'GEP > 0 and ER < 0 were replaced by 0.')),
    color = "Warming",
    shape = "Site",
    linetype = "Site",
    x = "Date",
    y = bquote(~CO[2]~'flux [mmol/'*m^2*'/h]')
  )
PFTC_3d