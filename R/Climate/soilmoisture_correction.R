### Soilmoisture correction
# based on appendix A of Wild 2019 (https://www-sciencedirect-com.pva.uib.no/science/article/pii/S0168192318304118#sec0095) and https://www.tomst.com/tms/tacr/TMS3calibr1-11.xlsm


soil.moist <- function(rawsoilmoist, soil_temp, soilclass){

  # creating df with parameters for each soil type
  soilclass.df <- tibble(
    soil = c("sand", "loamy_sand_A", "loamy_sand_B", "sandy_loam_A", "sandy_loam_B", "loam", "silt_loam", "peat"),
    a = c(-3E-9, -1.9e-8, -2.3e-8, -3.8e-8, -9e-10, -5.1e-8, 1.7e-8, 1.23e-7),
    b = c(1.61192e-4, 2.6561e-4, 2.82473e-4, 3.39449e-4, 2.61847e-4, 3.97984e-4, 1.18119e-4, 1.44644e-4),
    c = c(-0.109956505, -0.154089291, -0.167211156, -0.214921782, -0.158618303, 0.291046437, -0.101168511, 0.202927906),
    AirCalib = rep(57.64530756, 8), # a constant across all soil types, don't know exactly what this does
    AirPuls = rep(56.88867311, 8), # a constant across all soil types, don't know exactly what this does
    DilVol = rep(-59.72975311, 8) # a constant across all soil types, don't know exactly what this does
  )
  
  #filtering soilclass.df based on which soilclass was entered in the function
  soilclass.df <- soilclass.df %>%
    filter(
      soil == soilclass
    )
  
  #calculating the volumetric soil moisture with the parameters corresponding to the soil class and the raw soil moisture from the logger
  volmoist = (soilclass.df$a * rawsoilmoist^2) + (soilclass.df$b * rawsoilmoist) + soilclass.df$c
  
  #temperature correction
  temp_ref <- 24
  delta_air <- 1.91132689118083
  delta_water <- 0.64108
  delta_dil <- -1.270246891 # this is delta-water - delta_air
  # we don't know what this does or what the variables do, but the result is the same as in excel
  temp_corr <- rawsoilmoist + ((temp_ref-soil_temp) * (delta_air + delta_dil * volmoist))
  # volumetric soil moisture with temperatue correction
  volmoistcorr <- with(soilclass.df,
                       ifelse(rawsoilmoist>AirCalib,
                              (temp_corr+AirPuls+DilVol*volmoist)^2*a+(temp_corr+AirPuls+DilVol*volmoist)*b+c,
                              NA))
  return(volmoistcorr)
  # return(volmoist) #let's just use the soil moisture without temperature correction for now
}