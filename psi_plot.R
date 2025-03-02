# Plot glucose

# library(showtext)
# font_add_google("Montserrat")
# showtext_auto()

#library(ggplot2)
#' Stylized theme for consistent plot style
#' @import ggplot2
#' @export
# psi_theme <-   theme(text = element_text(# family = "Montserrat",
#                                          face = "bold", size = 15),
#                      axis.text.x = element_text(size = 15, angle = 90, hjust = 1),
#                      legend.title = element_blank())
#


#' @title Plot a glucose dataframe
#' @description Plot of a valid CGM file.
#' @param glucose_raw dataframe of a valid CGM data stream
#' @param title string to display on ggplot
#' @import ggplot2
#' @export
#' @return ggplot object
plot_glucose <- function(glucose_raw, title = "Name") {

  g_df <- glucose_raw %>% filter(!is.na(value)) # remove NA values (usually because they're from a strip)

  earliest <- min(g_df[["time"]])
  latest <- max(g_df[["time"]])

  lowest <- min(g_df[["value"]])
  highest <- max(g_df[["value"]])

  auc = auc_calc(g_df,as.numeric(difftime(latest,earliest,units="mins")))
  g = ggplot(data = g_df, aes(x=time, y = value) )
  g +
    psi_theme +
    geom_line(color = "red")  +
    labs(title = title, x = "", y = "mg/mL",
         subtitle = paste0("Continuous glucose monitoring",
                          sprintf("(AUC = %.2f)",auc)
                          )) +
    scaled_axis(g_df) +
    #scale_x_datetime(date_breaks = "1 day", date_labels = "%a %b-%d") +
    coord_cartesian(ylim = c(lowest, highest))
}

#' Adjust x axis depending on time scale of glucose data frame
#' @param glucose_raw dataframe of a valid Libreview glucose table
#' @return scale_x_datetime object, to be added to glucose plot
scaled_axis <- function(glucose_raw) {
  time_length <- max(glucose_raw$time) - min(glucose_raw$time)
  if (as.numeric(time_length, units = "days") > 1)
    return(scale_x_datetime(date_breaks = "1 day", date_labels = "%a %b-%d", timezone = Sys.timezone()) )
  else return(scale_x_datetime(date_breaks = "15 min", date_labels = "%b-%d %H:%M", timezone = Sys.timezone()))
}

#' @title plot differences in glucose response to a particular food
#' @description
#' Given a dataframe of food times, returns a ggplot object
#' representing the plot of all different food times along a constant time period
#' @param food_times a dataframe of food times, preferably generated by `food_times_df()`
#' @param foodname character string matching the food of interest
#' @return ggplot object
#' @export
plot_food_compare <- function(food_times = food_times_df(foodname = "watermelon"),
                              foodname = "watermelon") {

  food_times %>% ggplot(aes(t,value, color = meal)) + geom_line(size = 2) +
    psi_theme +
    labs(title = paste0("Glucose Response to ",stringr::str_to_title(foodname)),
         subtitle = "",
         x = "Minutes",
         y = "mg/mL")


}

#' @title Generate a ggplot2 overlay for notes dataframe
#' @description
#' When following a `plot_glucose()` call to generate a ggplot object, this returns a
#' ggplot object to draw the correct information from the notes dataframe
#' @import ggplot2
#' @param g a ggplot graphic object
#' @param notes_df a valid notes dataframe
#' @return ggplot object
plot_notes_overlay <- function(g, notes_df) {

  f = geom_vline(xintercept = notes_df %>%
                   dplyr::filter(.data$Activity == "Food") %>% select("Start") %>%
                   unlist(), color = "yellow")

  fc =   geom_text(data = notes_df %>%
                     dplyr::filter(.data$Activity == "Food") %>% select("Start",
                                                                        "Comment"), aes(x = Start, y = 50, angle = 90, hjust = FALSE,
                                                                                        label = Comment), size = 6)


  s <- geom_rect(data = notes_df %>%
              dplyr::filter(.data$Activity == "Sleep") %>%
              select(xmin = .data$Start,
                     xmax = End) %>%
              cbind(ymin = -Inf, ymax = Inf),
            aes(xmin = xmin, xmax = xmax, ymin = ymin, ymax = ymax), fill = "red",
            alpha = 0.2, inherit.aes = FALSE)

  return(g + s + f + fc)



}
