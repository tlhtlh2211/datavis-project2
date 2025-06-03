# Welcome slide renderer
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