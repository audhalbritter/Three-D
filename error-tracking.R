test1 <- filter(co2_cut, campaign == 1) %>% 
  distinct(ID, type) %>% 
  mutate(
    type = as.factor(type)
  )
summary(test1)

test2 <- filter(co2_cut, campaign == 2) %>% 
  distinct(ID, type) %>% 
  mutate(
    type = as.factor(type)
  )
summary(test2)

#### 
filter(co2_fluxes, campaign == 1) %>% 
  distinct(ID, type) %>% 
  mutate(
    type = as.factor(type)
  ) %>% 
  summary()

filter(co2_fluxes, campaign == 2) %>% 
  distinct(ID, type) %>% 
  mutate(
    type = as.factor(type)
  ) %>% 
  summary()

###

filter(record, campaign == 1) %>% 
  mutate(
    type = as.factor(type)
  ) %>% 
  summary()

filter(record, campaign == 2) %>% 
  mutate(
    type = as.factor(type)
  ) %>% 
  summary()


filter(record, is.na(start))

#which flux ID had issues with temp soil or PAR sensor?
filter(co2_cut, !is.na(comments)) %>% 
  distinct(ID, comments, type)
