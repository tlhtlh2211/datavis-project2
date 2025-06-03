# Popularity slide renderer
render_popularity_slide <- function() {
  if (!values$logged_in) {
    return(div("Please log in first"))
  }
  
  # Check if data is loaded
  if (!values$data_loaded || is.null(values$popularity_data)) {
    return(div(style = "text-align: center; padding: 4rem;",
      div(style = "font-size: 3rem; margin-bottom: 1rem;", "📊"),
      h3("Configure Your Analysis First", style = "color: #1DB954; margin-bottom: 1rem;"),
      p("Please go back to 'Your Musical Journey' and configure your preferences to analyze your music taste.",
        style = "color: #D1D5DB; font-size: 1.1rem; max-width: 500px; margin: 0 auto;"),
      div(style = "margin-top: 2rem;",
        actionButton("back_to_config3", "← Back to Configuration", 
          style = "background: #1DB954; color: white; border: none; padding: 0.75rem 1.5rem; border-radius: 1rem; cursor: pointer;"
        )
      )
    ))
  }
  
  # Use API data for popularity analysis
  avg_popularity <- 50
  min_popularity <- 0
  max_popularity <- 100
  tracks_analyzed <- 0
  popularity_message <- "You have a balanced taste between popular and unique tracks."
  
  if (!is.null(values$popularity_data)) {
    # Extract data from API response
    if (!is.null(values$popularity_data$average_popularity)) {
      avg_popularity <- as.numeric(values$popularity_data$average_popularity)
    }
    if (!is.null(values$popularity_data$min_popularity)) {
      min_popularity <- as.numeric(values$popularity_data$min_popularity)
    }
    if (!is.null(values$popularity_data$max_popularity)) {
      max_popularity <- as.numeric(values$popularity_data$max_popularity)
    }
    if (!is.null(values$popularity_data$tracks_analyzed)) {
      tracks_analyzed <- as.numeric(values$popularity_data$tracks_analyzed)
    }
    if (!is.null(values$popularity_data$message)) {
      popularity_message <- values$popularity_data$message
    }
  }
  
  div(style = "text-align: center; max-width: 600px; margin: 0 auto;",
    div(style = "margin-bottom: 3rem;",
      p("How mainstream is your music taste?", style = "font-size: 1.25rem; color: #D1D5DB; margin-bottom: 2rem;"),
      div(class = "percentage-circle",
        div(class = "percentage-text", paste0(round(avg_popularity, 1), "%"))
      ),
      p(popularity_message,
        style = "font-size: 1.125rem; color: white; line-height: 1.6;")
    ),
    div(class = "stat-grid",
      div(class = "stat-card",
        div(class = "stat-value", paste0(min_popularity, "%")),
        div(class = "stat-label", "Least Popular")
      ),
      div(class = "stat-card",
        div(class = "stat-value", tracks_analyzed),
        div(class = "stat-label", "Tracks Analyzed")
      ),
      div(class = "stat-card",
        div(class = "stat-value", paste0(max_popularity, "%")),
        div(class = "stat-label", "Most Popular")
      )
    )
  )
} 