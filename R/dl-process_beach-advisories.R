# downloaded from website:
# https://beaches.mdeq.ms.gov/Historical/HCA
# on 7/16/26
# this includes all advisories and closures back to 2000
# site numbers in current use only started in 2016 or so
# reasons for advisories/closures have varied as well
# I've got some notes but for now will just summarize number of days
# by station  


# here, just need to subset to 2025
# any closures - starting or ending in 2025

library(readxl)
library(dplyr)
library(stringr)
library(lubridate)

dat <- read_xlsx(here::here("data",
                            "beach_advisories",
                            "HistoricalAdvisoriesClosures-07162026081951.xlsx"))
dat_stn.needed <- dat |> 
  filter(is.na(`Station Number`),
         `Advisory/Closure` == "Advisory")
dat_stn.needed$station <- str_match(dat_stn.needed$Description, "(?i)county\\s*station\\s*([A-Za-z0-9]+)")[,2]
dat_stn.needed$beach   <- str_match(dat_stn.needed$Description,
                        "(?i)county\\s*station\\s*[A-Za-z0-9]+\\s*\\(?\\s*(?:\\[[^\\]]*\\]\\s*)?([A-Za-z][A-Za-z '.\\-]*?Beach)")[,2]

dat_2025 <- dat %>%
  filter(year(`Start Date`) == 2025 | year(`End Date`) == 2025)

dat_2025 <- dat_2025 %>%
  mutate(
    clipped_start = pmax(`Start Date`, as.Date("2025-01-01")),
    clipped_end   = pmin(`End Date`,   as.Date("2025-12-31")),
    days_total    = as.numeric(`End Date` - `Start Date`) + 1,
    days_in_2025  = as.numeric(clipped_end - clipped_start) + 1
  )

# make sure we don't have any issues where start date is
# actually after end date
dat_2025 %>% filter(days_in_2025 <= 0)

beach_advisories_2025 <- dat_2025
save(beach_advisories_2025,
     file = here::here("data",
                       "beach_advisories",
                       "beach_advisories_2025.RData"),
     compress = "xz")
