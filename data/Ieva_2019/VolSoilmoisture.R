library("tidyverse")

dat <- read_csv(file = "data/Ieva_2019/TomstLogger_Ieva_2019.csv")
meta <- dat %>% 
  select(File, LoggerID:Site)

dat2 <- dat %>% 
  select(ID:ErrorFlag)

write_csv(dat2, path = "data/Ieva_2019/TomstLogger_Raw.csv")
writexl::write_xlsx(dat2, path = "data/Ieva_2019/TomstLogger_Raw.xlsx")
dd <- read.csv(file = "data/Ieva_2019/TMS3calibr1-11.csv", sep = ";", dec = ",") %>% 
  as_tibble()

dd2 <- meta %>% 
  bind_cols(dd)
writexl::write_xlsx(dd2, path = "data/Ieva_2019/TomstLogger_Data.xlsx")
