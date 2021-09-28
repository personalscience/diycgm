

#' @title List all products consumed by `user_id`
#' @param user_id vector of user IDs or NULL to show all users
#' @return character vector of product names sorted alphabetically
#' @export
food_list_db <- function(user_id = 1234  ) {
  conn_args <- config::get("dataconnection")
  con <- DBI::dbConnect(
    drv = conn_args$driver,
    user = conn_args$user,
    host = conn_args$host,
    port = conn_args$port,
    dbname = conn_args$dbname,
    password = conn_args$password
  )

  ID <- user_id

  if (is.null(ID)) {
    prods <- tbl(con, "notes_records") %>% filter(Activity == "Food") %>%
      filter(Start > "2021-06-01") %>%
      group_by(Comment) %>% add_count() %>% filter(n > 2) %>% distinct(Comment) %>%
      transmute(productName = Comment, user_id = user_id) %>%
      collect() %>% arrange(productName)
  } else
    prods <-
    tbl(con, "notes_records") %>% filter(Activity == "Food") %>%
    filter(Start > "2021-06-01") %>% filter(user_id %in% ID) %>% distinct(Comment) %>%
    collect() %>% pull(Comment)

  if(length(prods) > 0)
    return(sort(prods))
  else return(NULL)

  DBI::dbDisconnect(con)
  return(prods)
}

# psi User Management Functions

#' @title All user records in the database
#' @param conn_args database connection
#' @return dataframe of all user records
#' @export
user_df_from_db <- function(conn_args = config::get("dataconnection")){
  con <- DBI::dbConnect(
    drv = conn_args$driver,
    user = conn_args$user,
    host = conn_args$host,
    port = conn_args$port,
    dbname = conn_args$dbname,
    password = conn_args$password
  )

  users_df <- tbl(con, "user_list" ) %>% collect()

  DBI::dbDisconnect(con)
  return(users_df)

}
