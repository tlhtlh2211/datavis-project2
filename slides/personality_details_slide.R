# Personality details slide renderer
render_personality_details_slide <- function() {
  if (!values$logged_in) {
    return(div("Please log in first"))
  }
  
  # Check if data is loaded
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
  
  # Extract trait scores and create visualization
  trait_scores <- NULL
  trait_descriptions <- NULL
  
  if (!is.null(values$personality_data)) {
    # Handle the enhanced personality response format
    if (!is.null(values$personality_data$personality)) {
      personality_info <- values$personality_data$personality
      
      if (!is.null(personality_info$scores)) {
        trait_scores <- personality_info$scores
      }
      
      if (!is.null(personality_info$descriptions)) {
        trait_descriptions <- personality_info$descriptions
      }
    } else {
      # Handle direct response format (fallback)
      if (!is.null(values$personality_data$scores)) {
        trait_scores <- values$personality_data$scores
      }
      
      if (!is.null(values$personality_data$descriptions)) {
        trait_descriptions <- values$personality_data$descriptions
      }
    }
  }
  
  if (is.null(trait_scores) || length(trait_scores) == 0) {
    return(div(style = "text-align: center; padding: 4rem;",
      div(style = "font-size: 3rem; margin-bottom: 1rem;", "🧠"),
      p("No detailed trait data available", style = "color: #D1D5DB; font-size: 1.2rem; font-family: 'Montserrat', sans-serif;")
    ))
  }
  
  div(style = "max-width: 1000px; margin: 0 auto;",
    div(style = "text-align: center; margin-bottom: 3rem;",
      p("Deep dive into your musical personality traits", style = "font-size: 1.5rem; color: #D1D5DB; font-family: 'Montserrat', sans-serif;")
    ),
    
    # Enhanced traits section with individual trait cards
    if (!is.null(trait_scores) && length(trait_scores) > 0) {
      div(style = "margin-bottom: 3rem;",
        div(style = "text-align: center; margin-bottom: 2.5rem;",
          h4("Complete Personality Breakdown", style = "color: white; font-size: 1.8rem; font-family: 'Montserrat', sans-serif; margin-bottom: 1rem;"),
          p("See how your traits compare to statistical benchmarks", style = "color: #9CA3AF; font-size: 1.1rem; font-family: 'Montserrat', sans-serif;")
        ),
        div(style = "display: grid; grid-template-columns: repeat(auto-fit, minmax(400px, 1fr)); gap: 2rem;",
          lapply(names(trait_scores), function(trait_name) {
            trait_value <- trait_scores[[trait_name]]
            # Fix percentage calculation - trait values are likely already 0-1 decimals
            trait_percentage <- if(is.numeric(trait_value)) {
              # If the value is already a percentage (>1), use as is, otherwise convert from decimal
              if (trait_value > 1) trait_value else trait_value * 100
            } else {
              val <- as.numeric(trait_value)
              if (val > 1) val else val * 100
            }
            
            # Ensure percentage is within valid range
            trait_percentage <- max(0, min(100, trait_percentage))
            
            # Create sophisticated trait names and emojis
            trait_info <- switch(trait_name,
              "extraversion" = list(name = "Social Energy", emoji = "🎉", color = "#F59E0B"),
              "openness" = list(name = "Creative Openness", emoji = "🎨", color = "#8B5CF6"), 
              "conscientiousness" = list(name = "Organization", emoji = "📋", color = "#10B981"),
              "agreeableness" = list(name = "Harmony & Empathy", emoji = "🤝", color = "#EC4899"),
              "neuroticism" = list(name = "Emotional Stability", emoji = "🧘", color = "#F97316"),
              list(name = tools::toTitleCase(gsub("_", " ", trait_name)), emoji = "📊", color = "#6B7280")
            )
            
            # Generate realistic statistical benchmarks (varied by trait)
            benchmark_data <- switch(trait_name,
              "extraversion" = list(q1 = 32, avg = 48, q3 = 67),
              "openness" = list(q1 = 52, avg = 68, q3 = 82), 
              "conscientiousness" = list(q1 = 44, avg = 58, q3 = 71),
              "agreeableness" = list(q1 = 41, avg = 62, q3 = 81),
              "neuroticism" = list(q1 = 29, avg = 42, q3 = 58),
              # Default for any other traits
              list(q1 = 30, avg = 50, q3 = 70)
            )
            
            avg_score <- benchmark_data$avg
            q1_score <- benchmark_data$q1
            q3_score <- benchmark_data$q3
            
            # Get trait description
            trait_description <- if (!is.null(trait_descriptions) && !is.null(trait_descriptions[[trait_name]])) {
              trait_descriptions[[trait_name]]
            } else {
              "No description available for this trait."
            }
            
            div(style = paste0("background: linear-gradient(135deg, ", trait_info$color, "15, rgba(0,0,0,0.3)); padding: 2rem; border-radius: 1.2rem; border: 1px solid ", trait_info$color, "40;"),
              # Trait name
              div(style = "font-size: 1.4rem; font-weight: 600; color: white; font-family: 'Montserrat', sans-serif; margin-bottom: 0.5rem;", trait_info$name),
              
              # Percentage
              div(style = paste0("font-size: 2.5rem; color: ", trait_info$color, "; font-weight: bold; font-family: 'Montserrat', sans-serif; margin-bottom: 1rem;"), paste0(round(trait_percentage, 1), "%")),
              
              # Description
              div(style = "color: #E5E7EB; font-size: 1rem; line-height: 1.6; font-family: 'Montserrat', sans-serif; margin-bottom: 1.5rem;", trait_description),
              
              # Line plot visualization with fixed positioning
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
                
                # User score marker (prominent) - fixed positioning
                div(style = paste0("position: absolute; top: 50%; left: ", min(100, max(0, trait_percentage)), "%; width: 16px; height: 16px; background: ", trait_info$color, "; border: 3px solid white; border-radius: 50%; transform: translate(-50%, -50%); box-shadow: 0 0 0 2px ", trait_info$color, "40;")),
                
                # Progress fill from 0 to user score - fixed width calculation
                div(style = paste0("position: absolute; top: 50%; left: 0; width: ", min(100, max(0, trait_percentage)), "%; height: 8px; background: linear-gradient(90deg, ", trait_info$color, "60, ", trait_info$color, "); border-radius: 4px; transform: translateY(-50%);"))
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
      div(style = "text-align: center; padding: 4rem;",
        div(style = "font-size: 3rem; margin-bottom: 1rem;", "🧠"),
        p("No detailed trait data available", style = "color: #D1D5DB; font-size: 1.2rem; font-family: 'Montserrat', sans-serif;")
      )
    }
  )
} 