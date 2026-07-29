library(httr2)
library(dplyr)

# --- setup ---
year <- 2025
vec_yyyymm <- sprintf("%d%02d", year, 1:12)

variable <- "ppt"
zip_dir <- here::here("data", "precip", "zip")
tif_dir <- here::here("data", "precip", "tif")
# create directories (no problem if they already exist)
dir.create(zip_dir, showWarnings = FALSE, recursive = TRUE)
dir.create(tif_dir, showWarnings = FALSE, recursive = TRUE)

# --- 1. get release dates for the whole year in one call ---
releaseurl <- paste0(
  "https://services.nacse.org/prism/data/get/releaseDate/us/4km/", variable,
  "/", first(vec_yyyymm), "/", last(vec_yyyymm)
)

release_resp <- request(releaseurl) |> req_perform()
release_text <- resp_body_string(release_resp)

release_dates_all <- read.table(
  text = release_text, header = FALSE, sep = "",
  col.names = c("date", "release_date", "variable", "grid_count", "url"),
  stringsAsFactors = FALSE
)

# --- 2. loop through months, check local files, download + unzip if missing ---

for (i in seq_len(nrow(release_dates_all))) {
  
  yyyymm <- format(as.Date(release_dates_all$date[i]), "%Y%m")
  release_date <- release_dates_all$release_date[i]
  
  local_zip <- file.path(zip_dir, paste0(variable, "_", yyyymm, "_", release_date, ".zip"))
  
  # if a file already exists for this exact release date, skip it
  if (file.exists(local_zip)) {
    message(yyyymm, ": already have release ", release_date, ", skipping.")
    next
  }
  
  download_url <- paste0(
    "https://services.nacse.org/prism/data/get/us/4km/", variable, "/", yyyymm
  )
  
  message(yyyymm, ": downloading release ", release_date, "...")
  
  dl_resp <- tryCatch(
    request(download_url) |> req_perform(),
    error = function(e) e
  )
  
  if (inherits(dl_resp, "error")) {
    warning("Download failed for ", yyyymm, ": ", conditionMessage(dl_resp))
    next
  }
  
  writeBin(resp_body_raw(dl_resp), local_zip)
  
  # unzip just the .tif file into tif_dir
  zip_contents <- unzip(local_zip, list = TRUE)
  tif_name <- zip_contents$Name[grepl("\\.tif$", zip_contents$Name)]
  
  if (length(tif_name) == 1) {
    unzip(local_zip, files = tif_name, exdir = tif_dir, junkpaths = TRUE)
    message(yyyymm, ": extracted ", tif_name)
  } else {
    warning(yyyymm, ": expected exactly one .tif in zip, found ", length(tif_name))
  }
  
  Sys.sleep(2)  # be nice to PRISM's server, per their own example script
}