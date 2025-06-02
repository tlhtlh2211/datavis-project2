from flask import Flask, jsonify, request as flask_request
import time
from data.get_data import fetch_spotify_data_sequence
from flask_cors import CORS

from routes import register_routes

app = Flask(__name__)
CORS(app)

@app.route("/")
def hello_world():
    return "<p>Hello, World!</p>"

@app.route("/login", methods=["POST", "GET"])
def login_and_fetch_data():
    results = fetch_spotify_data_sequence()
    return jsonify(results)

register_routes(app)

if __name__ == "__main__":
    print("Starting Flask server...")
    print("Visit http://127.0.0.1:5000 to access the API")
    print("Press CTRL+C to quit")
    app.run(debug=True, host='127.0.0.1', port=5000)
