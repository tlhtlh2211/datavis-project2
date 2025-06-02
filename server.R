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
    list(id = "top-tracks", title = "Your Top Tracks"),
    list(id = "top-artists", title = "Your Top Artists"),
    list(id = "popularity", title = "Your Music Taste"),
    list(id = "genres", title = "Your Genre Universe"),
    list(id = "moods", title = "Your Musical Moods"),
    list(id = "personality", title = "Your Musical Personality"),
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
      # COMMENTED OUT: Original API call for later restoration
      # response <- GET("http://127.0.0.1:5000/login")
      # 
      # if (status_code(response) == 200) {
      #   raw_content <- content(response, "text", encoding = "UTF-8")
      #   api_response <- fromJSON(raw_content, simplifyVector = FALSE)
      #   
      #   if ("json_file" %in% names(api_response) && "username" %in% names(api_response)) {
      #     values$username <- api_response$username
      #     values$filename <- api_response$json_file
      #     values$logged_in <- TRUE
      #     
      #     # Fetch user profile only
      #     fetchUserProfile()
      #     
      #     showNotification("Successfully logged in to Spotify!", type = "message")
      #   } else {
      #     showNotification("Login failed - unexpected response format", type = "error")
      #   }
      # } else {
      #   showNotification(paste("Login failed - status code:", status_code(response)), type = "error")
      # }
      
      # TEMPORARY: Direct file loading for login setup only
      cat("Setting up login credentials...\n")
      
      # Set login status and basic credentials
      values$logged_in <- TRUE
      values$username <- "m36i6tkbyxen3w6euott3ufhi"
      values$filename <- "m36i6tkbyxen3w6euott3ufhi_spotify.json"
      
      # Load only user profile data for the welcome slide
      json_file_path <- "api/data/m36i6tkbyxen3w6euott3ufhi_spotify.json"
      
      if (file.exists(json_file_path)) {
        cat("Reading user profile from file for setup...\n")
        spotify_data <- fromJSON(json_file_path, simplifyVector = FALSE)
        
        # Load only user profile data
        for (item in spotify_data) {
          if (item$step == "current_user") {
            values$current_user <- item$data
            cat("Loaded user profile data for welcome slide\n")
            break
          }
        }
        
        showNotification("Successfully logged in! Please configure your preferences.", type = "message")
      } else {
        showNotification("Data file not found!", type = "error")
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
        values$current_user <- fromJSON(content(response, "text", encoding = "UTF-8"))
        cat("User profile fetched from API\n")
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
        values$mood_data <- fromJSON(content(response, "text", encoding = "UTF-8"))
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
        values$popularity_data <- fromJSON(content(response, "text", encoding = "UTF-8"))
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
        values$genre_data <- fromJSON(content(response, "text", encoding = "UTF-8"))
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
      response <- GET(url)
      
      if (status_code(response) == 200) {
        values$personality_data <- fromJSON(content(response, "text", encoding = "UTF-8"))
        cat("Personality prediction data fetched\n")
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
      "top-tracks" = render_top_tracks_slide(),
      "top-artists" = render_top_artists_slide(),
      "popularity" = render_popularity_slide(),
      "genres" = render_genres_slide(),
      "moods" = render_moods_slide(),
      "personality" = render_personality_slide(),
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
          actionButton("back_to_config", "← Back to Configuration", 
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
        p("These were your most played songs this year", style = "font-size: 1.5rem; color: #D1D5DB; font-family: 'Montserrat', sans-serif;")
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
        p("The artists who soundtracked your year", style = "font-size: 1.5rem; color: #D1D5DB; font-family: 'Montserrat', sans-serif;")
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
        p("The genres that defined your year", style = "font-size: 1.5rem; color: #D1D5DB; font-family: 'Montserrat', sans-serif;")
      ),
      # Just the genre list - no chart
      div(
        div(style = "text-align: center; margin-bottom: 2rem;",
          div(style = "font-size: 2.5rem; font-weight: bold; color: #10B981; margin-bottom: 0.5rem; font-family: 'Montserrat', sans-serif;", 
              if(length(sorted_genres) > 0) names(sorted_genres)[1] else "No genres"),
          div("Your #1 genre", style = "color: #9CA3AF; font-size: 1.2rem; font-family: 'Montserrat', sans-serif;")
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
    
    if (length(mood_data) == 0) {
      # Fallback for no mood data
      return(div(style = "max-width: 1000px; margin: 0 auto; text-align: center;",
        div(style = "margin-bottom: 3rem;",
          p("Based on your music, here's your emotional soundtrack", style = "font-size: 1.25rem; color: #D1D5DB;")
        ),
        div(style = "height: 300px; background: rgba(0,0,0,0.3); border-radius: 0.75rem; display: flex; align-items: center; justify-content: center; border: 1px solid rgba(29, 185, 84, 0.2); margin-bottom: 2rem;",
          div(style = "text-align: center;",
            div(style = "font-size: 3rem; margin-bottom: 1rem;", "🎭"),
            div("Mood Analysis Coming Soon", style = "color: #9CA3AF; font-size: 1.125rem;"),
            div("We're working on analyzing the emotional content of your music", style = "color: #6B7280; font-size: 0.875rem; margin-top: 0.5rem;")
          )
        )
      ))
    }
    
    # Just show the chart - no mood cards
    div(style = "max-width: 1000px; margin: 0 auto;",
      div(style = "text-align: center; margin-bottom: 3rem;",
        p("Based on your music, here's your emotional soundtrack", style = "font-size: 1.5rem; color: #D1D5DB; font-family: 'Montserrat', sans-serif;")
      ),
      div(style = "display: flex; justify-content: center;",
        plotlyOutput("mood_pie", height = "700px", width = "100%")
      )
    )
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
    
    # Extract personality data from the actual API response format
    personality_type <- "Balanced"
    personality_description <- "Your musical taste reflects a well-rounded personality with balanced traits."
    confidence_score <- 85  # Default confidence since API doesn't provide it
    traits <- list()
    
    if (!is.null(values$personality_data)) {
      cat("=== PERSONALITY API RESPONSE DEBUG ===\n")
      cat("Personality data available fields:", paste(names(values$personality_data), collapse = ", "), "\n")
      
      # Extract personality information based on actual API response structure
      if (!is.null(values$personality_data$personality)) {
        personality_info <- values$personality_data$personality
        
        # Extract scores as traits
        if (!is.null(personality_info$scores)) {
          traits <- personality_info$scores
          cat("Found personality scores:", length(traits), "traits\n")
          
          # Calculate a general personality type based on highest scores
          scores <- personality_info$scores
          if (length(scores) > 0) {
            # Find the highest scoring trait
            max_trait <- names(scores)[which.max(unlist(scores))]
            max_score <- max(unlist(scores))
            
            # Create a personality type based on dominant trait
            personality_type <- switch(max_trait,
              "extraversion" = "Social Butterfly",
              "openness" = "Creative Explorer", 
              "conscientiousness" = "Organized Achiever",
              "agreeableness" = "Harmonious Connector",
              "emotional_stability" = "Steady Minded",
              "Balanced Listener"
            )
            
            # Get description for the dominant trait
            if (!is.null(personality_info$descriptions) && !is.null(personality_info$descriptions[[max_trait]])) {
              personality_description <- personality_info$descriptions[[max_trait]]
            }
            
            # Calculate confidence based on how high the dominant score is
            confidence_score <- max_score
          }
        }
        
        # If no specific dominant trait, use a general description
        if (!is.null(personality_info$descriptions)) {
          # Create a combined description from all traits
          all_descriptions <- personality_info$descriptions
          if (length(all_descriptions) > 0) {
            # Use the first description as primary, or create a summary
            personality_description <- "Based on your music preferences, you show a balanced personality with varied traits that complement each other well."
          }
        }
      }
      
      cat("Personality type:", personality_type, "\n")
      cat("Confidence score:", confidence_score, "\n")
      cat("Number of traits:", length(traits), "\n")
      cat("=====================================\n")
    }
    
    # Define personality emojis and colors based on type
    personality_emojis <- list(
      "Social Butterfly" = "🦋",
      "Creative Explorer" = "🎨", 
      "Organized Achiever" = "🎯",
      "Harmonious Connector" = "🤝",
      "Steady Minded" = "🧘",
      "Balanced Listener" = "⚖️"
    )
    
    emoji <- personality_emojis[[personality_type]] %||% "🧠"
    
    div(style = "max-width: 1000px; margin: 0 auto;",
      div(style = "text-align: center; margin-bottom: 3rem;",
        p("Based on your music taste, here's your musical personality", style = "font-size: 1.5rem; color: #D1D5DB; font-family: 'Montserrat', sans-serif;")
      ),
      
      # Main personality card
      div(style = "background: rgba(0,0,0,0.3); padding: 3rem; border-radius: 1.5rem; border: 2px solid #1DB954; text-align: center; margin-bottom: 2rem;",
        div(style = "font-size: 4rem; margin-bottom: 1.5rem;", emoji),
        div(style = "font-size: 2.5rem; font-weight: bold; color: #1DB954; margin-bottom: 1rem; font-family: 'Montserrat', sans-serif;", personality_type),
        div(style = "font-size: 1.2rem; color: #D1D5DB; line-height: 1.6; margin-bottom: 2rem; font-family: 'Montserrat', sans-serif;", personality_description),
        
        # Confidence score
        div(style = "display: inline-block; background: rgba(29, 185, 84, 0.2); color: #10B981; padding: 0.75rem 1.5rem; border-radius: 2rem; font-size: 1.1rem; font-weight: 600; font-family: 'Montserrat', sans-serif;",
            paste0("Confidence: ", round(confidence_score, 1), "%"))
      ),
      
      # Traits section (if available)
      if (length(traits) > 0) {
        div(style = "margin-top: 2rem;",
          div(style = "text-align: center; margin-bottom: 2rem;",
            h4("Your Musical Personality Traits", style = "color: white; font-size: 1.5rem; font-family: 'Montserrat', sans-serif;")
          ),
          div(style = "display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 1rem;",
            lapply(names(traits), function(trait_name) {
              trait_value <- traits[[trait_name]]
              trait_percentage <- if(is.numeric(trait_value)) trait_value else as.numeric(trait_value)
              
              # Create better trait names for display
              display_name <- switch(trait_name,
                "extraversion" = "Social Energy",
                "openness" = "Creativity", 
                "conscientiousness" = "Organization",
                "agreeableness" = "Harmony",
                "emotional_stability" = "Emotional Balance",
                tools::toTitleCase(gsub("_", " ", trait_name))
              )
              
              div(style = "background: rgba(0,0,0,0.2); padding: 1.5rem; border-radius: 1rem; border: 1px solid rgba(29, 185, 84, 0.3); text-align: center;",
                div(style = "font-size: 1.2rem; font-weight: 600; color: white; margin-bottom: 0.5rem; font-family: 'Montserrat', sans-serif;", display_name),
                div(style = "font-size: 1.5rem; color: #1DB954; font-weight: bold; font-family: 'Montserrat', sans-serif;", paste0(round(trait_percentage, 1), "%"))
              )
            })
          )
        )
      } else {
        div()
      }
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

  # --- MOOD PIE CHART ---
  output$mood_pie <- renderPlotly({
    req(values$mood_data$percentages)
    df <- data.frame(
      mood = names(values$mood_data$percentages),
      percent = as.numeric(values$mood_data$percentages)
    )
    df <- df[order(-df$percent), ]
    shiny::validate(need(nrow(df) > 0, "No mood data to plot"))
    
    # Define mood colors for the pie chart
    mood_colors <- c("#1DB954", "#1ed760", "#FFD700", "#FF6B35", "#4A90E2", "#7ED321", "#D0021B", "#F5A623", "#9013FE")
    
    plot_ly(
      df,
      labels = ~mood,
      values = ~percent,
      type = 'pie',
      textinfo = 'label+percent',
      insidetextorientation = 'radial',
      marker = list(colors = mood_colors[1:nrow(df)]),
      textfont = list(family = "Montserrat, sans-serif", color = "white", size = 18)
    ) %>%
      layout(
        title = list(
          text = "Your Musical Moods",
          font = list(family = "Montserrat, sans-serif", color = "white", size = 28)
        ),
        font = list(family = "Montserrat, sans-serif", color = "white", size = 16),
        paper_bgcolor = "rgba(0,0,0,0)",  # Transparent background
        plot_bgcolor = "rgba(0,0,0,0)",   # Transparent plot area
        showlegend = TRUE,
        legend = list(
          font = list(family = "Montserrat, sans-serif", color = "white", size = 16),
          bgcolor = "rgba(0,0,0,0)"
        ),
        margin = list(l = 20, r = 20, t = 80, b = 20)
      )
  })
}
