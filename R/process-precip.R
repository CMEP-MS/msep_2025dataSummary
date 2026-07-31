# use files downloaded in dl-precip.R and trim them to the msep boundary
# and associated huc8s

library(terra)
library(sf)
library(msepBoundaries)
library(dplyr)
library(stringr)

in_path <- here::here("data",
                      "precip",
                      "tif")
out_path <- here::here("data",
                       "precip",
                       "processed")

# make sure out_path exists
dir.create(out_path, recursive = TRUE, showWarnings = FALSE)


in_fls <- dir(in_path)
out_fls <- list()

for(i in seq_along(in_fls)){
  in_file <- in_fls[i]
  out_file <- str_replace(in_file, "_us_", "_msep_")
  
  # read in and trim the file
  # msepBoundaries::outline_full is in NAD83,
  # and so are the PRISM rasters as of this writing (always worth checking)
  dat <- rast(here::here(in_path, in_file))
  dat_msep <- crop(dat, outline_full)
  dat_msep <- mask(dat_msep, outline_full)
  
  # writeRaster(dat_msep,
  #             here::here(out_path, out_file),
  #             overwrite = TRUE)
  
  out_fls[[i]] <- dat_msep
}

dat_stacked <- rast(out_fls)

# name the layers for month and year
# attach the "dates" as a time attribute, in case needed later
yyyymm <- str_extract(in_fls, "\\d{4}[-_]?\\d{2}")
dates <- as.Date(paste0(yyyymm, "01"), format = "%Y%m%d")
names(dat_stacked) <- format(dates, "%b %Y")     # "Jan 2025", "Feb 2025", ...
time(dat_stacked) <- dates


# write it all out
writeRaster(dat_stacked,
            here::here(out_path, "precip_2025.tif"),
            overwrite = TRUE)
