#' Get the current schema / catalog of a database-related objects
#'
#' @name get_schema
#' @param .x The object from which to retrieve a schema
#' @return
#' For `get_schema.DBIConnection`, the current schema of the connection. See "Default schema" for more.
#'
#' For `get_schema.tbl_dbi` the schema as retrieved from the lazy_query.
#' If the lazy_query does not specify a schema, `NULL` is returned.
#' Note that lazy queries are sensitive to server-side changes and may therefore return entirely different tables
#' if changes are made server-side.
#'
#' @section Default schema:
#'
#' In some backends, it is possible to modify settings so that when a schema is not explicitly stated in a query,
#' the backend searches for the table in this schema by default.
#' For Postgres databases, this can be shown with `SELECT CURRENT_SCHEMA()` (defaults to `public`) and modified with
#' `SET search_path TO { schema }`.
#'
#' For SQLite databases, a `temp` schema for temporary tables always exists as well as a `main` schema for permanent
#' tables.
#' Additional databases may be attached to the connection with a named schema, but as the attachment must be made after
#' the connection is established, `get_schema` will never return any of these, as the default schema will always be
#' `main`.
#'
#' @examples
#' conn <- get_connection(drv = RSQLite::SQLite())
#'
#' dplyr::copy_to(conn, mtcars, name = "mtcars", temporary = FALSE)
#'
#' get_schema(conn)
#' get_schema(get_table(conn, id("mtcars", conn = conn)))
#'
#' close_connection(conn)
#' @export
get_schema <- function(.x) {
  UseMethod("get_schema")
}

#' @export
get_schema.tbl_dbi <- function(.x) {
  schema <- dbplyr::remote_table(.x) |>
    unclass() |>
    purrr::discard(is.na) |>
    purrr::pluck("schema")

  return(schema)
}

#' @export
get_schema.Id <- function(.x) {
  return(purrr::pluck(.x@name, "schema"))
}

#' @export
get_schema.PqConnection <- function(.x) {
  return(DBI::dbGetQuery(.x, "SELECT CURRENT_SCHEMA()")$current_schema)
}

#' @export
get_schema.SQLiteConnection <- function(.x) {
  return("main")
}

#' @export
`get_schema.Microsoft SQL Server` <- function(.x) {
  query <- paste("SELECT ISNULL((SELECT",
                 "COALESCE(default_schema_name, 'dbo') AS default_schema",
                 "FROM sys.database_principals",
                 "WHERE [name] = CURRENT_USER), 'dbo') default_schema")

  return(DBI::dbGetQuery(.x, query)$default_schema)
}

#' @export
get_schema.NULL <- function(.x) {
  return(NULL)
}
