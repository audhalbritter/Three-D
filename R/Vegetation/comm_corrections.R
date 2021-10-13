### Community data corrections

comm_corrections = tribble(
  ~year, ~turfID, ~correction,
  2020, "83 AN1I 83", "Change Avenella flexuosa to Festuca rubra. Change cover, delete Ave fle; Change Phleum alp to Agrsotis cap, and change cover, delete Phl alp",
  2019, "1 WN1M 84", "Change Antennaria alp cf to sp; Change Festuca ovina in some subplots to rubra; adjust cover in both species",
  2020, "1 WN1M 84", "Change Antennaria dio cf to sp",
  2019, "5 WN1I 86", "Change Antennaria alpina cf to sp; Change Fes ovi to rubra, adjust cover, delete ovina; Change some sublots of Tar sp to Leo aut; add cover for Leo aut",
  2020, "5 WN1I 86", "Change Antennaria dioica cf to sp",
  2019, "13 WN6C 90", "Change Antennaria alpina cf to dioica, because flowering in 2021",
  2019, "13 WN6C 90", "Change Fes rub to Ave fle, adjust cover and delete Fes rub",
  2019, "14 WN6I 92", "Change luzula spicata cf to sp",
  2019, "15 WN6N 95", "Change Luzula spicata cf to sp",
  2021, "15 WN6N 95", "Change Antennaria sp to Antennaria alpina cf, because of comment in the data",
  2019, "19 WN5I 97", "Change Antennaria dioica cf to Antennaria sp",
  2019, "21 WN5C 99", "Change Antennaria alpina cf to Antennaria sp",
  2019, "22 WN5M 102", "Change Antennaria alpina cf to Antennaria sp",
  2019, "29 WN3C 106", "Change Luz spi cf to Luz spi: flower",
  2020, "29 WN3C 106", "Change Luz spi cf to Luz spi: flower",
  2021, "29 WN3C 106", "Change Antennaria sp to Antennaria alpina cf; change Luz spi cf to Luz spi: flower",
  2021, "30 WN3M 107", "Change Antennaria sp to Antennaria alpina cf; change Luz sp to Luz mult cf",
  2019, "30 WN3M 107", "Change Luz mult to spi in some sublots, adjust cover, remove from subplots",
  2019, "32 WN3N 112", "Change Luzula sspicata cf to Luzula sp",
  2021, "34 WN10I 114", "Change Antennaria sp to Antennaria dioica cf, because flower in 2019; Change Luzula sp to Luzula spicata cf, very narrow leaves",
  2019, "36 WN10M 115", "Change Tar to Leo aut, adjust cover, add Tar sp to some sublots and add cover; Remove Phl alp, because it looks like it was never there and add some subplots for Agr cap, often confused these two sp.",
  2021, "37 WN10C 116", "Change Antennaria sp to Antennaria dioica cf, because flowering in 2019",
  2019, "42 WN7I 123", "Change Antennaria alpina cf to Antennaria sp, no comment on which species it could be.",
  2019, "44 WN7M 125", "Change Taraxacum sp. to Leontodon autumnalis, misidentificaiton.",
  2021, "53 WN4C 133", "Change Antennaria sp to Antennaria alpina cf, because of comment",
  2019, "53 WN4C 133", "Change Tar sp to Leo aut, because of pic, add Tar sp in some supblots and cover",
  2019, "54 WN4I 134", "Change Salix reticulata to Vaccinium uliginosum, clear misidentification; Change Tar sp to Leo aut, because of pic, add Tar sp in some supblots and cover",
  2019, "59 WN8C 1385", "Add Tar sp to some of the subplots, because it is clearer there according to the pics, adjust cover for Tar sp and Leo aut",
  2019, "61 WN8I 140", "Change Luzula spicata cf to Luzula sp, no indication what sp it is; Add Leo aut in subplots, adjust cover",
  2021, "71 WN9N 151", "Change Luzula multiflora cf to Luzula multiflora, flower"

)



# 120 AN10N 120 could Desch cesp in 2019 be Fes rub? According to pic...
# 44 WN7M 125 poa pra very likely only poa alp in 2019, missing in 2021
# 47 WN7N 128 Ave fle in 2019 is probabyl Fes rub, trust species ID in 2021 more; also check Poa alp, Phl alp in 2019, something is there! Also there are some Vac in 2019!
# 53 WN4C 133 Ave fle in 2019 might be Fes rub
# 139 AN8I 139 2019 phle alp or agr cap?
# 61 WN8I 140 Ave fle in 2019 very likely Fes something?
# 64 WN8N 143 Fes ovi?
# 65 WN9M 145 Vac myr in 2019 maybe some of the salix?  
# 66 WN9I 147 Vac myr in 2021 Salix? Def Salix in 2019, pic! Poa vs. Phle??? 
# 69 WN9C 150 Def more Fes rub?ovi? in 2019! There is salix herb in 2019, what happens in 2021? Does not look like there is Sibb pro in 2019... very dark plot, maybe all disappeared.