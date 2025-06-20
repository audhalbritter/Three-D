### Trying to automate data cleaning usin folling functions

# special packages
#library(tibbletime)

# Custom function to return mean, sd, 95% conf interval
rolling_functions <- function(x, na.rm = TRUE) {
  
  m  <- mean(x, na.rm = na.rm)
  s  <- sd(x, na.rm = na.rm)
  hi <- m + 2*s
  lo <- m - 2*s
  
  ret <- c(mean = m, stdev = s, hi.95 = hi, lo.95 = lo)
  return(ret)
}

# calculate rolling mean and sd to remove outliers
# functions to perform
rollli_functions <- function(x) {
  data.frame(  
    rolled_summary_type = c("roll_mean", "roll_sd"),
    rolled_summary_value  = c(mean(x), sd(x))
  )
}
# window for half a day
rolling_summary <- rollify(~ rollli_functions(.x), window = 48, unlist = FALSE)

temp_raw1_rollo <- dd %>% 
  mutate(rollo_soil = rolling_summary(soil_temperature),
         rollo_ground = rolling_summary(soil_temperature),
         rollo_air = rolling_summary(soil_temperature)) 
#saveRDS(temp_raw1_rollo, "temp_raw1_rollo.RDS")

temp_raw1_rollo_unnest <- temp_raw1_rollo %>% 
  unnest(cols = c(rollo_soil)) %>% 
  filter(!is.na(rolled_summary_type)) %>% 
  pivot_wider(names_from = rolled_summary_type, values_from = rolled_summary_value) %>% 
  ggplot(aes(x = date_time, y = roll_sd)) +
  geom_line()



# make long table
pivot_longer(cols = soil_temperature:air_temperature, names_to = "variable", values_to = "value")

# Curate data (outliers, logger failure etc)
# usually a rolling sd

dd %>% 
  # fix values with stdev > 2
  mutate(value = if_else(variable == "soiltemperature" & loggerID %in% c("94195224", "94195230", "94195246", "94195250", "94195256", "94200493", "94200495", "942004939", "94195206", "94195220", "94195251", "94195257") & stdev > 2), NA_real_, value,
         # Problems at Vikesland stdev > 3
         value = if_else(variable == "soiltemperature" & loggerID %in% c("94195235", "94195264", "94195263") & stdev > 3), NA_real_, value)

dd <- temp_raw1 %>%
  # remove period with wrong values for this logger
  mutate(value = if_else(loggerID == "94200493" & variable == "soil_temperature" & date_time > "2020-07-17 01:00:00" & date_time < "2020-09-16 01:00:00", NA_real_, value)) %>% 
  # remove when error flag is > 0 for soil, air and ground
  # These logger need to be checked again when new data is added
  mutate(value = if_else(loggerID %in% c("94195209", "94195252", "94195208") & variable %in% c("soil_temperature", "ground_temperature", "air_temperature") & error_flag > 0, NA_real_, value)) %>% 
  # only soil temp needs to be removed
  mutate(value = if_else(loggerID == "94195236" & variable == "soil_temperature" & error_flag > 0, NA_real_, value)) 

