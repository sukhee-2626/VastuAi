import os
import random
from flask import Flask, request, jsonify, render_template
from flask_cors import CORS
from vastu_engine import analyze_vastu

app = Flask(__name__)
CORS(app)

# --- Dummy floor plan layouts for demo ---
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

@app.route('/')
def home():
    try:
        return render_template('index.html')
    except Exception as e:
        return f"Error loading UI: {str(e)}", 500


@app.route('/analyze', methods=['POST'])
def analyze():
    print("Request received at /analyze")

    if 'image' not in request.files:
        return jsonify({"error": "No image uploaded"}), 400

    # Ignore the image — return smart dummy Vastu analysis
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


if __name__ == '__main__':
    print("VastuAI Backend Running on http://localhost:5000")
    app.run(debug=True, port=5000)
