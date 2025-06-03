# Moods slide renderer
render_moods_slide <- function() {
  if (!values$logged_in) {
    return(div("Please log in first"))
  }
  
  # Check if data is loaded
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
    # Check different possible field names
    if (!is.null(values$mood_data$moods)) {
      mood_data <- values$mood_data$moods
    } else if (!is.null(values$mood_data$mood_distribution)) {
      mood_data <- values$mood_data$mood_distribution
    } else if (!is.null(values$mood_data$percentages)) {
      mood_data <- values$mood_data$percentages
    } else if (!is.null(values$mood_data$data)) {
      mood_data <- values$mood_data$data
    } else {
      # Try to use the mood_data directly if it's a list of moods
      if (is.list(values$mood_data) && length(values$mood_data) > 0) {
        mood_names <- names(values$mood_data)
        mood_like_names <- c("happy", "sad", "energetic", "calm", "angry", "romantic", "nostalgic", "excited")
        if (any(tolower(mood_names) %in% mood_like_names)) {
          mood_data <- values$mood_data
        }
      }
    }
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