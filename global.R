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


source("mod_CSV.R")
source("psi_plot.R")

