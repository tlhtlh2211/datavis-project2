from flask import Blueprint, jsonify, request as flask_request
import os
import json
from utils import get_from_file

# Create a Blueprint for user routes
user_bp = Blueprint('user', __name__)

# 1. Get current user profile
@user_bp.route("/profile", methods=["GET"])
def get_user_profile():
    username = flask_request.args.get('username')
    filename = flask_request.args.get('filename')
    if not username or not filename:
        return jsonify({"error": "Missing username or filename"}), 400
    result = get_from_file(f"data/{filename}", "current_user")
    if result is None:
        return jsonify({"error": "Data not found or file missing"}), 404
    return jsonify(result)

# 2. Recently played tracks (customizable limit)
@user_bp.route("/recently_played", methods=["GET"])
def get_recently_played():
    username = flask_request.args.get('username')
    filename = flask_request.args.get('filename')
    limit = int(flask_request.args.get('limit', 50))
    if not username or not filename:
        return jsonify({"error": "Missing username or filename"}), 400
    if not (1 <= limit <= 50):
        return jsonify({"error": "Limit must be between 1 and 50"}), 400
    result = get_from_file(f"data/{filename}", "recently_played")
    if result is None:
        return jsonify({"error": "Data not found or file missing"}), 404
    # result['items'] is the list of tracks
    result_copy = dict(result)
    # Filter out only the fields we want from each track
    filtered_items = []
    for item in result_copy.get('items', []):
        track = item.get('track', {})
        album_data = track.get('album', {})
        filtered_track = {
            'name': track.get('name'),
            'popularity': track.get('popularity'),
            'artists': [artist.get('name') for artist in track.get('artists', [])],
            'album': {
                'name': album_data.get('name'),
                'images': album_data.get('images', [])
            },
            'duration_ms': track.get('duration_ms'),
            'played_at': item.get('played_at')
        }
        filtered_items.append({'track': filtered_track})
    
    result_copy['items'] = filtered_items
    result_copy['items'] = result_copy.get('items', [])[:limit]
    return jsonify(result_copy)

# 3. Top artists (customizable term and limit)
@user_bp.route("/top_artists", methods=["GET"])
def get_top_artists():
    username = flask_request.args.get('username')
    filename = flask_request.args.get('filename')
    time_range = flask_request.args.get('time_range', 'short_term')
    limit = int(flask_request.args.get('limit', 50))
    if not username or not filename:
        return jsonify({"error": "Missing username or filename"}), 400
    if time_range not in ['short_term', 'medium_term', 'long_term']:
        return jsonify({"error": "Invalid time_range"}), 400
    if not (1 <= limit <= 50):
        return jsonify({"error": "Limit must be between 1 and 50"}), 400
    step = f"top_artists_{time_range.split('_')[0]}" if time_range != 'long_term' else "top_artists_long"
    result = get_from_file(f"data/{filename}", step)
    if result is None:
        return jsonify({"error": "Data not found or file missing"}), 404
    result_copy = dict(result)
    filtered_item = []
    for item in result_copy.get('items', []):
        filtered_artist = {
            'name': item.get('name'),
            'popularity': item.get('popularity'),
            'images': item.get('images'),
            'genres': item.get('genres'),
            'total_followers': item.get('followers').get('total')
        }
        filtered_item.append(filtered_artist)
    result_copy['items'] = filtered_item
    result_copy['items'] = result_copy.get('items', [])[:limit]
    return jsonify(result_copy)

# 4. Top tracks (customizable term and limit)
@user_bp.route("/top_tracks", methods=["GET"])
def get_top_tracks():
    username = flask_request.args.get('username')
    filename = flask_request.args.get('filename')
    time_range = flask_request.args.get('time_range', 'short_term')
    limit = int(flask_request.args.get('limit', 50))
    if not username or not filename:
        return jsonify({"error": "Missing username or filename"}), 400
    if time_range not in ['short_term', 'medium_term', 'long_term']:
        return jsonify({"error": "Invalid time_range"}), 400
    if not (1 <= limit <= 50):
        return jsonify({"error": "Limit must be between 1 and 50"}), 400
    step = f"top_tracks_{time_range.split('_')[0]}" if time_range != 'long_term' else "top_tracks_long"
    result = get_from_file(f"data/{filename}", step)
    if result is None:
        return jsonify({"error": "Data not found or file missing"}), 404
    result_copy = dict(result)
    filtered_items = []
    for item in result_copy.get('items', []):
        album_data = item.get('album', {})
        filtered_track = {
            'name': item.get('name'),
            'id': item.get('id'),
            'popularity': item.get('popularity'),
            'artists': [artist.get('name') for artist in item.get('artists', [])],
            'album': {
                'name': album_data.get('name'),
                'images': album_data.get('images', [])
            },
            'duration_ms': item.get('duration_ms'),
            'played_at': item.get('played_at')
        }
        filtered_items.append({'track': filtered_track})
    
    result_copy['items'] = filtered_items
    result_copy['items'] = result_copy.get('items', [])[:limit]
    return jsonify(result_copy)

# 5. Saved tracks (customizable limit)
@user_bp.route("/saved_tracks", methods=["GET"])
def get_saved_tracks():
    username = flask_request.args.get('username')
    filename = flask_request.args.get('filename')
    limit = int(flask_request.args.get('limit', 50))
    if not username or not filename:
        return jsonify({"error": "Missing username or filename"}), 400
    if not (1 <= limit <= 50):
        return jsonify({"error": "Limit must be between 1 and 50"}), 400
    result = get_from_file(f"data/{filename}", "saved_tracks")
    if result is None:
        return jsonify({"error": "Data not found or file missing"}), 404
    filtered_items = []
    result_copy = dict(result)
    for item in result_copy.get('items', []):
        track = item.get('track', {})
        album_data = track.get('album', {})
        filtered_track = {
            'name': track.get('name'),
            'id': track.get('id'),
            'popularity': track.get('popularity'),
            'artists': [artist.get('name') for artist in track.get('artists', [])],
            'album': {
                'name': album_data.get('name'),
                'images': album_data.get('images', [])
            },
            'duration_ms': track.get('duration_ms'),
            'played_at': item.get('played_at')
        }
        filtered_items.append({'track': filtered_track})
    
    result_copy['items'] = filtered_items
    result_copy['items'] = result_copy.get('items', [])[:limit]
    return jsonify(result_copy)