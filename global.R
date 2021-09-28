# global variables
library(shiny)
library(tidyverse)
library(lubridate)
library(DBI)
library(RPostgres)
library(cgmr)

Sys.setenv(R_CONFIG_ACTIVE = "shinyapps")

conn_args <- config::get("dataconnection")
con <- DBI::dbConnect(
  drv = conn_args$driver,
  user = conn_args$user,
  host = conn_args$host,
  port = conn_args$port,
  dbname = conn_args$dbname,
  password = conn_args$password
)

GLUCOSE_RECORDS<- tbl(con,"glucose_records") %>% collect()
NOTES_RECORDS <- tbl(con, "notes_records") %>% collect()

source('utils.R')
source("mod_CSV.R")
source("psi_plot.R")
source("mod_goddessUI.R")
taster_foods <- food_list_db(user_id = c(1001:1004,1007:1021))
source("mod_foodTaster_compare.R")

psi_theme <-   theme(text = element_text(# family = "Montserrat",
  face = "bold", size = 15),
  axis.text.x = element_text(size = 15, angle = 90, hjust = 1),
  legend.title = element_blank())

