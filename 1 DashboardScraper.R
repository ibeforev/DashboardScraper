rm(list = ls())
gc()

#############
##| Setup |##
#############

# Load Selenium #
require("RSelenium")
require("lubridate")

##| GA Dashboard |##

# Start driver #
driver_ga <- rsDriver(port = 4567L, 
                      browser = c("chrome"), 
                      chromever = "78.0.3904.70")

# Navigate to dashboard # 
remoteDriver_ga <- driver_ga$client
remoteDriver_ga$navigate("https://analytics.google.com/analytics/web/#/dashboard/zYiiP3mcRH69X3M5_jvnVA/a45693420w181462896p179706048/")

# SIGN IN - FUTURE AUTO LOGIN #

# Frames #
frames <- remoteDriver_ga$findElements(using = "tag name", 
                                       value = "iframe")

# Show list of frames #
sapply(frames, 
       function(x){
         x$getElementAttribute("src")
       })

# Switched to needed frame #
remoteDriver_ga$switchToFrame(frames[[1]]) # <- May need to change

# Find element #
activeUsersCheckout <- remoteDriver_ga$findElement(using = "id", 
                                                   value = "ID-layout-1571853332714-counterValue")
activeUsersRacePage <- remoteDriver_ga$findElement(using = "id", 
                                                   value = "ID-layout-1571853253294-counterValue")
activeUsersOverall <- remoteDriver_ga$findElement(using = "id", 
                                                  value = "ID-layout-1571853233601-counterValue")

##| Queue-It Dashboard |##

# Start driver #
driver_qi <- rsDriver(port = 4568L, 
                      browser = c("chrome"), 
                      chromever = "78.0.3904.70")

# Navigate to dashboard # 
remoteDriver_qi <- driver_qi$client
remoteDriver_qi$navigate("https://nyrr.go.queue-it.net/")

# Find element #
waiting <- remoteDriver_qi$findElement(using = "xpath", 
                                       value = "//*[@id='monitor-content']/app-root/app-monitor/div/div[2]/div[1]/div[2]/div/div[3]/app-info-tile-flip/div/div/div[2]/div/span")

######################
##| Active scraper |##
######################

# Start results dataset #
res <- data.frame(Timestamp = character(),
                  Metric = character(),
                  Value = integer())

# Scrape counts every 60 seconds and write to file #
endTime <- Sys.time() + hours(24)
while (Sys.time() < endTime){
  
  # Get text from elements #
  cat(paste0("Scraping (", Sys.time(), ") ... "))
  activeUsersCheckoutCount <- as.integer(activeUsersCheckout$getElementText())
  activeUsersRacePageCount <- as.integer(activeUsersRacePage$getElementText())
  activeUsersOverallCount <- as.integer(activeUsersOverall$getElementText())
  waitingCount <- ifelse(
    grepl("K", waiting$getElementText(), fixed = TRUE),
    as.integer(as.numeric(gsub("K", "", waiting$getElementText())) * 1000),
    as.integer(waiting$getElementText())
  )
  
  # Create temporary set #
  temp <- data.frame(
    Timestamp = substr(as.character(Sys.time()), 1, 16),
    Metric = ls(pattern = "Count"),
    Value = c(activeUsersCheckoutCount, activeUsersOverallCount, activeUsersRacePageCount, waitingCount)
  )
  
  # Combine with results set #
  res <- rbind(res, temp)
  
  # Write to file #
  write.csv(res,
            "QueueItGA-Scrape.csv",
            quote = TRUE,
            row.names = FALSE,
            na = "")
  
  # Pause for 60 seconds #
  cat(paste("zzz ... "))
  Sys.sleep(60)
  
  rm(temp)
}
