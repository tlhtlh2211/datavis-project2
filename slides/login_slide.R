# Login slide renderer
render_login_slide <- function() {
  # Define available datasets locally since we can't access from server scope
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