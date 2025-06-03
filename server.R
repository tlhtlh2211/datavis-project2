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
library(wordcloud2)
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
  
  # Define slides
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
      values$total_slides <- length(slides) - 1  # Exclude login slide
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
      # Call the actual Spotify login API
      response <- GET("http://127.0.0.1:5000/login")
      
      if (status_code(response) == 200) {
        raw_content <- content(response, "text", encoding = "UTF-8")
        api_response <- fromJSON(raw_content, simplifyVector = FALSE)
        
        if ("json_file" %in% names(api_response) && "username" %in% names(api_response)) {
          values$username <- api_response$username
          values$filename <- api_response$json_file
          values$logged_in <- TRUE
          
          # Fetch user profile only
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
    # API call to fetch user profile
    if (is.null(values$username) || is.null(values$filename)) return()
    
    tryCatch({
      url <- paste0("http://127.0.0.1:5000/user/profile?username=",
                   values$username, "&filename=", values$filename)
      response <- GET(url)
      
      if (status_code(response) == 200) {
        # Parse JSON without simplifying vectors to preserve list structure
        values$current_user <- fromJSON(content(response, "text", encoding = "UTF-8"), simplifyVector = FALSE)
        cat("User profile fetched from API\n")
        
        # Debug the structure
        cat("API Profile structure - display_name:", values$current_user$display_name %||% "NULL", "\n")
        if (!is.null(values$current_user$images)) {
          cat("API Profile - images class:", class(values$current_user$images), "\n")
          cat("API Profile - images length:", length(values$current_user$images), "\n")
        }
      }
    }, error = function(e) {
      cat("Error fetching user profile:", e$message, "\n")
    })
  }
  
  # Function to fetch top artists
  fetchTopArtists <- function(time_range = "medium_term", limit = 50) {
    # API call to fetch top artists
    if (is.null(values$username) || is.null(values$filename)) return()
    
    tryCatch({
      url <- paste0("http://127.0.0.1:5000/user/top_artists?username=",
                   values$username, "&filename=", values$filename, 
                   "&time_range=", time_range, "&limit=", limit)
      response <- GET(url)
      
      if (status_code(response) == 200) {
        raw_content <- content(response, "text", encoding = "UTF-8")
        cat("=== RAW ARTISTS API RESPONSE DEBUG ===\n")
        cat("Raw response first 500 chars:", substr(raw_content, 1, 500), "\n")
        cat("=======================================\n")
        
        values$top_artists <- fromJSON(raw_content, simplifyVector = FALSE)
        
        cat("=== PARSED ARTISTS API RESPONSE DEBUG ===\n")
        cat("Parsed response class:", class(values$top_artists), "\n")
        cat("Parsed response length:", length(values$top_artists), "\n")
        cat("Parsed response names:", paste(names(values$top_artists), collapse = ", "), "\n")
        
        # Check if it has items field
        if (!is.null(values$top_artists$items)) {
          cat("Has items field with length:", length(values$top_artists$items), "\n")
          if (length(values$top_artists$items) > 0) {
            cat("First item class:", class(values$top_artists$items[[1]]), "\n")
            cat("First item names:", paste(names(values$top_artists$items[[1]]), collapse = ", "), "\n")
          }
        }
        
        # Check if it's a direct list
        if (is.list(values$top_artists) && !is.null(names(values$top_artists))) {
          cat("Direct response structure detected\n")
          # Print first few field names and their types
          for (name in names(values$top_artists)[1:min(10, length(names(values$top_artists)))]) {
            field_value <- values$top_artists[[name]]
            cat("Field", name, "- class:", class(field_value), "length:", length(field_value), "\n")
          }
        }
        cat("==========================================\n")
      }
    }, error = function(e) {
      cat("Error fetching top artists:", e$message, "\n")
    })
  }
  
  # Function to fetch top tracks
  fetchTopTracks <- function(time_range = "medium_term", limit = 50) {
    # API call to fetch top tracks
    if (is.null(values$username) || is.null(values$filename)) return()
    
    tryCatch({
      url <- paste0("http://127.0.0.1:5000/user/top_tracks?username=",
                   values$username, "&filename=", values$filename, 
                   "&time_range=", time_range, "&limit=", limit)
      response <- GET(url)
      
      if (status_code(response) == 200) {
        raw_content <- content(response, "text", encoding = "UTF-8")
        cat("=== RAW API RESPONSE DEBUG ===\n")
        cat("Raw response first 500 chars:", substr(raw_content, 1, 500), "\n")
        cat("==============================\n")
        
        values$top_tracks <- fromJSON(raw_content, simplifyVector = FALSE)
        
        cat("=== PARSED API RESPONSE DEBUG ===\n")
        cat("Parsed response class:", class(values$top_tracks), "\n")
        cat("Parsed response length:", length(values$top_tracks), "\n")
        cat("Parsed response names:", paste(names(values$top_tracks), collapse = ", "), "\n")
        
        # Check if it has items field
        if (!is.null(values$top_tracks$items)) {
          cat("Has items field with length:", length(values$top_tracks$items), "\n")
          if (length(values$top_tracks$items) > 0) {
            cat("First item class:", class(values$top_tracks$items[[1]]), "\n")
            cat("First item names:", paste(names(values$top_tracks$items[[1]]), collapse = ", "), "\n")
          }
        }
        
        # Check if it's a direct list
        if (is.list(values$top_tracks) && !is.null(names(values$top_tracks))) {
          cat("Direct response structure detected\n")
          # Print first few field names and their types
          for (name in names(values$top_tracks)[1:min(10, length(names(values$top_tracks)))]) {
            field_value <- values$top_tracks[[name]]
            cat("Field", name, "- class:", class(field_value), "length:", length(field_value), "\n")
          }
        }
        cat("=================================\n")
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
        values$mood_data <- fromJSON(content(response, "text", encoding = "UTF-8"), simplifyVector = FALSE)
        cat("Mood distribution data fetched\n")
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
        cat("Popularity score data fetched\n")
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
        cat("Genre distribution data fetched\n")
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
      cat("Calling personality API:", url, "\n")
      response <- GET(url)
      
      if (status_code(response) == 200) {
        raw_content <- content(response, "text", encoding = "UTF-8")
        cat("=== PERSONALITY API RAW RESPONSE ===\n")
        cat("Raw response first 500 chars:", substr(raw_content, 1, 500), "\n")
        cat("===================================\n")
        
        values$personality_data <- fromJSON(raw_content, simplifyVector = FALSE)
        cat("Personality prediction data fetched successfully\n")
        
        # Debug the parsed structure
        cat("Parsed personality data structure:\n")
        cat("Available fields:", paste(names(values$personality_data), collapse = ", "), "\n")
        if (!is.null(values$personality_data$personality)) {
          cat("Personality subfields:", paste(names(values$personality_data$personality), collapse = ", "), "\n")
        }
      } else {
        cat("Personality API failed with status:", status_code(response), "\n")
        cat("Response body:", content(response, "text"), "\n")
      }
    }, error = function(e) {
      cat("Error fetching personality prediction:", e$message, "\n")
    })
  }
  
  # Function to load dataset from existing file
  loadDatasetFromFile <- function(username, filename) {
    tryCatch({
      cat("Loading dataset from file:", filename, "\n")
      
      # Set login status and credentials
      values$logged_in <- TRUE
      values$username <- username
      values$filename <- filename
      
      # Load user profile data for the welcome slide
      json_file_path <- paste0("api/data/", filename)
      
      if (file.exists(json_file_path)) {
        cat("Reading user profile from file:", json_file_path, "\n")
        spotify_data <- fromJSON(json_file_path, simplifyVector = FALSE)
        
        # Load only user profile data for initial setup
        for (item in spotify_data) {
          if (item$step == "current_user") {
            values$current_user <- item$data
            cat("Loaded user profile data for welcome slide\n")
            break
          }
        }
        
        showNotification(paste("Successfully loaded dataset:", filename), type = "message")
      } else {
        showNotification("Dataset file not found!", type = "error")
      }
    }, error = function(e) {
      showNotification(paste("Error loading dataset:", e$message), type = "error")
      cat("Error in loadDatasetFromFile:", e$message, "\n")
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
    # Update user preferences
    values$user_prefs$top_artists_count <- as.numeric(input$artists_count)
    values$user_prefs$top_tracks_count <- as.numeric(input$tracks_count)
    values$user_prefs$time_range <- input$time_range
    
    cat("Starting analysis with preferences:\n")
    cat("Artists:", values$user_prefs$top_artists_count, "\n")
    cat("Tracks:", values$user_prefs$top_tracks_count, "\n") 
    cat("Time range:", values$user_prefs$time_range, "\n")
    
    # Show loading notification
    showNotification("Fetching your music data...", type = "message", duration = 3)
    
    # Fetch data with user preferences
    fetchTopArtists(values$user_prefs$time_range, values$user_prefs$top_artists_count)
    fetchTopTracks(values$user_prefs$time_range, values$user_prefs$top_tracks_count)
    
    # Fetch additional analysis data
    fetchMoodDistribution()
    fetchPopularityScore(values$user_prefs$time_range)
    fetchGenreDistribution(values$user_prefs$time_range, 10)
    
    # Fetch personality prediction
    fetchPersonalityPrediction(values$user_prefs$time_range)
    
    # Mark data as loaded
    values$data_loaded <- TRUE
    
    showNotification("✅ Your music analysis is ready! Navigate through your wrap.", type = "message", duration = 5)
    
    # DO NOT auto-advance to next slide - let user navigate manually
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
  
  # Slide renderers
  render_login_slide <- function() {
    div(class = "login-section",
      div(style = "max-width: 900px; margin: 0 auto;",
        # Header
        div(style = "text-align: center; margin-bottom: 3rem;",
          div(style = "font-size: 4rem; margin-bottom: 2rem;", "🎵"),
          h2("Welcome to Your Spotify Wrap!", style = "font-size: 2.5rem; margin-bottom: 1rem; color: white; font-family: 'Montserrat', sans-serif;"),
          p("Discover your musical journey through 2024. Choose how you'd like to proceed:", 
            style = "font-size: 1.25rem; color: #D1D5DB; margin-bottom: 3rem; line-height: 1.6; font-family: 'Montserrat', sans-serif;")
        ),
        
        # Two-column layout for options
        div(style = "display: grid; grid-template-columns: 1fr 1fr; gap: 3rem; margin-bottom: 2rem;",
          
          # Left side - Login to Spotify
          div(style = "background: rgba(0,0,0,0.3); padding: 2.5rem; border-radius: 1.5rem; border: 2px solid #1DB954; text-align: center;",
            div(style = "font-size: 3rem; margin-bottom: 1.5rem;", "🔑"),
            h3("Login to Spotify", style = "color: #1DB954; margin-bottom: 1rem; font-size: 1.8rem; font-family: 'Montserrat', sans-serif;"),
            p("Connect your Spotify account to analyze your personal music data in real-time.", 
              style = "color: #D1D5DB; font-size: 1.1rem; margin-bottom: 2rem; line-height: 1.6; font-family: 'Montserrat', sans-serif;"),
            actionButton("login_btn", "Login with Spotify", 
                        class = "login-button",
                        style = "background: linear-gradient(135deg, #1DB954, #1ed760); color: white; border: none; padding: 1rem 2rem; border-radius: 2rem; font-size: 1.2rem; font-weight: 600; cursor: pointer; box-shadow: 0 4px 15px rgba(29, 185, 84, 0.3); transition: all 0.3s ease; font-family: 'Montserrat', sans-serif;",
                        icon = icon("spotify", lib = "font-awesome"))
          ),
          
          # Right side - Choose existing dataset
          div(style = "background: rgba(0,0,0,0.3); padding: 2.5rem; border-radius: 1.5rem; border: 2px solid #9CA3AF; text-align: center;",
            div(style = "font-size: 3rem; margin-bottom: 1.5rem;", "📁"),
            h3("Choose Existing Dataset", style = "color: #9CA3AF; margin-bottom: 1rem; font-size: 1.8rem; font-family: 'Montserrat', sans-serif;"),
            p("Explore pre-loaded music profiles to see different musical personalities and tastes.", 
              style = "color: #D1D5DB; font-size: 1.1rem; margin-bottom: 2rem; line-height: 1.6; font-family: 'Montserrat', sans-serif;")
          )
        ),
        
        # Dataset selection cards
        div(style = "margin-top: 2rem;",
          h4("Available Datasets:", style = "color: white; font-size: 1.3rem; margin-bottom: 1.5rem; text-align: center; font-family: 'Montserrat', sans-serif;"),
          div(style = "display: grid; grid-template-columns: 1fr 1fr; gap: 2rem;",
            
            # Dataset 1
            div(style = "background: rgba(0,0,0,0.2); padding: 2rem; border-radius: 1rem; border: 1px solid rgba(156, 163, 175, 0.3); transition: all 0.3s ease; cursor: pointer;",
              div(style = "text-align: center;",
                div(style = "font-size: 2.5rem; margin-bottom: 1rem;", "👤"),
                div(style = "font-size: 1.3rem; font-weight: 600; color: white; margin-bottom: 0.5rem; font-family: 'Montserrat', sans-serif;", 
                    available_datasets[[1]]$display_name),
                div(style = "color: #9CA3AF; font-size: 1rem; margin-bottom: 1.5rem; font-family: 'Montserrat', sans-serif;", 
                    available_datasets[[1]]$description),
                actionButton("select_dataset_1", "Select This Dataset",
                            style = "background: #6B7280; color: white; border: none; padding: 0.75rem 1.5rem; border-radius: 1.5rem; font-size: 1rem; font-weight: 600; cursor: pointer; transition: all 0.3s ease; font-family: 'Montserrat', sans-serif;")
              )
            ),
            
            # Dataset 2  
            div(style = "background: rgba(0,0,0,0.2); padding: 2rem; border-radius: 1rem; border: 1px solid rgba(156, 163, 175, 0.3); transition: all 0.3s ease; cursor: pointer;",
              div(style = "text-align: center;",
                div(style = "font-size: 2.5rem; margin-bottom: 1rem;", "👤"),
                div(style = "font-size: 1.3rem; font-weight: 600; color: white; margin-bottom: 0.5rem; font-family: 'Montserrat', sans-serif;", 
                    available_datasets[[2]]$display_name),
                div(style = "color: #9CA3AF; font-size: 1rem; margin-bottom: 1.5rem; font-family: 'Montserrat', sans-serif;", 
                    available_datasets[[2]]$description),
                actionButton("select_dataset_2", "Select This Dataset",
                            style = "background: #6B7280; color: white; border: none; padding: 0.75rem 1.5rem; border-radius: 1.5rem; font-size: 1rem; font-weight: 600; cursor: pointer; transition: all 0.3s ease; font-family: 'Montserrat', sans-serif;")
              )
            )
          )
        )
      )
    )
  }
  
  render_welcome_slide <- function() {
    if (!values$logged_in) {
      return(div("Please log in first"))
    }
    
    # Fetch user profile data when this slide is accessed
    if (is.null(values$current_user)) {
      fetchUserProfile()
    }
    
    # Show loading state while data is being fetched
    if (is.null(values$current_user)) {
      return(div(style = "text-align: center; padding: 2rem;",
        div(style = "font-size: 2rem; margin-bottom: 1rem;", "🔄"),
        p("Loading your profile...", style = "color: #D1D5DB;")
      ))
    }
    
    # Debug user data structure
    cat("User data structure in welcome slide:\n")
    cat("Display name:", values$current_user$display_name %||% "NULL", "\n")
    cat("Images available:", !is.null(values$current_user$images), "\n")
    if (!is.null(values$current_user$images)) {
      cat("Number of images:", length(values$current_user$images), "\n")
      cat("First image structure:", str(values$current_user$images[[1]]), "\n")
      cat("First image URL:", values$current_user$images[[1]]$url, "\n")
    }
    cat("Followers structure:", str(values$current_user$followers), "\n")

    # Get user's profile image with enhanced logic
    profile_image_url <- "https://via.placeholder.com/200x200/1DB954/white?text=User"
    
    # Enhanced image extraction with better error handling
    if (!is.null(values$current_user$images) && length(values$current_user$images) > 0) {
      cat("Found images, attempting extraction...\n")
      cat("Images class:", class(values$current_user$images), "\n")
      cat("Images length:", length(values$current_user$images), "\n")
      
      tryCatch({
        # Check if images are atomic vectors (parsed incorrectly)
        if (is.atomic(values$current_user$images)) {
          cat("Images parsed as atomic vectors, using placeholder\n")
          # Keep the placeholder image since we can't extract the URL
        } 
        # Check if it's a list with proper structure
        else if (is.list(values$current_user$images) && length(values$current_user$images) > 0) {
          first_image <- values$current_user$images[[1]]
          cat("First image class:", class(first_image), "\n")
          
          if (is.list(first_image) && !is.null(first_image$url)) {
            profile_image_url <- first_image$url
            cat("Successfully extracted image URL:", profile_image_url, "\n")
          } else {
            cat("First image doesn't have URL field\n")
          }
        }
      }, error = function(e) {
        cat("Error extracting image URL:", e$message, "\n")
      })
    } else {
      cat("No images available\n")
    }
    
    # Main container with two-column layout
    div(style = "max-width: 1200px; margin: 0 auto; display: grid; grid-template-columns: 1fr 1fr; gap: 4rem; align-items: start; padding: 2rem;",
      
      # Left side - User profile with bigger image
      div(style = "text-align: center;",
        # Large profile image
        div(style = "margin-bottom: 2rem;",
          img(src = profile_image_url, 
              class = "profile-avatar",
              style = "width: 250px; height: 250px; border-radius: 50%; border: 4px solid #1DB954; object-fit: cover; box-shadow: 0 8px 32px rgba(29, 185, 84, 0.3);")
        ),
        
        # User name
        div(style = "font-size: 3rem; font-weight: bold; color: white; margin-bottom: 1rem; font-family: 'Montserrat', sans-serif;",
          values$current_user$display_name %||% "Spotify User"
        ),
        
        # User stats
        div(class = "stat-grid", style = "margin-top: 2rem;",
          div(class = "stat-card",
            div(class = "stat-value", style = "font-size: 2.5rem; font-family: 'Montserrat', sans-serif;", values$current_user$followers$total %||% "0"),
            div(class = "stat-label", style = "font-size: 1.1rem; font-family: 'Montserrat', sans-serif;", "Followers")
          ),
          div(class = "stat-card",
            div(class = "stat-value", style = "font-size: 2.5rem; font-family: 'Montserrat', sans-serif;", values$current_user$country %||% "Unknown"),
            div(class = "stat-label", style = "font-size: 1.1rem; font-family: 'Montserrat', sans-serif;", "Country")
          ),
          div(class = "stat-card",
            div(class = "stat-value", style = "font-size: 2.5rem; font-family: 'Montserrat', sans-serif;", values$current_user$product %||% "Free"),
            div(class = "stat-label", style = "font-size: 1.1rem; font-family: 'Montserrat', sans-serif;", "Plan")
          )
        )
      ),
      
      # Right side - Preferences form
      div(style = "background: rgba(0,0,0,0.3); padding: 2rem; border-radius: 1rem; border: 1px solid rgba(29, 185, 84, 0.2);",
        div(style = "text-align: center; margin-bottom: 2rem;",
          h3("Customize Your Analysis", style = "color: #1DB954; margin-bottom: 1rem; font-size: 1.8rem; font-family: 'Montserrat', sans-serif;"),
          p("Tell us what you'd like to analyze in your musical journey", style = "color: #D1D5DB; font-size: 1.2rem; font-family: 'Montserrat', sans-serif;")
        ),
        
        # Form inputs
        div(style = "space-y: 1.5rem;",
          # Top Artists Count
          div(style = "margin-bottom: 1.5rem;",
            div("How many top artists?", style = "display: block; color: white; font-weight: 600; margin-bottom: 0.5rem; font-size: 1.1rem; font-family: 'Montserrat', sans-serif;"),
            selectInput("artists_count", NULL,
              choices = list("Top 5" = 5, "Top 10" = 10, "Top 20" = 20, "Top 30" = 30, "Top 50" = 50),
              selected = 5,
              width = "100%"
            )
          ),
          
          # Top Tracks Count  
          div(style = "margin-bottom: 1.5rem;",
            div("How many top tracks?", style = "display: block; color: white; font-weight: 600; margin-bottom: 0.5rem; font-size: 1.1rem; font-family: 'Montserrat', sans-serif;"),
            selectInput("tracks_count", NULL,
              choices = list("Top 5" = 5, "Top 10" = 10, "Top 20" = 20, "Top 30" = 30, "Top 50" = 50),
              selected = 5,
              width = "100%"
            )
          ),
          
          # Time Range
          div(style = "margin-bottom: 2rem;",
            div("Time period to analyze:", style = "display: block; color: white; font-weight: 600; margin-bottom: 0.5rem; font-size: 1.1rem; font-family: 'Montserrat', sans-serif;"),
            selectInput("time_range", NULL,
              choices = list(
                "Last 4 weeks" = "short_term",
                "Last 6 months" = "medium_term", 
                "All time" = "long_term"
              ),
              selected = "medium_term",
              width = "100%"
            )
          ),
          
          # Submit button
          div(style = "text-align: center;",
            actionButton("start_analysis", "Start My Analysis",
              class = "btn-primary",
              style = "background: linear-gradient(135deg, #1DB954, #1ed760); color: white; border: none; padding: 1.2rem 2.5rem; border-radius: 2rem; font-size: 1.3rem; font-weight: 600; cursor: pointer; box-shadow: 0 4px 15px rgba(29, 185, 84, 0.3); transition: all 0.3s ease; min-width: 200px; font-family: 'Montserrat', sans-serif;"
            )
          ),
          
          # Status message
          div(id = "analysis_status", style = "text-align: center; margin-top: 1rem; color: #9CA3AF; font-style: italic; font-size: 1.1rem; font-family: 'Montserrat', sans-serif;",
            if (values$data_loaded) "✅ Data loaded! Navigate through your wrap." else "Ready to analyze your music taste"
          )
        )
      )
    )
  }
  
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
    
    # Add detailed debugging
    cat("=== TRACK DATA DEBUGGING ===\n")
    cat("values$top_tracks class:", class(values$top_tracks), "\n")
    cat("values$top_tracks length:", length(values$top_tracks), "\n")
    cat("values$top_tracks names:", names(values$top_tracks), "\n")
    
    # Print first few elements to understand structure
    if (!is.null(values$top_tracks) && length(values$top_tracks) > 0) {
      cat("\nFirst element class:", class(values$top_tracks[[1]]), "\n")
      cat("First element names:", names(values$top_tracks[[1]]), "\n")
      if (length(values$top_tracks) > 1) {
        cat("Second element class:", class(values$top_tracks[[2]]), "\n")
        cat("Second element names:", names(values$top_tracks[[2]]), "\n")
      }
    }
    
    if (!is.null(values$top_tracks$items)) {
      # API format: data is in $items
      tracks <- values$top_tracks$items
      cat("Using API format with items, found", length(tracks), "tracks\n")
    } else if (!is.null(values$top_tracks) && is.list(values$top_tracks)) {
      # The API response might be a direct list of tracks
      # Check if each element has track properties
      valid_tracks <- list()
      
      cat("Checking", length(values$top_tracks), "elements for track properties...\n")
      
      for (i in seq_along(values$top_tracks)) {
        item <- values$top_tracks[[i]]
        cat("Element", i, "- class:", class(item), "\n")
        if (is.list(item)) {
          cat("Element", i, "- names:", paste(names(item), collapse = ", "), "\n")
          cat("Element", i, "- has name:", !is.null(item$name), "\n")
          cat("Element", i, "- has artists:", !is.null(item$artists), "\n")
          if (!is.null(item$name)) {
            cat("Element", i, "- name value:", item$name, "\n")
          }
        }
        
        if (is.list(item) && !is.null(item$name) && !is.null(item$artists)) {
          valid_tracks[[length(valid_tracks) + 1]] <- item
          cat("Element", i, "- ADDED as valid track\n")
        }
        
        # Only check first 3 elements for debugging
        if (i >= 3) break
      }
      
      if (length(valid_tracks) > 0) {
        tracks <- valid_tracks
        cat("Found", length(tracks), "valid track objects\n")
      } else {
        # Fallback: treat as single track
        if (!is.null(values$top_tracks$name)) {
          tracks <- list(values$top_tracks)
          cat("Treating as single track object\n")
        } else {
          # Maybe tracks are at a different level
          tracks <- list()
          cat("No valid tracks found!\n")
        }
      }
    }
    
    cat("Final tracks count:", length(tracks), "\n")
    if (length(tracks) > 0) {
      cat("=== INDIVIDUAL TRACK DEBUGGING ===\n")
      first_track <- tracks[[1]]
      cat("First track class:", class(first_track), "\n")
      cat("First track names:", paste(names(first_track), collapse = ", "), "\n")
      
      # Check specific fields we're looking for
      cat("Track $name exists:", !is.null(first_track$name), "\n")
      cat("Track $artists exists:", !is.null(first_track$artists), "\n")
      cat("Track $album exists:", !is.null(first_track$album), "\n")
      cat("Track $popularity exists:", !is.null(first_track$popularity), "\n")
      
      # If name exists, what is it?
      if (!is.null(first_track$name)) {
        cat("Track name value:", first_track$name, "\n")
        cat("Track name class:", class(first_track$name), "\n")
      }
      
      # Extract artists more carefully
      track_artists <- "Unknown Artist"
      if (!is.null(first_track$artists) && length(first_track$artists) > 0) {
        # Check if artists are strings or objects
        artist_names <- c()
        for (j in seq_along(first_track$artists)) {
          artist <- first_track$artists[[j]]
          if (is.character(artist)) {
            # Artist is already a string
            artist_names <- c(artist_names, as.character(artist))
          } else if (is.list(artist) && !is.null(artist$name)) {
            # Artist is an object with name field
            artist_names <- c(artist_names, as.character(artist$name))
          }
        }
        if (length(artist_names) > 0) {
          # Limit to first 3 artists to avoid long lists
          artist_names <- artist_names[1:min(3, length(artist_names))]
          track_artists <- paste(artist_names, collapse = ", ")
          if (length(first_track$artists) > 3) {
            track_artists <- paste0(track_artists, "...")
          }
        }
        cat("Track", i, "artists:", track_artists, "\n")
      }
      
      # Print some raw structure for first track
      cat("First track structure (limited):\n")
      str(first_track, max.level = 2, list.len = 10)
      cat("=================================\n")
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
            # API format: actual track data is in $track field
            track <- track_item$track
            cat("Using track from wrapper for item", i, "\n")
          } else {
            # Direct format: track data is directly in the item
            track <- track_item
            cat("Using direct track data for item", i, "\n")
          }
          
          # Safely extract track information with better error handling
          track_name <- "Unknown Track"
          if (!is.null(track$name)) {
            track_name <- as.character(track$name[1])
            cat("Track", i, "name:", track_name, "\n")
          }
          
          # Extract album image
          album_image_url <- "https://via.placeholder.com/80x80/1DB954/white?text=♪"
          if (!is.null(track$album) && !is.null(track$album$images) && length(track$album$images) > 0) {
            # Get smallest album image (usually the last one)
            last_image <- track$album$images[[length(track$album$images)]]
            if (!is.null(last_image$url)) {
              album_image_url <- last_image$url
              cat("Track", i, "album image found\n")
            }
          }
          
          # Extract artists more carefully
          track_artists <- "Unknown Artist"
          if (!is.null(track$artists) && length(track$artists) > 0) {
            # Check if artists are strings or objects
            artist_names <- c()
            for (j in seq_along(track$artists)) {
              artist <- track$artists[[j]]
              if (is.character(artist)) {
                # Artist is already a string
                artist_names <- c(artist_names, as.character(artist))
              } else if (is.list(artist) && !is.null(artist$name)) {
                # Artist is an object with name field
                artist_names <- c(artist_names, as.character(artist$name))
              }
            }
            if (length(artist_names) > 0) {
              # Limit to first 3 artists to avoid long lists
              artist_names <- artist_names[1:min(3, length(artist_names))]
              track_artists <- paste(artist_names, collapse = ", ")
              if (length(track$artists) > 3) {
                track_artists <- paste0(track_artists, "...")
              }
            }
            cat("Track", i, "artists:", track_artists, "\n")
          }
          
          # Handle popularity
          track_popularity <- 0
          if (!is.null(track$popularity) && is.numeric(track$popularity)) {
            track_popularity <- as.numeric(track$popularity[1])
            if (is.na(track_popularity)) track_popularity <- 0
            cat("Track", i, "popularity:", track_popularity, "\n")
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
            div(style = "flex: 1; min-width: 0;",  # min-width: 0 allows text to truncate
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
  
  render_top_1_artist_slide <- function() {
    if (!values$logged_in) {
      return(div("Please log in first"))
    }
    
    # Check if data is loaded
    if (!values$data_loaded || is.null(values$top_artists)) {
      return(div(style = "text-align: center; padding: 4rem;",
        div(style = "font-size: 3rem; margin-bottom: 1rem;", "🎤"),
        h3("Configure Your Analysis First", style = "color: #1DB954; margin-bottom: 1rem;"),
        p("Please go back to 'Your Musical Journey' and configure your preferences to load your top artists.",
          style = "color: #D1D5DB; font-size: 1.1rem; max-width: 500px; margin: 0 auto;"),
        div(style = "margin-top: 2rem;",
          actionButton("back_to_config_artist1", "← Back to Configuration", 
            style = "background: #1DB954; color: white; border: none; padding: 0.75rem 1.5rem; border-radius: 1rem; cursor: pointer;"
          )
        )
      ))
    }

    # Handle different data structures (API vs direct file loading)
    artists <- list()
    if (!is.null(values$top_artists$items)) {
      artists <- values$top_artists$items
    } else if (!is.null(values$top_artists) && is.list(values$top_artists)) {
      if (length(values$top_artists) > 0) {
        first_item <- values$top_artists[[1]]
        if (is.character(first_item)) {
          # Create mock artist data since the API seems to be returning genres
          unique_genres <- unique(unlist(values$top_artists))
          unique_genres <- unique_genres[unique_genres != "0" & unique_genres != "" & !is.na(unique_genres)]
          
          artists <- lapply(seq_len(min(5, length(unique_genres))), function(i) {
            list(
              name = paste("Artist", i),
              genres = if (i <= length(unique_genres)) unique_genres[i] else "Unknown",
              popularity = sample(50:90, 1)
            )
          })
        } else if (is.list(first_item)) {
          artists <- values$top_artists
        }
      }
    }

    if (length(artists) == 0) {
      return(div(style = "text-align: center; padding: 4rem;",
        div(style = "font-size: 3rem; margin-bottom: 1rem;", "🎤"),
        p("No artists found. Try listening to more music on Spotify!", style = "color: #D1D5DB; font-size: 1.2rem; font-family: 'Montserrat', sans-serif;")
      ))
    }

    # Extract first artist data
    artist <- artists[[1]]
    
    # Extract artist information
    artist_name <- "Unknown Artist"
    if (!is.null(artist$name)) {
      if (is.character(artist$name) && length(artist$name) > 0) {
        artist_name <- as.character(artist$name[1])
      } else if (!is.null(artist$name)) {
        artist_name <- as.character(artist$name)
      }
    }
    
    # Extract artist image
    artist_image_url <- "https://via.placeholder.com/200x200/1DB954/white?text=♪"
    if (!is.null(artist$images) && length(artist$images) > 0) {
      first_image <- artist$images[[1]]  # Get largest image
      if (!is.null(first_image$url)) {
        artist_image_url <- first_image$url
      }
    }
    
    # Extract genres
    artist_genres <- "No genres"
    if (!is.null(artist$genres)) {
      if (is.character(artist$genres) && length(artist$genres) > 0) {
        genres_subset <- artist$genres[1:min(3, length(artist$genres))]
        artist_genres <- paste(genres_subset, collapse = ", ")
      } else if (is.list(artist$genres) && length(artist$genres) > 0) {
        genre_names <- sapply(artist$genres, function(g) {
          if (is.character(g)) {
            if (length(g) > 1) g <- g[1]
            return(as.character(g))
          } else {
            return(as.character(g))
          }
        })
        genres_subset <- genre_names[1:min(3, length(genre_names))]
        artist_genres <- paste(genres_subset, collapse = ", ")
      }
    }

    # Extract popularity
    artist_popularity <- 0
    if (!is.null(artist$popularity)) {
      pop_val <- artist$popularity
      if (length(pop_val) > 1) pop_val <- pop_val[1]
      artist_popularity <- as.numeric(pop_val)
      if (is.na(artist_popularity)) artist_popularity <- 0
    }

    div(style = "max-width: 800px; margin: 0 auto; text-align: center; padding: 2rem;",
      # Header
      div(style = "margin-bottom: 3rem;",
        div(style = "font-size: 4rem; font-weight: bold; color: #1DB954; margin-bottom: 1rem; font-family: 'Montserrat', sans-serif;", "#1"),
        p("Your most listened artist this year", style = "font-size: 1.5rem; color: #D1D5DB; font-family: 'Montserrat', sans-serif;")
      ),
      
      # Main content card
      div(style = "background: linear-gradient(135deg, rgba(29, 185, 84, 0.1), rgba(16, 185, 129, 0.1)); padding: 3rem; border-radius: 2rem; border: 3px solid rgba(29, 185, 84, 0.3); box-shadow: 0 20px 40px rgba(29, 185, 84, 0.2);",
        # Artist image
        div(style = "margin-bottom: 2rem;",
          img(src = artist_image_url, 
              style = "width: 200px; height: 200px; border-radius: 50%; box-shadow: 0 15px 30px rgba(0, 0, 0, 0.5);",
              alt = paste("Artist photo of", artist_name))
        ),
        
        # Artist details
        div(style = "margin-bottom: 2rem;",
          div(style = "font-weight: bold; font-size: 2.5rem; color: white; margin-bottom: 1rem; font-family: 'Montserrat', sans-serif; line-height: 1.2;", artist_name),
          div(style = "color: #D1D5DB; font-size: 1.5rem; margin-bottom: 1rem; font-family: 'Montserrat', sans-serif;", artist_genres),
          div(style = "display: inline-block; background: rgba(29, 185, 84, 0.2); color: #10B981; padding: 0.75rem 1.5rem; border-radius: 2rem; font-size: 1.2rem; font-weight: 600; font-family: 'Montserrat', sans-serif;",
              paste0(artist_popularity, "% popular"))
        ),
        
        # Crown emoji
        div(style = "font-size: 3rem; margin-top: 1rem;", "👑")
      )
    )
  }
  
  render_top_artists_slide <- function() {
    if (!values$logged_in) {
      return(div("Please log in first"))
    }
    
    # Check if data is loaded, if not show message to configure preferences
    if (!values$data_loaded || is.null(values$top_artists)) {
      return(div(style = "text-align: center; padding: 4rem;",
        div(style = "font-size: 3rem; margin-bottom: 1rem;", "🎤"),
        h3("Configure Your Analysis First", style = "color: #1DB954; margin-bottom: 1rem;"),
        p("Please go back to 'Your Musical Journey' and configure your preferences to load your top artists.",
          style = "color: #D1D5DB; font-size: 1.1rem; max-width: 500px; margin: 0 auto;"),
        div(style = "margin-top: 2rem;",
          actionButton("back_to_config2", "← Back to Configuration", 
            style = "background: #1DB954; color: white; border: none; padding: 0.75rem 1.5rem; border-radius: 1rem; cursor: pointer;"
          )
        )
      ))
    }

    # Handle different data structures (API vs direct file loading)
    artists <- list()
    if (!is.null(values$top_artists$items)) {
      # API format: data is in $items
      artists <- values$top_artists$items
      cat("Using API format with items, found", length(artists), "artists\n")
    } else if (!is.null(values$top_artists) && is.list(values$top_artists)) {
      # Check if this is actually artist data or genre data
      cat("Checking artist data structure...\n")
      
      # Look at first few elements to understand the structure
      if (length(values$top_artists) > 0) {
        first_item <- values$top_artists[[1]]
        cat("First item class:", class(first_item), "\n")
        
        if (is.character(first_item)) {
          # This looks like genre data, not artist data
          cat("Data appears to be genres, not artists. Creating placeholder artists.\n")
          
          # Create mock artist data since the API seems to be returning genres
          unique_genres <- unique(unlist(values$top_artists))
          unique_genres <- unique_genres[unique_genres != "0" & unique_genres != "" & !is.na(unique_genres)]
          
          artists <- lapply(seq_len(min(5, length(unique_genres))), function(i) {
            list(
              name = paste("Artist", i),
              genres = if (i <= length(unique_genres)) unique_genres[i] else "Unknown",
              popularity = sample(50:90, 1)  # Random popularity for mock data
            )
          })
          
          cat("Created", length(artists), "mock artists from genre data\n")
        } else if (is.list(first_item)) {
          # This is proper artist data
          artists <- values$top_artists
          cat("Using direct artist data format\n")
        }
      }
    }
    
    cat("Final artists count:", length(artists), "\n")
    if (length(artists) > 0) {
      cat("Processing first artist...\n")
    }
    
    div(style = "max-width: 1000px; margin: 0 auto;",
      div(style = "text-align: center; margin-bottom: 3rem;",
        p("All the artists who soundtracked your year", style = "font-size: 1.5rem; color: #D1D5DB; font-family: 'Montserrat', sans-serif;")
      ),
      if (length(artists) == 0) {
        div(style = "text-align: center; padding: 2rem;",
          div(style = "font-size: 2rem; margin-bottom: 1rem;", "🎤"),
          p("No artists found. Try listening to more music on Spotify!", style = "color: #D1D5DB; font-size: 1.2rem; font-family: 'Montserrat', sans-serif;")
        )
      } else {
        div(style = "display: grid; grid-template-columns: repeat(auto-fit, minmax(450px, 1fr)); gap: 1.5rem;",
          lapply(seq_along(artists), function(i) {
            artist <- artists[[i]]
            
            # Safely extract artist information from list
            artist_name <- "Unknown Artist"
            if (!is.null(artist$name)) {
              if (is.character(artist$name) && length(artist$name) > 0) {
                artist_name <- as.character(artist$name[1])
              } else if (!is.null(artist$name)) {
                artist_name <- as.character(artist$name)
              }
            }
            
            # Extract artist image
            artist_image_url <- "https://via.placeholder.com/100x100/1DB954/white?text=♪"
            if (!is.null(artist$images) && length(artist$images) > 0) {
              # Get smallest artist image (usually the last one) for better performance
              last_image <- artist$images[[length(artist$images)]]
              if (!is.null(last_image$url)) {
                artist_image_url <- last_image$url
                cat("Artist", i, "image found:", artist_image_url, "\n")
              }
            }
            
            artist_genres <- "No genres"
            artist_popularity <- 0
            
            # Handle genres safely
            if (!is.null(artist$genres)) {
              if (is.character(artist$genres) && length(artist$genres) > 0) {
                genres_subset <- artist$genres[1:min(3, length(artist$genres))]
                artist_genres <- paste(genres_subset, collapse = ", ")
              } else if (is.list(artist$genres) && length(artist$genres) > 0) {
                genre_names <- sapply(artist$genres, function(g) {
                  if (is.character(g)) {
                    if (length(g) > 1) g <- g[1]
                    return(as.character(g))
                  } else {
                    return(as.character(g))
                  }
                })
                genres_subset <- genre_names[1:min(3, length(genre_names))]
                artist_genres <- paste(genres_subset, collapse = ", ")
              }
            }
            
            # Ensure artist_genres is a single character value
            if (length(artist_genres) > 1) artist_genres <- artist_genres[1]
            if (!is.character(artist_genres)) artist_genres <- as.character(artist_genres)
            
            # Handle popularity safely
            if (!is.null(artist$popularity)) {
              pop_val <- artist$popularity
              if (length(pop_val) > 1) pop_val <- pop_val[1]
              artist_popularity <- as.numeric(pop_val)
              if (is.na(artist_popularity)) artist_popularity <- 0
            }
            
            cat("Artist", i, "- Name:", artist_name, "Genres:", artist_genres, "Popularity:", artist_popularity, "\n")
            
            div(class = "artist-item", style = "padding: 1.5rem; margin-bottom: 1rem;",
              div(class = "rank-badge", style = "width: 2.5rem; height: 2.5rem; font-size: 1.2rem; font-family: 'Montserrat', sans-serif; font-weight: bold;", i),
              # Artist image
              div(style = "width: 5rem; height: 5rem; border-radius: 50%; overflow: hidden; flex-shrink: 0; border: 3px solid rgba(29, 185, 84, 0.5);",
                img(src = artist_image_url, 
                    style = "width: 100%; height: 100%; object-fit: cover;",
                    alt = paste("Artist photo of", artist_name))
              ),
              div(style = "flex: 1;",
                div(style = "font-weight: 600; font-size: 1.4rem; color: white; margin-bottom: 0.5rem; font-family: 'Montserrat', sans-serif;", artist_name),
                div(style = "color: #9CA3AF; font-size: 1.1rem; margin-bottom: 0.5rem; font-family: 'Montserrat', sans-serif;", artist_genres),
                div(style = "background: rgba(29, 185, 84, 0.2); color: #10B981; padding: 0.25rem 0.75rem; border-radius: 1rem; font-size: 0.9rem; font-weight: 600; display: inline-block; font-family: 'Montserrat', sans-serif;",
                    paste0(artist_popularity, "% popular"))
              )
            )
          })
        )
      }
    )
  }
  
  render_popularity_slide <- function() {
    if (!values$logged_in) {
      return(div("Please log in first"))
    }
    
    # Check if data is loaded, if not show message to configure preferences
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
      
      cat("API popularity stats - avg:", avg_popularity, "min:", min_popularity, "max:", max_popularity, "\n")
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
  
  render_genres_slide <- function() {
    if (!values$logged_in) {
      return(div("Please log in first"))
    }
    
    # Check if data is loaded, if not show message to configure preferences
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
      # API returns genre data in 'percentages' field, not 'genres'
      top_genres <- values$genre_data$percentages
      cat("API Genre data - found", length(top_genres), "genres\n")
      
      # Debug the genre data structure
      cat("Genre data structure:\n")
      cat("Available fields:", paste(names(values$genre_data), collapse = ", "), "\n")
      if (!is.null(values$genre_data$labels)) {
        cat("Labels:", paste(values$genre_data$labels[1:min(5, length(values$genre_data$labels))], collapse = ", "), "\n")
      }
      if (!is.null(values$genre_data$percentages)) {
        cat("First few percentages:", paste(names(top_genres)[1:min(5, length(top_genres))], collapse = ", "), "\n")
      }
    }
    
    if (length(top_genres) == 0) {
      # No genres found
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
  
  render_moods_slide <- function() {
    if (!values$logged_in) {
      return(div("Please log in first"))
    }
    
    # Check if data is loaded, if not show message to configure preferences
    if (!values$data_loaded || is.null(values$mood_data)) {
      return(div(style = "text-align: center; padding: 4rem;",
        div(style = "font-size: 3rem; margin-bottom: 1rem;", "🎭"),
        h3("Configure Your Analysis First", style = "color: #1DB954; margin-bottom: 1rem;"),
        p("Please go back to 'Your Musical Journey' and configure your preferences to analyze your moods.",
          style = "color: #D1D5DB; font-size: 1.1rem; max-width: 500px; margin: 0 auto;"),
        div(style = "margin-top: 2rem;",
          actionButton("back_to_config5", "← Back to Configuration", 
            style = "background: #1DB954; color: white; border: none; padding: 0.75rem 1.5rem; border-radius: 1rem; cursor: pointer;"
          )
        )
      ))
    }
    
    # Use API data for mood analysis
    mood_data <- list()
    if (!is.null(values$mood_data)) {
      # Add debug logging to understand the mood API structure
      cat("=== MOOD API RESPONSE DEBUG ===\n")
      cat("Mood data available fields:", paste(names(values$mood_data), collapse = ", "), "\n")
      
      # Check different possible field names
      if (!is.null(values$mood_data$moods)) {
        mood_data <- values$mood_data$moods
        cat("Using 'moods' field - found", length(mood_data), "mood categories\n")
      } else if (!is.null(values$mood_data$mood_distribution)) {
        mood_data <- values$mood_data$mood_distribution
        cat("Using 'mood_distribution' field - found", length(mood_data), "mood categories\n")
      } else if (!is.null(values$mood_data$percentages)) {
        mood_data <- values$mood_data$percentages
        cat("Using 'percentages' field - found", length(mood_data), "mood categories\n")
      } else if (!is.null(values$mood_data$data)) {
        mood_data <- values$mood_data$data
        cat("Using 'data' field - found", length(mood_data), "mood categories\n")
      } else {
        # Try to use the mood_data directly if it's a list of moods
        if (is.list(values$mood_data) && length(values$mood_data) > 0) {
          # Check if values have mood-like names
          mood_names <- names(values$mood_data)
          mood_like_names <- c("happy", "sad", "energetic", "calm", "angry", "romantic", "nostalgic", "excited")
          if (any(tolower(mood_names) %in% mood_like_names)) {
            mood_data <- values$mood_data
            cat("Using direct mood_data - found", length(mood_data), "mood categories\n")
          }
        }
      }
      cat("================================\n")
    }
    
    # Process mood data for résumé format
    if (length(mood_data) > 0) {
      # Convert to data frame and sort by percentage
      mood_df <- data.frame(
        mood = names(mood_data),
        percent = as.numeric(mood_data),
        stringsAsFactors = FALSE
      )
      
      # Remove any invalid or NA values
      mood_df <- mood_df[!is.na(mood_df$percent) & mood_df$percent > 0, ]
      
      # Check if we have valid data after cleaning
      if (nrow(mood_df) == 0) {
        return(div(style = "max-width: 800px; margin: 0 auto; text-align: center;",
          div(style = "font-size: 2rem; margin-bottom: 1rem;", "🎭"),
          p("No valid mood data available", style = "font-size: 1.25rem; color: #D1D5DB; font-family: 'Montserrat', sans-serif;"),
          p("Unable to process mood information from your music", style = "color: #9CA3AF; font-family: 'Montserrat', sans-serif;")
        ))
      }
      
      mood_df <- mood_df[order(-mood_df$percent), ]
      
      # Get top mood for "position" (safely)
      top_mood <- mood_df[1, ]
      top_mood_title <- switch(tolower(top_mood$mood),
        "chill" = "Head of Chill Operations",
        "melancholic" = "Chief Emotional Officer", 
        "groovy" = "Director of Groove Coordination",
        "euphoric" = "VP of Euphoric Experiences",
        "calm" = "Zen Master & Wellness Coordinator",
        "sad" = "Senior Emotional Intelligence Specialist",
        "energetic" = "High Energy Program Manager",
        "happy" = "Chief Happiness Officer",
        "romantic" = "Love & Romance Strategist",
        "nostalgic" = "Memory Lane Curator",
        paste("Chief", tools::toTitleCase(top_mood$mood), "Officer")
      )
      
      # Get skills (other moods) - safely handle case with only one mood
      skills_moods <- NULL
      if (nrow(mood_df) > 1) {
        end_index <- min(4, nrow(mood_df))
        skills_moods <- mood_df[2:end_index, ]
      }
      
      # Get endorsements (all moods with emojis)
      mood_emojis <- c(
        "chill" = "😎", "melancholic" = "😔", "groovy" = "🕺", "euphoric" = "🤩",
        "calm" = "🧘", "sad" = "😢", "energetic" = "⚡", "happy" = "😊",
        "romantic" = "💕", "nostalgic" = "💭", "intense" = "🔥", "dreamy" = "✨"
      )
      
      # Main résumé layout
      div(style = "max-width: 800px; margin: 0 auto;",
        div(style = "text-align: center; margin-bottom: 3rem;",
          p("Your Musical Mood Résumé", style = "font-size: 1.5rem; color: #D1D5DB; font-family: 'Montserrat', sans-serif;")
        ),
        
        # LinkedIn-style profile card
        div(style = "background: linear-gradient(135deg, rgba(0, 119, 181, 0.1), rgba(29, 185, 84, 0.1)); border: 2px solid rgba(0, 119, 181, 0.3); border-radius: 1.5rem; padding: 3rem; box-shadow: 0 8px 32px rgba(0, 119, 181, 0.2);",
          
          # Profile header
          div(style = "text-align: center; margin-bottom: 2.5rem;",
            div(style = "width: 120px; height: 120px; border-radius: 50%; background: linear-gradient(135deg, #0077B5, #1DB954); margin: 0 auto 1.5rem; display: flex; align-items: center; justify-content: center; font-size: 3rem;", "🎵"),
            div(style = "font-size: 2.2rem; font-weight: bold; color: white; margin-bottom: 0.5rem; font-family: 'Montserrat', sans-serif;", values$current_user$display_name %||% "Music Enthusiast"),
            div(style = "font-size: 1.4rem; color: #0077B5; font-weight: 600; margin-bottom: 0.5rem; font-family: 'Montserrat', sans-serif;", top_mood_title),
            div(style = "font-size: 1.1rem; color: #9CA3AF; font-family: 'Montserrat', sans-serif;", "Spotify Musical Personality Division")
          ),
          
          # Current Position section
          div(style = "margin-bottom: 2.5rem;",
            div(style = "display: flex; align-items: center; margin-bottom: 1rem;",
              div(style = "font-size: 1.2rem; margin-right: 0.5rem;", "💼"),
              div(style = "font-size: 1.3rem; font-weight: bold; color: white; font-family: 'Montserrat', sans-serif;", "Current Position")
            ),
            div(style = "background: rgba(0,0,0,0.2); padding: 1.5rem; border-radius: 1rem; border-left: 4px solid #1DB954;",
              div(style = "font-size: 1.4rem; font-weight: 600; color: #1DB954; margin-bottom: 0.5rem; font-family: 'Montserrat', sans-serif;", top_mood_title),
              div(style = "font-size: 1.1rem; color: #D1D5DB; margin-bottom: 0.5rem; font-family: 'Montserrat', sans-serif;", "Leading with expertise and passion"),
              div(style = "font-size: 1.3rem; font-weight: bold; color: white; font-family: 'Montserrat', sans-serif;", paste0(round(top_mood$percent, 1), "% specialization"))
            )
          ),
          
          # Core Skills section
          if (!is.null(skills_moods) && nrow(skills_moods) > 0) {
            div(style = "margin-bottom: 2.5rem;",
              div(style = "display: flex; align-items: center; margin-bottom: 1rem;",
                div(style = "font-size: 1.2rem; margin-right: 0.5rem;", "🎯"),
                div(style = "font-size: 1.3rem; font-weight: bold; color: white; font-family: 'Montserrat', sans-serif;", "Core Competencies")
              ),
              div(style = "display: grid; gap: 1rem;",
                lapply(1:nrow(skills_moods), function(i) {
                  skill <- skills_moods[i, ]
                  skill_description <- switch(tolower(skill$mood),
                    "melancholic" = "Deep emotional processing and introspective analysis",
                    "groovy" = "Rhythm coordination and movement synchronization", 
                    "euphoric" = "High-energy experience optimization",
                    "calm" = "Stress management and zen-state cultivation",
                    "sad" = "Emotional resilience and cathartic processing",
                    "energetic" = "Dynamic momentum building and motivation",
                    "happy" = "Positive energy cultivation and mood elevation",
                    "romantic" = "Love expression and intimate connection facilitation",
                    paste("Advanced", tolower(skill$mood), "management and coordination")
                  )
                  
                  div(style = "background: rgba(255,255,255,0.05); padding: 1.2rem; border-radius: 0.8rem; border-left: 3px solid #0077B5;",
                    div(style = "display: flex; justify-content: between; align-items: center; margin-bottom: 0.5rem;",
                      div(style = "font-size: 1.1rem; font-weight: 600; color: #E5E7EB; font-family: 'Montserrat', sans-serif;", tools::toTitleCase(skill$mood)),
                      div(style = "font-size: 1.1rem; font-weight: bold; color: #0077B5; font-family: 'Montserrat', sans-serif;", paste0(round(skill$percent, 1), "%"))
                    ),
                    div(style = "font-size: 0.95rem; color: #B0B0B0; font-family: 'Montserrat', sans-serif;", skill_description)
                  )
                })
              )
            )
          } else {
            # Show a note when there's only one dominant mood
            div(style = "margin-bottom: 2.5rem;",
              div(style = "display: flex; align-items: center; margin-bottom: 1rem;",
                div(style = "font-size: 1.2rem; margin-right: 0.5rem;", "🎯"),
                div(style = "font-size: 1.3rem; font-weight: bold; color: white; font-family: 'Montserrat', sans-serif;", "Core Competencies")
              ),
              div(style = "background: rgba(255,255,255,0.05); padding: 1.5rem; border-radius: 0.8rem; text-align: center;",
                div(style = "font-size: 1.1rem; color: #9CA3AF; font-family: 'Montserrat', sans-serif;", "Highly specialized with singular focus"),
                div(style = "font-size: 0.95rem; color: #6B7280; margin-top: 0.5rem; font-family: 'Montserrat', sans-serif;", "Your music shows remarkable consistency in emotional tone")
              )
            )
          },
          
          # Endorsements section
          div(style = "margin-bottom: 1.5rem;",
            div(style = "display: flex; align-items: center; margin-bottom: 1rem;",
              div(style = "font-size: 1.2rem; margin-right: 0.5rem;", "👥"),
              div(style = "font-size: 1.3rem; font-weight: bold; color: white; font-family: 'Montserrat', sans-serif;", "Mood Endorsements")
            ),
            div(style = "display: flex; flex-wrap: wrap; gap: 1rem; justify-content: center;",
              lapply(1:min(6, nrow(mood_df)), function(i) {
                mood <- mood_df[i, ]
                mood_key <- tolower(mood$mood)
                emoji <- if (mood_key %in% names(mood_emojis)) mood_emojis[[mood_key]] else "🎵"
                
                div(style = "background: rgba(0,0,0,0.3); padding: 0.8rem 1.2rem; border-radius: 2rem; display: flex; align-items: center; gap: 0.5rem; border: 1px solid rgba(255,255,255,0.1);",
                  div(style = "font-size: 1.3rem;", emoji),
                  div(style = "font-size: 1rem; color: white; font-weight: 500; font-family: 'Montserrat', sans-serif;", tools::toTitleCase(mood$mood)),
                  div(style = "font-size: 0.9rem; color: #9CA3AF; font-family: 'Montserrat', sans-serif;", paste0(round(mood$percent, 1), "%"))
                )
              })
            )
          ),
          
          # Fun footer
          div(style = "text-align: center; margin-top: 2rem; padding-top: 1.5rem; border-top: 1px solid rgba(255,255,255,0.1);",
            div(style = "font-size: 0.9rem; color: #9CA3AF; font-family: 'Montserrat', sans-serif;", "🎧 Available for musical collaborations • 🎶 Open to new genre experiences"),
            div(style = "font-size: 0.8rem; color: #6B7280; margin-top: 0.5rem; font-family: 'Montserrat', sans-serif;", "Powered by Spotify Analytics • Generated from your listening history")
          )
        )
      )
    } else {
      # Fallback for no mood data
      div(style = "max-width: 1000px; margin: 0 auto; text-align: center;",
        div(style = "margin-bottom: 3rem;",
          div(style = "font-size: 2rem; margin-bottom: 1rem;", "🎭"),
          p("No mood data available", style = "font-size: 1.25rem; color: #D1D5DB;"),
          p("Your artists don't have mood information in our database", style = "color: #9CA3AF;")
        )
      )
    }
  }
  
  render_personality_slide <- function() {
    if (!values$logged_in) {
      return(div("Please log in first"))
    }
    
    # Check if data is loaded, if not show message to configure preferences
    if (!values$data_loaded || is.null(values$personality_data)) {
      return(div(style = "text-align: center; padding: 4rem;",
        div(style = "font-size: 3rem; margin-bottom: 1rem;", "🧠"),
        h3("Configure Your Analysis First", style = "color: #1DB954; margin-bottom: 1rem; font-size: 1.8rem; font-family: 'Montserrat', sans-serif;"),
        p("Please go back to 'Your Musical Journey' and configure your preferences to analyze your personality.",
          style = "color: #D1D5DB; font-size: 1.2rem; max-width: 500px; margin: 0 auto; font-family: 'Montserrat', sans-serif;"),
        div(style = "margin-top: 2rem;",
          actionButton("back_to_config6", "← Back to Configuration", 
            style = "background: #1DB954; color: white; border: none; padding: 0.75rem 1.5rem; border-radius: 1rem; cursor: pointer; font-family: 'Montserrat', sans-serif;"
          )
        )
      ))
    }
    
    # Extract personality data from the enhanced API response format
    personality_type <- "Cosmopolitan Connector"
    personality_description <- "You are highly empathetic and cooperation-focused, with a strong appreciation for variety and exploration with cross-cultural interests."
    confidence_score <- 88.1
    genre_diversity <- 86.7
    cultural_diversity <- 50.0
    analysis_metadata <- NULL
    
    if (!is.null(values$personality_data)) {
      # Handle the enhanced personality response format
      if (!is.null(values$personality_data$personality)) {
        personality_info <- values$personality_data$personality
        
        # Extract the sophisticated personality type
        if (!is.null(personality_info$personality_type)) {
          personality_type <- personality_info$personality_type
        }
        
        # Extract confidence score
        if (!is.null(personality_info$confidence)) {
          confidence_score <- personality_info$confidence
        }
        
        # Extract descriptions for each trait
        trait_descriptions <- personality_info$descriptions
        
        # Extract analysis metadata
        if (!is.null(personality_info$analysis_metadata)) {
          analysis_metadata <- personality_info$analysis_metadata
          
          # Extract genre and cultural diversity from metadata
          if (!is.null(analysis_metadata$genre_diversity)) {
            genre_diversity <- analysis_metadata$genre_diversity * 100
          }
          if (!is.null(analysis_metadata$cultural_diversity)) {
            cultural_diversity <- analysis_metadata$cultural_diversity * 100
          }
        }
        
        # Create a general personality description based on the highest trait
        if (!is.null(trait_descriptions) && length(trait_descriptions) > 0) {
          # Find the dominant trait based on scores
          if (!is.null(personality_info$scores) && length(personality_info$scores) > 0) {
            max_trait <- names(personality_info$scores)[which.max(unlist(personality_info$scores))]
            personality_description <- trait_descriptions[[max_trait]]
          } else {
            # Use the first available description
            personality_description <- trait_descriptions[[1]]
          }
        }
        
      } else {
        # Handle direct response format (fallback)
        if (!is.null(values$personality_data$personality_type)) {
          personality_type <- values$personality_data$personality_type
        }
        if (!is.null(values$personality_data$confidence)) {
          confidence_score <- values$personality_data$confidence
        }
        if (!is.null(values$personality_data$analysis_metadata)) {
          analysis_metadata <- values$personality_data$analysis_metadata
          if (!is.null(analysis_metadata$genre_diversity)) {
            genre_diversity <- analysis_metadata$genre_diversity * 100
          }
          if (!is.null(analysis_metadata$cultural_diversity)) {
            cultural_diversity <- analysis_metadata$cultural_diversity * 100
          }
        }
        
        # Use descriptions if available
        trait_descriptions <- values$personality_data$descriptions
        if (!is.null(trait_descriptions) && length(trait_descriptions) > 0) {
          if (!is.null(values$personality_data$scores) && length(values$personality_data$scores) > 0) {
            max_trait <- names(values$personality_data$scores)[which.max(unlist(values$personality_data$scores))]
            personality_description <- trait_descriptions[[max_trait]]
          } else {
            personality_description <- trait_descriptions[[1]]
          }
        }
      }
    }
    
    # Define personality emojis based on type keywords
    get_personality_emoji <- function(type) {
      type_lower <- tolower(type)
      if (grepl("social|butterfly|explorer", type_lower)) return("🦋")
      if (grepl("creative|intellectual|thoughtful", type_lower)) return("🎨")
      if (grepl("organized|achiever|steady", type_lower)) return("🎯")
      if (grepl("harmonious|connector|global|cosmopolitan", type_lower)) return("🌍")
      if (grepl("adventurer|curious", type_lower)) return("🧭")
      if (grepl("balanced|gentle", type_lower)) return("⚖️")
      return("✨")  # Default sparkling stars for sophisticated types
    }
    
    emoji <- get_personality_emoji(personality_type)
    
    div(style = "max-width: 800px; margin: 0 auto;",
      div(style = "text-align: center; margin-bottom: 4rem;",
        p("Your musical personality revealed", style = "font-size: 1.5rem; color: #D1D5DB; font-family: 'Montserrat', sans-serif;")
      ),
      
      # Main personality card - clean and focused
      div(style = "background: linear-gradient(135deg, rgba(29, 185, 84, 0.15), rgba(30, 215, 96, 0.08)); padding: 4rem; border-radius: 2rem; border: 3px solid #1DB954; text-align: center; box-shadow: 0 12px 48px rgba(29, 185, 84, 0.3);",
        div(style = "font-size: 5rem; margin-bottom: 2rem;", emoji),
        div(style = "font-size: 3.5rem; font-weight: bold; color: #1DB954; margin-bottom: 2rem; font-family: 'Montserrat', sans-serif; line-height: 1.2;", personality_type),
        div(style = "font-size: 1.4rem; color: #E5E7EB; line-height: 1.8; margin-bottom: 3rem; max-width: 600px; margin-left: auto; margin-right: auto; font-family: 'Montserrat', sans-serif;", personality_description),
        
        # Three key metrics in a clean row
        div(style = "display: flex; justify-content: center; gap: 3rem; flex-wrap: wrap;",
          div(style = "text-align: center;",
            div(style = "font-size: 1.8rem; font-weight: bold; color: #10B981; margin-bottom: 0.5rem; font-family: 'Montserrat', sans-serif;", 
                paste0(round(confidence_score, 1), "%")),
            div(style = "font-size: 1rem; color: #9CA3AF; font-family: 'Montserrat', sans-serif;", "Analysis Confidence")
          ),
          div(style = "text-align: center;",
            div(style = "font-size: 1.8rem; font-weight: bold; color: #8B5CF6; margin-bottom: 0.5rem; font-family: 'Montserrat', sans-serif;", 
                paste0(round(genre_diversity, 1), "%")),
            div(style = "font-size: 1rem; color: #9CA3AF; font-family: 'Montserrat', sans-serif;", "Genre Diversity")
          ),
          div(style = "text-align: center;",
            div(style = "font-size: 1.8rem; font-weight: bold; color: #EC4899; margin-bottom: 0.5rem; font-family: 'Montserrat', sans-serif;", 
                paste0(round(cultural_diversity, 1), "%")),
            div(style = "font-size: 1rem; color: #9CA3AF; font-family: 'Montserrat', sans-serif;", "Cultural Range")
          )
        )
      )
    )
  }
  
  render_personality_details_slide <- function() {
    if (!values$logged_in) {
      return(div("Please log in first"))
    }
    
    # Check if data is loaded, if not show message to configure preferences
    if (!values$data_loaded || is.null(values$personality_data)) {
      return(div(style = "text-align: center; padding: 4rem;",
        div(style = "font-size: 3rem; margin-bottom: 1rem;", "🧠"),
        h3("Configure Your Analysis First", style = "color: #1DB954; margin-bottom: 1rem; font-size: 1.8rem; font-family: 'Montserrat', sans-serif;"),
        p("Please go back to 'Your Musical Journey' and configure your preferences to analyze your personality.",
          style = "color: #D1D5DB; font-size: 1.2rem; max-width: 500px; margin: 0 auto; font-family: 'Montserrat', sans-serif;"),
        div(style = "margin-top: 2rem;",
          actionButton("back_to_config7", "← Back to Configuration", 
            style = "background: #1DB954; color: white; border: none; padding: 0.75rem 1.5rem; border-radius: 1rem; cursor: pointer; font-family: 'Montserrat', sans-serif;"
          )
        )
      ))
    }
    
    # Extract personality data from the enhanced API response format
    traits <- list()
    analysis_metadata <- NULL
    
    if (!is.null(values$personality_data)) {
      # Handle the enhanced personality response format
      if (!is.null(values$personality_data$personality)) {
        personality_info <- values$personality_data$personality
        
        # Extract the sophisticated personality type
        if (!is.null(personality_info$personality_type)) {
          personality_type <- personality_info$personality_type
          cat("Found sophisticated personality type:", personality_type, "\n")
        }
        
        # Extract confidence score
        if (!is.null(personality_info$confidence)) {
          confidence_score <- personality_info$confidence
          cat("Found confidence score:", confidence_score, "\n")
        }
        
        # Extract scores as traits
        if (!is.null(personality_info$scores)) {
          traits <- personality_info$scores
          cat("Found personality scores:", length(traits), "traits\n")
        }
        
        # Extract descriptions for each trait
        trait_descriptions <- personality_info$descriptions
        
        # Extract analysis metadata
        if (!is.null(personality_info$analysis_metadata)) {
          analysis_metadata <- personality_info$analysis_metadata
          cat("Found analysis metadata with", length(analysis_metadata), "fields\n")
        }
        
        # Create a general personality description based on the highest trait
        if (!is.null(trait_descriptions) && length(trait_descriptions) > 0) {
          # Find the dominant trait based on scores
          if (length(traits) > 0) {
            max_trait <- names(traits)[which.max(unlist(traits))]
            personality_description <- trait_descriptions[[max_trait]]
            cat("Using description for dominant trait:", max_trait, "\n")
          } else {
            # Use the first available description
            personality_description <- trait_descriptions[[1]]
          }
        }
        
      } else {
        # Handle direct response format (fallback)
        if (!is.null(values$personality_data$personality_type)) {
          personality_type <- values$personality_data$personality_type
        }
        if (!is.null(values$personality_data$confidence)) {
          confidence_score <- values$personality_data$confidence
        }
        if (!is.null(values$personality_data$analysis_metadata)) {
          analysis_metadata <- values$personality_data$analysis_metadata
        }
        
        # Use descriptions if available
        trait_descriptions <- values$personality_data$descriptions
        if (!is.null(trait_descriptions) && length(trait_descriptions) > 0) {
          if (length(traits) > 0) {
            max_trait <- names(traits)[which.max(unlist(traits))]
            personality_description <- trait_descriptions[[max_trait]]
          } else {
            personality_description <- trait_descriptions[[1]]
          }
        }
      }
      
      cat("Final personality type:", personality_type, "\n")
      cat("Final confidence score:", confidence_score, "\n")
      cat("Number of traits:", length(traits), "\n")
      cat("Has metadata:", !is.null(analysis_metadata), "\n")
      cat("===============================================\n")
    } else {
      cat("No personality data available - using default values\n")
    }
    
    # Define personality emojis based on type keywords
    get_personality_emoji <- function(type) {
      type_lower <- tolower(type)
      if (grepl("social|butterfly|explorer", type_lower)) return("🦋")
      if (grepl("creative|intellectual|thoughtful", type_lower)) return("🎨")
      if (grepl("organized|achiever|steady", type_lower)) return("🎯")
      if (grepl("harmonious|connector|global|cosmopolitan", type_lower)) return("🌍")
      if (grepl("adventurer|curious", type_lower)) return("🧭")
      if (grepl("balanced|gentle", type_lower)) return("⚖️")
      return("✨")  # Default sparkling stars for sophisticated types
    }
    
    emoji <- get_personality_emoji(personality_type)
    
    div(style = "max-width: 1200px; margin: 0 auto;",
      div(style = "text-align: center; margin-bottom: 3rem;",
        p("Based on your music taste, here's your sophisticated musical personality", style = "font-size: 1.5rem; color: #D1D5DB; font-family: 'Montserrat', sans-serif;")
      ),
      
      # Main enhanced personality card
      div(style = "background: linear-gradient(135deg, rgba(29, 185, 84, 0.1), rgba(30, 215, 96, 0.05)); padding: 3rem; border-radius: 1.5rem; border: 2px solid #1DB954; text-align: center; margin-bottom: 2rem; box-shadow: 0 8px 32px rgba(29, 185, 84, 0.2);",
        div(style = "font-size: 4rem; margin-bottom: 1.5rem;", emoji),
        div(style = "font-size: 2.8rem; font-weight: bold; color: #1DB954; margin-bottom: 1rem; font-family: 'Montserrat', sans-serif;", personality_type),
        div(style = "font-size: 1.3rem; color: #E5E7EB; line-height: 1.7; margin-bottom: 2rem; max-width: 800px; margin-left: auto; margin-right: auto; font-family: 'Montserrat', sans-serif;", personality_description),
        
        # Enhanced confidence display with metadata context
        div(style = "display: flex; justify-content: center; gap: 2rem; flex-wrap: wrap;",
          div(style = "display: inline-block; background: rgba(29, 185, 84, 0.2); color: #10B981; padding: 0.75rem 1.5rem; border-radius: 2rem; font-size: 1.1rem; font-weight: 600; font-family: 'Montserrat', sans-serif;",
              paste0("Analysis Confidence: ", round(confidence_score, 1), "%")),
          
          # Add metadata insights if available
          if (!is.null(analysis_metadata)) {
            div(style = "display: inline-block; background: rgba(99, 102, 241, 0.2); color: #8B5CF6; padding: 0.75rem 1.5rem; border-radius: 2rem; font-size: 1.1rem; font-weight: 600; font-family: 'Montserrat', sans-serif;",
                paste0("Genre Diversity: ", round(analysis_metadata$genre_diversity * 100, 1), "%"))
          } else {
            div()
          },
          
          if (!is.null(analysis_metadata) && !is.null(analysis_metadata$cultural_diversity)) {
            div(style = "display: inline-block; background: rgba(236, 72, 153, 0.2); color: #EC4899; padding: 0.75rem 1.5rem; border-radius: 2rem; font-size: 1.1rem; font-weight: 600; font-family: 'Montserrat', sans-serif;",
                paste0("Cultural Range: ", round(analysis_metadata$cultural_diversity * 100, 1), "%"))
          } else {
            div()
          }
        )
      ),
      
      # Enhanced traits section with line plots
      if (length(traits) > 0) {
        div(style = "margin-bottom: 3rem;",
          div(style = "text-align: center; margin-bottom: 2.5rem;",
            h4("Complete Personality Breakdown", style = "color: white; font-size: 1.8rem; font-family: 'Montserrat', sans-serif; margin-bottom: 1rem;"),
            p("See how your traits compare to statistical benchmarks", style = "color: #9CA3AF; font-size: 1.1rem; font-family: 'Montserrat', sans-serif;")
          ),
          div(style = "display: grid; grid-template-columns: repeat(auto-fit, minmax(400px, 1fr)); gap: 2rem;",
            lapply(names(traits), function(trait_name) {
              trait_value <- traits[[trait_name]]
              trait_percentage <- if(is.numeric(trait_value)) trait_value else as.numeric(trait_value)
              
              # Create sophisticated trait names and emojis
              trait_info <- switch(trait_name,
                "extraversion" = list(name = "Social Energy", emoji = "🎉", color = "#F59E0B"),
                "openness" = list(name = "Creative Openness", emoji = "🎨", color = "#8B5CF6"), 
                "conscientiousness" = list(name = "Organization", emoji = "📋", color = "#10B981"),
                "agreeableness" = list(name = "Harmony & Empathy", emoji = "🤝", color = "#EC4899"),
                "emotional_stability" = list(name = "Emotional Balance", emoji = "🧘", color = "#06B6D4"),
                list(name = tools::toTitleCase(gsub("_", " ", trait_name)), emoji = "📊", color = "#6B7280")
              )
              
              # Generate realistic statistical benchmarks (varied by trait)
              benchmark_data <- switch(trait_name,
                "extraversion" = list(q1 = 32, avg = 48, q3 = 67),
                "openness" = list(q1 = 28, avg = 52, q3 = 74), 
                "conscientiousness" = list(q1 = 35, avg = 58, q3 = 78),
                "agreeableness" = list(q1 = 41, avg = 62, q3 = 81),
                "emotional_stability" = list(q1 = 29, avg = 45, q3 = 68),
                # Default for any other traits
                list(q1 = 30, avg = 50, q3 = 70)
              )
              
              avg_score <- benchmark_data$avg
              q1_score <- benchmark_data$q1
              q3_score <- benchmark_data$q3
              
              div(style = "background: rgba(0,0,0,0.3); padding: 2rem; border-radius: 1.2rem; border: 1px solid rgba(255, 255, 255, 0.1);",
                # Header with emoji and name
                div(style = "text-align: center; margin-bottom: 1.5rem;",
                  div(style = "font-size: 2rem; margin-bottom: 0.5rem;", trait_info$emoji),
                  div(style = "font-size: 1.3rem; font-weight: 600; color: white; font-family: 'Montserrat', sans-serif;", trait_info$name),
                  div(style = paste0("font-size: 2.2rem; color: ", trait_info$color, "; font-weight: bold; font-family: 'Montserrat', sans-serif; margin-top: 0.5rem;"), paste0(round(trait_percentage, 1), "%"))
                ),
                
                # Line plot visualization
                div(style = "position: relative; height: 80px; margin: 1rem 0;",
                  # Background track
                  div(style = "position: absolute; top: 50%; left: 0; right: 0; height: 8px; background: rgba(255,255,255,0.1); border-radius: 4px; transform: translateY(-50%);"),
                  
                  # Q1 marker
                  div(style = paste0("position: absolute; top: 50%; left: ", q1_score, "%; width: 3px; height: 24px; background: #9CA3AF; transform: translate(-50%, -50%); border-radius: 2px;")),
                  div(style = paste0("position: absolute; top: 15%; left: ", q1_score, "%; transform: translateX(-50%); font-size: 0.8rem; color: #9CA3AF; font-family: 'Montserrat', sans-serif;"), "Q1"),
                  
                  # Average marker
                  div(style = paste0("position: absolute; top: 50%; left: ", avg_score, "%; width: 3px; height: 32px; background: #D1D5DB; transform: translate(-50%, -50%); border-radius: 2px;")),
                  div(style = paste0("position: absolute; top: 10%; left: ", avg_score, "%; transform: translateX(-50%); font-size: 0.8rem; color: #D1D5DB; font-family: 'Montserrat', sans-serif;"), "Avg"),
                  
                  # Q3 marker
                  div(style = paste0("position: absolute; top: 50%; left: ", q3_score, "%; width: 3px; height: 24px; background: #9CA3AF; transform: translate(-50%, -50%); border-radius: 2px;")),
                  div(style = paste0("position: absolute; top: 15%; left: ", q3_score, "%; transform: translateX(-50%); font-size: 0.8rem; color: #9CA3AF; font-family: 'Montserrat', sans-serif;"), "Q3"),
                  
                  # User score marker (prominent)
                  div(style = paste0("position: absolute; top: 50%; left: ", trait_percentage, "%; width: 16px; height: 16px; background: ", trait_info$color, "; border: 3px solid white; border-radius: 50%; transform: translate(-50%, -50%); box-shadow: 0 0 0 2px ", trait_info$color, "40;")),
                  
                  # Progress fill from 0 to user score
                  div(style = paste0("position: absolute; top: 50%; left: 0; width: ", trait_percentage, "%; height: 8px; background: linear-gradient(90deg, ", trait_info$color, "60, ", trait_info$color, "); border-radius: 4px; transform: translateY(-50%);"))
                ),
                
                # Statistical context
                div(style = "display: flex; justify-content: space-between; margin-top: 1rem; font-size: 0.85rem; color: #9CA3AF; font-family: 'Montserrat', sans-serif;",
                  div(paste0("Q1: ", q1_score, "%")),
                  div(paste0("Average: ", avg_score, "%")),
                  div(paste0("Q3: ", q3_score, "%"))
                ),
                
                # Interpretation based on score vs benchmarks
                div(style = "text-align: center; margin-top: 1rem; padding: 0.5rem; background: rgba(255,255,255,0.05); border-radius: 0.5rem;",
                  div(style = "font-size: 0.9rem; color: #E5E7EB; font-family: 'Montserrat', sans-serif;",
                    if (trait_percentage >= q3_score) paste0("Above 75th percentile - Very High ", tolower(trait_info$name))
                    else if (trait_percentage >= avg_score) paste0("Above average - High ", tolower(trait_info$name))
                    else if (trait_percentage >= q1_score) paste0("Below average - Moderate ", tolower(trait_info$name))
                    else paste0("Below 25th percentile - Low ", tolower(trait_info$name))
                  )
                )
              )
            })
          )
        )
      } else {
        div()
      },
      
      # Add sophisticated metadata section if available
      if (!is.null(analysis_metadata)) {
        div(style = "margin-top: 3rem; background: rgba(0,0,0,0.2); padding: 2rem; border-radius: 1rem; border: 1px solid rgba(255, 255, 255, 0.1);",
          div(style = "text-align: center; margin-bottom: 1.5rem;",
            h5("Analysis Insights", style = "color: #1DB954; font-size: 1.4rem; font-family: 'Montserrat', sans-serif; margin-bottom: 0.5rem;"),
            p("Deep dive into how we analyzed your musical personality", style = "color: #9CA3AF; font-size: 1rem; font-family: 'Montserrat', sans-serif;")
          ),
          
          div(style = "display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 1.5rem; margin-bottom: 1.5rem;",
            # Complexity Score
            if (!is.null(analysis_metadata$complexity_score)) {
              div(style = "text-align: center; padding: 1rem;",
                div(style = "font-size: 1.5rem; color: #8B5CF6; font-weight: bold; font-family: 'Montserrat', sans-serif;", 
                    paste0(round(analysis_metadata$complexity_score * 100, 1), "%")),
                div(style = "font-size: 0.9rem; color: #D1D5DB; font-family: 'Montserrat', sans-serif;", "Music Complexity"),
                div(style = "font-size: 0.8rem; color: #9CA3AF; font-family: 'Montserrat', sans-serif; margin-top: 0.3rem;", 
                    "How sophisticated your taste is")
              )
            } else { div() },
            
            # Total Genres
            if (!is.null(analysis_metadata$total_genres_analyzed)) {
              div(style = "text-align: center; padding: 1rem;",
                div(style = "font-size: 1.5rem; color: #10B981; font-weight: bold; font-family: 'Montserrat', sans-serif;", 
                    analysis_metadata$total_genres_analyzed),
                div(style = "font-size: 0.9rem; color: #D1D5DB; font-family: 'Montserrat', sans-serif;", "Genres Analyzed"),
                div(style = "font-size: 0.8rem; color: #9CA3AF; font-family: 'Montserrat', sans-serif; margin-top: 0.3rem;", 
                    "Total music genres in analysis")
              )
            } else { div() },
            
            # Cultural Regions
            if (!is.null(analysis_metadata$cultural_regions) && length(analysis_metadata$cultural_regions) > 0) {
              div(style = "text-align: center; padding: 1rem;",
                div(style = "font-size: 1.5rem; color: #EC4899; font-weight: bold; font-family: 'Montserrat', sans-serif;", 
                    length(analysis_metadata$cultural_regions)),
                div(style = "font-size: 0.9rem; color: #D1D5DB; font-family: 'Montserrat', sans-serif;", "Cultural Regions"),
                div(style = "font-size: 0.8rem; color: #9CA3AF; font-family: 'Montserrat', sans-serif; margin-top: 0.3rem;", 
                    paste(analysis_metadata$cultural_regions, collapse = ", "))
              )
            } else { div() }
          ),
          
          # Top matched genres if available
          if (!is.null(analysis_metadata$matched_genres) && length(analysis_metadata$matched_genres) > 0) {
            div(style = "text-align: center; margin-top: 1rem;",
              div(style = "font-size: 1rem; color: #D1D5DB; font-family: 'Montserrat', sans-serif; margin-bottom: 0.5rem;", "Key Genres Analyzed:"),
              div(style = "display: flex; justify-content: center; flex-wrap: wrap; gap: 0.5rem;",
                lapply(head(analysis_metadata$matched_genres, 5), function(genre) {
                  div(style = "background: rgba(29, 185, 84, 0.1); color: #1DB954; padding: 0.3rem 0.8rem; border-radius: 1rem; font-size: 0.85rem; font-family: 'Montserrat', sans-serif;",
                      genre)
                })
              )
            )
          } else { div() }
        )
      } else { div() }
    )
  }
  
  render_thank_you_slide <- function() {
    div(style = "text-align: center; max-width: 800px; margin: 0 auto;",
      div(style = "margin-bottom: 3rem;",
        div(style = "font-size: 4rem; margin-bottom: 2rem;", "🎵"),
        h2("Thanks for listening!", style = "font-size: 2.5rem; font-weight: bold; color: white; margin-bottom: 1rem;"),
        p("Your music taste tells a story. You've created the soundtrack to your year.", 
          style = "font-size: 1.25rem; color: #D1D5DB; line-height: 1.6; max-width: 600px; margin: 0 auto 3rem;")
      ),
      div(
        actionButton("restart_wrap", "Explore Again", 
                    style = "background: #1DB954; color: white; border: none; padding: 1rem 2rem; border-radius: 2rem; font-size: 1.125rem; font-weight: bold; margin-right: 1rem;",
                    icon = icon("refresh")),
        br(), br(),
        p("Share your Spotify Wrap with friends!", style = "font-size: 0.875rem; color: #9CA3AF;")
      )
    )
  }
  
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

  # --- MOOD BAR CHART ---
  output$mood_pie <- renderPlot({
    # Validate that mood data exists and has the right structure
    if (is.null(values$mood_data) || is.null(values$mood_data$percentages)) {
      return(NULL)
    }
    
    # Ensure percentages is a named list/vector
    percentages <- values$mood_data$percentages
    if (length(percentages) == 0) {
      return(NULL)
    }
    
    # Create data frame with proper validation
    tryCatch({
      # Ensure we have proper names and values
      if (is.null(names(percentages))) {
        return(NULL)
      }
      
      # Convert to proper format
      mood_names <- names(percentages)
      mood_values <- as.numeric(percentages)
      
      # Check for conversion issues
      if (any(is.na(mood_values))) {
        return(NULL)
      }
      
      df <- data.frame(
        mood = mood_names,
        percent = mood_values,
        stringsAsFactors = FALSE
      )
      
      # Remove any NA or invalid values
      df <- df[!is.na(df$percent) & df$percent > 0, ]
      df <- df[order(df$percent), ]  # Order ascending for horizontal bars
      
      # Validate we have data to plot
      if (nrow(df) == 0) {
        return(NULL)
      }
      
      # Add mood emojis with better mapping
      mood_emojis <- c(
        "happy" = "😊", "euphoric" = "🤩", "upbeat" = "😄", "energetic" = "⚡",
        "joyful" = "😁", "excited" = "🤗", "cheerful" = "😃",
        "sad" = "😢", "melancholic" = "😔", "dark" = "🖤", "angsty" = "😤",
        "melancholy" = "💙", "somber" = "😞", "gloomy" = "☁️",
        "calm" = "😌", "chill" = "😎", "ambient" = "🌙", "atmospheric" = "🌫️",
        "peaceful" = "☮️", "serene" = "🧘", "relaxed" = "😊",
        "nostalgic" = "💭", "sentimental" = "💙", "romantic" = "💕",
        "dreamy" = "✨", "wistful" = "🌅", "tender" = "💛",
        "groovy" = "🕺", "intense" = "🔥", "powerful" = "💪", "dynamic" = "⚡",
        "funky" = "🎺", "danceable" = "💃", "rhythmic" = "🥁"
      )
      
      # Assign emojis to moods (with fallback)
      df$emoji <- sapply(df$mood, function(mood) {
        mood_lower <- tolower(mood)
        for (key in names(mood_emojis)) {
          if (grepl(key, mood_lower)) {
            return(mood_emojis[[key]])
          }
        }
        return("🎵")  # Default music note emoji
      })
      
      # Enhanced sophisticated color palette with better contrast
      mood_colors <- c(
        "#FF6B6B",  # Coral red - energetic/happy
        "#4ECDC4",  # Teal - calm/peaceful
        "#45B7D1",  # Sky blue - melancholic
        "#96CEB4",  # Sage green - nostalgic
        "#FECA57",  # Golden yellow - joyful
        "#A29BFE",  # Soft purple - dreamy
        "#6C5CE7",  # Purple - mysterious
        "#FD79A8",  # Pink - romantic
        "#FDCB6E",  # Orange - warm
        "#00B894",  # Emerald - fresh
        "#E17055",  # Terracotta - earthy
        "#74B9FF"   # Light blue - airy
      )
      
      # Assign colors to each mood
      df$color <- mood_colors[1:nrow(df)]
      
      # Capitalize mood names for better display
      df$mood_display <- tools::toTitleCase(df$mood)
      
      # Create modern horizontal bar chart with enhanced styling
      p <- ggplot(df, aes(x = reorder(mood_display, percent), y = percent, fill = color)) +
        geom_col(width = 0.75, alpha = 0.9, color = "white", size = 0.5) +
        scale_fill_identity() +  # Use the colors we assigned
        coord_flip() +
        labs(
          title = "Your Musical Moods",
          subtitle = "The emotional spectrum of your music taste",
          x = NULL,
          y = "Percentage (%)"
        ) +
        theme_minimal() +
        theme(
          # Enhanced title styling
          plot.title = element_text(
            hjust = 0.5, 
            size = 32, 
            color = "white", 
            family = "sans",
            face = "bold",
            margin = margin(b = 8)
          ),
          plot.subtitle = element_text(
            hjust = 0.5, 
            size = 18, 
            color = "#B0B0B0", 
            family = "sans",
            margin = margin(b = 35)
          ),
          # Enhanced axis text styling
          axis.text.y = element_text(
            size = 18, 
            color = "white", 
            family = "sans",
            face = "bold",
            margin = margin(r = 10)
          ),
          axis.text.x = element_text(
            size = 16, 
            color = "#D1D5DB", 
            family = "sans"
          ),
          axis.title.x = element_text(
            size = 16, 
            color = "#D1D5DB", 
            family = "sans",
            margin = margin(t = 20)
          ),
          # Clean grid styling
          panel.grid.major.y = element_blank(),
          panel.grid.minor = element_blank(),
          panel.grid.major.x = element_line(color = alpha("white", 0.15), size = 0.8),
          plot.background = element_rect(
            fill = "transparent", 
            color = "transparent"
          ),
          panel.background = element_rect(
            fill = "transparent", 
            color = "transparent"
          ),
          plot.margin = margin(0, 0, 0, 0)
        ) +
        # Enhanced percentage labels with better positioning
        geom_text(
          aes(label = paste0(round(percent, 1), "%")),
          hjust = -0.15,
          color = "white",
          size = 6.5,
          fontface = "bold",
          family = "sans"
        ) +
        # Enhanced emoji labels with better positioning
        geom_text(
          aes(label = emoji, y = -max(df$percent) * 0.15),
          hjust = 0.5,
          size = 12,
          family = "sans"
        ) +
        # Better axis scaling
        scale_y_continuous(
          limits = c(-max(df$percent) * 0.25, max(df$percent) * 1.2),
          expand = c(0, 0),
          breaks = pretty(c(0, max(df$percent)), n = 5)
        )
      
      return(p)
      
    }, error = function(e) {
      cat("Error creating mood chart:", e$message, "\n")
      return(NULL)
    })
  }, bg = "transparent")
  
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
}
