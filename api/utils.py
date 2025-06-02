import os
import json
from collections import Counter

def verify_and_load_file(filename):
    """Load and verify a JSON file"""
    if not filename or not os.path.exists(filename):
        return None
    with open(filename, 'r') as f:
        return json.load(f)

def get_from_file(filename, step):
    """Get data from a specific step in the JSON file"""
    data = verify_and_load_file(filename)
    if data is None:
        return None
    for entry in data:
        if entry.get('step') == step:
            return entry.get('data')
    return None

def classify_mood(features):
    """
    Classify a track's mood based on its audio features using a more nuanced approach.
    
    Parameters:
    - features: dict containing Spotify audio features
    
    Returns:
    - mood: string representing the classified mood
    """
    # Extract relevant features
    valence = features['valence']           # Musical positiveness (0.0 to 1.0)
    energy = features['energy']             # Intensity and activity (0.0 to 1.0)
    acousticness = features['acousticness'] # Confidence of being acoustic (0.0 to 1.0)
    danceability = features['danceability'] # How suitable for dancing (0.0 to 1.0)
    tempo = features['tempo']               # Estimated tempo in BPM
    instrumentalness = features.get('instrumentalness', 0)  # Predicts if track has no vocals (0.0 to 1.0)
    mode = features.get('mode', 1)          # Major (1) or minor (0) modality
    loudness = features.get('loudness', -10)  # Overall loudness in dB (-60 to 0)
    
    # More specific mood classification with weighted consideration of multiple features
    
    # HAPPY: High valence, moderately high energy, likely major mode
    if valence > 0.65 and energy > 0.55 and mode == 1:
        # Further distinguish between different types of happy
        if danceability > 0.7:
            return 'Euphoric'  # Very danceable happy music
        return 'Happy'
    
    # SAD: Low valence, lower energy, often minor mode, acoustic elements
    elif valence < 0.4 and energy < 0.45 and (mode == 0 or acousticness > 0.4):
        if acousticness > 0.7:
            return 'Melancholic'  # Acoustic sad music
        return 'Sad'
    
    # ENERGETIC: Very high energy regardless of emotional tone
    elif energy > 0.75:
        if danceability > 0.65:
            return 'Energetic'  # High energy and danceable
        elif valence < 0.4:
            return 'Intense'    # High energy but not positive/danceable
        return 'Upbeat'
    
    # CALM: Acoustic, lower energy, moderate to slow tempo
    elif acousticness > 0.65 and energy < 0.55 and tempo < 100:
        if instrumentalness > 0.5:
            return 'Ambient'    # Instrumental calm music
        return 'Calm'
    
    # ANGSTY: Low valence but high energy, often louder
    elif valence < 0.4 and energy > 0.6 and loudness > -8:
        return 'Angsty'
    
    # DARK: Low valence, moderate energy, minor mode
    elif valence < 0.3 and mode == 0 and 0.4 < energy < 0.7:
        return 'Dark'
    
    # SENTIMENTAL: Moderate valence, lower energy, acoustic elements
    elif 0.4 <= valence <= 0.6 and energy < 0.5 and acousticness > 0.4:
        return 'Sentimental'
    
    # NOSTALGIC: Moderate valence, moderate acoustic, often not extremely energetic
    elif 0.4 <= valence <= 0.7 and 0.4 <= acousticness <= 0.7 and energy < 0.65:
        return 'Nostalgic'
    
    # CHILL: Default catch-all category for moderate tracks
    else:
        # Try to distinguish some "chill" variations
        if danceability > 0.6 and energy < 0.6:
            return 'Groovy'     # Danceable but not too energetic
        elif instrumentalness > 0.5:
            return 'Atmospheric'  # Instrumental moderate tracks
        return 'Chill'

def predict_personality(top_genres):
    """
    Predict personality traits based on top music genres.
    
    Returns a dictionary of personality dimensions and their scores (0-100)
    with descriptions.
    """
    # Personality dimensions with genre associations:
    # 1. Openness to experience (experimental, complex vs. conventional)
    # 2. Conscientiousness (organized, dependable vs. spontaneous)
    # 3. Extraversion (outgoing, energetic vs. reserved)
    # 4. Agreeableness (cooperative, empathetic vs. critical, rational)
    # 5. Emotional stability (calm, secure vs. anxious, sensitive)
    
    # Genre-trait associations (simplified model)
    genre_traits = {
        # Format: genre: [openness, conscientiousness, extraversion, agreeableness, emotional_stability]
        # Rock genres
        "rock": [60, 50, 60, 50, 55],
        "alternative rock": [70, 45, 55, 60, 50],
        "indie rock": [75, 45, 50, 65, 45],
        "classic rock": [55, 60, 55, 50, 60],
        "hard rock": [60, 45, 70, 40, 60],
        "punk": [70, 30, 65, 40, 50],
        "metal": [65, 55, 60, 40, 55],
        "progressive rock": [80, 70, 50, 55, 60],
        
        # Pop genres
        "pop": [45, 55, 75, 65, 60],
        "dance pop": [50, 45, 80, 60, 65],
        "indie pop": [65, 50, 60, 70, 50],
        "synth pop": [60, 55, 65, 60, 55],
        "k-pop": [55, 60, 75, 65, 60],
        
        # Electronic genres
        "electronic": [65, 55, 70, 50, 60],
        "edm": [60, 50, 80, 55, 65],
        "house": [60, 55, 75, 60, 65],
        "techno": [65, 60, 70, 45, 60],
        "dubstep": [70, 45, 75, 40, 55],
        "ambient": [80, 60, 30, 65, 70],
        
        # Hip hop genres
        "hip hop": [60, 45, 70, 50, 60],
        "rap": [65, 40, 75, 45, 60],
        "trap": [55, 35, 70, 40, 50],
        "r&b": [55, 50, 65, 70, 55],
        
        # Jazz and classical
        "jazz": [75, 65, 50, 60, 65],
        "classical": [70, 75, 40, 65, 70],
        "neo-classical": [75, 70, 45, 65, 65],
        
        # Folk and country
        "folk": [65, 60, 40, 75, 60],
        "country": [45, 65, 60, 70, 65],
        "singer-songwriter": [70, 55, 45, 75, 50],
        
        # World music
        "latin": [60, 50, 80, 70, 65],
        "reggae": [60, 40, 65, 75, 70],
        "afrobeat": [65, 50, 75, 65, 60],
        "k-pop": [50, 60, 75, 65, 55],
        
        # Default/fallback values for unknown genres
        "unknown": [50, 50, 50, 50, 50]
    }
    
    # Initialize scores
    traits = {
        "openness": 0, 
        "conscientiousness": 0, 
        "extraversion": 0, 
        "agreeableness": 0, 
        "emotional_stability": 0
    }
    
    # Calculate weighted trait scores based on top genres
    total_weight = 0
    for genre, weight in top_genres:
        # Find the closest matching genre in our dictionary
        genre_lower = genre.lower()
        matched_genre = "unknown"
        
        for known_genre in genre_traits.keys():
            if known_genre in genre_lower:
                matched_genre = known_genre
                break
        
        # Add weighted trait values
        trait_values = genre_traits.get(matched_genre, genre_traits["unknown"])
        traits["openness"] += trait_values[0] * weight
        traits["conscientiousness"] += trait_values[1] * weight
        traits["extraversion"] += trait_values[2] * weight
        traits["agreeableness"] += trait_values[3] * weight
        traits["emotional_stability"] += trait_values[4] * weight
        
        total_weight += weight
    
    # Normalize scores (0-100 scale)
    if total_weight > 0:
        for trait in traits:
            traits[trait] = round(traits[trait] / total_weight)
    
    # Generate descriptions based on scores
    descriptions = {}
    
    # Openness to experience
    if traits["openness"] >= 70:
        descriptions["openness"] = "You are intellectually curious, creative, and open to new experiences. You likely appreciate art, beauty, and innovation."
    elif traits["openness"] >= 50:
        descriptions["openness"] = "You have a balance of conventional and novel approaches to life. You appreciate tradition but are willing to try new things."
    else:
        descriptions["openness"] = "You are practical, conventional, and prefer familiar routines. You focus on concrete facts rather than abstract theories."
    
    # Conscientiousness
    if traits["conscientiousness"] >= 70:
        descriptions["conscientiousness"] = "You are organized, responsible, and goal-oriented. You tend to plan ahead and prioritize tasks efficiently."
    elif traits["conscientiousness"] >= 50:
        descriptions["conscientiousness"] = "You have a balance between being organized and spontaneous. You can follow plans but also adapt when needed."
    else:
        descriptions["conscientiousness"] = "You are spontaneous, flexible, and prefer to go with the flow rather than stick to strict plans."
    
    # Extraversion
    if traits["extraversion"] >= 70:
        descriptions["extraversion"] = "You are outgoing, energetic, and thrive in social situations. You gain energy from being around others."
    elif traits["extraversion"] >= 50:
        descriptions["extraversion"] = "You have a balance of social energy and need for solitude. You enjoy social interactions but also value your alone time."
    else:
        descriptions["extraversion"] = "You are reserved, reflective, and prefer deeper one-on-one connections to large social gatherings."
    
    # Agreeableness
    if traits["agreeableness"] >= 70:
        descriptions["agreeableness"] = "You are empathetic, cooperative, and prioritize harmony in relationships. You're likely seen as trustworthy and helpful."
    elif traits["agreeableness"] >= 50:
        descriptions["agreeableness"] = "You balance cooperation with self-assertion. You can be empathetic but also stand up for your own needs."
    else:
        descriptions["agreeableness"] = "You are analytical, skeptical, and prioritize logic over emotional factors in decision-making."
    
    # Emotional stability
    if traits["emotional_stability"] >= 70:
        descriptions["emotional_stability"] = "You are calm, resilient, and handle stress well. You maintain emotional balance even in difficult situations."
    elif traits["emotional_stability"] >= 50:
        descriptions["emotional_stability"] = "You have a reasonable balance of emotional responsiveness and stability. You feel emotions but can manage them."
    else:
        descriptions["emotional_stability"] = "You are emotionally sensitive and responsive to your environment. You experience emotions deeply and intensely."
    
    return {
        "scores": traits,
        "descriptions": descriptions
    }