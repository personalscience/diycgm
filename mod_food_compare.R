#' food_compare UI Function
#'
#' @description A shiny Module.
#'
#' @param id,input,output,session Internal parameters for {shiny}.
#'
#' @noRd
#'
#' @importFrom shiny NS tagList
mod_food_compare_ui <- function(id){
  ns <- NS(id)
  tagList(
    sidebarLayout(
      sidebarPanel(
        selectInput(
          ns("food_name"),
          label = "Select Food",
          choices = food_list_db(user_id = c(1001:1004,1007:1021)),
          selected = "Clif Bar Chocolate"
        ),
        checkboxInput(ns("normalize"), label = "Normalize"),
        checkboxInput(ns("smooth"), label = "Smooth"),
        checkboxInput(ns("combine"), label = "Show Average"),
        actionButton(ns("show_raw"), label = "Show Data and Stats"),
        downloadButton(ns("downloadFood_df"), label = "Download Results"),
        hr(),
        checkboxGroupInput(ns("meal_items"),label = "Meal", choices = NULL),
        hr()
      ),
      mainPanel(plotOutput(ns("main_plot")),
                h3("Statistics"),
                wellPanel(dataTableOutput(ns("auc_table"))),
                hr(),
                h3("Raw Data"),
                dataTableOutput(ns("raw_data_table"))
      ))
  )
}

#' food_compare Server Functions
#'
#' @noRd
#' @import dplyr
#' @import ggplot2
#' @importFrom magrittr %>%
#' @importFrom stats sd
mod_food_compare_server <- function(id){
  moduleServer( id, function(input, output, session){
    ns <- session$ns
    conn_args <-  config::get("dataconnection")
    con <- DBI::dbConnect(
      drv = conn_args$driver,
      user = conn_args$user,
      host = conn_args$host,
      port = conn_args$port,
      dbname = conn_args$dbname,
      password = conn_args$password)

    GLUCOSE_RECORDS<- tbl(con,"glucose_records") %>% collect()
    NOTES_RECORDS <- tbl(con, "notes_records") %>% collect()
    psi_theme <-   theme(text = element_text(# family = "Montserrat",
      face = "bold", size = 15),
      axis.text.x = element_text(size = 15, angle = 90, hjust = 1),
      legend.title = element_blank())


    # food_df ----
    food_df <- reactive({
      validate(
        need(input$food_name, "No food selected")
      )

      one_food_df <-  cgmr::food_times_df_fast(
        glucose_df = GLUCOSE_RECORDS,
        notes_df = NOTES_RECORDS,
        user_id = NULL,
        timeLength = 150,
        prefixLength = 30,
        foodname = input$food_name
      )

      validate(
        need(!is.null(one_food_df), sprintf("No glucose results for food %s", input$food_name1))
      )

   df <-  if(input$normalize) {
      message(sprintf("normalizing...\n"))
      one_food_df %>% cgmr::normalize_value()
    } else one_food_df

    return(cgmr::combined_food_times_df(df))
    }
    )





    # meals_all ----
    # reactive returns a character vector of all meals with this type of food
    meals_all <- reactive({
      one_food_df <- food_df()
      validate(
        need(!is.null(one_food_df), sprintf("No glucose results for food %s", input$food_name1))
      )
      one_food_df %>% distinct(meal) %>% pull(meal)}
    )

    # output$main_plot  ----
    output$main_plot <- renderPlot({

      validate(
        need(input$food_name, "Waiting on database..."),
        need(!is.null(food_df()), "Problem with food times")
      )
      observe(
        {cat(file = stderr(), sprintf("render plot for food=%s \n",
                                      isolate(input$food_name)))
          message(sprintf("currently selected choices:\n%s", paste(isolate(input$meal_items),
                                                                   collapse="\n")))}
      )

      food_df <-  food_df() #if(input$normalize) {food_df() %>% cgmr::normalize_value()}
      #else food_df()

      food_df_ave <- if(input$combine) {message(sprintf("combining...\n"))}

      foods_to_show <- food_df %>%
        filter(meal %in% input$meal_items)

      validate(
        need(nrow(foods_to_show)>0, "Please select a meal")
      )

      g <- if(input$combine){
        foods_to_show %>% cgmr::combined_food_times_df() %>%
        ggplot() +
          geom_line(aes(x=t,y=value, color = date_ch), size = 1) +
          geom_smooth(inherit.aes= FALSE,
                      aes(x=t,y=ave),
                      method = "loess",
                      size = 4)

      } else {

        foods_to_show %>%
        #filter(meal %in% input$meal_items) %>%
        ggplot(aes(x=t,y=value,color=date_ch))  +
        if(input$smooth) geom_smooth(method = "loess", aes(fill=date_ch)) else geom_line(size=2)
      }

      g +
        psi_theme +
        annotate(geom="rect",  # draw a light box around the portion of the graph during "expected experiment time"
                 xmin=0,
                 xmax=120, # we typical measure two hours out
                 ymin=-Inf,
                 ymax=Inf,
                  color = "lightgrey",
                  alpha=0.2) +
        labs(title = "Glucose Response", subtitle = stringr::str_to_title(isolate(input$food_name)),
             x = "minutes", y = "")

    })

    # input$foodname ----
    observeEvent(input$food_name,{
      validate(
        need(input$food_name, "Waiting on database..."),
        need(!is.null(food_df()), "Problem with food times")
      )
      updateCheckboxGroupInput(inputId = "meal_items",
                               label = "Select Meals",
                               choices = meals_all())
    })

    # output$raw_data_table ----
    output$raw_data_table <- renderDataTable({

      validate(
        need(input$show_raw, "Press Show Data and Stats")
      )
      food_df() %>% mutate(timestamp = lubridate::with_tz(timestamp, tzone = "America/Los_Angeles"))

    })

    output$downloadFood_df <-
      downloadHandler(
        filename = function() {
          sprintf("Food_data-%s-%s.csv", input$food_name, Sys.Date())
        },
        content = function(file) {
          readr::write_csv(food_df(), file)
        })

    # output$auc_table ----
    output$auc_table <- renderDataTable({
      validate(
        need(input$show_raw, "Press Show Data and Stats")
      )

      food_df() %>% distinct() %>%
        filter(t >= -5) %>% # only look at the times after the food was eaten.
        filter(t <= 120) %>% # and only the first 2 hours.
        group_by(meal) %>% arrange(t) %>%
        summarize( iAUC = cgmr::auc_calc(tibble(time=t,value=value)),
                   auc_total = DescTools::AUC(t,value-first(value)),

                   min = min(value),
                   max = max(value),
                   sd = sd(value),
                   rise = last(value) - first(value),
                   .groups = 'drop') %>%
        #summarize(auc = sum((lag(value)-value)*(t-lag(t)), na.rm = TRUE)) %>%
        arrange(iAUC)

    })

  })
}

## To be copied in the UI
# mod_food_compare_ui("food_compare_ui_1")

## To be copied in the server
# mod_food_compare_server("food_compare_ui_1")

#' @description Demo for mod_food_compare
#' @noRd
#'
demo_food <- function() {
  ui <- fluidPage(mod_food_compare_ui("x"))
  sample_glucose <- cgmr::glucose_df_from_libreview_csv()
  server <- function(input, output, session) {
    mod_food_compare_server("x")

  }
  shinyApp(ui, server)
}


