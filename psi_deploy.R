# deploy to shinyapps.io

# install.packages(c("tidyverse", "DBI", "config", "RPostgres", "shiny", "devtools"))
# install.packages(c("devtools", "roxygen2", "testthat", "knitr"))
# install.packages(c("bslib"))
# install.packages(c("firebase"))

### Deploy to Polished

remove.packages("tastermonial")
devtools::install_github("personalscience/taster",
                         ref = "a5d6649977c3177c48f8a7c8ec7b067924ab1e0e",
                         upgrade = "never") #577dc4100cac3940") #,

remotes::install_github("tychobra/polished")

polished::deploy_app(
  app_name = config::get("tastermonial")$polishedApp,
  api_key = config::get("tastermonial")$polishedAPI
)


#devtools::load_all("~/dev/psi/psiCGM/")
