from flask import Flask, jsonify, request as flask_request
import spotipy
from spotipy.oauth2 import SpotifyOAuth
import time
from get_data import fetch_spotify_data_sequence
import json
import os

app = Flask(__name__)

@app.route("/")
def hello_world():
    return "<p>Hello, World!</p>"

@app.route("/login")
def login_and_fetch_data():
    results = fetch_spotify_data_sequence()
    return jsonify(results)

def verify_and_load_file(filename):
    if not filename or not os.path.exists(filename):
        return None
    with open(filename, 'r') as f:
        return json.load(f)

# 1. Get current user profile
def get_from_file(filename, step):
    data = verify_and_load_file(filename)
    if data is None:
        return None
    for entry in data:
        if entry.get('step') == step:
            return entry.get('data')
    return None

@app.route("/user/profile", methods=["GET"])
def api_user_profile():
    username = flask_request.args.get('username')
    filename = flask_request.args.get('filename')
    if not username or not filename:
        return jsonify({"error": "Missing username or filename"}), 400
    result = get_from_file(filename, "current_user")
    if result is None:
        return jsonify({"error": "Data not found or file missing"}), 404
    return jsonify(result)

# 2. Recently played tracks (customizable limit)
@app.route("/user/recently_played", methods=["GET"])
def api_recently_played():
    username = flask_request.args.get('username')
    filename = flask_request.args.get('filename')
    limit = int(flask_request.args.get('limit', 50))
    if not username or not filename:
        return jsonify({"error": "Missing username or filename"}), 400
    if not (1 <= limit <= 50):
        return jsonify({"error": "Limit must be between 1 and 50"}), 400
    result = get_from_file(filename, "recently_played")
    if result is None:
        return jsonify({"error": "Data not found or file missing"}), 404
    # result['items'] is the list of tracks
    result_copy = dict(result)
    result_copy['items'] = result_copy.get('items', [])[:limit]
    return jsonify(result_copy)

# 3. Top artists (customizable term and limit)
@app.route("/user/top_artists", methods=["GET"])
def api_top_artists():
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
    result = get_from_file(filename, step)
    if result is None:
        return jsonify({"error": "Data not found or file missing"}), 404
    result_copy = dict(result)
    result_copy['items'] = result_copy.get('items', [])[:limit]
    return jsonify(result_copy)

# 4. Top tracks (customizable term and limit)
@app.route("/user/top_tracks", methods=["GET"])
def api_top_tracks():
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
    result = get_from_file(filename, step)
    if result is None:
        return jsonify({"error": "Data not found or file missing"}), 404
    result_copy = dict(result)
    result_copy['items'] = result_copy.get('items', [])[:limit]
    return jsonify(result_copy)

# 5. Saved tracks (customizable limit)
@app.route("/user/saved_tracks", methods=["GET"])
def api_saved_tracks():
    username = flask_request.args.get('username')
    filename = flask_request.args.get('filename')
    limit = int(flask_request.args.get('limit', 50))
    if not username or not filename:
        return jsonify({"error": "Missing username or filename"}), 400
    if not (1 <= limit <= 50):
        return jsonify({"error": "Limit must be between 1 and 50"}), 400
    result = get_from_file(filename, "saved_tracks")
    if result is None:
        return jsonify({"error": "Data not found or file missing"}), 404
    result_copy = dict(result)
    result_copy['items'] = result_copy.get('items', [])[:limit]
    return jsonify(result_copy)

if __name__ == "__main__":
    app.run(debug=True)
