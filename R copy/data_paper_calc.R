### Data paper


### (iii) microclimate

# read in data
microclimate <- read_csv("data_cleaned/climate/Three-D_clean_microclimate_2019-2022.csv")

daily <- microclimate |> 
  mutate(date = date(date_time)) |> 
  group_by(date, turfID) |> 
  summarise(soil_temperature = mean(soil_temperature, na.rm = TRUE),
            ground_temperature = mean(ground_temperature, na.rm = TRUE),
            air_temperature = mean(air_temperature, na.rm = TRUE),
            soilmoisture = mean(soilmoisture, na.rm = TRUE))

daily_climate <- daily |> 
  pivot_longer(cols = soil_temperature:soilmoisture, names_to = "variable", values_to = "value") |> 
  filter(!is.na(value)) |> 
  left_join(metaTurfID, by = "turfID")

# average daily values during growing season
daily_climate |> 
  mutate(month = month(date)) |> 
  filter(month %in% c(6, 7, 8, 9)) |> 
  ungroup() |> 
  group_by(variable) |> 
  summarise(min = min(value, na.rm = TRUE),
            max = max(value, na.rm = TRUE))

# average daily values along gradient during growing season
daily_climate |> 
  mutate(month = month(date)) |> 
  filter(month %in% c(6, 7, 8, 9)) |> 
  ungroup() |> 
  group_by(variable, destSiteID) |> 
  summarise(mean = mean(value, na.rm = TRUE)) |> 
  pivot_wider(names_from = destSiteID, values_from = mean) |> 
  mutate(diff_1 = Joa - Vik,
         diff_2 = Lia - Joa,
         diff_3 = (Lia - Vik)/2)


# average daily values between treatments during growing season
daily_climate |> 
  mutate(month = month(date)) |> 
  filter(month %in% c(5, 6, 7, 8, 9)) |> 
  ungroup() |> 
  group_by(variable, warming) |> 
  summarise(mean = mean(value, na.rm = TRUE)) |> 
  pivot_wider(names_from = "warming", values_from = mean) |> 
  mutate(diff = W - A)

daily_climate |> 
  mutate(month = month(date)) |> 
  filter(month %in% c(5, 6, 7, 8, 9),
         Nlevel == 0) |> 
  ungroup() |> 
  group_by(variable, grazing) |> 
  summarise(mean = mean(value, na.rm = TRUE)) |> 
  pivot_wider(names_from = grazing, values_from = mean) |> 
  mutate(diff_I = I - C, diff_M = M - C)

# careful 0.5 kg N exist only at Lia, so very cold!
daily_climate |> 
  mutate(month = month(date)) |> 
  filter(month %in% c(5, 6, 7, 8, 9),
         Nlevel != 4,
         grazing == "C",
         warming == "A") |> 
  ungroup() |> 
  group_by(variable, Namount_kg_ha_y) |> 
  summarise(mean = mean(value, na.rm = TRUE)) |> print(n = Inf)

daily_climate |> 
  mutate(month = month(date),
         year = year(date)) |> 
  filter(month %in% c(5, 6, 7, 8, 9)) |> 
  ungroup() |> 
  group_by(variable, year) |> 
  summarise(mean = mean(value, na.rm = TRUE))

