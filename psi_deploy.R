# deploy to shinyapps.io

# install.packages(c("tidyverse", "DBI", "config", "RPostgres", "shiny", "devtools"))
# install.packages(c("devtools", "roxygen2", "testthat", "knitr"))
# install.packages(c("bslib"))
# install.packages(c("firebase"))

### Deploy to Polished

remotes::install_github("tychobra/polished")

polished::deploy_app(
  app_name = config::get("tastermonial")$polishedApp,
  api_key = config::get("tastermonial")$polishedAPI
)


#devtools::load_all("~/dev/psi/psiCGM/")
