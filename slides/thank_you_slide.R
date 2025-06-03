# Thank you slide renderer
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