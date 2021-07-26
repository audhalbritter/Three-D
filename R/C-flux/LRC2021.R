library("dataDownloader")
library(broom)
source("R/Load packages.R")
source("R/Rgathering/create meta data.R")


#download data from OSF and read it
# get_file(node = "pk4bg",
#          file = "Three-D_c-flux_2021.csv",
#          path = "data/C-Flux/summer_2021",
#          remote_path = "C-Flux")
# 
flux <- read_csv("data/C-Flux/summer_2021/Three-D_c-flux_2021.csv")



#adding meta data
flux <- left_join(flux, metaTurfID, by = c("turf_ID"="turfID"))

#LRC
lrc_flux <- flux %>% 
  filter(type == c("LRC1", "LRC2", "LRC3", "LRC4", "LRC5"))

#graph each light response curves
ggplot(lrc_flux, aes(x = PARavg, y = flux, color = turf_ID)) +
  geom_point(size = 0.1) +
  facet_wrap(vars(campaign)) +
  # geom_smooth(method = "lm", se = FALSE)
  geom_smooth(method = "lm", formula = y ~ poly(x, 2), se = FALSE)

#grouping per treatment instead of turfs
ggplot(lrc_flux, aes(x = PARavg, y = flux, color = warming)) +
  geom_point(size = 0.1) +
  facet_wrap(vars(campaign)) +
  # geom_smooth(method = "lm", se = FALSE)
  geom_smooth(method = "lm", formula = y ~ poly(x, 2), se = FALSE)

#extract the equation and correct all the NEE fluxes for PAR = 1000 micromol/s/m2

coefficients_lrc <- lrc_flux %>%
  group_by(warming, campaign) %>% 
  nest %>% 
  mutate(lm = map(data, ~ lm(flux ~ PARavg + I(PARavg^2), data = .x)),
         table = map(lm, tidy),
         table = map(table, select, term, estimate),
         table = map(table, pivot_wider, names_from = term, values_from = estimate)
         
  ) %>% 
  unnest(table) %>% 
  select(treatment, `(Intercept)`, PARavg, `I(PARavg^2)`) %>% 
  rename(
    origin = "(Intercept)",
    a = "I(PARavg^2)",
    b = "PARavg"
  )


#what I want to do: predict flux at PAR = 1000, given the origin
#origini is calculated with coefficients from the model and flux and PAR value of specific flux
# corrected_flux = flux + a (1000^2 - PAR^2) + b (1000 - PAR)

PARfix <- 1000 #PAR value at which we want the corrected flux to be

flux_test <- flux %>% 
  left_join(coefficients_lrc, by = c("warming", "campaign")) %>% 
  mutate(
    corrected_flux = 
      case_when( #we correct only the NEE
        type == "NEE" ~ flux + a * (PARfix^2 - PARavg^2) + b * (PARfix - PARavg),
        type == "ER" ~ flux
      )
  )