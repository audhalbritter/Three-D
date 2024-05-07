# Data simulation
library("tidyverse")
library("simr")
library("lme4")
library("vegan")
library("ggvegan")
library("readxl")

model1 <- glmer(z ~ x + (1|g), family="poisson", data=simdata)
summary(model1)

fixef(model1)["x"] <- -0.1

powerSim(model1)

model2 <- extend(model1, along = "x", n = 20)
powerSim(model2)

pc2 <- powerCurve(model2)


# adding groups
model3 <- extend(model1, along = "g", n = 15)
pc3 <- powerCurve(model3, along = "g")


# Simulate your own data
x <- rep(1:10)
g <- c("a", "b", "c")
X <- expand.grid(x = x, g = g)


b <- c(2, -0.1) # fixed intercept and slope
V1 <- 0.5 # random intercept variance
V2 <- matrix(c(0.5,0.05,0.05,0.1), 2) # random intercept and slope variance-covariance matrix
s <- 1 # residual variance

model1 <- makeLmer(y ~ x + (1|g), fixef = b, VarCorr = V1, sigma = s, data = X)
print(model1)


#### SPECIE RICHNESS - SEEDCLIM ####
load(file = "data/cover.thin.Rdata")

dat <- cover.thin %>% 
  filter(TTtreat %in% c("TTC", "TT2"),
         siteID %in% c("Lavisdalen", "Hogsete"),
         year %in% c(2011)) %>% 
  # calculate diversity
  group_by(turfID, blockID, TTtreat, siteID, year) %>%  
  summarise(richness = n(), 
            diversity = diversity(cover), 
            evenness = diversity/log(richness)) %>% 
  ungroup() %>% 
  mutate(TTtreat = factor(TTtreat, levels = c("TTC", "TT2"))) %>% 
  filter(!blockID %in% c("Lav5", "Hog5"))

hist(dat$richness, breaks = 10)
fit <- lmer(richness ~ TTtreat*siteID + (1|blockID), dat)
#fit <- glmer(richness ~ TTtreat*siteID + (1|blockID), dat, family = "poisson")
summary(fit)

fixef(fit)["TTtreatTT2"] <- 1.75
powerSim(fit, nsim = 100, test = fcompare(richness ~ TTtreat))



#### SPECIE RICHNESS - FINSE (WARM AND N) #### 
# Vegetasjonsresponser i 2000, 2003, 2007
# sub-plot frekvenser, altså hvor mange sub-plot arten er til stede av totalt 36 sub-plot
# slow release granular NPK fertilizer (ca. 10g N, 2g P, 8g K.m–2·yr–1)
finse <- read_excel(path = "data/testdata/Data warming and nutrient addition 2000-2007.xlsx")
finse <- finse %>% 
  gather(key = Species, value = PropSubPlot, -Plot.ID, -Block, -Treatment, -Year) %>% 
  filter(PropSubPlot > 0) %>% 
  group_by(Year, Treatment, Block) %>%  
  summarise(richness = n(), 
            diversity = diversity(PropSubPlot), 
            evenness = diversity/log(richness)) %>% 
  ungroup() %>% 
  mutate(Treatment = factor(Treatment, levels = c("control", "warming", "nutrient addition", "warming + nutrient addition")))
  
ggplot(finse, aes(x = richness)) +
  geom_histogram() +
  facet_wrap(~ Treatment)

dat <- finse %>% 
  filter(Year == 2007,
         Treatment %in% c("control", "warming"))

fit <- lmer(richness ~ Treatment + (1|Block), dat)
summary(fit)

fixef(fit)["Treatmentwarming"] <- -3.2
powerSim(fit, nsim = 100, test = fcompare(richness ~ Treatment))

fixef(fit)["Treatmentnutrient addition"] <- -5.9
powerSim(fit, nsim = 100, test = fcompare(richness ~ Treatment))

# Test only warm and w+N or N and w+N
fixef(fit)["Treatmentwarming + nutrient addition"] <- -13
powerSim(fit, nsim = 100, test = fcompare(richness ~ Treatment))



fit2 <- extend(fit, along = "blockID", n = 60)
powerSim(fit2)
pc2 <- powerCurve(fit2, along = "blockID")
plot(pc2)

ggplot(finse, aes(x = Treatment, y = richness, fill = Treatment)) +
  geom_boxplot() +
  facet_wrap(~ Year)



#### C-FLUX - FunCAB #### 
# 2017 NEE, GPP and Reco data
# 3 years after removal
carbon <- read_csv(file = "data/testdata/CO2veg_Removal2017.csv")
carbon <- carbon %>% 
  filter(Treatment == "C",
         Site %in% c("Lav", "Hog", "Vik")) %>% 
  mutate(Site = factor(Site, levels = c("Lav", "Hog", "Vik")))

fit <- lmer(GPP ~ Site + (1|Block), carbon)
summary(fit)

fixef(fit)["SiteVik"] <- 3.3
powerSim(fit, nsim = 100, test = fcompare(richness ~ Site))





t <- dat$TTtreat
b <- dat$blockID
y = dat$richness
X <- data_frame(t = t,
                b = b,
                y = y)
effectSize <- c(28, -2.8)
V1 <- -0.5
sigma = 1
model1 <- makeLmer(y ~ t + (1|b), fixef = effectSize, VarCorr = V1, sigma = sigma, data = X)
print(model1)

powerSim(model1)


# THREE-D data N level per block or random
richness <- tibble(richness = rpois(n = 160, lambda = 10))
dat <- ExperimentalDesign %>% 
  bind_cols(richness)

fit <- lmer(richness ~ grazing + (1|origBlockID), dat)
summary(fit)

fixef(fit)["grazingI"] <- -0.07
powerSim(fit)

fit2 <- extend(fit, along = "grazing", n = 200)
summary(fit2)
powerSim(fit2)