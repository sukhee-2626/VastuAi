import sys
import os
import random

# ── Add backend to path so vastu_engine can be imported ──────────────────────
backend_path = os.path.join(os.path.dirname(__file__), '..', 'backend')
sys.path.insert(0, backend_path)

from flask import Flask, request, jsonify, render_template
from flask_cors import CORS
from vastu_engine import analyze_vastu

# ── Flask app — tell it where templates & static files live ──────────────────
app = Flask(
    __name__,
    template_folder=os.path.join(backend_path, 'templates'),
    static_folder=os.path.join(backend_path, 'static'),
    static_url_path='/static'
)
CORS(app)

# ── Dummy floor plan presets ──────────────────────────────────────────────────
DUMMY_LAYOUTS = [
    {
        "entrance": "north",
        "kitchen": "south-east",
        "master_bedroom": "south-west",
        "toilet": "north-west",
        "living_room": "east"
    },
    {
        "entrance": "south-west",
        "kitchen": "north-east",
        "master_bedroom": "south-east",
        "toilet": "north-east",
        "living_room": "north"
    },
    {
        "entrance": "east",
        "kitchen": "north-west",
        "master_bedroom": "south-west",
        "toilet": "south-west",
        "living_room": "north-east"
    },
    {
        "entrance": "west",
        "kitchen": "south-east",
        "master_bedroom": "south-west",
        "toilet": "west",
        "living_room": "north"
    },
]

# ── Routes ────────────────────────────────────────────────────────────────────

@app.route('/')
def home():
    try:
        return render_template('index.html')
    except Exception as e:
        return f"<h1>VastuAI</h1><p>Template error: {e}</p>", 500


@app.route('/analyze', methods=['POST'])
def analyze():
    if 'image' not in request.files:
        return jsonify({"error": "No image uploaded"}), 400

    data = random.choice(DUMMY_LAYOUTS)
    language = request.form.get('language', 'en')
    analysis = analyze_vastu(data, language=language)

    return jsonify({
        "raw_data": data,
        "analysis": analysis,
        "is_dummy": True,
        "notice": "Demo Mode: Showing simulated Vastu analysis based on common floor plan patterns."
    })


@app.route('/health', methods=['GET'])
def health():
    return jsonify({"status": "healthy", "mode": "demo"})
