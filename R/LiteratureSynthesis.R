#### LITERATURE SYNTHESIS ####

#devtools::install_github("rmetaverse/metaverse")
#install.packages("bibliometrix", dependencies = TRUE)
library("metaverse")
library("bibliometrix")

#install.packages("BiocManager")
#BiocManager::install("EBImage")
#install.packages("RGtk2")
#install.packages("metagear")
library("metagear")
library("tidyverse")


# WOS search 31-10-2019
D1 <- readFiles("data/LiteratureSurvey/2019-10-31_WOK_Search/savedrecs.bib", "data/LiteratureSurvey/2019-10-31_WOK_Search/savedrecs (1).bib", "data/LiteratureSurvey/2019-10-31_WOK_Search/savedrecs (2).bib", "data/LiteratureSurvey/2019-10-31_WOK_Search/savedrecs (3).bib", "data/LiteratureSurvey/2019-10-31_WOK_Search/savedrecs (4).bib", "data/LiteratureSurvey/2019-10-31_WOK_Search/savedrecs (5).bib", "data/LiteratureSurvey/2019-10-31_WOK_Search/savedrecs (6).bib", "data/LiteratureSurvey/2019-10-31_WOK_Search/savedrecs (7).bib", "data/LiteratureSurvey/2019-10-31_WOK_Search/savedrecs (8).bib")
M1 <- convert2df(D1, dbsource = "isi", format = "bibtex")
LitSearch1 <- M1 %>% as_tibble()
#write.csv(LitSearch1, file = "data/LiteratureSurvey/2019-10-31/LitSearchFull_2019-10-31.csv")

LitSearchTiAb1 <- LitSearch1 %>% 
  select(TI, AB)
#write.csv(LitSearchTiAb1, file = "data/LiteratureSurvey/2019-10-31/LitSearchTiAb1.csv")


# WOS search 17-04-2020
D2 <- readFiles("data/LiteratureSurvey/2020-04-17_WOS_Search/savedrecs.bib", "data/LiteratureSurvey/2020-04-17_WOS_Search/savedrecs (1).bib", "data/LiteratureSurvey/2020-04-17_WOS_Search/savedrecs (2).bib", "data/LiteratureSurvey/2020-04-17_WOS_Search/savedrecs (3).bib", "data/LiteratureSurvey/2020-04-17_WOS_Search/savedrecs (4).bib", "data/LiteratureSurvey/2020-04-17_WOS_Search/savedrecs (5).bib", "data/LiteratureSurvey/2020-04-17_WOS_Search/savedrecs (6).bib", "data/LiteratureSurvey/2020-04-17_WOS_Search/savedrecs (7).bib", "data/LiteratureSurvey/2020-04-17_WOS_Search/savedrecs (8).bib", "data/LiteratureSurvey/2020-04-17_WOS_Search/savedrecs (9).bib")

M2 <- convert2df(D2, dbsource = "isi", format = "bibtex")
LitSearch2 <- M2 %>% as_tibble() %>% 
  # Remove duplicate paper
  filter(UT != "ISI000457245700009") %>% 
  # create new unique ID with SR_FULL: author, year, Journal name
  mutate(UniqueID = paste(SR_FULL, UT, sep = "_"))
  
# Check for duplicates - none
#LitSearch2 %>% select(AU, TI,PY, JI, UniqueID) %>% group_by(UniqueID) %>% mutate(n = n()) %>% filter(n > 1) %>% arrange(AU)
#write.csv(LitSearch2, file = "data/LiteratureSurvey/LitSearchFull_2020-04-17.csv")

### MERGE THE TWO SEARCHES ###
# Merge with Papers where decision already had been made
AlreadyDone <- readxl::read_excel(path = "data/LiteratureSurvey/2019-10-31/LitSearchTiAb1_Decision.xlsx") %>% 
  filter(!is.na(Include_ymn)) %>% 
  rename("Nr" = "ID")

# Merge by TI and AB
LitSearch_Decision <- LitSearch2 %>% 
  left_join(AlreadyDone, by = c("TI", "AB")) %>% 
  select(Nr, UniqueID, TI, Include_ymn, Remark, AB) %>% 
  rename("Nr_old" = "Nr")
writexl::write_xlsx(LitSearch_Decision, path = "data/LiteratureSurvey/LitSearch_Decision.xlsx")
