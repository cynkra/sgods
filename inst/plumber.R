library(plumber)
library(readr)
library(openxlsx)
library(jsonlite)
library(arrow)

#* @apiTitle Data API PoC

# Define the data to be returned
get_data <- function() {
  mtcars
}

#* Return data in JSON format
#* @get /data/json
function(req, res) {
  data <- get_data()
  res$body <- data |> toJSON(auto_unbox = TRUE)
  res$setHeader("Content-Type", "application/json")
  res
}

#* Return data in CSV format
#* @get /data/csv
function(req, res) {
  data <- get_data()
  temp_file <- tempfile(fileext = ".csv")
  data |> write_csv(temp_file, col_names = TRUE)
  csv_content <- readBin(temp_file, "raw", n = file.info(temp_file)$size)
  res$body <- csv_content
  res$setHeader("Content-Type", "text/csv")
  res
}

#* Return data in Excel format
#* @get /data/excel
function(req, res) {
  data <- get_data()
  temp_file <- tempfile(fileext = ".xlsx")
  data |> write.xlsx(temp_file)
  excel_content <- readBin(temp_file, "raw", n = file.info(temp_file)$size)
  res$body <- excel_content
  res$setHeader("Content-Type", "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet")
  res
}

#* Return data in Parquet format
#* @get /data/parquet
function(req, res) {
  data <- get_data()
  temp_file <- tempfile(fileext = ".parquet")
  data |> write_parquet(temp_file)
  parquet_content <- readBin(temp_file, "raw", n = file.info(temp_file)$size)
  res$body <- parquet_content
  res$setHeader("Content-Type", "application/octet-stream")
  res
}
