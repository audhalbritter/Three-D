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
