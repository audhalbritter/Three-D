source("R/Rgathering/ReadInTomstLogger.R")

# Select Ievas data
TomstLogger_Ieva_2019 <- TomstLogger_2019_2020 %>% 
  filter(LoggerID %in% c("5226", "5221", "5227", "5263", "5267", "5222", "5223", "5272", "5224", "5228", "5266", "5261")) %>%
  # Mark IEVAs data
  mutate(Treatment = case_when(LoggerID %in% c("5226", "5221", "5227", "5263", "5267") ~ "cage",
                               LoggerID %in% c("5222", "5223", "5224", "5228", "5266", "5272", "5261") ~ "no-cage")) %>% 
  mutate(Site = case_when(LoggerID == "5226" ~ "Inb",
                          LoggerID == "5221" ~ "Joa",
                          LoggerID == "5227" ~ "Lia",
                          LoggerID == "5263" ~ "Hog",
                          LoggerID == "5267" ~ "Vik",
                          LoggerID == "5222" ~ "Lia",
                          LoggerID == "5223" ~ "Joa",
                          LoggerID == "5272" ~ "Joa",
                          LoggerID == "5224" ~ "Lia",
                          LoggerID == "5228" ~ "Lia",
                          LoggerID == "5266" ~ "Joa",
                          LoggerID == "5261" ~ "Vik")) %>% 
  filter(Date_Time > earlyStart) %>% 
  select(-destSiteID, -destBlockID, -destPlotID)
#write_csv(TomstLogger_Ieva_2019, path = "data/iButton Ieva 2019/TomstLogger_Ieva_2019.csv", col_names = TRUE)