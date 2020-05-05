library(tidyverse)
library(dbplyr)
library(lubridate)
library(scales)
library(ggthemes)
library(forecast)

con <- DBI::dbConnect(RMySQL::MySQL(),    
                      host = "localhost",   
                      port = 3306,   
                      dbname = "fitbit",   
                      user = "root",   
                      password = keyring::key_get('mysql'))

df <- tbl(con, 'sleep') %>%
  arrange(date) %>%
  filter(mainSleep == 1) %>% # main sleep = no naps
  collect() %>%
  mutate(date = as_datetime(date),
         startTime = as_datetime(startTime),
         sh = ifelse(hour(startTime) < 8, hour(startTime) + 24, hour(startTime)), #create numeric times
         sm = minute(startTime),
         st = sh + sm/60,
         eh = hour(endTime),
         em = minute(endTime),
         et = eh + em/60,
         mst = ma(st, 7), #create moving averages
         met = ma(et, 7)
  )

plt <- df %>%
    ggplot(aes(x = date))+
    geom_line(aes(y = et), color = 'coral', alpha = .3)+
    geom_line(aes(y = st), color = 'dodgerblue', alpha = .3)+
    geom_line(aes(y = met), color = 'coral', na.rm=T)+
    geom_line(aes(y = mst), color = 'dodgerblue', na.rm=T)+
    scale_y_continuous(breaks = seq(0, 30, 2),
                       labels = trans_format(function(x) ifelse(x > 23, x - 24, x), 
                                             format = scales::comma_format(suffix = ":00"))
    )+
    labs(x = "Date",
         y = 'Time')+
    theme_fivethirtyeight()

ggsave('sleepplot.svg', plt, 'svg', dpi = 'retina', path = '~/Documents/GitHub/fitbit/viz', width = 6, height = 4.8)