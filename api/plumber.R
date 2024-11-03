library(plumber)
library(readr)
library(openxlsx)
library(jsonlite)
library(arrow)

#* @apiTitle Data API PoC

#* @filter cors
cors <- function(req, res) {
  res$setHeader("Access-Control-Allow-Origin", "*")
  res$setHeader("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
  res$setHeader("Access-Control-Allow-Headers", "Content-Type, Authorization")
  if (req$REQUEST_METHOD == "OPTIONS") {
    res$status <- 200
    return(list())
  } else {
    plumber::forward()
  }
}

# Update the get_data function to accept a dataset parameter
get_data <- function(dataset) {
  switch(
    dataset,
    "mtcars" = mtcars,
    "iris" = iris,
    "cars" = cars,
    stop("Dataset not found")
  )
}

#* Return data in specified format
#* @param dataset The name of the dataset (mtcars, iris, cars)
#* @param format The format to return (json, csv, excel, parquet)
#* @get /data
function(req, res, dataset = "mtcars", format = "json") {
  # Try to get the data; handle errors if dataset is not found
  data <- tryCatch(
    get_data(dataset),
    error = function(e) {
      res$status <- 400
      res$body <- list(error = e$message) |> toJSON(auto_unbox = TRUE)
      res$setHeader("Content-Type", "application/json")
      return(res)
    }
  )

  # Check if an error response was already set
  if (!is.null(res$body)) {
    return(res)
  }

  # Prepare the data according to the requested format
  if (format == "json") {
    res$body <- data |> toJSON(auto_unbox = TRUE)
    res$setHeader("Content-Type", "application/json")
  } else if (format == "csv") {
    temp_file <- tempfile(fileext = ".csv")
    data |> write_csv(temp_file, col_names = TRUE)
    res$body <- readBin(temp_file, "raw", n = file.info(temp_file)$size)
    res$setHeader("Content-Type", "text/csv")
  } else if (format == "excel") {
    temp_file <- tempfile(fileext = ".xlsx")
    data |> write.xlsx(temp_file)
    res$body <- readBin(temp_file, "raw", n = file.info(temp_file)$size)
    res$setHeader("Content-Type", "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet")
  } else if (format == "parquet") {
    temp_file <- tempfile(fileext = ".parquet")
    data |> write_parquet(temp_file)
    res$body <- readBin(temp_file, "raw", n = file.info(temp_file)$size)
    res$setHeader("Content-Type", "application/octet-stream")
  } else {
    res$status <- 400
    res$body <- list(error = "Invalid format") |> toJSON(auto_unbox = TRUE)
    res$setHeader("Content-Type", "application/json")
  }
  res
}
