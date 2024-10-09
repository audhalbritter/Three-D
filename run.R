#!/usr/bin/env Rscript
library(targets)
source("R copy/Load packages.R")

targets::tar_make()
# targets::tar_make_clustermq(workers = 2) # nolint
# targets::tar_make_future(workers = 2) # nolint
tar_load_everything()
