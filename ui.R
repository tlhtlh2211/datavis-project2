#
# This is the user-interface definition of a Shiny web application. You can
# run the application by clicking 'Run App' above.
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
library(plotly)

# Define UI for Spotify Wrapped application
fluidPage(
  # Include dependencies
  tags$head(
    tags$link(href = "https://fonts.googleapis.com/css2?family=Montserrat:wght@300;400;600;700;800&display=swap", rel = "stylesheet"),
    tags$link(rel = "stylesheet", href = "https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0/css/all.min.css"),
    
    # CSS Styling to match the React design
    tags$style(HTML("
    body {
      background: linear-gradient(to bottom right, #14532d, #000000, #14532d);
      color: white;
      font-family: 'Montserrat', sans-serif;
      margin: 0;
      padding: 0;
      min-height: 100vh;
      overflow-x: hidden;
    }

    .main-container {
      min-height: 100vh;
      display: flex;
      flex-direction: column;
      padding: 2rem;
    }

    .progress-section {
      margin-bottom: 1.5rem;
    }

    .progress-info {
      display: flex;
      justify-content: space-between;
      align-items: center;
      margin-bottom: 0.5rem;
    }

    .progress-text {
      font-size: 0.875rem;
      color: #9CA3AF;
    }

    .progress-bar {
      width: 100%;
      height: 8px;
      background: rgba(255, 255, 255, 0.1);
      border-radius: 4px;
      overflow: hidden;
    }

    .progress-fill {
      height: 100%;
      background: linear-gradient(to right, #1DB954, #1ed760);
      border-radius: 4px;
      transition: width 0.3s ease;
    }

    .slide-container {
      flex: 1;
      display: flex;
      flex-direction: column;
      justify-content: center;
      max-width: 6xl;
      margin: 0 auto;
      width: 100%;
    }

    .slide-title {
      text-align: center;
      margin-bottom: 2rem;
    }

    .slide-title h1 {
      font-size: 3rem;
      font-weight: 700;
      background: linear-gradient(to right, #10B981, #1DB954);
      -webkit-background-clip: text;
      -webkit-text-fill-color: transparent;
      background-clip: text;
      margin-bottom: 1rem;
    }

    .slide-content {
      flex: 1;
      display: flex;
      align-items: center;
      justify-content: center;
    }

    .navigation {
      display: flex;
      justify-content: space-between;
      align-items: center;
      margin-top: 2rem;
    }

    .nav-button {
      background: rgba(29, 185, 84, 0.2);
      border: 1px solid rgba(29, 185, 84, 0.3);
      color: #10B981;
      padding: 0.75rem 1.5rem;
      border-radius: 0.5rem;
      cursor: pointer;
      transition: all 0.3s ease;
      font-weight: 600;
    }

    .nav-button:hover {
      background: rgba(29, 185, 84, 0.3);
      border-color: #1DB954;
    }

    .nav-button:disabled {
      opacity: 0.5;
      cursor: not-allowed;
    }

    .nav-button.primary {
      background: #1DB954;
      color: white;
    }

    .nav-button.primary:hover {
      background: #159f46;
    }

    .slide-dots {
      display: flex;
      gap: 0.5rem;
    }

    .slide-dot {
      width: 12px;
      height: 12px;
      border-radius: 50%;
      background: #4B5563;
      cursor: pointer;
      transition: all 0.3s ease;
    }

    .slide-dot.active {
      background: #1DB954;
    }

    .slide-dot:hover {
      background: #6B7280;
    }

    .slide-dot.active:hover {
      background: #1DB954;
    }

    .card {
      background: rgba(0, 0, 0, 0.3);
      backdrop-filter: blur(10px);
      border: 1px solid rgba(29, 185, 84, 0.2);
      border-radius: 0.75rem;
      padding: 1.5rem;
      margin: 0.5rem 0;
      transition: all 0.3s ease;
    }

    .card:hover {
      border-color: rgba(29, 185, 84, 0.4);
    }

    .track-item, .artist-item {
      display: flex;
      align-items: center;
      gap: 1rem;
      padding: 1rem;
      background: rgba(0, 0, 0, 0.3);
      border: 1px solid rgba(29, 185, 84, 0.2);
      border-radius: 0.5rem;
      margin: 0.5rem 0;
      transition: all 0.3s ease;
    }

    .track-item:hover, .artist-item:hover {
      border-color: rgba(29, 185, 84, 0.4);
    }

    .rank-badge {
      width: 3rem;
      height: 3rem;
      background: linear-gradient(to bottom right, #10B981, #1DB954);
      border-radius: 50%;
      display: flex;
      align-items: center;
      justify-content: center;
      font-weight: bold;
      font-size: 1.25rem;
    }

    .profile-avatar {
      width: 8rem;
      height: 8rem;
      border-radius: 50%;
      border: 4px solid #1DB954;
      margin: 0 auto 1rem;
    }

    .stat-grid {
      display: grid;
      grid-template-columns: repeat(3, 1fr);
      gap: 1.5rem;
      max-width: 28rem;
      margin: 0 auto;
    }

    .stat-card {
      text-align: center;
      padding: 1rem;
      background: rgba(0, 0, 0, 0.3);
      border-radius: 0.5rem;
    }

    .stat-value {
      font-size: 1.5rem;
      font-weight: bold;
      color: #10B981;
    }

    .stat-label {
      font-size: 0.875rem;
      color: #9CA3AF;
    }

    .percentage-circle {
      width: 150px;
      height: 150px;
      border-radius: 50%;
      background: conic-gradient(#1DB954 0deg 130deg, rgba(255,255,255,0.1) 130deg 360deg);
      display: flex;
      align-items: center;
      justify-content: center;
      margin: 0 auto 2rem;
      position: relative;
    }

    .percentage-circle::before {
      content: '';
      width: 120px;
      height: 120px;
      background: rgba(0, 0, 0, 0.8);
      border-radius: 50%;
      position: absolute;
    }

    .percentage-text {
      position: relative;
      z-index: 1;
      font-size: 2rem;
      font-weight: bold;
      color: #1DB954;
    }

    .login-section {
      text-align: center;
      padding: 3rem;
    }

    .login-button {
      background: #1DB954;
      color: white;
      border: none;
      padding: 1rem 2rem;
      border-radius: 2rem;
      font-size: 1.125rem;
      font-weight: bold;
      cursor: pointer;
      transition: all 0.3s ease;
      margin-top: 2rem;
    }

    .login-button:hover {
      background: #159f46;
      transform: translateY(-2px);
    }

    .hidden {
      display: none !important;
    }

    .genre-bar {
      display: flex;
      align-items: center;
      gap: 0.75rem;
      padding: 0.75rem;
      background: rgba(0, 0, 0, 0.3);
      border-radius: 0.5rem;
      margin: 0.25rem 0;
    }

    .genre-color {
      width: 1rem;
      height: 1rem;
      border-radius: 50%;
    }

    .genre-name {
      flex: 1;
      font-weight: 500;
    }

    .genre-percentage {
      color: #10B981;
      font-weight: 600;
    }

    .personality-trait {
      margin: 1rem 0;
      padding: 1rem;
      background: rgba(0, 0, 0, 0.3);
      border-radius: 0.5rem;
    }

    .trait-header {
      display: flex;
      justify-content: space-between;
      align-items: center;
      margin-bottom: 0.75rem;
    }

    .trait-name {
      font-weight: 600;
      font-size: 1.125rem;
    }

    .trait-score {
      color: #10B981;
      font-weight: bold;
      font-size: 1.25rem;
    }

    .trait-bar {
      width: 100%;
      height: 12px;
      background: rgba(255, 255, 255, 0.1);
      border-radius: 6px;
      overflow: hidden;
      margin-bottom: 0.75rem;
    }

    .trait-fill {
      height: 100%;
      background: linear-gradient(to right, #1DB954, #10B981);
      border-radius: 6px;
      transition: width 0.5s ease;
    }

    .trait-description {
      font-size: 0.875rem;
      color: #D1D5DB;
      line-height: 1.4;
    }
    "))
  ),

  # Main container
  div(class = "main-container",
    # Progress section
    div(class = "progress-section",
      div(class = "progress-info",
        span(class = "progress-text", textOutput("slide_progress", inline = TRUE)),
        span(class = "progress-text", textOutput("slide_title", inline = TRUE))
      ),
      div(class = "progress-bar",
        div(class = "progress-fill", style = "width: 0%", id = "progress-fill")
      )
    ),
    
    # Slide container
    div(class = "slide-container",
      div(class = "slide-title",
        h1(textOutput("current_slide_title"))
      ),
      div(class = "slide-content",
        uiOutput("current_slide_content")
      )
    ),
    
    # Navigation
    div(class = "navigation",
      actionButton("prev_slide", "Previous", class = "nav-button", icon = icon("chevron-left")),
      div(class = "slide-dots", id = "slide-dots"),
      actionButton("next_slide", "Next", class = "nav-button primary", icon = icon("chevron-right"))
    )
  ),
  
  # JavaScript for slide functionality
  tags$script(HTML("
    function updateProgress(current, total) {
      const percentage = (current / total) * 100;
      document.getElementById('progress-fill').style.width = percentage + '%';
    }
    
    function updateDots(current, total) {
      const dotsContainer = document.getElementById('slide-dots');
      dotsContainer.innerHTML = '';
      for (let i = 0; i < total; i++) {
        const dot = document.createElement('div');
        dot.className = 'slide-dot' + (i === current - 1 ? ' active' : '');
        dot.onclick = function() {
          Shiny.setInputValue('goto_slide', i + 1, {priority: 'event'});
        };
        dotsContainer.appendChild(dot);
      }
    }
    
    Shiny.addCustomMessageHandler('updateSlideProgress', function(data) {
      updateProgress(data.current, data.total);
      updateDots(data.current, data.total);
    });
  "))
)
