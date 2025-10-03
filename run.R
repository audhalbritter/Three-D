#!/usr/bin/env Rscript
library(targets)
source("libraries.R")

targets::tar_make()
# targets::tar_make_clustermq(workers = 2) # nolint
# targets::tar_make_future(workers = 2) # nolint
tar_load_everything()


#ggsave("soil_figure.png", soil_figure, dpi = 300, width = 7, height = 5)
#ggsave("productivity_figure.png", productivity_figure, dpi = 300, width = 8, height = 3)
ggsave("pca.png", pca, dpi = 300, width = 8, height = 6)
ggsave("biomass.png", biomass_figure, dpi = 300, width = 8, height = 6)
