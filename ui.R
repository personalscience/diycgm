#
# This is the user-interface definition of a Shiny web application. You can
# run the application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#



#' Define UI for application that reads a CSV file
#' @import shiny
#' @import magrittr dplyr
ui <-fluidPage(tags$head(includeScript("google-analytics.html")),
                  navbarPage("Tastermonial", collapsible = TRUE, inverse = TRUE,

                            # theme = bslib::bs_theme(bootswatch = "cerulean"),

                 tabPanel("Compare Experiments",
                          fluidPage(
                              h2("Compare Experiments"),
                              mod_goddess_ui("food2_compare_plot")
                          )),
                 tabPanel("Compare Foods",
                          fluidPage(
                            mod_food_compare_ui("food_compare_plot")
                          )),
                 tabPanel("User View",
                          fluidPage(
                            mod_user_view_ui("user_view_ui_1")
                          )),

                 tabPanel("CSV Load",
                          fluidPage(
                            titlePanel("Upload your own Libreview CSV results"),
                            showLibreviewUI("fromCSV")
                          )),
                 tabPanel("About",
                          fluidPage(
                              #Application title
                              titlePanel("Personal Science Experiments", windowTitle = "Personal Science, Inc."),
                              tags$a(href="https://personalscience.com", "More details"),
                              textOutput("about_page"),
                              textOutput("currentDB")
                          )
                 )

)
)



