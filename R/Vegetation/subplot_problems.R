#suplot data problems

# names that were merged to the same name and now 2 entires per subplot exist. The solution is to remove one and if needed change the cover from the whole plot. Cover change is only needed for 51 WN4M 132, Carex light green.
duplicate_problem = tribble(
  ~year, ~turfID, ~species, ~cover,
  2019, "51 WN4M 132", "Carex light green", 6,
  2019, "51 WN4M 132", "Carex atrata cf", 1,
  2019, "77 AN2C 77", "Carex saxatilis cf", 1,
  2019, "67 AN9M 67", "Carex saxatilis cf", 1,
  2019, "48 AN7N 48", "Carex wide", 2,
  2019, "42 WN7I 123", "Carex saxatilis cf", 2,
  2019, "60 AN8M 60", "Carex norvegica cf", 1,
  2019, "68 AN9I 68", "Carex saxatilis cf", 1,
  2019, "72 AN9N 72", "Carex saxatilis cf", 2
  )


#77 AN2C 77 
#80 WN2N 159 # same cover!
#42 WN7I 123
#48 AN7N 48 
#51 WN4M 132
#54 WN4I 134 # same cover!
#60 AN8M 60 
#67 AN9M 67 
#68 AN9I 68 
#72 AN9N 72 

# impute subplot values that have been removed by removing duplicates
subplot_missing = tribble(
  ~year, ~turfID, ~species, ~subplot, ~variable, ~value,
  2019, "77 AN2C 77", "Carex saxatilis cf", "15", "fertile", 1,
  2019, "80 WN2N 159", "Carex small bigelowii", "21", "presence", 1,
  2019, "42 WN7I 123", "Carex saxatilis cf", "8", "presence", 1,
  2019, "42 WN7I 123", "Carex saxatilis cf", "9", "presence", 1,
  2019, "42 WN7I 123", "Carex saxatilis cf", "13", "presence", 1,
  2019, "42 WN7I 123", "Carex saxatilis cf", "15", "presence", 1,
  2019, "48 AN7N 48", "Carex wide", "23", "presence", 1,
  2019, "48 AN7N 48", "Carex wide", "24", "presence", 1,
  2019, "51 WN4M 132", "Carex light green", "1", "presence", 1,
  2019, "51 WN4M 132", "Carex light green", "2", "presence", 1,
  2019, "51 WN4M 132", "Carex light green", "3", "presence", 1,
  2019, "51 WN4M 132", "Carex light green", "4", "presence", 1,
  2019, "51 WN4M 132", "Carex light green", "5", "presence", 1,
  2019, "51 WN4M 132", "Carex light green", "6", "presence", 1,
  2019, "51 WN4M 132", "Carex light green", "10", "presence", 1,
  2019, "51 WN4M 132", "Carex light green", "11", "presence", 1,
  2019, "51 WN4M 132", "Carex light green", "13", "presence", 1,
  2019, "51 WN4M 132", "Carex light green", "14", "presence", 1,
  2019, "51 WN4M 132", "Carex light green", "15", "presence", 1,
  2019, "51 WN4M 132", "Carex light green", "16", "presence", 1,
  2019, "51 WN4M 132", "Carex light green", "17", "presence", 1,
  2019, "51 WN4M 132", "Carex light green", "19", "presence", 1,
  2019, "51 WN4M 132", "Carex light green", "20", "presence", 1,
  2019, "51 WN4M 132", "Carex light green", "21", "presence", 1,
  2019, "51 WN4M 132", "Carex light green", "22", "presence", 1,
  2019, "51 WN4M 132", "Carex light green", "24", "presence", 1,
  2019, "51 WN4M 132", "Carex atrata cf", "12", "presence", 1,
  2019, "51 WN4M 132", "Carex atrata cf", "10", "fertile", 1,
  2019, "51 WN4M 132", "Carex atrata cf", "14", "juvenile", 1,
  2019, "51 WN4M 132", "Carex atrata cf", "22", "fertile", 1,
  2019, "54 WN4I 134", "Carex sp", "18", "presence", 1,
  2019, "60 AN8M 60", "Carex norvegica cf", "16", "fertile", 1,
  2019, "67 AN9M 67", "Carex saxatilis cf", "17", "fertile", 1,
  2019, "67 AN9M 67", "Carex saxatilis cf", "21", "presence", 1,
  2019, "68 AN9I 68", "Carex saxatilis cf", "17", "fertile", 1,
  2019, "72 AN9N 72", "Carex saxatilis cf", "9", "fertile", 1,
  2019, "72 AN9N 72", "Carex saxatilis cf", "11", "fertile", 1,
  2019, "72 AN9N 72", "Carex saxatilis cf", "19", "fertile", 1,
  2019, "72 AN9N 72", "Carex saxatilis cf", "25", "fertile", 1,
  2019, "72 AN9N 72", "Carex saxatilis cf", "18", "presence", 1
) %>% 
  left_join(metaTurfID, by = "turfID")




# Change species name
# in community
fix_species = tribble(
  ~year, ~turfID, ~species, ~species_new,
  2019, "1 WN1M 84", "Antennaria alpina cf", "Antennaria sp",
  2020, "1 WN1M 84", "Antennaria dioica cf", "Antennaria sp",
  2019, "5 WN1I 86", "Antennaria alpina cf", "Antennaria sp",
  2020, "5 WN1I 86", "Antennaria dioica cf", "Antennaria sp",
  2021, "8 WN1N 87", "Luzula sp", "Luzula spicata cf",
  2019, "13 WN6C 90", "Antennaria alpina cf", "Antennaria dioica",
  2021, "13 WN6C 90", "Antennaria dioica cf", "Antennaria dioica",
  2019, "14 WN6I 92", "Luzula spicata cf", "Luzula sp",
  2021, "15 WN6N 95", "Antennaria sp", "Antennaria alpina cf",
  2019, "15 WN6N 95", "Luzula spicata cf", "Luzula sp",
  2019, "19 WN5I 97", "Antennaria dioica cf", "Antennaria sp",
  2019, "21 WN5C 99", "Antennaria alpina cf", "Antennaria sp",
  2019, "22 WN5M 102", "Antennaria alpina cf", "Antennaria sp",
  2021, "29 WN3C 106", "Antennaria sp", "Antennaria alpina cf",
  2019, "29 WN3C 106", "Taraxacum sp.", "Leontodon autumnalis",
  2019, "29 WN3C 106", "Luzula spicata cf", "Luzula spicata",
  2020, "29 WN3C 106", "Luzula spicata cf", "Luzula spicata",
  2021, "29 WN3C 106", "Luzula spicata cf", "Luzula spicata",
  2021, "30 WN3M 107", "Antennaria sp", "Antennaria alpina cf",
  2021, "30 WN3M 107", "Luzula sp", "Luzula multiflora cf",
  2019, "32 WN3N 112", "Luzula spicata cf", "Luzula sp",
  2021, "34 WN10I 114", "Antennaria sp", "Antennaria dioica cf",
  2021, "34 WN10I 114", "Luzula sp", "Luzula spicata cf",
  2019, "36 WN10M 115", "Taraxacum sp.", "Leontodon autumnalis",
  2021, "37 WN10C 116", "Antennaria sp", "Antennaria dioica cf",
  2019, "42 WN7I 123", "Antennaria alpina cf", "Antennaria sp",
  2019, "44 WN7M 125", "Taraxacum sp.", "Leontodon autumnalis",
  2021, "53 WN4C 133", "Antennaria sp", "Antennaria alpina cf",
  2019, "53 WN4C 133", "Taraxacum sp.", "Leontodon autumnalis",
  2019, "54 WN4I 134", "Salix reticulata", "Vaccinium uliginosum",
  2019, "54 WN4I 134", "Taraxacum sp.", "Leontodon autumnalis",
  2019, "61 WN8I 140", "Luzula spicata cf", "Luzula sp",
  2021, "71 WN9N 151", "Luzula multiflora cf", "Luzula multiflora"
  )
  


# Fix cover of wrong species (replace with correct species)
# in community
fix_cover = tribble(
  ~year, ~turfID, ~species, ~cover_new,
  2020, "83 AN1I 83", "Agrostis capillaris",  34,
  2020, "83 AN1I 83", "Festuca rubra",  16,
  2019, "1 WN1M 84", "Festuca ovina",  4,
  2019, "1 WN1M 84", "Festuca rubra",  16,
  2019, "5 WN1I 86", "Festuca rubra",  15,
  2019, "13 WN6C 90", "Avenella flexuosa", 2,
  2019, "30 WN3M 107", "Luzula spicata cf", 1,
  2019, "36 WN10M 115", "Leontodon autumnalis", 6,
  2019, "36 WN10M 115", "Agrostis capillaris", 12,
  2019, "59 WN8C 1385", "Leontodon autumnalis", 17,
  2019, "59 WN8C 1385", "Taraxacum sp.", 8,
  2019, "61 WN8I 140", "Leontodon autumnalis", 4
  )

add_cover = tribble(
  ~year, ~turfID, ~species, ~cover,
2019, "5 WN1I 86", "Leontodon autumnalis",  1,
2019, "30 WN3M 107", "Luzula multiflora cf", 1,
2019, "36 WN10M 115", "Taraxacum sp.", 1,
2019, "53 WN4C 133", "Taraxacum sp.", 1,
2019, "54 WN4I 134", "Taraxacum sp.", 2
)  %>% 
  left_join(metaTurfID, by = "turfID")
# need to add 5 WN1I 86 Leo aut in cover dataset. Full record.

# remove wrong species using anti_join (in community)
#community %>% anti_join(remove_wrong_species, by = c("year", "turfID", "species"))
remove_wrong_species = tribble(
  ~year, ~turfID, ~species,
  2020, "83 AN1I 83", "Phleum alpinum",
  2020, "83 AN1I 83", "Avenella flexuosa",
  2019, "5 WN1I 86", "Festuca ovina",
  2019, "13 WN6C 90", "Festuca rubra",
  2019, "36 WN10M 115", "Phleum alpinum"
  
  
)


# in CommunitySubplot
add_subplot = tribble(
  ~year, ~turfID, ~species, ~subplot, ~variable, ~value, ~recorder,
  2020, "83 AN1I 83", "Festuca rubra", list(4, 5, 9, 12, 15, 18, 19, 20, 21, 22, 23, 24, 25), "presence", 1, "aud",
  2019, "1 WN1M 84", "Festuca rubra", list(5, 6, 7), "presence", 1, "silje",
  2019, "5 WN1I 86", "Festuca rubra", list(1, 16, 17, 18, 20), "presence", 1, "silje",
  2019, "5 WN1I 86", "Leontodon autumnalis", list(8, 9, 10, 15, 20), "presence", 1, "silje",
  2019, "13 WN6C 90", "Avenella flexuosa", list(3, 7, 16), "presence", 1, "aud",
  2019, "30 WN3M 107", "Luzula multiflora cf", list(2, 7), "presence", 1, "aud",
  2019, "36 WN10M 115", "Taraxacum sp.", list(7, 23, 24), "presence", 1, "silje",
  2019, "36 WN10M 115", "Agrostis capillaris", list(3, 5, 23), "presence", 1, "silje",
  2019, "53 WN4C 133", "Taraxacum sp.", list(2, 18, 22), "presence", 1, "silje",
  2019, "54 WN4I 134", "Taraxacum sp.", list(11, 12, 13, 16, 21), "presence", 1, "silje",
  2019, "59 WN8C 138", "Taraxacum sp.", list(3, 7, 13, 14, 17, 18, 19, 22), "presence", 1, "linn",
  2019, "61 WN8I 140", "Leontodon autumnalis", list(5, 11, 16, 17, 21, 22, 25), "presence", 1, "silje"
  
  ) %>% 
  unchop(subplot) %>% 
  mutate(subplot = unlist(subplot),
         subplot = as.character(subplot)) %>% 
  left_join(metaTurfID, by = "turfID")

remove_subplot = tribble(
  ~year, ~turfID, ~species, ~subplot, ~variable,
  2019, "1 WN1M 84", "Festuca ovina", list(1, 2, 3, 4, 5, 6, 7, 8, 10, 13, 14, 15, 19, 20), "presence",
  2019, "5 WN1I 86", "Taraxacum sp.", list(8, 9, 10, 15, 20), "presence",
  2019, "30 WN3M 107", "Luzula spicata cf", list(2, 7), "presence"
  
) %>% 
  unchop(subplot) %>% 
  mutate(subplot = unlist(subplot),
         subplot = as.character(subplot))


c("Antennaria alpina cf", "Antennaria dioica cf", "Antennaria sp")
c("Luzula multiflora cf", "Luzula sp", "Luzula spicata cf")

cover %>% filter(turfID == "61 WN8I 140", species %in% c("Taraxacum sp.", "Leontodon autumnalis")) %>% as.data.frame()
community %>% filter(turfID == "71 WN9N 151", species %in% c("Luzula multiflora cf", "Luzula sp", "Luzula spicata cf")) %>% as.data.frame()
CommunitySubplot %>% filter(turfID == "5 WN1I 86", species %in% c("Festuca rubra"), variable == "presence") %>% as.data.frame()

cover %>% filter(turfID == "3 WN1C 85") %>% distinct(species) %>% pn
  

CommunitySubplot %>% 
  filter(variable == "presence",
         ! grepl("Carex", species),
         turfID == "59 WN8C 138"
  ) %>%
  left_join(cover %>% select(year, turfID, species, cover)) %>% 
  mutate(subplot = as.numeric(subplot),
         year_recorder = paste(year, recorder, sep = "_")) %>% 
  select(-year) %>% 
  arrange(destSiteID, destPlotID, turfID) %>% 
  group_by(destSiteID, destPlotID, turfID) %>% 
  nest() %>% 
  {map2(
    .x = .$data, 
    .y = glue::glue("Site {.$destSiteID}: plot {.$destPlotID}: turf {.$turfID}"),
    .f = ~make_turf_plot(
      data = .x, 
      year = year_recorder, 
      species = species, 
      cover = cover, 
      subturf = subplot, 
      title = glue::glue(.y), 
      grid_long = grid)
  )}
