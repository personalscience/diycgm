#
# This is the server logic of a Shiny web application. You can run the
# application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#


#Sys.setenv(R_CONFIG_ACTIVE = "local")


#' Define server logic required to display CGM information
#' @import shiny
#' @import magrittr dplyr
server <- function(input, output) {

   output$about_page <- renderText("Be Your Own Scientist")

   output$currentDB <- renderText(sprintf("DB=%s. cgmr version = %s, db  = %s",
                                          attr(config::get(),"config"),
                                          packageVersion("cgmr"),
                                          first(tbl(con,"glucose_records") %>%
                                                  filter(time == max(time, na.rm=TRUE)) %>%
                                                  pull(time) %>%
                                                  with_tz(tzone="America/Los_Angeles"))))
   #

   glucose_df <- csv_read_server("fromCSV")

}






