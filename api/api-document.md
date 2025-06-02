## Overview
This Flask API interfaces with Spotify data to provide endpoints for retrieving and analyzing a user's Spotify listening history. It supports fetching user profiles, recently played tracks, top artists, top tracks, and saved tracks.

## Project Structure
The API is now organized into a modular structure:

```
api/
├── main.py              # Main application entry point
├── utils.py             # Common utility functions
├── routes/              # Route modules organized by functionality
│   ├── __init__.py      # Blueprint registration
│   ├── user.py          # User-related endpoints
│   └── analysis.py      # Data analysis endpoints
└── data/                # Data handling and storage
    └── get_data.py      # Spotify data fetching functions
```

## API Endpoints

### Base Endpoint
- `GET /` - Simple "Hello World" response to verify the API is running

### Authentication
- `POST, GET /login` - Authenticates with Spotify and initiates data collection sequence

### User Data Endpoints
- `GET /user/profile` - Retrieves user's Spotify profile information
  - Query params: `username`, `filename`
  
- `GET /user/recently_played` - Gets user's recently played tracks
  - Query params: `username`, `filename`, `limit` (default: 50)
  
- `GET /user/top_artists` - Retrieves user's top artists
  - Query params: `username`, `filename`, `time_range` (short_term, medium_term, long_term), `limit` (default: 50)
  
- `GET /user/top_tracks` - Gets user's top tracks
  - Query params: `username`, `filename`, `time_range` (short_term, medium_term, long_term), `limit` (default: 50)
  
- `GET /user/saved_tracks` - Retrieves user's saved/liked tracks
  - Query params: `username`, `filename`, `limit` (default: 50)

### Analytics Endpoints

- `GET /analysis/mood_distribution` - Provides mood distribution data suitable for pie charts based on recently played tracks
  - Query params: `username`, `filename`, `token`
  - Returns: JSON with labels, data counts, percentages, and total tracks for pie chart visualization
  - Example response:
    ```json
    {
      "labels": ["Happy", "Euphoric", "Sad", "Melancholic", "Energetic", "Calm", "Angsty", "Dark", "Nostalgic", "Groovy"],
      "data": [10, 5, 7, 3, 15, 8, 3, 2, 4, 6],
      "percentages": {
        "Happy": 15.87,
        "Euphoric": 7.93,
        "Sad": 11.11,
        "Melancholic": 4.76,
        "Energetic": 23.80,
        "Calm": 12.69,
        "Angsty": 4.76,
        "Dark": 3.17,
        "Nostalgic": 6.34,
        "Groovy": 9.52
      },
      "total_tracks": 63
    }
    ```

- `GET /analysis/popularity_score` - Calculates popularity score for a specific user based on their top tracks
  - Query params: `username`, `filename`, `time_range` (short_term, medium_term, long_term)
  - Returns: JSON with popularity metrics for that user
  - Example response:
    ```json
    {
      "username": "bnloh6i0ho8vorne47adabziz",
      "time_range": "medium_term",
      "average_popularity": 67.85,
      "weighted_average": 73.42,
      "min_popularity": 41,
      "max_popularity": 94,
      "track_count": 50
    }
    ```

- `GET /analysis/genre_distribution` - Provides distribution of music genres for pie chart visualization
  - Query params: `username`, `filename`, `time_range` (short_term, medium_term, long_term), `top_n` (default: 10)
  - Returns: JSON with labels, data counts, percentages for top genres
  - Example response:
    ```json
    {
      "labels": ["indie rock", "alt-pop", "dance pop", "electropop", "indie pop", "pop", "synth pop", "art pop", "chamber pop", "chillwave"],
      "data": [15, 12, 10, 8, 8, 7, 6, 5, 4, 3],
      "percentages": {
        "indie rock": 19.23,
        "alt-pop": 15.38,
        "dance pop": 12.82,
        "electropop": 10.26,
        "indie pop": 10.26,
        "pop": 8.97,
        "synth pop": 7.69,
        "art pop": 6.41,
        "chamber pop": 5.13,
        "chillwave": 3.85
      },
      "total_genres": 146,
      "unique_genres": 42,
      "time_range": "medium_term"
    }
    ```

- `GET /analysis/personality_prediction` - Predicts personality traits based on music genre preferences
  - Query params: `username`, `filename`, `time_range` (short_term, medium_term, long_term)
  - Returns: JSON with personality trait scores and descriptions
  - Example response:
    ```json
    {
      "username": "bnloh6i0ho8vorne47adabziz",
      "time_range": "medium_term",
      "top_genres": ["indie rock", "alt-pop", "dance pop", "electropop", "indie pop", "pop", "synth pop", "art pop", "chamber pop", "chillwave"],
      "personality": {
        "scores": {
          "openness": 65,
          "conscientiousness": 48,
          "extraversion": 62,
          "agreeableness": 63,
          "emotional_stability": 52
        },
        "descriptions": {
          "openness": "You are intellectually curious, creative, and open to new experiences. You likely appreciate art, beauty, and innovation.",
          "conscientiousness": "You have a balance between being organized and spontaneous. You can follow plans but also adapt when needed.",
          "extraversion": "You have a balance of social energy and need for solitude. You enjoy social interactions but also value your alone time.",
          "agreeableness": "You balance cooperation with self-assertion. You can be empathetic but also stand up for your own needs.",
          "emotional_stability": "You have a reasonable balance of emotional responsiveness and stability. You feel emotions but can manage them."
        }
      }
    }
    ```

## Helper Functions

### File Operations
- `verify_and_load_file(filename)` - Validates file existence and loads JSON data
- `get_from_file(filename, step)` - Extracts specific data section from JSON files

### Track Analysis
- `analyze_track_features(ids_param, token)` - Requests audio features from Spotify's API

## Mood Classification

The API includes a `classify_mood(features)` function that categorizes songs based on their audio features:

| Mood | Criteria |
|------|----------|
| Happy | High valence (>0.65), moderate-high energy (>0.55), major mode |
| Euphoric | Same as Happy with higher danceability (>0.7) |
| Sad | Low valence (<0.4), low energy (<0.45), minor mode or acoustic |
| Melancholic | Same as Sad with high acousticness (>0.7) |
| Energetic | Very high energy (>0.75) and high danceability (>0.65) |
| Intense | Very high energy (>0.75) with low valence (<0.4) |
| Upbeat | Very high energy (>0.75) with moderate-high valence |
| Calm | High acousticness (>0.65), low energy (<0.55), slow tempo (<100 BPM) |
| Ambient | Same as Calm with high instrumentalness (>0.5) |
| Angsty | Low valence (<0.4), high energy (>0.6), loud (>-8dB) |
| Dark | Very low valence (<0.3), minor mode, moderate energy |
| Sentimental | Moderate valence (0.4-0.6), low energy, acoustic elements |
| Nostalgic | Moderate valence (0.4-0.7), moderate acousticness, moderate energy |
| Groovy | Moderate danceability (>0.6), moderate energy (<0.6) |
| Atmospheric | Moderate energy with high instrumentalness |
| Chill | Default classification for songs that don't fit other categories |

## Personality Prediction

The API includes a personality prediction system based on the Big Five personality traits model:

1. **Openness to Experience**: Reflects preference for novelty, creativity, and intellectual curiosity vs conventionality
2. **Conscientiousness**: Reflects organization, responsibility, and planning vs spontaneity and flexibility
3. **Extraversion**: Reflects sociability, energy from social interaction vs preference for solitude and reflection
4. **Agreeableness**: Reflects empathy, cooperation, and harmony vs critical thinking and logic
5. **Emotional Stability**: Reflects calmness and resilience vs emotional sensitivity and reactivity

The genre-trait associations are based on research correlating music preferences with personality traits, with each genre having different weightings for each trait.

## Testing Endpoints

For testing purposes, you can use the following sample URLs with pre-existing data in the repository:

### Sample Test URLs

1. Test user profile:
   ```
   http://127.0.0.1:5000/user/profile?username=bnloh6i0ho8vorne47adabziz&filename=data/bnloh6i0ho8vorne47adabziz_spotify.json
   ```

2. Test recently played tracks:
   ```
   http://127.0.0.1:5000/user/recently_played?username=bnloh6i0ho8vorne47adabziz&filename=data/bnloh6i0ho8vorne47adabziz_spotify.json&limit=10
   ```

3. Test top artists:
   ```
   http://127.0.0.1:5000/user/top_artists?username=bnloh6i0ho8vorne47adabziz&filename=data/bnloh6i0ho8vorne47adabziz_spotify.json&time_range=short_term&limit=5
   ```

4. Test top tracks:
   ```
   http://127.0.0.1:5000/user/top_tracks?username=m36i6tkbyxen3w6euott3ufhi&filename=data/m36i6tkbyxen3w6euott3ufhi_spotify.json&time_range=medium_term
   ```

5. Test mood distribution:
   ```
   http://127.0.0.1:5000/analysis/mood_distribution?username=bnloh6i0ho8vorne47adabziz&filename=data/bnloh6i0ho8vorne47adabziz_spotify.json
   ```
   Note: You'll need to replace YOUR_SPOTIFY_TOKEN with a valid Spotify API token

6. Test user popularity score:
   ```
   http://127.0.0.1:5000/analysis/popularity_score?username=bnloh6i0ho8vorne47adabziz&filename=data/bnloh6i0ho8vorne47adabziz_spotify.json&time_range=medium_term
   ```

7. Test genre distribution:
   ```
   http://127.0.0.1:5000/analysis/genre_distribution?username=bnloh6i0ho8vorne47adabziz&filename=data/bnloh6i0ho8vorne47adabziz_spotify.json&time_range=medium_term&top_n=10
   ```

8. Test personality prediction:
   ```
   http://127.0.0.1:5000/analysis/personality_prediction?username=bnloh6i0ho8vorne47adabziz&filename=data/bnloh6i0ho8vorne47adabziz_spotify.json&time_range=medium_term
   ```

### Running the API Locally

To run the API locally for testing:

1. Install dependencies:
   ```
   pip install -r requirements.txt
   ```

2. Start the Flask server:
   ```
   python main.py
   ```

The API will be available at http://127.0.0.1:5000