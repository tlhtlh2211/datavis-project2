from flask import Blueprint, jsonify, request as flask_request
import requests
from collections import Counter
from utils import get_from_file, classify_mood, predict_personality
from dotenv import load_dotenv
import os

load_dotenv()
token_env = os.getenv('token')

# Create a Blueprint for analysis routes
analysis_bp = Blueprint('analysis', __name__)

# Mood distribution endpoint
@analysis_bp.route("/mood_distribution", methods=["GET"])
def get_mood_distribution():
    username = flask_request.args.get('username')
    filename = flask_request.args.get('filename')
    
    if not username or not filename:
        return jsonify({"error": "Missing username, filename or token"}), 400
        
    # Get recently played tracks
    recently_played = get_from_file(f"data/{filename}", "recently_played")
    
    if recently_played is None:
        return jsonify({"error": "Recently played data not found or file missing"}), 404
    
    # Process all recently played tracks
    filtered_tracks = []
    
    for item in recently_played.get('items', []):
        track = item.get('track', {})
        played_at = item.get('played_at')
        
        if not played_at:
            continue
                
        track_id = track.get('id')
        if track_id:
            filtered_tracks.append({
                'id': track_id, 
                'name': track.get('name'),
                'played_at': played_at
            })
    
    # Get audio features for the tracks
    track_ids = [track['id'] for track in filtered_tracks]
    all_moods = []
    
    # Process tracks in batches of 50 (Spotify API limit)
    for i in range(0, len(track_ids), 50):
        batch_ids = track_ids[i:i+50]
        ids_param = ','.join(batch_ids)
        
        # Call Spotify API to get audio features
        url = "https://api.spotify.com/v1/audio-features"
        params = {"ids": ids_param}
        headers = {
            "authorization": f"Bearer {token_env}",
            "user-agent": "Mozilla/5.0"
        }
        
        try:
            response = requests.get(url, params=params, headers=headers)
            response.raise_for_status()
            features_data = response.json()
            
            # Classify mood for each track
            for features in features_data.get('audio_features', []):
                if features:
                    mood = classify_mood(features)
                    all_moods.append(mood)
        except Exception as e:
            return jsonify({"error": f"Failed to get audio features: {str(e)}"}), 500
    
    # Count occurrences of each mood
    mood_counts = dict(Counter(all_moods))
    
    # Calculate percentages
    total_tracks = len(all_moods)
    mood_percentages = {
        mood: (count / total_tracks) * 100 
        for mood, count in mood_counts.items()
    }
    
    # Format for pie chart data
    result = {
        'labels': list(mood_counts.keys()),
        'data': list(mood_counts.values()),
        'percentages': mood_percentages,
        'total_tracks': total_tracks
    }
    
    return jsonify(result)

# Popularity score endpoint
@analysis_bp.route("/popularity_score", methods=["GET"])
def get_popularity_score():
    username = flask_request.args.get('username')
    filename = flask_request.args.get('filename')
    time_range = flask_request.args.get('time_range', 'medium_term')
    
    if not username or not filename:
        return jsonify({"error": "Missing username or filename"}), 400
        
    if time_range not in ['short_term', 'medium_term', 'long_term']:
        return jsonify({"error": "Invalid time_range"}), 400
    
    # Determine the correct step based on time_range
    step = f"top_tracks_{time_range.split('_')[0]}" if time_range != 'long_term' else "top_tracks_long"
    
    # Get top tracks for the specified time range
    top_tracks = get_from_file(f"data/{filename}", step)
    
    if top_tracks is None:
        return jsonify({"error": "Top tracks data not found or file missing"}), 404
    
    # Calculate average popularity
    total_popularity = 0
    track_count = 0
    weighted_popularity = 0
    
    track_items = top_tracks.get('items', [])
    
    # Calculate both simple average and weighted average
    for i, item in enumerate(track_items):
        popularity = item.get('popularity', 0)
        
        # Simple average
        total_popularity += popularity
        
        # Weighted average (top tracks have higher weight)
        position_weight = 1 - (i / len(track_items)) if track_items else 0
        weighted_popularity += popularity * position_weight
        
        track_count += 1
    
    # Calculate results
    if track_count > 0:
        average_popularity = total_popularity / track_count
        weighted_average = weighted_popularity / track_count
    else:
        average_popularity = 0
        weighted_average = 0
        
    # Get additional stats
    popularity_values = [item.get('popularity', 0) for item in track_items]
    min_popularity = min(popularity_values) if popularity_values else 0
    max_popularity = max(popularity_values) if popularity_values else 0
    
    result = {
        'username': username,
        'time_range': time_range,
        'average_popularity': round(average_popularity, 2),
        'weighted_average': round(weighted_average, 2),
        'min_popularity': min_popularity,
        'max_popularity': max_popularity,
        'track_count': track_count
    }
    
    return jsonify(result)

# Genre distribution endpoint
@analysis_bp.route("/genre_distribution", methods=["GET"])
def get_genre_distribution():
    username = flask_request.args.get('username')
    filename = flask_request.args.get('filename')
    time_range = flask_request.args.get('time_range', 'medium_term')
    top_n = int(flask_request.args.get('top_n', 10))  # Top N genres to return
    
    if not username or not filename:
        return jsonify({"error": "Missing username or filename"}), 400
        
    if time_range not in ['short_term', 'medium_term', 'long_term']:
        return jsonify({"error": "Invalid time_range"}), 400
    
    # Determine the correct step based on time_range
    step = f"top_artists_{time_range.split('_')[0]}" if time_range != 'long_term' else "top_artists_long"
    
    # Get top artists for the specified time range
    top_artists = get_from_file(f"data/{filename}", step)
    
    if top_artists is None:
        return jsonify({"error": "Top artists data not found or file missing"}), 404
    
    # Collect all genres from top artists
    all_genres = []
    artist_items = top_artists.get('items', [])
    
    # Apply weighting based on artist position
    for i, artist in enumerate(artist_items):
        position_weight = 1 - (i / len(artist_items)) if artist_items else 0
        # Higher ranked artists' genres get counted multiple times based on weight
        artist_genres = artist.get('genres', [])
        # Weight multiplier - convert position weight to integer multiplier (1-5)
        weight_multiplier = max(1, int(position_weight * 5))
        all_genres.extend(artist_genres * weight_multiplier)
    
    # Count genre occurrences
    genre_counts = Counter(all_genres)
    
    # Get top N genres
    top_genres = genre_counts.most_common(top_n)
    
    # Calculate percentages
    total_count = sum(count for _, count in top_genres)
    
    # Create result in pie chart format
    labels = [genre for genre, _ in top_genres]
    data = [count for _, count in top_genres]
    percentages = {genre: (count / total_count) * 100 for genre, count in top_genres}
    
    result = {
        'labels': labels,
        'data': data,
        'percentages': {k: round(v, 2) for k, v in percentages.items()},
        'total_genres': len(all_genres),
        'unique_genres': len(genre_counts),
        'time_range': time_range
    }
    
    return jsonify(result)

# Personality prediction endpoint
@analysis_bp.route("/personality_prediction", methods=["GET"])
def get_personality_prediction():
    username = flask_request.args.get('username')
    filename = flask_request.args.get('filename')
    time_range = flask_request.args.get('time_range', 'medium_term')
    
    if not username or not filename:
        return jsonify({"error": "Missing username or filename"}), 400
        
    if time_range not in ['short_term', 'medium_term', 'long_term']:
        return jsonify({"error": "Invalid time_range"}), 400
    
    # Get genre distribution data from top artists
    step = f"top_artists_{time_range.split('_')[0]}" if time_range != 'long_term' else "top_artists_long"
    top_artists = get_from_file(f"data/{filename}", step)
    
    if top_artists is None:
        return jsonify({"error": "Top artists data not found or file missing"}), 404
    
    # Get top tracks for audio features analysis
    track_step = f"top_tracks_{time_range.split('_')[0]}" if time_range != 'long_term' else "top_tracks_long"
    top_tracks = get_from_file(f"data/{filename}", track_step)
    
    # Collect all genres from top artists with weighting
    genre_counts = Counter()
    artist_items = top_artists.get('items', [])
    
    for i, artist in enumerate(artist_items):
        position_weight = 1 - (i / len(artist_items)) if artist_items else 0
        # Weight multiplier - convert position weight to integer multiplier (1-5)
        weight_multiplier = max(1, int(position_weight * 5))
        
        for genre in artist.get('genres', []):
            genre_counts[genre] += weight_multiplier
    
    # Get top genres with their counts
    top_genres = genre_counts.most_common(15)  # Use top 15 genres for prediction
    
    # Fetch audio features for top tracks
    audio_features = None
    track_popularity_data = None
    
    if top_tracks and 'items' in top_tracks:
        track_items = top_tracks['items'][:20]  # Analyze top 20 tracks max
        track_ids = [track['id'] for track in track_items if track.get('id')]
        
        # Extract track popularity data for additional analysis
        track_popularity_data = []
        for track in track_items:
            if track.get('id'):
                track_info = {
                    'id': track['id'],
                    'popularity': track.get('popularity', 0),
                    'duration_ms': track.get('duration_ms', 0),
                    'explicit': track.get('explicit', False),
                    'release_date': track.get('album', {}).get('release_date', ''),
                    'artist_followers': track.get('artists', [{}])[0].get('followers', {}).get('total', 0) if track.get('artists') else 0
                }
                track_popularity_data.append(track_info)
        
        if track_ids:
            # Join track IDs with commas for batch request
            ids_param = ','.join(track_ids)
            try:
                audio_features_response = analyze_track_features(ids_param)
                if isinstance(audio_features_response, dict) and 'audio_features' in audio_features_response:
                    audio_features = audio_features_response['audio_features']
                    # Filter out None values (tracks without features)
                    audio_features = [f for f in audio_features if f is not None]
            except Exception as e:
                print(f"Error fetching audio features: {e}")
                audio_features = None
    
    # Predict personality based on genres, audio features, and additional data
    personality = predict_personality(top_genres, audio_features, track_popularity_data)
    
    # Add the top genres to the response for reference
    result = {
        'username': username,
        'time_range': time_range,
        'top_genres': [genre for genre, _ in top_genres[:10]],  # Just include names of top 10
        'audio_features_count': len(audio_features) if audio_features else 0,
        'personality': personality
    }
    
    return jsonify(result)

# Helper function for track features analysis
def analyze_track_features(ids_param):
    if not ids_param:
        return jsonify({"error": "No track IDs provided"}), 400

    url = "https://api.spotify.com/v1/audio-features"
    params = {"ids": ids_param}
    headers = {
        "accept": "*/*",
        "accept-language": "vi-VN,vi;q=0.9,fr-FR;q=0.8,fr;q=0.7,en-US;q=0.6,en;q=0.5",
        "authorization": f"Bearer {token_env}",
        "origin": "https://receiptify.herokuapp.com",
        "priority": "u=1, i",
        "referer": "https://receiptify.herokuapp.com/",
        "sec-ch-ua": '"Google Chrome";v="135", "Not-A.Brand";v="8", "Chromium";v="135"',
        "sec-ch-ua-mobile": "?0",
        "sec-ch-ua-platform": '"macOS"',
        "sec-fetch-dest": "empty",
        "sec-fetch-mode": "cors",
        "sec-fetch-site": "cross-site",
        "user-agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/135.0.0.0 Safari/537.36"
    }
    
    response = requests.get(url, params=params, headers=headers)
    try:
        return response.json()
    except Exception as e:
        return {"error": str(e)}, 500