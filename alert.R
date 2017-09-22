#!/usr/bin/env Rscript
#
################################################################################
#
# Alert dependency change on CRAN like networks
#
# New R packages get added to CRAN everyday and new dependencies keep getting
# created and deleted. This script is used with a CRON job to periodically look
# at new dependencies that got forged and removed during a certain period.
#
# This script is to be run using a CRON jon at regular interval. Run setup.R
# script to setup the directories and packages for the first time. After that
# the alerts directory contains periodic alterts.
#
# usage: Rscript alert.R non_existing_directory
#
################################################################################

ca       = commandArgs(trailingOnly = TRUE)
basePath = ca[1]
if(length(ca) > 1){ repository = ca[2] } else { repository = "CRAN" }

# load libraries
pacman::p_load("pkggraph")
stopifnot(packageVersion("pkggraph") >= "0.2.2")
pacman::p_load("tidyverse")
pacman::p_load("futile.logger")
pacman::p_load("safer")
pacman::p_load("sidekicks")
pacman::p_load("curl")

logFile = file.path(basePath, "log.log")
flog.logger("alertLog"
            , INFO
            , appender = appender.file(logFile)
            ) %>% invisible()

flog.info("Starting Alert check", name = "alertLog")

# check for internet connection
if(!curl::has_internet()){
  flog.error("No internet", name = "alertLog")
  flog.info("Ended Alert check unsuccessfully", name = "alertLog")
  stop("No internet")
}

# read previous depTable and pkglist
depTablePath = file.path(basePath, "depTable")
fileNames    = list.files(depTablePath, full.names = TRUE)
depTableOld  = safer::retrieve_object(conn = fileNames[1])
pkglistOld   = scan(file.path(basePath, "pkglist")
                    , what = "character"
                    , quiet = TRUE
                    )

# get current cran data
suppressMessages(pkggraph::init())
pkglistNew = rownames(packmeta)
newPackages = setdiff(pkglistNew, pkglistOld)

# look at the difference and write to file
depTableAdded   = dplyr::setdiff(deptable, depTableOld) %>%
  mutate(type = "addition")
depTableRemoved = dplyr::setdiff(depTableOld, deptable) %>%
  mutate(type = "deletion")

depTableDiff = dplyr::bind_rows(depTableAdded, depTableRemoved) %>%
  mutate(is_pkg_1_new = pkg_1 %in% newPackages)

if(nrow(depTableDiff) == 0){
  flog.info("No new dependencies found", name = "alertLog")
}

alertDir = file.path(basePath, "alerts", "alert") %>%
  sidekicks::append_time()

dir.create(alertDir) %>% invisible()
depTableDiffFile = file.path(alertDir, "depTableDiff")
file.create(depTableDiffFile) %>% invisible()
readr::write_csv(depTableDiff, path = depTableDiffFile)
flog.info(paste0("Wrote diff to ", depTableDiffFile), name = "alertLog")

# move depTableOld to archive and write a new depTable
archiveFileName = file.path(basePath
                            , "archive"
                            , basename(fileNames[1])
                            )
file.copy(fileNames[1], archiveFileName) %>% invisible()
file.remove(fileNames[1]) %>% invisible()
flog.info(paste0("Moved old depTable to archive"), name = "alertLog")


depTableName = file.path(basePath, "depTable", "depTable.bin") %>%
  sidekicks::append_time()
safer::save_object(object = deptable, conn = depTableName) %>%
  invisible()
flog.info(paste0("Renewed depTable"), name = "alertLog")

# renew pkglist
if(length(newPackages) > 0){
  write(pkglistNew, file.path(basePath, "pkglist"), append = FALSE)
  flog.info(paste0("Renewed pkglist"), name = "alertLog")
}

flog.info("Ended Alert check successfully", name = "alertLog")
