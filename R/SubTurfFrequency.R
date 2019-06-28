#*****************************************************************************

# load libraries
library("RSQLite")

con <- dbConnect(SQLite(), dbname = "~/Dropbox/Bergen/seedclimComm/database/seedclim.sqlite")

# vies all subtables
DBI::dbListTables(conn = con)
# view column names of a table
dbListFields(con, "sites")


cover <- tbl(con, "turfCommunity") %>% 
  left_join(tbl(con, "turfs"), by = "turfID") %>% 
  # only control plots
  filter(TTtreat %in% c("TTC", "TT1")) %>% 
  select(-RTtreat, -GRtreat, -destinationPlotID, -cf, -flag) %>% 
  left_join(tbl(con, "plots"), by = c("originPlotID" = "plotID")) %>% 
  left_join(tbl(con, "blocks"), by = c("blockID")) %>% 
  left_join(tbl(con, "sites"), by = c("siteID")) %>% 
  select(-c(originPlotID, aspect.x, slope.x, slope.y:landUse)) %>% 
  collect()



### Load fertility subTurf data from database
subFreq <- tbl(con, "subTurfCommunity") %>% 
  select(turfID, subTurf, year, species) %>%
  left_join(tbl(con, "turfs"), by = "turfID") %>% 
  # only control plots
  filter(TTtreat %in% c("TTC", "TT1")) %>% 
  select(-RTtreat, -GRtreat, -destinationPlotID) %>% 
  left_join(tbl(con, "plots"), by = c("originPlotID" = "plotID")) %>% 
  left_join(tbl(con, "blocks"), by = c("blockID")) %>% 
  left_join(tbl(con, "sites"), by = c("siteID")) %>% 
  select(-c(originPlotID, aspect.x, slope.x, slope.y:landUse)) %>% 
  collect()

# Calculate stuff
cover13 <- cover %>% 
  filter(year == 2013,
         siteID %in% c("Gudmedalen", "Hogsete", "Vikesland"))

subFreqTot <- subFreq %>% 
  filter(year == 2013,
         siteID %in% c("Gudmedalen", "Hogsete", "Vikesland")) %>% 
  group_by(turfID, species, siteID) %>% 
  summarise(SumOfSubTurfs = n()) %>% 
  mutate(PropSubTurfs = SumOfSubTurfs/25, 
         freq = "all")

subFreq16 <- subFreq %>% 
  filter(year == 2013,
         siteID %in% c("Gudmedalen", "Hogsete", "Vikesland"),
         subTurf %in% c(1:6, 10, 11, 15, 16, 20:25)) %>% 
  group_by(turfID, species, siteID) %>% 
  summarise(SumOfSubTurfs = n()) %>% 
  mutate(PropSubTurfs = SumOfSubTurfs/16,
         freq = "outer")

subFreq9 <- subFreq %>% 
  filter(year == 2013,
         siteID %in% c("Gudmedalen", "Hogsete", "Vikesland"),
         subTurf %in% c(7, 8, 9, 12, 13, 14, 17, 18, 19)) %>% 
  group_by(turfID, species, siteID) %>% 
  summarise(SumOfSubTurfs = n()) %>% 
  mutate(PropSubTurfs = SumOfSubTurfs/9,
         freq = "nine")

subFreq5 <- subFreq %>% 
  filter(year == 2013,
         siteID %in% c("Gudmedalen", "Hogsete", "Vikesland"),
         subTurf %in% c(8, 12, 13, 14, 18)) %>% 
  group_by(turfID, species, siteID) %>% 
  summarise(SumOfSubTurfs = n()) %>% 
  mutate(PropSubTurfs = SumOfSubTurfs/5,
         freq = "five")


subFreqTot %>% 
  bind_rows(subFreq16, subFreq9, subFreq5) %>% 
  select(-SumOfSubTurfs) %>% 
  spread(key = freq, value = PropSubTurfs) %>% 
  gather(key = SubTurfs, value = propSubTurfs, five, nine, outer) %>% 
  ggplot(aes(x = all, y = propSubTurfs, color = SubTurfs)) +
  geom_point() +
  geom_smooth(method = "lm", se = FALSE) +
  geom_abline(slope = 1, linetype = "dashed") +
  facet_grid(~ siteID)


