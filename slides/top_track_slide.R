# Top 1 track slide renderer
render_top_1_track_slide <- function() {
  if (!values$logged_in) {
    return(div("Please log in first"))
  }
  
  # Check if data is loaded
  if (!values$data_loaded || is.null(values$top_tracks)) {
    return(div(style = "text-align: center; padding: 4rem;",
      div(style = "font-size: 3rem; margin-bottom: 1rem;", "🎵"),
      h3("Configure Your Analysis First", style = "color: #1DB954; margin-bottom: 1rem;"),
      p("Please go back to 'Your Musical Journey' and configure your preferences to load your top tracks.",
        style = "color: #D1D5DB; font-size: 1.1rem; max-width: 500px; margin: 0 auto;"),
      div(style = "margin-top: 2rem;",
        actionButton("back_to_config_track1", "← Back to Configuration", 
          style = "background: #1DB954; color: white; border: none; padding: 0.75rem 1.5rem; border-radius: 1rem; cursor: pointer;"
        )
      )
    ))
  }

  # Extract tracks data
  tracks <- list()
  if (!is.null(values$top_tracks$items)) {
    tracks <- values$top_tracks$items
  } else if (!is.null(values$top_tracks) && is.list(values$top_tracks)) {
    valid_tracks <- list()
    for (i in seq_along(values$top_tracks)) {
      item <- values$top_tracks[[i]]
      if (is.list(item) && !is.null(item$name) && !is.null(item$artists)) {
        valid_tracks[[length(valid_tracks) + 1]] <- item
      }
    }
    if (length(valid_tracks) > 0) {
      tracks <- valid_tracks
    } else if (!is.null(values$top_tracks$name)) {
      tracks <- list(values$top_tracks)
    }
  }

  if (length(tracks) == 0) {
    return(div(style = "text-align: center; padding: 4rem;",
      div(style = "font-size: 3rem; margin-bottom: 1rem;", "🎵"),
      p("No tracks found. Try listening to more music on Spotify!", style = "color: #D1D5DB; font-size: 1.2rem; font-family: 'Montserrat', sans-serif;")
    ))
  }

  # Extract first track data
  track_item <- tracks[[1]]
  
  # Handle API response structure
  if (!is.null(track_item$track)) {
    track <- track_item$track
  } else {
    track <- track_item
  }
  
  # Extract track information
  track_name <- if (!is.null(track$name)) as.character(track$name[1]) else "Unknown Track"
  
  # Extract album image
  album_image_url <- "https://via.placeholder.com/200x200/1DB954/white?text=♪"
  if (!is.null(track$album) && !is.null(track$album$images) && length(track$album$images) > 0) {
    first_image <- track$album$images[[1]]  # Get largest image
    if (!is.null(first_image$url)) {
      album_image_url <- first_image$url
    }
  }
  
  # Extract artists
  track_artists <- "Unknown Artist"
  if (!is.null(track$artists) && length(track$artists) > 0) {
    artist_names <- c()
    for (j in seq_along(track$artists)) {
      artist <- track$artists[[j]]
      if (is.character(artist)) {
        artist_names <- c(artist_names, as.character(artist))
      } else if (is.list(artist) && !is.null(artist$name)) {
        artist_names <- c(artist_names, as.character(artist$name))
      }
    }
    if (length(artist_names) > 0) {
      track_artists <- paste(artist_names, collapse = ", ")
    }
  }

  # Extract album name
  album_name <- "Unknown Album"
  if (!is.null(track$album) && !is.null(track$album$name)) {
    album_name <- as.character(track$album$name)
  }

  div(style = "max-width: 800px; margin: 0 auto; text-align: center; padding: 2rem;",
    # Header
    div(style = "margin-bottom: 3rem;",
      div(style = "font-size: 4rem; font-weight: bold; color: #1DB954; margin-bottom: 1rem; font-family: 'Montserrat', sans-serif;", "#1"),
      p("Your most played song this year", style = "font-size: 1.5rem; color: #D1D5DB; font-family: 'Montserrat', sans-serif;")
    ),
    
    # Main content card
    div(style = "background: linear-gradient(135deg, rgba(29, 185, 84, 0.1), rgba(16, 185, 129, 0.1)); padding: 3rem; border-radius: 2rem; border: 3px solid rgba(29, 185, 84, 0.3); box-shadow: 0 20px 40px rgba(29, 185, 84, 0.2);",
      # Album artwork
      div(style = "margin-bottom: 2rem;",
        img(src = album_image_url, 
            style = "width: 200px; height: 200px; border-radius: 1.5rem; box-shadow: 0 15px 30px rgba(0, 0, 0, 0.5);",
            alt = paste("Album cover for", track_name))
      ),
      
      # Track details
      div(style = "margin-bottom: 2rem;",
        div(style = "font-weight: bold; font-size: 2.5rem; color: white; margin-bottom: 1rem; font-family: 'Montserrat', sans-serif; line-height: 1.2;", track_name),
        div(style = "color: #D1D5DB; font-size: 1.8rem; margin-bottom: 0.5rem; font-family: 'Montserrat', sans-serif;", track_artists),
        div(style = "color: #9CA3AF; font-size: 1.3rem; font-family: 'Montserrat', sans-serif;", album_name)
      ),
      
      # Crown emoji
      div(style = "font-size: 3rem; margin-top: 1rem;", "👑")
    )
  )
} 