# Spotify Data Visualization - Your 2024 Musical Journey

A comprehensive Spotify data visualization application built with R Shiny and Python Flask that creates personalized music analytics including top tracks, artists, genres, mood analysis, and personality predictions based on your listening habits.

## Features

- **🎵 Top Tracks & Artists**: Visualize your most played songs and favorite artists
- **📊 Music Taste Analysis**: Discover how mainstream or unique your music preferences are
- **🎭 Mood Distribution**: See the emotional landscape of your music through interactive charts
- **🎼 Genre Universe**: Explore your musical genre preferences with beautiful visualizations
- **🧠 Musical Personality**: Get AI-powered personality insights based on your listening patterns
- **📱 Modern UI**: Beautiful, responsive interface with Spotify's signature green styling
- **🎯 Dual Login Options**: Connect your Spotify account or explore demo datasets

## Project Structure

```
datavis-project2/
├── api/                    # Python Flask backend
│   ├── data/              # Spotify data storage
│   ├── main.py            # Main Flask application
│   ├── requirements.txt   # Python dependencies
│   └── .env              # Environment variables (you need to create this)
├── server.R              # Shiny server logic
├── ui.R                  # Shiny user interface
├── www/                  # Static assets (CSS, images)
└── README.md            # This file
```

## Setup Instructions

### Prerequisites

- **R** (version 4.0+) with required packages
- **Python** (version 3.9+)
- **Spotify Account** for personal data analysis

### 1. Backend Setup (Python Flask API)

#### Step 1: Create Environment File

Create a new `.env` file in the `api/` folder:

```bash
cd api
touch .env
```

Add the following content to the `.env` file:

```env
SPOTIFY_CLIENT_ID=your_spotify_client_id
SPOTIFY_CLIENT_SECRET=your_spotify_client_secret
SPOTIFY_ACCESS_TOKEN=your_access_token
SPOTIFY_REFRESH_TOKEN=your_refresh_token
```

#### Step 2: Get Spotify Tokens

**Quick Method using Receiptify:**

1. Go to [Receiptify](https://receiptify.herokuapp.com/)
2. Click "Log in with Spotify" and authorize the application
3. After login, check the URL in your browser address bar
4. The URL will have this structure:
   ```
   https://receiptify.herokuapp.com/#client=spotify&access_token={token}&refresh_token={refresh_token}
   ```
5. Copy the `access_token` and `refresh_token` values from the URL
6. Paste them into your `.env` file

⚠️ **Important**: Access tokens expire after 1 hour. You'll need to refresh them periodically.

#### Step 3: Install Python Dependencies

```bash
# Activate virtual environment
source venv/bin/activate

# Navigate to API directory
cd api

# Install required packages
pip install -r requirements.txt
```

#### Step 4: Run the Backend

```bash
# Make sure you're in the api directory and virtual environment is activated
python3 main.py
```

The Flask API will start running on `http://127.0.0.1:5000`

### 2. Shiny App Setup

#### Step 1: Install Required R Packages

Open R or RStudio and install the required packages:

```r
# Install required packages
install.packages(c(
  "shiny",
  "jsonlite", 
  "bslib",
  "scales",
  "wordcloud2",
  "tm",
  "stringr",
  "ggplot2",
  "httr",
  "plotly"
))
```

#### Step 2: Run the Shiny Application

**Option A: Using RStudio**
1. Open the project in RStudio
2. Open either `server.R` or `ui.R`
3. Click the "Run App" button

**Option B: Using R Console**
```r
# Navigate to project directory
setwd("/path/to/datavis-project2")

# Run the app
shiny::runApp()
```

**Option C: Using Terminal**
```bash
# Navigate to project directory
cd /path/to/datavis-project2

# Run with R command
Rscript -e "shiny::runApp(host='127.0.0.1', port=3838, launch.browser=TRUE)"
```

The Shiny app will be available at `http://127.0.0.1:3838`

## Usage Guide

### Option 1: Login with Your Spotify Account

1. Click "Login with Spotify" on the welcome page
2. The app will fetch your personal Spotify data via the API
3. Configure your analysis preferences (number of tracks/artists, time period)
4. Click "Start My Analysis" to begin your musical journey

### Option 2: Explore Demo Datasets

1. Choose "Select This Dataset" under one of the available demo profiles:
   - **User Dataset 1 (Bò)**: K-pop, hyperpop, art pop enthusiast
   - **User Dataset 2**: Alternative music taste profile
2. Configure analysis preferences
3. Explore the pre-loaded musical personality

### Navigation

The app includes 9 slides in your musical journey:
1. **Welcome** - Login and configuration
2. **Top Tracks** - Your most played songs
3. **Top Artists** - Your favorite artists  
4. **Popularity** - Music taste analysis
5. **Genres** - Your genre universe
6. **Moods** - Musical mood distribution
7. **Personality** - AI-powered personality insights
8. **Thank You** - Journey summary

## API Endpoints

The Flask backend provides several analysis endpoints:

- `GET /user/profile` - User profile information
- `GET /user/top_tracks` - Top tracks analysis
- `GET /user/top_artists` - Top artists analysis  
- `GET /analysis/popularity_score` - Music popularity analysis
- `GET /analysis/mood_distribution` - Mood analysis
- `GET /analysis/genre_distribution` - Genre breakdown
- `GET /analysis/personality_prediction` - Personality insights

## Troubleshooting

### Common Issues

**1. "Address already in use" error**
```bash
# Kill processes on ports 3838 or 5000
sudo lsof -ti:3838 | xargs kill -9
sudo lsof -ti:5000 | xargs kill -9
```

**2. Token expired error**
- Get new tokens from [Receiptify](https://receiptify.herokuapp.com/)
- Update your `.env` file with new tokens
- Restart the Flask API

**3. Missing R packages**
```r
# Install any missing packages
install.packages("package_name")
```

**4. Python virtual environment issues**
```bash
# Recreate virtual environment
python3 -m venv venv
source venv/bin/activate
pip install -r api/requirements.txt
```

### Port Configuration

- **Flask API**: Default port 5000
- **Shiny App**: Default port 3838

To use different ports:

```bash
# Flask API (modify main.py)
app.run(host='127.0.0.1', port=5001)

# Shiny App
Rscript -e "shiny::runApp(port=3839)"
```

## Contributing

Feel free to contribute to this project by:
1. Reporting bugs or suggesting features
2. Improving the UI/UX design
3. Adding new analysis features
4. Enhancing the personality prediction algorithms

## Inspiration

This project was inspired by popular music visualization tools like [Receiptify](https://receiptify.herokuapp.com/) and Spotify's own year-end wrapped feature, with added personality analysis and mood detection capabilities.

## License

This project is for educational and personal use. Please respect Spotify's API terms of service when using this application.