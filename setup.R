#!/usr/bin/env Rscript
#
#################################################################################
#
# Alert dependency change on CRAN like networks
#
# New R packages get added to CRAN everyday and new dependencies keep getting
# created and deleted. This script is used with a CRON job to periodically look
# at new dependencies that got forged and removed during a certain period.
#
# Alert script is to be run using a CRON jon at regular interval. Run setup.R
# script to setup the directories and packages for the first time. After that
# the alerts directory contains periodic alterts.
#
# usage: Rscript setup.R non_existing_directory
#
################################################################################

message("\n----\nSetting up 'DependencyAlters' ...")

ca = commandArgs(trailingOnly = TRUE)
basePath = ca[1]

if(dir.exists(basePath)){
  stop("Directory exists!")
}

dir.create(basePath)
dir.create(file.path(basePath, "depTable"))
dir.create(file.path(basePath, "archive"))
dir.create(file.path(basePath, "alerts"))
invisible(file.create(file.path(basePath, "log.log")))

if(!("pacman" %in% installed.packages()[,1])){
  install.packages("pacman", repos = "http://cloud.r-project.org/")
}
pacman::p_load("tidyverse", "pkggraph", "safer"
               , "curl", "futile.logger", "devtools"
)
if(!pacman::p_exists("sidekicks")){
  devtools::install_github("talegari/sidekicks")
}

if(!curl::has_internet()){
  flog.error("No internet", name = "alertLog")
  flog.info("Ended Alert check unsuccessfully", name = "alertLog")
  stop("No internet")
}

suppressMessages(pkggraph::init())
depTableName = file.path(basePath, "depTable", "depTable.bin") %>%
  sidekicks::append_time()
safer::save_object(object = deptable, conn = depTableName) %>%
  invisible()

message("done!\n----\n")
