library(shiny)
library(httr)
library(jsonlite)

ui <- fluidPage(
  titlePanel("Data Explorer"),
  sidebarLayout(
    sidebarPanel(
      selectInput(
        inputId = "dataset",
        label = "Select Dataset:",
        choices = c("mtcars", "iris", "cars"),
        selected = "mtcars"
      ),
      selectInput(
        inputId = "format",
        label = "Select Format:",
        choices = c("json", "csv", "excel", "parquet"),
        selected = "json"
      ),
      downloadButton(
        outputId = "download_data",
        label = "Download Data"
      )
    ),
    mainPanel(
      tableOutput("data_preview")
    )
  )
)

handle_error <- function(msg = "Failed to fetch data.") {
  if (shiny::isRunning()) {
    showNotification(msg, type = "error")
  } else {
    stop(msg)
  }
}

get_data <- function(dataset = "iris", format = "csv") {
  url <- paste0(
    "https://connect.cynkra.com/sgods-api/data?dataset=",
    dataset,
    "&format=",
    format
  )
  res <- GET(url)
  if (status_code(res) != 200) {
    handle_error("Failed to fetch data.")
  }
  res
}
get_data_preview <- function(dataset = "iris") {
  get_data(dataset, format = "csv") |>
    content(as = "text", encoding = "UTF-8") |>
    read.csv(text = _, stringsAsFactors = FALSE)
}
server <- function(input, output, session) {
  data_reactive <- reactive({
    req(input$dataset)
    data <- get_data_preview(input$dataset)
    if (is.null(data)) {
      handle_error("Failed to fetch data.")
    }
    data
  })

  output$data_preview <- renderTable({
    data_reactive()
  })

  output$download_data <- downloadHandler(
    filename = function() {
      paste0(
        input$dataset,
        ".",
        switch(input$format,
          json = "json",
          csv = "csv",
          excel = "xlsx",
          parquet = "parquet",
          "dat"
        )
      )
    },
    content = function(file) {
      req(input$dataset)
      req(input$format)
      res <- get_data(input$dataset, input$format)
      if (status_code(res) == 200) {
        writeBin(content(res, "raw"), file)
      } else {
        showNotification("Failed to download data.", type = "error")
      }
    }
  )
}

shinyApp(ui = ui, server = server)