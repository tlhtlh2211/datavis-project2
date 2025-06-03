# Top tracks slide renderer
render_top_tracks_slide <- function() {
  if (!values$logged_in) {
    return(div("Please log in first"))
  }
  
  # Check if data is loaded, if not show message to configure preferences
  if (!values$data_loaded || is.null(values$top_tracks)) {
    return(div(style = "text-align: center; padding: 4rem;",
      div(style = "font-size: 3rem; margin-bottom: 1rem;", "🎵"),
      h3("Configure Your Analysis First", style = "color: #1DB954; margin-bottom: 1rem;"),
      p("Please go back to 'Your Musical Journey' and configure your preferences to load your top tracks.",
        style = "color: #D1D5DB; font-size: 1.1rem; max-width: 500px; margin: 0 auto;"),
      div(style = "margin-top: 2rem;",
        actionButton("back_to_config_track2", "← Back to Configuration", 
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
  
  div(style = "max-width: 900px; margin: 0 auto;",
    div(style = "text-align: center; margin-bottom: 3rem;",
      p("All your most played songs this year", style = "font-size: 1.5rem; color: #D1D5DB; font-family: 'Montserrat', sans-serif;")
    ),
    if (length(tracks) == 0) {
      div(style = "text-align: center; padding: 2rem;",
        div(style = "font-size: 2rem; margin-bottom: 1rem;", "🎵"),
        p("No tracks found. Try listening to more music on Spotify!", style = "color: #D1D5DB; font-size: 1.2rem; font-family: 'Montserrat', sans-serif;")
      )
    } else {
      lapply(seq_along(tracks), function(i) {
        track_item <- tracks[[i]]
        
        # Handle API response structure: tracks are wrapped in "track" field
        if (!is.null(track_item$track)) {
          track <- track_item$track
        } else {
          track <- track_item
        }
        
        # Extract track information
        track_name <- if (!is.null(track$name)) as.character(track$name[1]) else "Unknown Track"
        
        # Extract album image
        album_image_url <- "https://via.placeholder.com/80x80/1DB954/white?text=♪"
        if (!is.null(track$album) && !is.null(track$album$images) && length(track$album$images) > 0) {
          last_image <- track$album$images[[length(track$album$images)]]
          if (!is.null(last_image$url)) {
            album_image_url <- last_image$url
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
            artist_names <- artist_names[1:min(3, length(artist_names))]
            track_artists <- paste(artist_names, collapse = ", ")
            if (length(track$artists) > 3) {
              track_artists <- paste0(track_artists, "...")
            }
          }
        }
        
        # Handle popularity
        track_popularity <- 0
        if (!is.null(track$popularity) && is.numeric(track$popularity)) {
          track_popularity <- as.numeric(track$popularity[1])
          if (is.na(track_popularity)) track_popularity <- 0
        }
        
        div(class = "track-item", style = "padding: 1.5rem; margin-bottom: 1rem;",
          # Album image
          div(style = "width: 80px; height: 80px; border-radius: 12px; overflow: hidden; flex-shrink: 0;",
            img(src = album_image_url, 
                style = "width: 100%; height: 100%; object-fit: cover;",
                alt = "Album cover")
          ),
          # Rank badge
          div(class = "rank-badge", style = "width: 2.5rem; height: 2.5rem; font-size: 1.2rem; font-family: 'Montserrat', sans-serif; font-weight: bold;", i),
          # Track info
          div(style = "flex: 1; min-width: 0;",
            div(style = "font-weight: 600; font-size: 1.4rem; color: white; margin-bottom: 0.5rem; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; font-family: 'Montserrat', sans-serif;", 
                track_name),
            div(style = "color: #9CA3AF; font-size: 1.1rem; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; font-family: 'Montserrat', sans-serif;", 
                track_artists)
          ),
          # Popularity badge
          div(style = "background: rgba(29, 185, 84, 0.2); color: #10B981; padding: 0.5rem 1rem; border-radius: 1.5rem; font-size: 1rem; font-weight: 600; flex-shrink: 0; font-family: 'Montserrat', sans-serif;",
              paste0(track_popularity, "% popular"))
        )
      })
    }
  )
} 