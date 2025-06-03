# Top 1 genre slide renderer
render_top_1_genre_slide <- function() {
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
        actionButton("back_to_config_genre1", "← Back to Configuration", 
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
    return(div(style = "text-align: center; padding: 4rem;",
      div(style = "font-size: 3rem; margin-bottom: 1rem;", "🎼"),
      p("No genre data available", style = "color: #D1D5DB; font-size: 1.2rem; font-family: 'Montserrat', sans-serif;")
    ))
  }

  # Sort genres by percentage to get the top one
  sorted_genres <- top_genres[order(unlist(top_genres), decreasing = TRUE)]
  top_genre_name <- names(sorted_genres)[1]
  top_genre_percentage <- as.numeric(sorted_genres[[1]])

  # Define genre emojis
  genre_emojis <- list(
    "pop" = "🎵",
    "rock" = "🎸",
    "hip hop" = "🎤",
    "electronic" = "🎹",
    "jazz" = "🎺",
    "classical" = "🎼",
    "country" = "🤠",
    "indie" = "🎨",
    "alternative" = "⚡",
    "r&b" = "💫",
    "soul" = "❤️",
    "funk" = "🕺",
    "reggae" = "🌴",
    "blues" = "💙",
    "folk" = "🌾",
    "metal" = "⚡",
    "punk" = "💥"
  )

  # Find appropriate emoji
  genre_emoji <- "🎵"  # default
  for (genre_key in names(genre_emojis)) {
    if (grepl(genre_key, tolower(top_genre_name))) {
      genre_emoji <- genre_emojis[[genre_key]]
      break
    }
  }

  div(style = "max-width: 800px; margin: 0 auto; text-align: center; padding: 2rem;",
    # Header
    div(style = "margin-bottom: 3rem;",
      div(style = "font-size: 4rem; font-weight: bold; color: #1DB954; margin-bottom: 1rem; font-family: 'Montserrat', sans-serif;", "#1"),
      p("Your most listened genre this year", style = "font-size: 1.5rem; color: #D1D5DB; font-family: 'Montserrat', sans-serif;")
    ),
    
    # Main content card
    div(style = "background: linear-gradient(135deg, rgba(29, 185, 84, 0.1), rgba(16, 185, 129, 0.1)); padding: 3rem; border-radius: 2rem; border: 3px solid rgba(29, 185, 84, 0.3); box-shadow: 0 20px 40px rgba(29, 185, 84, 0.2);",
      # Genre emoji
      div(style = "font-size: 6rem; margin-bottom: 2rem;", genre_emoji),
      
      # Genre details
      div(style = "margin-bottom: 2rem;",
        div(style = "font-weight: bold; font-size: 2.5rem; color: white; margin-bottom: 1rem; font-family: 'Montserrat', sans-serif; line-height: 1.2; text-transform: capitalize;", top_genre_name),
        div(style = "color: #1DB954; font-size: 2rem; font-weight: 600; margin-bottom: 1rem; font-family: 'Montserrat', sans-serif;", paste0(round(top_genre_percentage, 1), "%")),
        div(style = "color: #D1D5DB; font-size: 1.3rem; font-family: 'Montserrat', sans-serif;", "of your music")
      ),
      
      # Crown emoji
      div(style = "font-size: 3rem; margin-top: 1rem;", "👑")
    )
  )
} 