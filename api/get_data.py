import time
import json
import spotipy
from datetime import datetime, timedelta
from collections import deque
from spotipy.oauth2 import SpotifyOAuth
import os

def test_basic_call():
    scope = "user-read-recently-played"
    sp_oauth = SpotifyOAuth(scope=scope)
    sp = spotipy.Spotify(auth_manager=sp_oauth)
    try:
        response = sp.current_user_recently_played(limit=1,before=1702377923123)
        print(response)
    except Exception as e:
        print(f"API Error: {str(e)}")

def fetch_spotify_data_sequence():
    """
    Authenticate and fetch a sequence of Spotify API data.
    For a new user, create {username}_spotify.json and append each API result as soon as it is fetched.
    Each entry in the JSON file is a dict: {"step": ..., "data": ...}
    """
    sp = spotipy.Spotify(auth_manager=SpotifyOAuth(
        scope="user-read-recently-played user-top-read user-read-private user-library-read",
        client_id='678b8f9bd6bd45f396cc637c5c6f04cf',
        client_secret='a5cfde08167a452fac10887add179566',
        redirect_uri='http://127.0.0.1:8000/callback'
    ))
    results = {}
    username = None
    json_filename = None
    try:
        # 1. Get current user profile
        user_data = None
        try:
            user_data = sp.current_user()
            username = user_data.get('id', 'unknown_user')
            json_filename = f"{username}_spotify.json"
            with open(json_filename, 'w') as f:
                json.dump([], f)  # Start with empty list
            with open(json_filename, 'r+') as f:
                data = json.load(f)
                data.append({"step": "current_user", "data": user_data})
                f.seek(0)
                json.dump(data, f, indent=2)
                f.truncate()
            print("current_user: success")
        except Exception as e:
            print("current_user: fail", str(e))
        # 2. Get recently played tracks (latest 50)
        try:
            now_ms = int(time.time() * 1000)
            recently_played = sp.current_user_recently_played(limit=50, before=now_ms)
            with open(json_filename, 'r+') as f:
                data = json.load(f)
                data.append({"step": "recently_played", "data": recently_played})
                f.seek(0)
                json.dump(data, f, indent=2)
                f.truncate()
            print("recently_played: success")
        except Exception as e:
            print("recently_played: fail", str(e))
        # 3. Top artists short term
        try:
            top_artists_short = sp.current_user_top_artists(limit=50, offset=0, time_range='short_term')
            with open(json_filename, 'r+') as f:
                data = json.load(f)
                data.append({"step": "top_artists_short", "data": top_artists_short})
                f.seek(0)
                json.dump(data, f, indent=2)
                f.truncate()
            print("top_artists_short: success")
        except Exception as e:
            print("top_artists_short: fail", str(e))
        # 4. Top artists medium term
        try:
            top_artists_medium = sp.current_user_top_artists(limit=50, offset=0, time_range='medium_term')
            with open(json_filename, 'r+') as f:
                data = json.load(f)
                data.append({"step": "top_artists_medium", "data": top_artists_medium})
                f.seek(0)
                json.dump(data, f, indent=2)
                f.truncate()
            print("top_artists_medium: success")
        except Exception as e:
            print("top_artists_medium: fail", str(e))
        # 5. Top artists long term
        try:
            top_artists_long = sp.current_user_top_artists(limit=50, offset=0, time_range='long_term')
            with open(json_filename, 'r+') as f:
                data = json.load(f)
                data.append({"step": "top_artists_long", "data": top_artists_long})
                f.seek(0)
                json.dump(data, f, indent=2)
                f.truncate()
            print("top_artists_long: success")
        except Exception as e:
            print("top_artists_long: fail", str(e))
        # 6. Top tracks short term
        try:
            top_tracks_short = sp.current_user_top_tracks(limit=50, offset=0, time_range='short_term')
            with open(json_filename, 'r+') as f:
                data = json.load(f)
                data.append({"step": "top_tracks_short", "data": top_tracks_short})
                f.seek(0)
                json.dump(data, f, indent=2)
                f.truncate()
            print("top_tracks_short: success")
        except Exception as e:
            print("top_tracks_short: fail", str(e))
        # 7. Top tracks medium term
        try:
            top_tracks_medium = sp.current_user_top_tracks(limit=50, offset=0, time_range='medium_term')
            with open(json_filename, 'r+') as f:
                data = json.load(f)
                data.append({"step": "top_tracks_medium", "data": top_tracks_medium})
                f.seek(0)
                json.dump(data, f, indent=2)
                f.truncate()
            print("top_tracks_medium: success")
        except Exception as e:
            print("top_tracks_medium: fail", str(e))
        # 8. Top tracks long term
        try:
            top_tracks_long = sp.current_user_top_tracks(limit=50, offset=0, time_range='long_term')
            with open(json_filename, 'r+') as f:
                data = json.load(f)
                data.append({"step": "top_tracks_long", "data": top_tracks_long})
                f.seek(0)
                json.dump(data, f, indent=2)
                f.truncate()
            print("top_tracks_long: success")
        except Exception as e:
            print("top_tracks_long: fail", str(e))
        # 9. Saved tracks
        try:
            saved_tracks = sp.current_user_saved_tracks(limit=50, offset=0, market=None)
            with open(json_filename, 'r+') as f:
                data = json.load(f)
                data.append({"step": "saved_tracks", "data": saved_tracks})
                f.seek(0)
                json.dump(data, f, indent=2)
                f.truncate()
            print("saved_tracks: success")
        except Exception as e:
            print("saved_tracks: fail", str(e))
    except Exception as e:
        print("General error in fetch_spotify_data_sequence:", str(e))
    return {"username": username, "json_file": json_filename}

if __name__ == "__main__":
    #fetcher = SpotifyHistoryFetcher()
    #fetcher.fetch_history()
    test_basic_call()
    print("History collection complete. Data saved to spotify_history.jsonl")
