### Productivity 2022 ####

dat <- read_excel("data/biomass/Three-D_raw_productivity_2022-09-27.xlsx")

productivity <- dat |> 
  # scale biomass that was cut on smaller square
  mutate(biomass = if_else(area_cm == 625, biomass*625/900, biomass),
         area_cm = if_else(area_cm == 625, 900, area_cm)) |> 
  # fix date/site problems
  tidylog::mutate(siteID = if_else(siteID == "Lia" & biomass == 6.87887, "Joa", siteID)) |> 
  rename(productivity = biomass)

write_csv(productivity, file = "data_cleaned/vegetation/Three-D_clean_productivity_2022.csv")

productivity |> 
  ggplot(aes(x = date, y = productivity, fill = treatment)) +
  geom_col() +
  facet_grid(~ siteID)

productivity |> 
  mutate(siteID = factor(siteID, levels = c("Vik", "Joa", "Lia"))) |> 
  ggplot(aes(x = factor(date), y = productivity, fill = treatment)) +
  geom_boxplot() +
  facet_grid(~ siteID)

productivity |> 
  mutate(siteID = factor(siteID, levels = c("Vik", "Joa", "Lia"))) |> 
  ggplot(aes(x = siteID, y = productivity, fill = treatment)) +
  geom_boxplot()

# test if cage and control differ
fit <- lm(productivity ~ treatment*siteID, productivity)
summary(fit)

# nr of days between each cutting
productivity |> 
  distinct(date, siteID) |> 
  arrange(siteID, date) |> 
  mutate(doy = yday(date),
         diff = doy - lag(doy)) |> 
  # calculate nr of days between
  slice(-c(1, 8, 13)) |> 
  summarise(se = sd(diff)/sqrt(n()),
            mean = mean(diff))
  
