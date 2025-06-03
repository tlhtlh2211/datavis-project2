# Personality slide renderer
render_personality_slide <- function() {
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
    ),
    
    # Analysis metadata section
    if (!is.null(analysis_metadata)) {
      div(style = "margin-top: 3rem; background: rgba(0,0,0,0.3); padding: 2rem; border-radius: 1.5rem; border: 1px solid rgba(255,255,255,0.1);",
        h4("Analysis Details", style = "color: #1DB954; text-align: center; margin-bottom: 2rem; font-size: 1.5rem; font-family: 'Montserrat', sans-serif;"),
        
        # Metadata grid
        div(style = "display: grid; grid-template-columns: repeat(auto-fit, minmax(250px, 1fr)); gap: 1.5rem;",
          
          # Complexity Score
          div(style = "background: rgba(255,255,255,0.05); padding: 1.5rem; border-radius: 1rem; text-align: center;",
            div(style = "font-size: 2rem; margin-bottom: 0.5rem;", "🎵"),
            div(style = "font-size: 1.1rem; font-weight: bold; color: #F59E0B; margin-bottom: 0.5rem; font-family: 'Montserrat', sans-serif;", "Complexity Score"),
            div(style = "font-size: 1.8rem; font-weight: bold; color: white; margin-bottom: 0.5rem; font-family: 'Montserrat', sans-serif;", 
                if (!is.null(analysis_metadata$complexity_score)) paste0(round(analysis_metadata$complexity_score * 100, 1), "%") else "N/A"),
            div(style = "font-size: 0.9rem; color: #9CA3AF; font-family: 'Montserrat', sans-serif;", "Musical sophistication level")
          ),
          
          # Cultural Regions
          div(style = "background: rgba(255,255,255,0.05); padding: 1.5rem; border-radius: 1rem; text-align: center;",
            div(style = "font-size: 2rem; margin-bottom: 0.5rem;", "🌏"),
            div(style = "font-size: 1.1rem; font-weight: bold; color: #EC4899; margin-bottom: 0.5rem; font-family: 'Montserrat', sans-serif;", "Cultural Regions"),
            div(style = "font-size: 1rem; color: white; margin-bottom: 0.5rem; font-family: 'Montserrat', sans-serif; line-height: 1.4;", 
                if (!is.null(analysis_metadata$cultural_regions) && length(analysis_metadata$cultural_regions) > 0) {
                  # Safely convert to character and apply title case
                  regions <- as.character(analysis_metadata$cultural_regions)
                  regions <- regions[!is.na(regions) & regions != ""]
                  if (length(regions) > 0) {
                    paste(tools::toTitleCase(regions), collapse = ", ")
                  } else {
                    "Western"
                  }
                } else {
                  "Western"
                }),
            div(style = "font-size: 0.9rem; color: #9CA3AF; font-family: 'Montserrat', sans-serif;", "Musical cultural exposure")
          ),
          
          # Genre Analysis
          div(style = "background: rgba(255,255,255,0.05); padding: 1.5rem; border-radius: 1rem; text-align: center;",
            div(style = "font-size: 2rem; margin-bottom: 0.5rem;", "📊"),
            div(style = "font-size: 1.1rem; font-weight: bold; color: #8B5CF6; margin-bottom: 0.5rem; font-family: 'Montserrat', sans-serif;", "Analysis Scope"),
            div(style = "font-size: 1.8rem; font-weight: bold; color: white; margin-bottom: 0.5rem; font-family: 'Montserrat', sans-serif;", 
                if (!is.null(analysis_metadata$total_genres_analyzed)) analysis_metadata$total_genres_analyzed else "N/A"),
            div(style = "font-size: 0.9rem; color: #9CA3AF; font-family: 'Montserrat', sans-serif;", "Total genres analyzed")
          )
        ),
        
        # Top matched genres section
        if (!is.null(analysis_metadata$matched_genres) && length(analysis_metadata$matched_genres) > 0) {
          div(style = "margin-top: 2rem; text-align: center;",
            div(style = "font-size: 1.1rem; font-weight: bold; color: #10B981; margin-bottom: 1rem; font-family: 'Montserrat', sans-serif;", "Top Matched Genres"),
            div(style = "display: flex; justify-content: center; flex-wrap: wrap; gap: 0.5rem;",
              lapply(analysis_metadata$matched_genres, function(genre) {
                # Safely handle genre name conversion
                genre_name <- if (!is.null(genre) && !is.na(genre)) {
                  genre_char <- as.character(genre)
                  if (nchar(genre_char) > 0) {
                    tools::toTitleCase(gsub("_", " ", genre_char))
                  } else {
                    "Unknown"
                  }
                } else {
                  "Unknown"
                }
                
                div(style = "background: rgba(29, 185, 84, 0.2); color: #1DB954; padding: 0.5rem 1rem; border-radius: 1rem; font-size: 0.9rem; font-family: 'Montserrat', sans-serif; border: 1px solid rgba(29, 185, 84, 0.3);", 
                    genre_name)
              })
            )
          )
        } else NULL
      )
    } else NULL
  )
} 