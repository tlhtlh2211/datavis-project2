# Genres slide renderer
render_genres_slide <- function() {
  if (!values$logged_in) {
    return(div("Please log in first"))
  }
  
  # Check if data is loaded
  if (!values$data_loaded || is.null(values$genre_data)) {
    return(div(style = "text-align: center; padding: 4rem;",
      div(style = "font-size: 3rem; margin-bottom: 1rem;", "🎼"),
      h3("Configure Your Analysis First", style = "color: #1DB954; margin-bottom: 1rem;"),
      p("Please go back to 'Your Musical Journey' and configure your preferences to analyze your genres.",
        style = "color: #D1D5DB; font-size: 1.1rem; max-width: 500px; margin: 0 auto;"),
      div(style = "margin-top: 2rem;",
        actionButton("back_to_config4", "← Back to Configuration", 
          style = "background: #1DB954; color: white; border: none; padding: 0.75rem 1.5rem; border-radius: 1rem; cursor: pointer;"
        )
      )
    ))
  }
  
  # Use API data for genre analysis
  top_genres <- list()
  if (!is.null(values$genre_data) && !is.null(values$genre_data$percentages)) {
    top_genres <- values$genre_data$percentages
  }
  
  if (length(top_genres) == 0) {
    return(div(style = "max-width: 1000px; margin: 0 auto; text-align: center;",
      div(style = "margin-bottom: 3rem;",
        div(style = "font-size: 2rem; margin-bottom: 1rem;", "🎼"),
        p("No genre data available", style = "font-size: 1.25rem; color: #D1D5DB;"),
        p("Your artists don't have genre information in our database", style = "color: #9CA3AF;")
      )
    ))
  }
  
  colors <- c("#1DB954", "#1ed760", "#1fdf64", "#84fab0", "#8fd3f4", "#74b9ff", "#a29bfe", "#fd79a8")
  
  # Sort genres by percentage (descending) to show top genres first
  sorted_genres <- top_genres[order(unlist(top_genres), decreasing = TRUE)]
  
  div(style = "max-width: 900px; margin: 0 auto;",
    div(style = "text-align: center; margin-bottom: 3rem;",
      p("All the genres that defined your year", style = "font-size: 1.5rem; color: #D1D5DB; font-family: 'Montserrat', sans-serif;")
    ),
    
    lapply(seq_along(sorted_genres[1:min(8, length(sorted_genres))]), function(i) {
      genre_name <- names(sorted_genres)[i]
      genre_percentage <- as.numeric(sorted_genres[[i]])
      color <- colors[((i-1) %% length(colors)) + 1]
      
      div(class = "genre-bar", style = "margin-bottom: 1rem;",
        div(class = "genre-color", style = paste0("background-color: ", color, "; width: 8px; height: 8px; border-radius: 50%; margin-right: 1rem;")),
        div(class = "genre-name", style = "font-size: 1.3rem; font-family: 'Montserrat', sans-serif; color: white;", genre_name),
        div(class = "genre-percentage", style = "font-size: 1.3rem; font-family: 'Montserrat', sans-serif; color: #1DB954;", paste0(round(genre_percentage, 1), "%"))
      )
    })
  )
} 