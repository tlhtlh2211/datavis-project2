# Updated Project Proposal

## High-Level Goal

We aim to build an interactive Shiny app that generates a personalised "Spotify Wrapped"-style report using real Spotify listening data collected from students and online sources. The app will focus primarily on analysing and visualising users’ most-listened-to music genres, artists, and overall listening patterns.

## Goals and Motivation

Our project aims to create a customised version of Spotify Wrapped that reflects the most up-to-date, real listening habits of users. The main focus will be on the genres and artists they listen to most frequently.

The motivation for this project comes from feedback from friends and peers who felt that last year’s official Spotify Wrapped did not accurately represent their music tastes. Typically, Wrapped provides its 675 million users with an interactive display of genre stories, cultural comparisons, music-personality quizzes, and location-based taste matches. However, the 2024 Wrapped lacked much of the human-like creativity it was known for, instead displaying basic lists of artists and songs (often with inaccuracies) and an AI-generated podcast. By applying the visualisation techniques we have learned in the Data Visualization course and developing our skills further, we hope to create a more precise and satisfying experience for music listeners.

## Method to Create Shiny App

1. Create a Spotify developer account  
2. Create and register an app to get API keys  
   - Obtain Client ID (Username) and Client Secret (Password) from our apps (used for API authentication).  
3. Use R packages in R Studio to connect to API  
4. Retrieve the listening data from our user accounts (not Spotify developer account)  
5. Create Shiny Application including the following features/interfaces using Samantha and Hai’s data as examples:
   - General theme with consistent colour palette and font
   - User’s top 5 songs  
     - Song name, artist, album cover, and play count  
   - User’s top 5 artists  
     - Artist name, image, genre tags  
   - User’s top 5 albums  
     - Album title, cover art, release year, and top track from that album  
   - Lineplot of listening hours per day  
     - Average listens by hour  
   - Heatmap of listening hours per month with trendline  
     - x-axis = months  
     - y-axis = total listening time per month  
   - User’s percentile or rank compared to other users regarding their top song  
   - Word cloud of lyrics from the song they listened to the most  
     - Colour words by emotion  
   - Pie chart of user’s most popular listening genre and personality prediction  

## Agenda

| Week | Task | Team Member(s) |
|------|------|----------------|
| 1 | Team meeting: Plan the project, set up GitHub, decide what features the Shiny app will have. | Hai, Samantha |
| 2 | Collect Spotify data from online sources, test using Spotify API, brainstorm the visualisations we plan to create, team meeting (10/05/2025), write feedback for other groups. | Hai, Samantha |
| 3 + 4 | Reflect on feedback on project proposal (ensure our project is better than other Spotify analysis services available), test whether our goal is achievable, edit our project proposal to be more specific and achievable, make the Shiny App. | Hai, Samantha |
| 5 | Finish the Shiny app; Samantha makes the presentation slides; Hai makes a short demo video; Show the app to friends and ask for feedback | Hai, Samantha |
