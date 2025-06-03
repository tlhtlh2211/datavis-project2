#
# This is the server logic of a Shiny web application. You can run the
# application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
#
#    https://shiny.posit.co/
#

library(shiny)
library(jsonlite)
library(bslib)
library(scales)
library(tm)
library(stringr)
library(ggplot2)
library(httr)
library(plotly)

# Define null-coalescing operator
`%||%` <- function(x, y) if (is.null(x)) y else x

# Define server logic for Spotify Wrapped application
function(input, output, session) {
  
  # Reactive values to store API data
  values <- reactiveValues(
    username = NULL,
    filename = NULL,
    current_user = NULL,
    recently_played = NULL,
    top_artists = NULL,
    top_tracks = NULL,
    saved_tracks = NULL,
    mood_data = NULL,
    popularity_data = NULL,
    genre_data = NULL,
    personality_data = NULL,
    logged_in = FALSE,
    current_slide = 1,
    total_slides = 9,
    # User preferences for data fetching
    user_prefs = list(
      top_artists_count = 5,
      top_tracks_count = 5,
      time_range = "medium_term"
    ),
    data_loaded = FALSE
  )
  
  # Source all slide files within server scope so they have access to values
  source("slides/login_slide.R", local = TRUE)
  source("slides/welcome_slide.R", local = TRUE)
  source("slides/top_track_slide.R", local = TRUE)
  source("slides/top_tracks_slide.R", local = TRUE)
  source("slides/top_artist_slide.R", local = TRUE)
  source("slides/top_artists_slide.R", local = TRUE)
  source("slides/popularity_slide.R", local = TRUE)
  source("slides/top_1_genre_slide.R", local = TRUE)
  source("slides/genres_slide.R", local = TRUE)
  source("slides/moods_slide.R", local = TRUE)
  source("slides/personality_slide.R", local = TRUE)
  source("slides/personality_details_slide.R", local = TRUE)
  source("slides/thank_you_slide.R", local = TRUE)
  
  # Define slides (removed wordcloud)
  slides <- list(
    list(id = "login", title = "Welcome to Your 2024 Spotify Wrap"),
    list(id = "welcome", title = "Your Musical Journey"),
    list(id = "top-1-track", title = "Your #1 Song"),
    list(id = "top-tracks", title = "Your Top Tracks"),
    list(id = "top-1-artist", title = "Your #1 Artist"),
    list(id = "top-artists", title = "Your Top Artists"),
    list(id = "popularity", title = "Your Music Taste"),
    list(id = "top-1-genre", title = "Your #1 Genre"),
    list(id = "genres", title = "Your Genre Universe"),
    list(id = "moods", title = "Your Musical Moods"),
    list(id = "personality", title = "Your Musical Personality"),
    list(id = "personality-details", title = "Personality Deep Dive"),
    list(id = "thank-you", title = "That's Your 2024 Wrap!")
  )
  
  # Available datasets for selection
  available_datasets <- list(
    list(
      username = "m36i6tkbyxen3w6euott3ufhi", 
      filename = "m36i6tkbyxen3w6euott3ufhi_spotify.json",
      display_name = "User Dataset 1 (Bò)",
      description = "K-pop, hyperpop, art pop enthusiast"
    ),
    list(
      username = "bnloh6i0ho8vorne47adabziz", 
      filename = "bnloh6i0ho8vorne47adabziz_spotify.json",
      display_name = "User Dataset 2",
      description = "Alternative music taste profile"
    )
  )
  
  # Update total slides when logged in
  observe({
    if (values$logged_in) {
      values$total_slides <- length(slides)  # Include all slides including thank you
      if (values$current_slide == 1) {
        values$current_slide <- 2  # Skip to welcome slide
      }
    } else {
      values$total_slides <- 1
      values$current_slide <- 1
    }
  })
  
  # Function to call login API and get user credentials
  callLoginAPI <- function() {
    tryCatch({
      response <- GET("http://127.0.0.1:5000/login")
      
      if (status_code(response) == 200) {
        raw_content <- content(response, "text", encoding = "UTF-8")
        api_response <- fromJSON(raw_content, simplifyVector = FALSE)
        
        if ("json_file" %in% names(api_response) && "username" %in% names(api_response)) {
          values$username <- api_response$username
          values$filename <- api_response$json_file
          values$logged_in <- TRUE
          
          fetchUserProfile()
          showNotification("Successfully logged in to Spotify!", type = "message")
        } else {
          showNotification("Login failed - unexpected response format", type = "error")
        }
      } else {
        showNotification(paste("Login failed - status code:", status_code(response)), type = "error")
      }
    }, error = function(e) {
      showNotification(paste("Error logging in:", e$message), type = "error")
      cat("Error in callLoginAPI:", e$message, "\n")
    })
  }
  
  # Function to fetch user profile
  fetchUserProfile <- function() {
    if (is.null(values$username) || is.null(values$filename)) return()
    
    tryCatch({
      url <- paste0("http://127.0.0.1:5000/user/profile?username=",
                   values$username, "&filename=", values$filename)
      response <- GET(url)
      
      if (status_code(response) == 200) {
        values$current_user <- fromJSON(content(response, "text", encoding = "UTF-8"), simplifyVector = FALSE)
        cat("User profile fetched from API\n")
      }
    }, error = function(e) {
      cat("Error fetching user profile:", e$message, "\n")
    })
  }
  
  # Function to fetch top artists
  fetchTopArtists <- function(time_range = "medium_term", limit = 50) {
    if (is.null(values$username) || is.null(values$filename)) return()
    
    tryCatch({
      url <- paste0("http://127.0.0.1:5000/user/top_artists?username=",
                   values$username, "&filename=", values$filename, 
                   "&time_range=", time_range, "&limit=", limit)
      response <- GET(url)
      
      if (status_code(response) == 200) {
        raw_content <- content(response, "text", encoding = "UTF-8")
        values$top_artists <- fromJSON(raw_content, simplifyVector = FALSE)
      }
    }, error = function(e) {
      cat("Error fetching top artists:", e$message, "\n")
    })
  }
  
  # Function to fetch top tracks
  fetchTopTracks <- function(time_range = "medium_term", limit = 50) {
    if (is.null(values$username) || is.null(values$filename)) return()
    
    tryCatch({
      url <- paste0("http://127.0.0.1:5000/user/top_tracks?username=",
                   values$username, "&filename=", values$filename, 
                   "&time_range=", time_range, "&limit=", limit)
      response <- GET(url)
      
      if (status_code(response) == 200) {
        raw_content <- content(response, "text", encoding = "UTF-8")
        values$top_tracks <- fromJSON(raw_content, simplifyVector = FALSE)
      }
    }, error = function(e) {
      cat("Error fetching top tracks:", e$message, "\n")
    })
  }
  
  # Function to fetch mood distribution
  fetchMoodDistribution <- function() {
    if (is.null(values$username) || is.null(values$filename)) return()
    
    tryCatch({
      url <- paste0("http://127.0.0.1:5000/analysis/mood_distribution?username=",
                   values$username, "&filename=", values$filename)
      response <- GET(url)
      
      if (status_code(response) == 200) {
        raw_content <- content(response, "text", encoding = "UTF-8")
        values$mood_data <- fromJSON(raw_content, simplifyVector = FALSE)
      }
    }, error = function(e) {
      cat("Error fetching mood distribution:", e$message, "\n")
    })
  }
  
  # Function to fetch popularity score
  fetchPopularityScore <- function(time_range = "medium_term") {
    if (is.null(values$username) || is.null(values$filename)) return()
    
    tryCatch({
      url <- paste0("http://127.0.0.1:5000/analysis/popularity_score?username=",
                   values$username, "&filename=", values$filename,
                   "&time_range=", time_range)
      response <- GET(url)
      
      if (status_code(response) == 200) {
        values$popularity_data <- fromJSON(content(response, "text", encoding = "UTF-8"), simplifyVector = FALSE)
      }
    }, error = function(e) {
      cat("Error fetching popularity score:", e$message, "\n")
    })
  }
  
  # Function to fetch genre distribution
  fetchGenreDistribution <- function(time_range = "medium_term", top_n = 10) {
    if (is.null(values$username) || is.null(values$filename)) return()
    
    tryCatch({
      url <- paste0("http://127.0.0.1:5000/analysis/genre_distribution?username=",
                   values$username, "&filename=", values$filename,
                   "&time_range=", time_range, "&top_n=", top_n)
      response <- GET(url)
      
      if (status_code(response) == 200) {
        values$genre_data <- fromJSON(content(response, "text", encoding = "UTF-8"), simplifyVector = FALSE)
      }
    }, error = function(e) {
      cat("Error fetching genre distribution:", e$message, "\n")
    })
  }
  
  # Function to fetch personality prediction
  fetchPersonalityPrediction <- function(time_range = "medium_term") {
    if (is.null(values$username) || is.null(values$filename)) return()
    
    tryCatch({
      url <- paste0("http://127.0.0.1:5000/analysis/personality_prediction?username=",
                   values$username, "&filename=", values$filename,
                   "&time_range=", time_range)
      response <- GET(url)
      
      if (status_code(response) == 200) {
        raw_content <- content(response, "text", encoding = "UTF-8")
        values$personality_data <- fromJSON(raw_content, simplifyVector = FALSE)
      }
    }, error = function(e) {
      cat("Error fetching personality prediction:", e$message, "\n")
    })
  }
  
  # Function to load dataset from existing file
  loadDatasetFromFile <- function(username, filename) {
    tryCatch({
      values$logged_in <- TRUE
      values$username <- username
      values$filename <- filename
      
      json_file_path <- paste0("api/data/", filename)
      
      if (file.exists(json_file_path)) {
        spotify_data <- fromJSON(json_file_path, simplifyVector = FALSE)
        
        for (item in spotify_data) {
          if (item$step == "current_user") {
            values$current_user <- item$data
            break
          }
        }
        
        showNotification(paste("Successfully loaded dataset:", filename), type = "message")
      } else {
        showNotification("Dataset file not found!", type = "error")
      }
    }, error = function(e) {
      showNotification(paste("Error loading dataset:", e$message), type = "error")
    })
  }
  
  # Handle login button click
  observeEvent(input$login_btn, {
    callLoginAPI()
  })
  
  # Handle dataset selection buttons
  observeEvent(input$select_dataset_1, {
    dataset <- available_datasets[[1]]
    loadDatasetFromFile(dataset$username, dataset$filename)
  })
  
  observeEvent(input$select_dataset_2, {
    dataset <- available_datasets[[2]]
    loadDatasetFromFile(dataset$username, dataset$filename)
  })
  
  # Handle start analysis button click
  observeEvent(input$start_analysis, {
    values$user_prefs$top_artists_count <- as.numeric(input$artists_count)
    values$user_prefs$top_tracks_count <- as.numeric(input$tracks_count)
    values$user_prefs$time_range <- input$time_range
    
    showNotification("Fetching your music data...", type = "message", duration = 3)
    
    fetchTopArtists(values$user_prefs$time_range, values$user_prefs$top_artists_count)
    fetchTopTracks(values$user_prefs$time_range, values$user_prefs$top_tracks_count)
    fetchMoodDistribution()
    fetchPopularityScore(values$user_prefs$time_range)
    fetchGenreDistribution(values$user_prefs$time_range, 10)
    fetchPersonalityPrediction(values$user_prefs$time_range)
    
    values$data_loaded <- TRUE
    showNotification("✅ Your music analysis is ready! Navigate through your wrap.", type = "message", duration = 5)
  })
  
  # Navigation handlers
  observeEvent(input$next_slide, {
    if (values$current_slide < values$total_slides) {
      values$current_slide <- values$current_slide + 1
    }
  })
  
  observeEvent(input$prev_slide, {
    if (values$current_slide > (if(values$logged_in) 2 else 1)) {
      values$current_slide <- values$current_slide - 1
    }
  })
  
  observeEvent(input$goto_slide, {
    if (values$logged_in && input$goto_slide >= 2 && input$goto_slide <= values$total_slides) {
      values$current_slide <- input$goto_slide
    } else if (!values$logged_in && input$goto_slide == 1) {
      values$current_slide <- 1
    }
  })
  
  # Progress and title outputs
  output$slide_progress <- renderText({
    if (values$logged_in) {
      paste(values$current_slide - 1, "of", values$total_slides - 1)
    } else {
      "Please log in to continue"
    }
  })
  
  output$slide_title <- renderText({
    current_slide_info <- slides[[values$current_slide]]
    current_slide_info$title
  })
  
  output$current_slide_title <- renderText({
    current_slide_info <- slides[[values$current_slide]]
    current_slide_info$title
  })
  
  # Main slide content
  output$current_slide_content <- renderUI({
    current_slide_info <- slides[[values$current_slide]]
    
    switch(current_slide_info$id,
      "login" = render_login_slide(),
      "welcome" = render_welcome_slide(), 
      "top-1-track" = render_top_1_track_slide(),
      "top-tracks" = render_top_tracks_slide(),
      "top-1-artist" = render_top_1_artist_slide(),
      "top-artists" = render_top_artists_slide(),
      "popularity" = render_popularity_slide(),
      "top-1-genre" = render_top_1_genre_slide(),
      "genres" = render_genres_slide(),
      "moods" = render_moods_slide(),
      "personality" = render_personality_slide(),
      "personality-details" = render_personality_details_slide(),
      "thank-you" = render_thank_you_slide()
    )
  })
  
  # Restart functionality
  observeEvent(input$restart_wrap, {
    values$current_slide <- 2  # Go back to welcome slide
  })
  
  # Update progress and dots
  observe({
    session$sendCustomMessage("updateSlideProgress", list(
      current = values$current_slide,
      total = values$total_slides
    ))
  })
  
  # Handle back to configuration buttons
  observeEvent(input$back_to_config, {
    values$current_slide <- 2  # Welcome slide
  })
  
  observeEvent(input$back_to_config2, {
    values$current_slide <- 2  # Welcome slide
  })
  
  observeEvent(input$back_to_config3, {
    values$current_slide <- 2  # Welcome slide
  })
  
  observeEvent(input$back_to_config4, {
    values$current_slide <- 2  # Welcome slide
  })
  
  observeEvent(input$back_to_config5, {
    values$current_slide <- 2  # Welcome slide
  })
  
  observeEvent(input$back_to_config6, {
    values$current_slide <- 2  # Welcome slide
  })
  
  observeEvent(input$back_to_config7, {
    values$current_slide <- 2  # Welcome slide
  })
  
  # Handle back to configuration buttons for TOP 1 slides
  observeEvent(input$back_to_config_track1, {
    values$current_slide <- 2  # Welcome slide
  })
  
  observeEvent(input$back_to_config_track2, {
    values$current_slide <- 2  # Welcome slide
  })
  
  observeEvent(input$back_to_config_artist1, {
    values$current_slide <- 2  # Welcome slide
  })
  
  observeEvent(input$back_to_config_artist2, {
    values$current_slide <- 2  # Welcome slide
  })
  
  observeEvent(input$back_to_config_genre1, {
    values$current_slide <- 2  # Welcome slide
  })
  
  observeEvent(input$back_to_config_genre2, {
    values$current_slide <- 2  # Welcome slide
  })
  
  observeEvent(input$back_to_config_wordcloud, {
    values$current_slide <- 2  # Welcome slide
  })
} 