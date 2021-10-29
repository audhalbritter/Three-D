### Community data corrections
# This script contains all changes that have been made to the community data (Cover and CommunitySubplot datasets)

comm_corrections = tribble(
  ~year, ~turfID, ~correction,
  2020, "83 AN1I 83", "Change Avenella flexuosa to Festuca rubra. Change cover, delete Ave fle; Change Phleum alp to Agrsotis cap, and change cover, delete Phl alp",
  2019, "1 WN1M 84", "Change Antennaria alp cf to sp; Change Festuca ovina in some subplots to rubra; adjust cover in both species; Add some subplots to Leo and remove from Tar sp, adjust cover",
  2020, "1 WN1M 84", "Change Antennaria dio cf to sp",
  2019, "5 WN1I 86", "Change Antennaria alpina cf to sp; Change Fes ovi to rubra, adjust cover, delete ovina; Change some sublots of Tar sp to Leo aut; add cover for Leo aut",
  2020, "5 WN1I 86", "Change Antennaria dioica cf to sp",
  2019, "13 WN6C 90", "Change Antennaria alpina cf to dioica, because flowering in 2021",
  2019, "13 WN6C 90", "Change Fes rub to Ave fle, adjust cover and delete Fes rub",
  2019, "14 WN6I 92", "Change luzula spicata cf to sp; Add subplots to Leontodon autumnalis according to pic and adjust cover",
  2019, "15 WN6N 95", "Change Luzula spicata cf to sp",
  2021, "15 WN6N 95", "Change Antennaria sp to Antennaria alpina cf, because of comment in the data",
  2019, "19 WN5I 97", "Change Antennaria dioica cf to Antennaria sp",
  2019, "21 WN5C 99", "Change Antennaria alpina cf to Antennaria sp; Remove Tar sp, and add some subplots to Leo aut, adjust cover, according to pic.",
  2019, "22 WN5M 102", "Change Antennaria alpina cf to Antennaria sp",
  2019, "24 WN5N 103", "Change Taraxacum sp. to Leontodon autumnalis, because of picutre",
  2019, "29 WN3C 106", "Change Luz spi cf to Luz spi: flower; Change Tar to Leo, according to picutre",
  2020, "29 WN3C 106", "Change Luz spi cf to Luz spi: flower",
  2021, "29 WN3C 106", "Change Antennaria sp to Antennaria alpina cf; change Luz spi cf to Luz spi: flower",
  2021, "30 WN3M 107", "Change Antennaria sp to Antennaria alpina cf; change Luz sp to Luz mult cf",
  2019, "30 WN3M 107", "Change Luz mult to spi in some sublots, adjust cover, remove from subplots",
  2019, "32 WN3N 112", "Change Luzula sspicata cf to Luzula sp",
  2021, "34 WN10I 114", "Change Antennaria sp to Antennaria dioica cf, because flower in 2019; Change Luzula sp to Luzula spicata cf, very narrow leaves",
  2019, "36 WN10M 115", "Change Tar to Leo aut, adjust cover, add Tar sp to some sublots and add cover; Remove Phl alp, because it looks like it was never there and add some subplots for Agr cap, often confused these two sp.",
  2019, "73 WN2M 153", "Change Luzula spicata cf to Luzula spicata because of flower",
  2020, "73 WN2M 153", "Change Luzula multiflora cf to Luzula spicata, because of flower in 2019",
  2021, "37 WN10C 116", "Change Antennaria sp to Antennaria dioica cf, because flowering in 2019; Change Luzula sp to Luz spicata because of flower in 2019",
  2019, "42 WN7I 123", "Change Antennaria alpina cf to Antennaria sp, no comment on which species it could be.",
  2019, "44 WN7M 125", "Change Taraxacum sp. to Leontodon autumnalis, misidentificaiton.",
  2021, "53 WN4C 133", "Change Antennaria sp to Antennaria alpina cf, because of comment",
  2019, "53 WN4C 133", "Change Tar sp to Leo aut, because of pic, add Tar sp in some supblots and cover",
  2019, "54 WN4I 134", "Change Salix reticulata to Vaccinium uliginosum, clear misidentification; Change Tar sp to Leo aut, because of pic, add Tar sp in some supblots and cover",
  2019, "59 WN8C 1385", "Add Tar sp to some of the subplots, because it is clearer there according to the pics, adjust cover for Tar sp and Leo aut",
  2019, "61 WN8I 140", "Change Luzula spicata cf to Luzula sp, no indication what sp it is; Add Leo aut in subplots, adjust cover",
  2021, "71 WN9N 151", "Change Luzula multiflora cf to Luzula multiflora, flower",
  2019, "73 WN2M 153", "Change Leontodon autumnalis to Taraxacum sp, because of following years",
  2019, "4 AN1C 4", "Change Antennaria alpina cf to Antennaria dioica, because of flower in 2020",
  2020, "4 AN1C 4", "Change Antennaria dioica cf to Antennaria dioica, because of flower in 2020",
  2021, "4 AN1C 4", "Change Antennaria sp to Antennaria dioica, because of flower in 2020",
  2021, "6 AN1I 6", "Change Antennaria sp to Antennaria alpina cf, because previous years",
  2021, "7 AN1N 7", "Change Antennaria sp to Antennaria alpina cf, because previous years",
  2019, "9 AN6M 9", "Change Achillea millefolium to Alchemilla alpina, misidentification",
  2021, "9 AN6M 9", "Change Antennaria dioica cf to Antennaria alpina cf, likely because of flower",
  2019, "9 AN6M 9", "Change Avenella flexuosa to Festuca rubra, does not occur in 2021, found evidence on picture, add subplots and cover",
  2019, "9 AN6M 9", "Change Leontodon autumnalis to Taraxacum sp.",
  2019, "11 AN6I 11", "Change Antennaria alpina cf and dioica cf to Antennaria sp, unclear which sp; Change Tar sp to Leo, because of picture, adjust cover and add some Tar to subplots according to picture",
  2019, "15 WN6N 95", "Add some subplots for Leo aut, and cover, according to pic and 2021 data",
  2019, "16 AN6N 16", "Change Astragalus alpina to Oxytropa laponica, verified in 2021; add Tar sp in 2019 in subplots, because of pic, adjust cover for leo and tar; Change Antennaria alpina cf to Antennaria sp, unsure",
  2019, "20 AN5I 20", "Make all Ave flex to Festuca rubra, adjust cover and subplots; Change most pot cra to Ger syl in 2019, adjust cover and subplots; Add some subplot to Tar sp in 2019 according to pics, adjust cover for Tar.",
  2019, "23 AN5N 23", "Change Antennaria sp to Antennaria dioica, because of flower; Make some subplots in 2019 to Ant sp.",
  2021, "27 AN3C 27", "Change Antennaria sp to Antennaria dioica, because of flower in 2019.",
  2019, "27 AN3C 27", "Change Deschampsia cespitosa to Deschampsia alpina, because of 2021; Change Taraxacum sp. to Leontodon autumnalis, because of following years and pic",
  2020, "27 AN3C 27", "Change Deschampsia cespitosa to Deschampsia alpina, because of 2021; change luz mult to luz mult cf",
  2019, "28 AN3I 28", "Change Antennaria dioica cf and alpina cf to Antennaria sp, uncertain",
  2020, "28 AN3I 28", "Change Antennaria dioica cf to Antennaria sp",
  2021, "28 AN3I 28", "Change Luzula sp to Luzula spicata cf, because previous years",
  2019, "31 AN3N 31", "Change Deschampsia cespitosa to Deschampsia alpina, because of 2021; Change all Luz to Luz sp, unsure",
  2020, "31 AN3N 31", "Change Deschampsia cespitosa to Deschampsia alpina, because of 2021; hange all Luz to Luz sp, unsure",
  2021, "31 AN3N 31", "Change all Luz to Luz sp, unsure",
  2019, "33 AN10I 33", "Change Antennaria alpina cf to Antennaria sp, unsure; Change Taraxacum sp. to Leontodon autumnalis according to pic and 2021 data",
  2019, "35 AN10C 35", "Change Antennaria alpina cf to Antennaria sp, unsure",
  2019, "38 AN10M 38", "Change Avenella flexuosa to Festuca ovina, because of pic; change Luz spicata sf to Luz spicata, because of flower; Change Taraxacum sp. to Leontodon autumnalis according to pic, adjust cover, add Tar sp to some subplots according to pics",
  2021, "38 AN10M 38", "Change Luzula sp to Luzula spicata because of 2019 data",
  2019, "39 AN10N 39", "Change Deschampsia cespitosa to Deschampsia alpina, because Lia",
  2019, "43 AN7C 43", "Add Taraxacum sp. in one subplot according to pic",
  2019, "45 AN7I 45", "Change Antennaria dioica cf to Antennaria dioica, because of flower; Change Deschampsia cespitosa to Deschampsia alpina because Lia; Add Fes ovi in one subplot according to pic; Change Taraxacum sp.to Leontodon autumnalis, add 2 subplots and cover with Tar sp",
  2021, "45 AN7I 45", "Change Antennaria sp to Antennaria dioica, because of 2019 data",
  2019, "46 AN7M 46", "Change Antennaria alpina cf to Antennaria sp, unsure; Add some subplots and cover for Tar sp according to pic.",
  2019, "49 AN4I 49", "Change Antennaria dioica cf to Antennaria sp, unsure; Chnage Tar sp to leo aut and adjust cover, add Tar in some subplots and cover according to picure",
  2021, "49 AN4I 49", "Change Antennaria alpina cf to Antennaria sp, unsure",
  2019, "52 AN4C 52", "Change Antennaria dioica cf to Antennaria alpina, flower and 2021, need to remove Ant alp and add to subplots, adjust cover; Change Luzula spicata cf to Luzula spicata, flower",
  2021, "52 AN4C 52", "Change Antennaria dioica cf to Antennaria dioica, flower; ChangeLuzula sp to Luzula spicata, flower",
  2019, "57 AN8C 57", "Add Tar sp in some subplots and cover",
  2019, "57 AN8C 57", "Change Tar to Leo, adjust cover, add Tar sp in some subplots and cover",
  2019, "63 AN8N 63", "Change Taraxacum sp. to Leontodon autumnalis, adjust cover, add some subplots and cover for Tar sp, picutre",
  2019, "68 AN9I 68", "Change Luzula spicata cf to Luzula spicata, because of flower",
  2021, "68 AN9I 68", "Ch angeLuzula sp to Luzula spicata because of flower in 2019",
  2019, "70 AN9C 70", "Change Taraxacum sp. to Leontodon autumnalis, because of pic",
  2020, "75 AN2I 75", "Change Luzula spicata cf to Luzula sp, unsure"

)

### General problems in the data
# Lot's of Phleum alpinum in 2019 at Joa, which is not there in 2021 anymore. Checked on pictures is real.
# In 2019 lots of Tar sp and Leo aut were mixed. Many of those can be fixed by checking on the pictures and with the data from the following years
# Ant alp and dio cannot always be distinguished. Ant sp have been changed to species when a plant was flowering or when there was a clear remark in the data that it was a specific species. In the other cases Antennaria has been change to Ant sp.
# Luzula species are difficult to distinguish. Luzula has been change to species if flowers are present in one year or if the recorded strongly suggests that it is a specific species. Otherwise, it has been changed to Luz sp.
# If species only occurs in one year, but shows similar patterns for another species, pictures and datasheets were checked and wrong entries/species names were fixed.



# CHECK PICS !!!
# 74 WN2C 155 Ave, Fes o, r...?
# 156 AN2C 156 Poa pra in 2020 is Poa alp?
# 80 WN2N 159 ver alp and ver fru; check leo tar; Poas?



### PROBLEMS IN THE DATA THAT MIGHT NEED FIXING ###
### JOA
# 94 AN6I 94 2019 Fes rub, 2021 Fes ovi? Unclear
# 19 WN5I 97 might not be much Tar sp in 2019, unsure from pic
# 110 AN3I 110 Phl alp only in 2020? Could be some in 2019...
# 32 WN3N 112 Looks like 2019 Fes ovi is Fes rub and 2020 Des ces is Fes rub.
# 120 AN10N 120 could Desch cesp in 2019 be Fes rub? According to pic...
### Lia
# 44 WN7M 125 poa pra very likely only poa alp in 2019, missing in 2021
# 47 WN7N 128 Ave fle in 2019 is probabyl Fes rub, trust species ID in 2021 more; also check Poa alp, Phl alp in 2019, something is there! Also there are some Vac in 2019!
# 53 WN4C 133 Ave fle in 2019 might be Fes rub
# 61 WN8I 140 Ave fle in 2019 very likely Fes something?
# 64 WN8N 143 Fes ovi?
# 65 WN9M 145 Vac myr in 2019 maybe some of the salix?  
# 66 WN9I 147 Vac myr in 2021 Salix? Def Salix in 2019, pic! Poa vs. Phle??? 
# 69 WN9C 150 Def more Fes rub?ovi? in 2019! There is salix herb in 2019, what happens in 2021? Does not look like there is Sibb pro in 2019... very dark plot, maybe all disappeared.
# 73 WN2M 153 Desch alp in 2020, could be Fes ovi and/or rub?
# 78 WN2I 158 Fes rub and Agr mert could be the same?
# 160 AN2N 160 Cerastium fontanum in 2019 could be Cer cer? Festucas could be the same?

### LIA
# 12 AN6C 12 Poa pra could be poa alp in 2019?
# 16 AN6N 16 Ave flex in 2019? Agr mert?
# 17 AN5M 17 Ave flex in 2019 Fes rub?
# 18 AN5C 18 Ave flex in 2019 Fes rub?
# 23 AN5N 23 Ave flex in 2019 Fes rub?
# 33 AN10I 33 most likely Luz spicata in 2021, Phle alp might be Agr cap
# 35 AN10C 35 Ave fle could be Fes rub in 2019, looks like Fes ovi?
# 39 AN10N 39 Phle alp looks like Agr cap on pic
# 43 AN7C 43 Anth odo in 2019 could be Phle alp?
# 45 AN7I 45 Ave flex in 2019 could be fes rub; potentially add Fes rub in 2019 in some subplots, according to pic.
# 46 AN7M 46 Omalotheca supina in 2019 in pic?
# 48 AN7N 48 Anth odo in 2019 Agr cap?
# 49 AN4I 49 Gen niv and Erigeron the same?
# 57 AN8C 57 Violas the same? Agr and Poa?
# 60 AN8M 60 Diphasiastrum...
# 63 AN8N 63 Festuca rubra 2019, does not look like much in 2019, seem ok.
# 70 AN9C 70 Unsure about Fes ovi in 2019
# 76 AN2M 76 Viola probably the same

### VIK
# 159 WN2N 200 Ave and Fes?