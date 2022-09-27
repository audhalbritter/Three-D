### THIS SCRIPT FIXES PROBLEMS IN THE COMMUNITY DATA ###

# MERGING SPECIES
# Problems regarding merging of species and then there are multiple entries at the subplot level and cover
# "duplicate_problem" and "subpot_missing" are fixing these problems before community is created.

# Names that were merged to the same name and now 2 entries per subplot exist. The solution is to remove one and if needed change the cover from the whole plot.
#80 WN2N 159 and #54 WN4I 134 have same cover!

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


# Impute presence in subplot for species that have been removed by removing duplicate entries (Merging species)
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
  2019, "72 AN9N 72", "Carex saxatilis cf", "18", "presence", 1,
  2019, "102 WN5I 171", "Poa pratensis", "21", "presence", 1,
  2019, "104 AN5N 104", "Poa pratensis", "2", "presence", 1,
  2019, "104 AN5N 104", "Poa pratensis", "10", "presence", 1
  
) %>% 
  left_join(metaTurfID, by = "turfID")



### FIX MISIDENTIFICAITONS OR WRONG ENTRIES IN THE DATA
# The following data frames fix misidentification of species, change species names, or problems in the data
# All these changes need to be done in community data frame when producing cover and CommunitySubplot

## Changes species names
# Fixes misidentification, or change uncertainties in species names containing cf to species or vice versa according to data in other years of pictures
fix_species = tribble(
  ~year, ~turfID, ~species, ~species_new,
  2019, "1 WN1M 84", "Antennaria alpina cf", "Antennaria sp",
  2020, "1 WN1M 84", "Antennaria dioica cf", "Antennaria sp",
  2021, "1 WN1M 84", "Erigeron sp", "Erigeron uniflorus",
  2021, "1 WN1M 84", "Luzula sp", "Luzula spicata cf",
  2019, "1 WN1M 84", "Festuca ovina", "Nardus stricta",
  2021, "1 WN1M 84", "Festuca ovina", "Nardus stricta",
  2022, "3 WN1C 85", "Antennaria sp", "Antennaria alpina cf",
  2019, "5 WN1I 86", "Antennaria alpina cf", "Antennaria sp",
  2020, "5 WN1I 86", "Antennaria dioica cf", "Antennaria sp",
  2021, "8 WN1N 87", "Luzula sp", "Luzula spicata cf",
  2022, "8 WN1N 87", "Luzula sp", "Luzula spicata cf",
  2021, "10 WN6M 89", "Luzula sp", "Luzula spicata cf",
  2019, "13 WN6C 90", "Antennaria alpina cf", "Antennaria dioica",
  2021, "13 WN6C 90", "Antennaria dioica cf", "Antennaria dioica",
  2021, "14 WN6I 92", "Luzula sp", "Luzula spicata cf",
  2021, "94 AN6I 94", "Festuca ovina", "Festuca rubra",
  2021, "15 WN6N 95", "Antennaria sp", "Antennaria alpina cf",
  2019, "15 WN6N 95", "Luzula spicata cf", "Luzula sp",
  2021, "19 WN5I 97", "Antennaria sp", "Antennaria dioica cf",
  2021, "21 WN5C 99", "Antennaria sp", "Antennaria alpina cf",
  2021, "22 WN5M 102", "Antennaria sp", "Antennaria alpina cf",
  2019, "24 WN5N 103", "Taraxacum sp.", "Leontodon autumnalis",
  2019, "26 WN3I 105", "Taraxacum sp.", "Leontodon autumnalis",
  2019, "26 WN3I 105", "Luzula spicata cf", "Luzula sp",
  2020, "26 WN3I 105", "Luzula multiflora cf", "Luzula sp",
  2021, "29 WN3C 106", "Antennaria sp", "Antennaria alpina cf",
  2019, "29 WN3C 106", "Taraxacum sp.", "Leontodon autumnalis",
  2019, "29 WN3C 106", "Luzula spicata cf", "Luzula spicata",
  2020, "29 WN3C 106", "Luzula spicata cf", "Luzula spicata",
  2021, "29 WN3C 106", "Luzula spicata cf", "Luzula spicata",
  2021, "30 WN3M 107", "Antennaria sp", "Antennaria alpina cf",
  2022, "30 WN3M 107", "Antennaria dioica cf", "Antennaria alpina cf",
  2021, "30 WN3M 107", "Luzula sp", "Luzula multiflora cf",
  2022, "30 WN3M 107", "Luzula sp", "Luzula multiflora cf",
  2019, "32 WN3N 112", "Luzula spicata cf", "Luzula sp",
  2021, "34 WN10I 114", "Antennaria sp", "Antennaria dioica cf",
  2021, "34 WN10I 114", "Luzula sp", "Luzula spicata cf",
  2022, "34 WN10I 114", "Luzula sp", "Luzula spicata cf",
  2022, "34 WN10I 114", "Potentilla erecta", "Potentilla crantzii",
  2019, "36 WN10M 115", "Taraxacum sp.", "Leontodon autumnalis",
  2021, "37 WN10C 116", "Antennaria sp", "Antennaria dioica cf",
  2019, "42 WN7I 123", "Antennaria alpina cf", "Antennaria sp",
  2019, "44 WN7M 125", "Taraxacum sp.", "Leontodon autumnalis",
  2021, "53 WN4C 133", "Antennaria sp", "Antennaria alpina cf",
  2019, "53 WN4C 133", "Taraxacum sp.", "Leontodon autumnalis",
  2021, "53 WN4C 133", "Erigeron sp", "Erigeron uniflorus",
  2021, "54 WN4I 134", "Erigeron sp", "Erigeron uniflorus",
  2019, "54 WN4I 134", "Salix reticulata", "Vaccinium uliginosum",
  2019, "54 WN4I 134", "Taraxacum sp.", "Leontodon autumnalis",
  2019, "61 WN8I 140", "Luzula spicata cf", "Luzula sp",
  2019, "64 WN8N 143", "Luzula spicata cf", "Luzula sp",
  2021, "71 WN9N 151", "Luzula multiflora cf", "Luzula multiflora",
  2019, "71 WN9N 151", "Luzula spicata cf", "Luzula multiflora",
  2019, "73 WN2M 153", "Leontodon autumnalis", "Taraxacum sp.",
  2019, "73 WN2M 153", "Luzula spicata cf", "Luzula spicata",
  2020, "73 WN2M 153", "Luzula multiflora cf", "Luzula spicata",
  2021, "73 WN2M 153", "Luzula sp", "Luzula spicata",
  2022, "73 WN2M 153", "Luzula spicata cf", "Luzula spicata",
  
  2020, "154 AN2M 154", "Vaccinium uliginosum", "Vaccinium vitis-idaea",
  
  2022, "2 AN1M 2", "Orchid sp", "Coeloglossum viride",
  2019, "4 AN1C 4", "Antennaria alpina cf", "Antennaria dioica",
  2020, "4 AN1C 4", "Antennaria dioica cf", "Antennaria dioica",
  2021, "4 AN1C 4", "Antennaria sp", "Antennaria dioica",
  2022, "4 AN1C 4", "Antennaria alpina cf", "Antennaria dioica",
  2021, "6 AN1I 6", "Antennaria sp", "Antennaria alpina cf",
  2021, "7 AN1N 7", "Antennaria sp", "Antennaria alpina cf",
  2019, "9 AN6M 9", "Achillea millefolium", "Alchemilla alpina",
  2021, "9 AN6M 9", "Antennaria dioica cf", "Antennaria alpina cf",
  2022, "9 AN6M 9", "Antennaria sp", "Antennaria alpina cf",
  2019, "9 AN6M 9", "Avenella flexuosa", "Festuca rubra",
  2019, "9 AN6M 9", "Leontodon autumnalis", "Taraxacum sp.",
  2019, "11 AN6I 11", "Antennaria alpina cf", "Antennaria sp",
  2019, "11 AN6I 11", "Antennaria dioica cf", "Antennaria sp",
  2019, "11 AN6I 11", "Taraxacum sp.", "Leontodon autumnalis",
  2022, "11 AN6I 11", "Luzula sp.", "Luzula spicata cf",
  2019, "16 AN6N 16", "Astragalus alpina", "Oxytropa laponica",
  2019, "16 AN6N 16", "Antennaria alpina cf", "Antennaria sp",
  2022, "16 AN6N 16", "Antennaria dioica cf", "Antennaria sp",
  2019, "17 AN5M 17", "Antennaria dioica cf", "Antennaria dioica",
  2021, "17 AN5M 17", "Antennaria dioica cf", "Antennaria dioica",
  2022, "17 AN5M 17", "Antennaria sp", "Antennaria dioica",
  2019, "18 AN5C 18", "Antennaria dioica cf", "Antennaria dioica",
  2021, "18 AN5C 18", "Antennaria dioica cf", "Antennaria dioica",
  2022, "18 AN5C 18", "Antennaria sp", "Antennaria dioica",
  2019, "23 AN5N 23", "Antennaria dioica cf", "Antennaria dioica",
  2021, "23 AN5N 23", "Antennaria dioica cf", "Antennaria dioica",
  2019, "27 AN3C 27", "Deschampsia cespitosa", "Deschampsia alpina",
  2020, "27 AN3C 27", "Deschampsia cespitosa", "Deschampsia alpina",
  2019, "27 AN3C 27", "Taraxacum sp.", "Leontodon autumnalis",
  2019, "27 AN3C 27", "Luzula multiflora", "Luzula multiflora cf",
  2020, "27 AN3C 27", "Luzula spicata cf", "Luzula spicata",
  2021, "27 AN3C 27", "Luzula spicata cf", "Luzula spicata",
  2021, "27 AN3C 27", "Luzula sp", "Luzula spicata",
  2022, "27 AN3C 27", "Luzula spicata cf", "Luzula spicata",
  2019, "28 AN3I 28", "Antennaria alpina cf", "Antennaria sp",
  2019, "28 AN3I 28", "Antennaria dioica cf", "Antennaria sp",
  2020, "28 AN3I 28", "Antennaria dioica cf", "Antennaria sp",
  2022, "28 AN3I 28", "Antennaria alpina cf", "Antennaria sp",
  2021, "28 AN3I 28", "Luzula sp", "Luzula spicata cf",
  2019, "31 AN3N 31", "Deschampsia cespitosa", "Deschampsia alpina",
  2020, "31 AN3N 31", "Deschampsia cespitosa", "Deschampsia alpina",
  2019, "31 AN3N 31", "Luzula spicata cf", "Luzula sp",
  2020, "31 AN3N 31", "Luzula spicata cf", "Luzula sp",
  2020, "31 AN3N 31", "Luzula multiflora cf", "Luzula sp",
  2021, "31 AN3N 31", "Luzula spicata cf", "Luzula sp",
  2022, "31 AN3N 31", "Antennaria sp", "Antennaria dioica cf",
  2019, "33 AN10I 33", "Antennaria alpina cf", "Antennaria sp",
  2019, "33 AN10I 33", "Taraxacum sp.", "Leontodon autumnalis",
  2021, "33 AN10I 33", "Luzula sp", "Luzula spicata cf",
  2022, "33 AN10I 33", "Antennaria alpina cf", "Antennaria sp",
  2019, "35 AN10C 35", "Antennaria alpina cf", "Antennaria sp",
  2019, "38 AN10M 38", "Avenella flexuosa", "Festuca ovina",
  2019, "38 AN10M 38", "Luzula spicata cf", "Luzula spicata",
  2021, "38 AN10M 38", "Luzula sp", "Luzula spicata",
  2019, "38 AN10M 38", "Taraxacum sp.", "Leontodon autumnalis",
  2022, "38 AN10M 38", "Luzula spicata cf", "Luzula spicata",
  2019, "39 AN10N 39", "Deschampsia cespitosa", "Deschampsia alpina",
  2019, "45 AN7I 45", "Antennaria alpina cf", "Antennaria alpina",
  2021, "45 AN7I 45", "Antennaria sp", "Antennaria alpina",
  2022, "45 AN7I 45", "Antennaria sp", "Antennaria alpina",
  2019, "45 AN7I 45", "Deschampsia cespitosa", "Deschampsia alpina",
  2019, "45 AN7I 45", "Taraxacum sp.", "Leontodon autumnalis",
  2019, "46 AN7M 46", "Antennaria alpina cf", "Antennaria sp",
  2022, "46 AN7M 46", "Antennaria sp", "Antennaria dioica cf",
  2022, "46 AN7M 46", "Luzula sp", "Luzula spicata cf",
  2019, "49 AN4I 49", "Antennaria dioica cf", "Antennaria sp",
  2021, "49 AN4I 49", "Antennaria alpina cf", "Antennaria sp",
  2022, "49 AN4I 49", "Antennaria alpina cf", "Antennaria sp",
  2019, "50 AN4M 50", "Taraxacum sp.", "Leontodon autumnalis",
  2019, "52 AN4C 52", "Antennaria dioica cf", "Antennaria alpina",
  2021, "52 AN4C 52", "Antennaria alpina cf", "Antennaria alpina",
  2021, "52 AN4C 52", "Luzula sp", "Luzula spicata",
  2022, "52 AN4C 52", "Antennaria alpina cf", "Antennaria alpina",
  2019, "52 AN4C 52", "Luzula spicata cf", "Luzula spicata",
  2019, "52 AN4C 52", "Viola biflora", "Viola palustris",
  2019, "58 AN8I 58", "Taraxacum sp.", "Leontodon autumnalis",
  2019, "63 AN8N 63", "Taraxacum sp.", "Leontodon autumnalis",
  2022, "63 AN8N 63", "Antennaria sp", "Antennaria alpina cf",
  2019, "68 AN9I 68", "Luzula spicata cf", "Luzula spicata",
  2021, "68 AN9I 68", "Luzula sp", "Luzula spicata",
  2022, "68 AN9I 68", "Luzula sp", "Luzula spicata",
  2022, "68 AN9I 68", "Luzula spicata cf", "Luzula spicata",
  2019, "70 AN9C 70", "Taraxacum sp.", "Leontodon autumnalis",
  2020, "75 AN2I 75", "Luzula spicata cf", "Luzula sp",
  2021, "76 AN2M 76", "Luzula spicata cf", "Luzula sp",
  2021, "79 AN2N 79", "Antennaria dioica cf", "Antennaria alpina cf"
  )
  


## Fixes cover of species
# This needs doing if species were merged, added or removed according to other years or pictures
fix_cover = tribble(
  ~year, ~turfID, ~species, ~cover_new,
  2020, "83 AN1I 83", "Agrostis capillaris",  34,
  2020, "83 AN1I 83", "Festuca rubra",  16,
  2019, "1 WN1M 84", "Taraxacum sp.", 3,
  2019, "1 WN1M 84", "Festuca ovina",  4,
  2019, "1 WN1M 84", "Festuca rubra",  16,
  2019, "5 WN1I 86", "Festuca rubra",  15,
  2019, "13 WN6C 90", "Avenella flexuosa", 2,
  2019, "14 WN6I 92", "Leontodon autumnalis", 3,
  2019, "21 WN5C 99", "Leontodon autumnalis", 6,
  2019, "30 WN3M 107", "Luzula spicata cf", 1,
  2019, "36 WN10M 115", "Leontodon autumnalis", 6,
  2019, "36 WN10M 115", "Agrostis capillaris", 12,
  2019, "59 WN8C 1385", "Leontodon autumnalis", 17,
  2019, "59 WN8C 1385", "Taraxacum sp.", 8,
  2019, "61 WN8I 140", "Leontodon autumnalis", 4,
  2019, "9 AN6M 9", "Festuca rubra", 2,
  2019, "11 AN6I 11", "Leontodon autumnalis", 4,
  2019, "16 AN6N 16", "Leontodon autumnalis", 2,
  2019, "20 AN5I 20", "Festuca rubra", 17,
  2019, "20 AN5I 20", "Potentilla crantzii", 3,
  2019, "38 AN10M 38", "Leontodon autumnalis", 4,
  2019, "50 AN4M 50", "Leontodon autumnalis", 6,
  2019, "52 AN4C 52", "Antennaria alpina", 4,
  2019, "58 AN8I 58", "Leontodon autumnalis", 4,
  2019, "63 AN8N 63", "Leontodon autumnalis", 3
  )


## Adds cover for new species
# This needs doing if species was missing, or species was split into 2 species according to other years or pictures
add_cover = tribble(
  ~year, ~turfID, ~species, ~cover,
  2019, "1 WN1M 84", "Leontodon autumnalis", 1,
2019, "5 WN1I 86", "Leontodon autumnalis",  1,
2019, "30 WN3M 107", "Luzula multiflora cf", 1,
2019, "36 WN10M 115", "Taraxacum sp.", 1,
2019, "53 WN4C 133", "Taraxacum sp.", 1,
2019, "54 WN4I 134", "Taraxacum sp.", 2,
2019, "11 AN6I 11", "Taraxacum sp.", 2,
2019, "15 WN6N 95", "Leontodon autumnalis", 2,
2019, "16 AN6N 16", "Taraxacum sp.", 6,
2019, "20 AN5I 20", "Geranium sylvaticum", 5,
2019, "20 AN5I 20", "Taraxacum sp.", 4,
2019, "23 AN5N 23", "Antennaria sp", 2,
2019, "38 AN10M 38", "Taraxacum sp.", 2,
2019, "43 AN7C 43", "Taraxacum sp.", 1,
2019, "45 AN7I 45", "Festuca ovina", 1,
2019, "45 AN7I 45", "Taraxacum sp.", 1,
2019, "46 AN7M 46", "Taraxacum sp.", 2,
2019, "50 AN4M 50", "Taraxacum sp.", 8,
2019, "57 AN8C 57", "Taraxacum sp.", 4,
2019, "58 AN8I 58", "Taraxacum sp.", 8,
2019, "63 AN8N 63", "Taraxacum sp.", 5
)  %>% 
  # needs joining with metadata, because these are new entries
  left_join(metaTurfID, by = "turfID")
# need to add 5 WN1I 86 Leo aut in cover dataset. Full record.



## Remove species using anti_join
# This is needed for species that were misidentified and only some of the subplots are change to another species
remove_wrong_species = tribble(
  ~year, ~turfID, ~species,
  2020, "83 AN1I 83", "Phleum alpinum",
  2020, "83 AN1I 83", "Avenella flexuosa",
  2019, "5 WN1I 86", "Festuca ovina",
  2019, "13 WN6C 90", "Festuca rubra",
  2019, "21 WN5C 99", "Taraxacum sp.",
  2019, "36 WN10M 115", "Phleum alpinum",
  2019, "20 AN5I 20", "Avenella flexuosa",
  2019, "52 AN4C 52", "Antennaria alpina cf"
)


## Adds presence in new subplots
# This is needed in cases where species names were changed or species were split into 2 and presence in some subplots need to be added to the dataset
# list for subplot is created and then made into a long table
# also needs more info like recorder, because this is needed for the maps
add_subplot = tribble(
  ~year, ~turfID, ~species, ~subplot, ~variable, ~value, ~recorder,
  2020, "83 AN1I 83", "Festuca rubra", list(4, 5, 9, 12, 15, 18, 19, 20, 21, 22, 23, 24, 25), "presence", 1, "aud",
  2019, "1 WN1M 84", "Leontodon autumnalis", list(3, 4, 10, 21, 22), "presence", 1, "silje",
  2019, "1 WN1M 84", "Festuca rubra", list(5, 6, 7), "presence", 1, "silje",
  2019, "5 WN1I 86", "Festuca rubra", list(1, 16, 17, 18, 20), "presence", 1, "silje",
  2019, "5 WN1I 86", "Leontodon autumnalis", list(8, 9, 10, 15, 20), "presence", 1, "silje",
  2019, "13 WN6C 90", "Avenella flexuosa", list(3, 7, 16), "presence", 1, "aud",
  2019, "14 WN6I 92", "Leontodon autumnalis", list(3, 4, 7, 8, 9, 11, 18, 19, 23), "presence", 1, "silje",
  2019, "21 WN5C 99", "Leontodon autumnalis", list(2, 6), "presence", 1, "linn",
  2019, "30 WN3M 107", "Luzula multiflora cf", list(2, 7), "presence", 1, "aud",
  2019, "36 WN10M 115", "Taraxacum sp.", list(7, 23, 24), "presence", 1, "silje",
  2019, "36 WN10M 115", "Agrostis capillaris", list(3, 5, 23), "presence", 1, "silje",
  2019, "53 WN4C 133", "Taraxacum sp.", list(2, 18, 22), "presence", 1, "silje",
  2019, "54 WN4I 134", "Taraxacum sp.", list(11, 12, 13, 16, 21), "presence", 1, "silje",
  2019, "59 WN8C 138", "Taraxacum sp.", list(3, 7, 13, 14, 17, 18, 19, 22), "presence", 1, "linn",
  2019, "61 WN8I 140", "Leontodon autumnalis", list(5, 11, 16, 17, 21, 22, 25), "presence", 1, "silje",
  2019, "9 AN6M 9", "Festuca rubra", list(19, 24), "presence", 1, "linn",
  2019, "9 AN6M 9", "Festuca rubra", list(24), "fertile", 1, "linn",
  2019, "11 AN6I 11", "Taraxacum sp.", list(3, 8, 9), "presence", 1, "silje",
  2019, "15 WN6N 95", "Leontodon autumnalis", list(7, 8, 22, 23), "presence", 1, "silje",
  2019, "16 AN6N 16", "Taraxacum sp.", list(2, 3, 4, 5, 6, 7, 12, 14, 16, 22, 23, 24), "presence", 1, "linn",
  2019, "20 AN5I 20", "Festuca rubra", list(2, 5, 7, 9, 10, 13, 14, 18, 19, 25), "presence", 1, "linn",
  2019, "20 AN5I 20", "Geranium sylvaticum", list(1, 6, 7, 17, 22, 23), "presence", 1, "linn",
  2019, "20 AN5I 20", "Taraxacum sp.", list(14, 15, 19, 20), "presence", 1, "linn",
  2019, "23 AN5N 23", "Antennaria sp", list(14, 15, 18, 22, 23), "presence", 1, "silje",
  2019, "38 AN10M 38", "Taraxacum sp.", list(8, 9), "presence", 1, "silje",
  2019, "43 AN7C 43", "Taraxacum sp.", list(21), "presence", 1, "linn",
  2019, "45 AN7I 45", "Festuca ovina", list(4), "presence", 1, "silje",
  2019, "45 AN7I 45", "Taraxacum sp.", list(1, 6), "presence", 1, "silje",
  2019, "46 AN7M 46", "Taraxacum sp.", list(10, 12, 14, 15), "presence", 1, "linn",
  2019, "50 AN4M 50", "Taraxacum sp.", list(2, 3, 8, 9, 10, 13, 14, 15, 19), "presence", 1, "silje",
  2019, "52 AN4C 52", "Antennaria alpina", list(19), "presence", 1, "aud",
  2019, "57 AN8C 57", "Taraxacum sp.", list(2, 3, 8, 9, 14, 25), "presence", 1, "linn",
  2019, "58 AN8I 58", "Taraxacum sp.", list(1, 2, 3, 4, 5, 6, 7, 11, 12, 16, 18, 23), "presence", 1, "silje",
  2019, "63 AN8N 63", "Taraxacum sp.", list(13, 14, 15, 16, 17, 19, 20, 22, 25), "presence", 1, "silje"
  
  ) %>% 
  unchop(subplot) %>% 
  mutate(subplot = unlist(subplot),
         subplot = as.character(subplot)) %>% 
  left_join(metaTurfID, by = "turfID")

# Removes presence data in subplots
# This is needed for misidentified species, or wrong entries in the data
remove_subplot = tribble(
  ~year, ~turfID, ~species, ~subplot, ~variable,
  2019, "1 WN1M 84", "Taraxacum sp.", list(3, 4, 10, 21, 22), "presence",
  2019, "1 WN1M 84", "Nardus stricta", list(1, 2, 3, 4, 5, 6, 7, 8, 10, 13, 14, 15, 19, 20), "presence",
  2019, "5 WN1I 86", "Taraxacum sp.", list(8, 9, 10, 15, 20), "presence",
  2019, "30 WN3M 107", "Luzula spicata cf", list(2, 7), "presence",
  2019, "20 AN5I 20", "Potentilla crantzii", list(1, 6, 7, 17, 22, 23), "presence",
  2019, "23 AN5N 23", "Antennaria dioica", list(14, 15, 18, 22, 23), "presence"
  
) %>% 
  unchop(subplot) %>% 
  mutate(subplot = unlist(subplot),
         subplot = as.character(subplot))




# CHECKS

# c("Antennaria alpina cf", "Antennaria dioica cf", "Antennaria sp")
# c("Luzula multiflora cf", "Luzula sp", "Luzula spicata cf")
# c("Taraxacum sp.", "Leontodon autumnalis")
# 
# cover %>% filter(turfID == "61 WN8I 140", species %in% c("Taraxacum sp.", "Leontodon autumnalis")) %>% as.data.frame()
# community %>% filter(turfID == "73 WN2M 153", species %in% c("Luzula multiflora cf", "Luzula sp", "Luzula spicata cf")) %>% as.data.frame()
CommunitySubplot %>% filter(turfID == "66 WN9I 147", grepl("Luzula", species), variable == "fertile") |> as.data.frame()
# 
# cover %>% filter(turfID == "3 WN1C 85") %>% distinct(species) %>% pn
#   
# library("turfmapper")
# grid <- make_grid(ncol = 5)
# CommunitySubplot %>%
#   filter(variable == "presence",
#          ! grepl("Carex", species),
#          turfID == "16 AN6N 16"
#   ) %>%
#   left_join(cover %>% select(year, turfID, species, cover)) %>%
#   mutate(subplot = as.numeric(subplot),
#          year_recorder = paste(year, recorder, sep = "_")) %>%
#   select(-year) %>%
#   arrange(destSiteID, destPlotID, turfID) %>%
#   group_by(destSiteID, destPlotID, turfID) %>%
#   nest() %>%
#   {map2(
#     .x = .$data,
#     .y = glue::glue("Site {.$destSiteID}: plot {.$destPlotID}: turf {.$turfID}"),
#     .f = ~make_turf_plot(
#       data = .x,
#       year = year_recorder,
#       species = species,
#       cover = cover,
#       subturf = subplot,
#       title = glue::glue(.y),
#       grid_long = grid)
#   )}
