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

def predict_personality(top_genres, audio_features=None, track_popularity_data=None):
    """
    Advanced personality prediction based on music genres and audio features with sophisticated analysis.
    
    Features:
    - Cultural and regional music influence analysis
    - Genre diversity and exploration metrics
    - Fuzzy genre matching and synonyms
    - Cross-genre interaction effects
    - Audio features analysis (valence, energy, danceability, etc.)
    - Track popularity and mainstream vs niche analysis
    - Temporal patterns and consistency analysis
    - Confidence scoring based on data quality
    - Dynamic personality type classification
    - Nuanced trait descriptions
    
    Parameters:
    - top_genres: List of (genre, weight) tuples from artist genres
    - audio_features: List of Spotify audio features dictionaries (optional)
    - track_popularity_data: List of track metadata including popularity scores (optional)
    
    Returns a comprehensive personality analysis dictionary.
    """
    import re
    from collections import defaultdict
    
    # Enhanced genre-trait mapping with cultural context
    genre_traits = {
        # Western Pop & Mainstream
        "pop": {"traits": [45, 55, 75, 65, 60], "cultural_weight": 1.0, "complexity": 0.3},
        "dance pop": {"traits": [50, 45, 80, 60, 65], "cultural_weight": 1.0, "complexity": 0.4},
        "indie pop": {"traits": [65, 50, 60, 70, 50], "cultural_weight": 0.8, "complexity": 0.6},
        "synth pop": {"traits": [60, 55, 65, 60, 55], "cultural_weight": 0.9, "complexity": 0.5},
        "dream pop": {"traits": [70, 45, 40, 75, 45], "cultural_weight": 0.7, "complexity": 0.7},
        "art pop": {"traits": [80, 50, 50, 65, 50], "cultural_weight": 0.6, "complexity": 0.8},
        "hyperpop": {"traits": [85, 35, 70, 55, 45], "cultural_weight": 0.5, "complexity": 0.9},
        
        # Rock & Alternative
        "rock": {"traits": [60, 50, 60, 50, 55], "cultural_weight": 1.0, "complexity": 0.5},
        "alternative rock": {"traits": [70, 45, 55, 60, 50], "cultural_weight": 0.8, "complexity": 0.6},
        "indie rock": {"traits": [75, 45, 50, 65, 45], "cultural_weight": 0.7, "complexity": 0.7},
        "classic rock": {"traits": [55, 60, 55, 50, 60], "cultural_weight": 1.0, "complexity": 0.4},
        "hard rock": {"traits": [60, 45, 70, 40, 60], "cultural_weight": 0.9, "complexity": 0.5},
        "punk": {"traits": [70, 30, 65, 40, 50], "cultural_weight": 0.8, "complexity": 0.6},
        "metal": {"traits": [65, 55, 60, 40, 55], "cultural_weight": 0.8, "complexity": 0.6},
        "progressive rock": {"traits": [80, 70, 50, 55, 60], "cultural_weight": 0.7, "complexity": 0.9},
        "post-rock": {"traits": [85, 60, 35, 70, 65], "cultural_weight": 0.6, "complexity": 0.8},
        
        # Electronic & EDM
        "electronic": {"traits": [65, 55, 70, 50, 60], "cultural_weight": 0.9, "complexity": 0.6},
        "edm": {"traits": [60, 50, 80, 55, 65], "cultural_weight": 1.0, "complexity": 0.4},
        "house": {"traits": [60, 55, 75, 60, 65], "cultural_weight": 0.9, "complexity": 0.5},
        "techno": {"traits": [65, 60, 70, 45, 60], "cultural_weight": 0.8, "complexity": 0.6},
        "dubstep": {"traits": [70, 45, 75, 40, 55], "cultural_weight": 0.8, "complexity": 0.7},
        "ambient": {"traits": [80, 60, 30, 65, 70], "cultural_weight": 0.6, "complexity": 0.8},
        "downtempo": {"traits": [75, 55, 35, 70, 75], "cultural_weight": 0.7, "complexity": 0.7},
        "drum and bass": {"traits": [70, 50, 75, 45, 60], "cultural_weight": 0.8, "complexity": 0.7},
        "trance": {"traits": [65, 55, 65, 55, 70], "cultural_weight": 0.8, "complexity": 0.6},
        
        # Hip Hop & R&B
        "hip hop": {"traits": [60, 45, 70, 50, 60], "cultural_weight": 1.0, "complexity": 0.5},
        "rap": {"traits": [65, 40, 75, 45, 60], "cultural_weight": 1.0, "complexity": 0.4},
        "trap": {"traits": [55, 35, 70, 40, 50], "cultural_weight": 0.9, "complexity": 0.4},
        "r&b": {"traits": [55, 50, 65, 70, 55], "cultural_weight": 1.0, "complexity": 0.5},
        "neo soul": {"traits": [70, 55, 55, 75, 60], "cultural_weight": 0.8, "complexity": 0.7},
        "conscious hip hop": {"traits": [75, 60, 60, 70, 65], "cultural_weight": 0.7, "complexity": 0.8},
        
        # Jazz & Classical
        "jazz": {"traits": [75, 65, 50, 60, 65], "cultural_weight": 0.8, "complexity": 0.8},
        "classical": {"traits": [70, 75, 40, 65, 70], "cultural_weight": 0.7, "complexity": 0.9},
        "neo-classical": {"traits": [75, 70, 45, 65, 65], "cultural_weight": 0.6, "complexity": 0.8},
        "contemporary jazz": {"traits": [80, 60, 55, 65, 70], "cultural_weight": 0.7, "complexity": 0.8},
        "bebop": {"traits": [85, 70, 50, 60, 65], "cultural_weight": 0.6, "complexity": 0.9},
        
        # Folk & Acoustic
        "folk": {"traits": [65, 60, 40, 75, 60], "cultural_weight": 0.8, "complexity": 0.6},
        "country": {"traits": [45, 65, 60, 70, 65], "cultural_weight": 1.0, "complexity": 0.4},
        "singer-songwriter": {"traits": [70, 55, 45, 75, 50], "cultural_weight": 0.8, "complexity": 0.7},
        "acoustic": {"traits": [60, 55, 40, 70, 65], "cultural_weight": 0.8, "complexity": 0.5},
        "indie folk": {"traits": [75, 50, 45, 80, 55], "cultural_weight": 0.7, "complexity": 0.7},
        
        # World Music & Cultural
        "k-pop": {"traits": [50, 60, 75, 65, 55], "cultural_weight": 0.9, "complexity": 0.5},
        "j-pop": {"traits": [55, 65, 70, 70, 60], "cultural_weight": 0.9, "complexity": 0.5},
        "v-pop": {"traits": [52, 58, 72, 68, 58], "cultural_weight": 0.9, "complexity": 0.5},
        "latin": {"traits": [60, 50, 80, 70, 65], "cultural_weight": 0.9, "complexity": 0.6},
        "reggae": {"traits": [60, 40, 65, 75, 70], "cultural_weight": 0.8, "complexity": 0.6},
        "afrobeat": {"traits": [65, 50, 75, 65, 60], "cultural_weight": 0.8, "complexity": 0.7},
        "bollywood": {"traits": [55, 55, 80, 70, 60], "cultural_weight": 0.9, "complexity": 0.6},
        "bossa nova": {"traits": [70, 60, 50, 80, 75], "cultural_weight": 0.7, "complexity": 0.7},
        
        # Regional Specific
        "vietnam indie": {"traits": [72, 52, 58, 75, 55], "cultural_weight": 0.8, "complexity": 0.7},
        "vietnamese hip hop": {"traits": [62, 45, 68, 58, 60], "cultural_weight": 0.8, "complexity": 0.6},
        "vietnamese lo-fi": {"traits": [78, 50, 35, 80, 70], "cultural_weight": 0.7, "complexity": 0.8},
        "vinahouse": {"traits": [58, 45, 78, 60, 65], "cultural_weight": 0.9, "complexity": 0.5},
        "soft pop": {"traits": [60, 60, 55, 75, 65], "cultural_weight": 0.8, "complexity": 0.4},
        
        # Experimental & Niche
        "experimental": {"traits": [90, 45, 40, 50, 45], "cultural_weight": 0.4, "complexity": 0.95},
        "noise": {"traits": [85, 30, 50, 35, 40], "cultural_weight": 0.3, "complexity": 0.9},
        "shoegaze": {"traits": [75, 40, 35, 65, 45], "cultural_weight": 0.5, "complexity": 0.8},
        "post-punk": {"traits": [80, 45, 55, 50, 50], "cultural_weight": 0.6, "complexity": 0.8},
        "lo-fi": {"traits": [70, 45, 30, 75, 65], "cultural_weight": 0.7, "complexity": 0.7},
        
        # Default fallback
        "unknown": {"traits": [50, 50, 50, 50, 50], "cultural_weight": 1.0, "complexity": 0.5}
    }
    
    # Genre synonyms and fuzzy matching
    genre_synonyms = {
        "hiphop": "hip hop",
        "rnb": "r&b",
        "jpop": "j-pop",
        "kpop": "k-pop",
        "vpop": "v-pop",
        "edm": "electronic",
        "dnb": "drum and bass",
        "dub": "dubstep",
        "indie": "indie rock",
        "alternative": "alternative rock",
        "singer songwriter": "singer-songwriter",
        "vietnam": "vietnamese",
        "vietnamese": "vietnam"
    }
    
    def fuzzy_match_genre(input_genre):
        """Advanced genre matching with fuzzy logic and cultural context"""
        input_lower = input_genre.lower().strip()
        
        # Direct match
        if input_lower in genre_traits:
            return input_lower, 1.0
            
        # Synonym match
        if input_lower in genre_synonyms:
            return genre_synonyms[input_lower], 1.0
            
        # Partial matching with scoring
        best_match = "unknown"
        best_score = 0.0
        
        for genre in genre_traits.keys():
            # Check if input contains genre or vice versa
            if genre in input_lower or input_lower in genre:
                overlap = len(set(input_lower.split()) & set(genre.split()))
                total_words = len(set(input_lower.split()) | set(genre.split()))
                score = overlap / total_words if total_words > 0 else 0
                
                if score > best_score:
                    best_score = score
                    best_match = genre
                    
        # Also check for cultural/regional indicators
        if "vietnam" in input_lower or "viet" in input_lower:
            if "indie" in input_lower:
                return "vietnam indie", 0.9
            elif "hip hop" in input_lower or "rap" in input_lower:
                return "vietnamese hip hop", 0.9
            elif "lo-fi" in input_lower or "lofi" in input_lower:
                return "vietnamese lo-fi", 0.9
                
        return best_match, max(best_score, 0.3)  # Minimum confidence for partial matches
    
    # Advanced trait calculation
    traits = {
        "openness": 0, 
        "conscientiousness": 0, 
        "extraversion": 0, 
        "agreeableness": 0, 
        "emotional_stability": 0
    }
    
    # Additional metrics
    genre_diversity = 0
    cultural_diversity = 0
    complexity_score = 0
    confidence_factors = []
    matched_genres = []
    total_weight = 0
    cultural_regions = set()
    
    # Process each genre with advanced weighting
    for i, (genre, weight) in enumerate(top_genres):
        matched_genre, match_confidence = fuzzy_match_genre(genre)
        genre_info = genre_traits[matched_genre]
        
        # Position-based weight decay (top genres matter more)
        position_weight = 1.0 - (i * 0.05)  # 5% decay per position
        
        # Cultural context weighting
        cultural_weight = genre_info["cultural_weight"]
        
        # Complexity contribution
        complexity_contribution = genre_info["complexity"]
        
        # Final weight calculation
        final_weight = weight * position_weight * cultural_weight * match_confidence
        
        # Add to traits
        trait_values = genre_info["traits"]
        traits["openness"] += trait_values[0] * final_weight
        traits["conscientiousness"] += trait_values[1] * final_weight
        traits["extraversion"] += trait_values[2] * final_weight
        traits["agreeableness"] += trait_values[3] * final_weight
        traits["emotional_stability"] += trait_values[4] * final_weight
        
        total_weight += final_weight
        complexity_score += complexity_contribution * final_weight
        
        # Track diversity metrics
        matched_genres.append(matched_genre)
        confidence_factors.append(match_confidence)
        
        # Cultural diversity tracking
        if "k-" in matched_genre or "korean" in matched_genre:
            cultural_regions.add("korean")
        elif "j-" in matched_genre or "japanese" in matched_genre:
            cultural_regions.add("japanese")
        elif "vietnam" in matched_genre or "v-" in matched_genre:
            cultural_regions.add("vietnamese")
        elif "latin" in matched_genre or "spanish" in matched_genre:
            cultural_regions.add("latin")
        elif matched_genre in ["folk", "country", "blues", "rock", "pop"]:
            cultural_regions.add("western")
        elif matched_genre in ["afrobeat", "reggae"]:
            cultural_regions.add("african")
    
    # Analyze audio features if provided
    audio_features_impact = {
        "openness": 0,
        "conscientiousness": 0, 
        "extraversion": 0,
        "agreeableness": 0,
        "emotional_stability": 0
    }
    
    audio_weight = 0
    
    if audio_features and len(audio_features) > 0:
        # Calculate average audio features
        avg_features = {}
        feature_keys = ['valence', 'energy', 'danceability', 'acousticness', 
                       'instrumentalness', 'tempo', 'loudness', 'speechiness']
        
        for key in feature_keys:
            values = [f.get(key, 0) for f in audio_features if f and f.get(key) is not None]
            avg_features[key] = sum(values) / len(values) if values else 0
        
        # Map audio features to personality traits
        # High valence (positive music) -> higher agreeableness, extraversion
        if avg_features['valence'] > 0.6:
            audio_features_impact["agreeableness"] += 15
            audio_features_impact["extraversion"] += 10
        elif avg_features['valence'] < 0.4:
            audio_features_impact["emotional_stability"] -= 10
        
        # High energy -> higher extraversion, lower emotional stability if extreme
        if avg_features['energy'] > 0.7:
            audio_features_impact["extraversion"] += 12
            if avg_features['energy'] > 0.85:
                audio_features_impact["emotional_stability"] -= 5
        elif avg_features['energy'] < 0.3:
            audio_features_impact["extraversion"] -= 8
            audio_features_impact["emotional_stability"] += 5
        
        # High danceability -> higher extraversion, agreeableness
        if avg_features['danceability'] > 0.7:
            audio_features_impact["extraversion"] += 8
            audio_features_impact["agreeableness"] += 5
        
        # High acousticness -> higher openness, emotional sensitivity
        if avg_features['acousticness'] > 0.6:
            audio_features_impact["openness"] += 10
            audio_features_impact["emotional_stability"] += 8
        
        # High instrumentalness -> higher openness, conscientiousness
        if avg_features['instrumentalness'] > 0.5:
            audio_features_impact["openness"] += 12
            audio_features_impact["conscientiousness"] += 5
        
        # Tempo analysis
        if avg_features['tempo'] > 140:  # Fast tempo
            audio_features_impact["extraversion"] += 6
            audio_features_impact["conscientiousness"] -= 3
        elif avg_features['tempo'] < 90:  # Slow tempo
            audio_features_impact["openness"] += 5
            audio_features_impact["emotional_stability"] += 5
        
        # Loudness analysis
        if avg_features['loudness'] > -5:  # Very loud
            audio_features_impact["extraversion"] += 5
        elif avg_features['loudness'] < -15:  # Quiet
            audio_features_impact["emotional_stability"] += 5
        
        # Speechiness (podcasts, rap, etc.)
        if avg_features['speechiness'] > 0.33:
            audio_features_impact["openness"] += 8
            audio_features_impact["conscientiousness"] += 3
        
        # Calculate audio weight based on number of tracks analyzed
        audio_weight = min(len(audio_features) / 20, 1.0) * 0.3  # Max 30% influence
    
    # Normalize base traits
    if total_weight > 0:
        for trait in traits:
            traits[trait] = round(traits[trait] / total_weight)
        complexity_score = complexity_score / total_weight
    
    # Apply audio features impact with proper weighting
    if audio_weight > 0:
        for trait in traits:
            audio_adjustment = audio_features_impact[trait] * audio_weight
            traits[trait] = max(0, min(100, traits[trait] + audio_adjustment))
            traits[trait] = round(traits[trait])
    
    # Advanced secondary analysis for more accurate scoring
    secondary_adjustments = {
        "openness": 0,
        "conscientiousness": 0, 
        "extraversion": 0,
        "agreeableness": 0,
        "emotional_stability": 0
    }
    
    if audio_features and len(audio_features) > 0:
        # Calculate advanced musical sophistication metrics
        track_durations = [f.get('duration_ms', 0) for f in audio_features if f and f.get('duration_ms')]
        avg_duration = sum(track_durations) / len(track_durations) if track_durations else 180000  # 3 min default
        
        # Musical complexity analysis
        complexity_indicators = []
        for f in audio_features:
            if f:
                # Complex music tends to have: low speechiness, variable tempo, high instrumentalness
                complexity = (
                    (1 - f.get('speechiness', 0)) * 0.3 +  # Less vocal = more complex
                    f.get('instrumentalness', 0) * 0.4 +     # More instrumental = more complex
                    (f.get('time_signature', 4) / 7) * 0.3   # Unusual time signatures = more complex
                )
                complexity_indicators.append(complexity)
        
        avg_complexity = sum(complexity_indicators) / len(complexity_indicators) if complexity_indicators else 0.3
        
        # Emotional range analysis (valence variance)
        valences = [f.get('valence', 0.5) for f in audio_features if f and f.get('valence') is not None]
        emotional_range = 0
        if len(valences) > 1:
            emotional_range = max(valences) - min(valences)
        
        # Energy consistency analysis
        energies = [f.get('energy', 0.5) for f in audio_features if f and f.get('energy') is not None]
        energy_variance = 0
        if len(energies) > 1:
            avg_energy = sum(energies) / len(energies)
            energy_variance = sum((e - avg_energy) ** 2 for e in energies) / len(energies)
        
        # Apply sophisticated adjustments
        
        # OPENNESS: Higher for complex, varied, longer tracks
        if avg_complexity > 0.6:
            secondary_adjustments["openness"] += 8
        if avg_duration > 240000:  # > 4 minutes
            secondary_adjustments["openness"] += 5
        if emotional_range > 0.6:  # Wide emotional range
            secondary_adjustments["openness"] += 6
        
        # CONSCIENTIOUSNESS: Higher for consistent patterns, organized listening
        if energy_variance < 0.05:  # Very consistent energy levels
            secondary_adjustments["conscientiousness"] += 7
        if emotional_range < 0.3:  # Consistent emotional preferences  
            secondary_adjustments["conscientiousness"] += 5
        
        # EXTRAVERSION: Confirmed by social, energetic music characteristics
        avg_danceability = sum(f.get('danceability', 0) for f in audio_features if f) / len(audio_features)
        avg_loudness = sum(f.get('loudness', -10) for f in audio_features if f) / len(audio_features)
        
        if avg_danceability > 0.7:
            secondary_adjustments["extraversion"] += 6
        if avg_loudness > -8:  # Louder music
            secondary_adjustments["extraversion"] += 4
        
        # AGREEABLENESS: Harmonious, positive music preferences
        avg_valence = sum(f.get('valence', 0.5) for f in audio_features if f) / len(audio_features)
        if avg_valence > 0.65:
            secondary_adjustments["agreeableness"] += 8
        if avg_complexity < 0.4:  # Accessible, non-challenging music
            secondary_adjustments["agreeableness"] += 4
        
        # EMOTIONAL_STABILITY: Consistent, moderate characteristics
        if energy_variance < 0.08:  # Consistent energy preference
            secondary_adjustments["emotional_stability"] += 6
        if 0.4 <= avg_valence <= 0.7:  # Moderate, stable emotional range
            secondary_adjustments["emotional_stability"] += 5
        if avg_complexity > 0.3 and avg_complexity < 0.7:  # Neither too simple nor too complex
            secondary_adjustments["emotional_stability"] += 4
    
    # Analyze genre sophistication and diversity patterns
    if len(matched_genres) > 0:
        # Niche vs mainstream genre analysis
        mainstream_genres = {'pop', 'rock', 'hip hop', 'country', 'r&b', 'dance pop', 'edm'}
        niche_count = sum(1 for genre in matched_genres[:10] if genre not in mainstream_genres)
        niche_ratio = niche_count / min(len(matched_genres), 10)
        
        if niche_ratio > 0.6:  # Mostly niche genres
            secondary_adjustments["openness"] += 10
            secondary_adjustments["conscientiousness"] -= 3  # Less conforming
        elif niche_ratio < 0.2:  # Mostly mainstream
            secondary_adjustments["agreeableness"] += 5
            secondary_adjustments["extraversion"] += 3
        
        # Genre consistency analysis
        if genre_diversity < 0.3:  # Very focused taste
            secondary_adjustments["conscientiousness"] += 6
            secondary_adjustments["emotional_stability"] += 4
        elif genre_diversity > 0.8:  # Very diverse taste
            secondary_adjustments["openness"] += 8
            secondary_adjustments["extraversion"] += 4
    
    # Analyze track popularity patterns and temporal data
    if track_popularity_data and len(track_popularity_data) > 0:
        popularities = [track.get('popularity', 0) for track in track_popularity_data]
        avg_popularity = sum(popularities) / len(popularities)
        popularity_variance = sum((p - avg_popularity) ** 2 for p in popularities) / len(popularities)
        
        # Mainstream vs niche preference analysis
        mainstream_count = sum(1 for p in popularities if p > 70)  # Very popular tracks
        niche_count = sum(1 for p in popularities if p < 30)       # Less popular tracks
        
        mainstream_ratio = mainstream_count / len(popularities)
        niche_ratio = niche_count / len(popularities)
        
        # Track duration patterns
        durations = [track.get('duration_ms', 0) for track in track_popularity_data if track.get('duration_ms')]
        avg_track_duration = sum(durations) / len(durations) if durations else 180000
        
        # Explicit content preference
        explicit_count = sum(1 for track in track_popularity_data if track.get('explicit', False))
        explicit_ratio = explicit_count / len(track_popularity_data)
        
        # Release date analysis (preference for newer vs older music)
        current_year = 2024
        release_years = []
        for track in track_popularity_data:
            release_date = track.get('release_date', '')
            if release_date and len(release_date) >= 4:
                try:
                    year = int(release_date[:4])
                    release_years.append(year)
                except:
                    pass
        
        if release_years:
            avg_release_year = sum(release_years) / len(release_years)
            year_variance = sum((y - avg_release_year) ** 2 for y in release_years) / len(release_years)
            recency_preference = (avg_release_year - 1950) / (current_year - 1950)  # 0-1 scale
        else:
            year_variance = 0
            recency_preference = 0.8  # Default to somewhat recent
        
        # Apply popularity-based adjustments
        
        # OPENNESS: Higher for niche music, varied eras, longer tracks
        if niche_ratio > 0.4:  # Significant niche preference
            secondary_adjustments["openness"] += 12
        if avg_track_duration > 300000:  # > 5 minutes average
            secondary_adjustments["openness"] += 6
        if year_variance > 100:  # Wide variety of release years
            secondary_adjustments["openness"] += 5
        if recency_preference < 0.6:  # Prefers older music
            secondary_adjustments["openness"] += 7
        
        # CONSCIENTIOUSNESS: Higher for consistent popularity levels, moderate duration
        if popularity_variance < 200:  # Consistent popularity preferences
            secondary_adjustments["conscientiousness"] += 8
        if 150000 <= avg_track_duration <= 250000:  # Standard track lengths
            secondary_adjustments["conscientiousness"] += 4
        if explicit_ratio < 0.1:  # Low explicit content
            secondary_adjustments["conscientiousness"] += 3
        
        # EXTRAVERSION: Higher for mainstream, popular, energetic music
        if mainstream_ratio > 0.6:  # Prefers popular music
            secondary_adjustments["extraversion"] += 10
        if avg_popularity > 60:  # Generally popular taste
            secondary_adjustments["extraversion"] += 6
        if recency_preference > 0.8:  # Prefers very recent music
            secondary_adjustments["extraversion"] += 4
        
        # AGREEABLENESS: Higher for mainstream, accessible music, low explicit
        if mainstream_ratio > 0.5:
            secondary_adjustments["agreeableness"] += 8
        if explicit_ratio < 0.15:  # Low explicit content preference
            secondary_adjustments["agreeableness"] += 6
        if 40 <= avg_popularity <= 80:  # Moderately popular, accessible music
            secondary_adjustments["agreeableness"] += 5
        
        # EMOTIONAL_STABILITY: Higher for consistent patterns, moderate preferences
        if popularity_variance < 300:  # Consistent popularity preference
            secondary_adjustments["emotional_stability"] += 7
        if year_variance < 50:  # Consistent era preference
            secondary_adjustments["emotional_stability"] += 5
        if 0.3 <= recency_preference <= 0.9:  # Balanced old vs new preference
            secondary_adjustments["emotional_stability"] += 4
        if explicit_ratio < 0.2:  # Moderate explicit content
            secondary_adjustments["emotional_stability"] += 3
    
    # Apply secondary adjustments with reduced weight
    secondary_weight = 0.15  # 15% additional influence
    for trait in traits:
        adjustment = secondary_adjustments[trait] * secondary_weight
        traits[trait] = max(0, min(100, traits[trait] + adjustment))
        traits[trait] = round(traits[trait])
    
    # Calculate diversity metrics
    unique_genres = len(set(matched_genres))
    genre_diversity = min(unique_genres / len(top_genres), 1.0) if top_genres else 0
    cultural_diversity = len(cultural_regions) / 6  # Max 6 cultural regions
    
    # Advanced personality type classification
    def classify_advanced_personality(scores, diversity, complexity, cultural_div):
        """Multi-dimensional personality classification"""
        dominant_trait = max(scores, key=scores.get)
        dominant_score = scores[dominant_trait]
        
        # Calculate secondary influences
        sorted_traits = sorted(scores.items(), key=lambda x: x[1], reverse=True)
        secondary_trait = sorted_traits[1][0] if len(sorted_traits) > 1 else None
        secondary_score = sorted_traits[1][1] if len(sorted_traits) > 1 else 0
        
        # Base personality types with modifiers
        base_types = {
            "extraversion": "Social",
            "openness": "Creative", 
            "conscientiousness": "Organized",
            "agreeableness": "Harmonious",
            "emotional_stability": "Steady"
        }
        
        base_type = base_types.get(dominant_trait, "Balanced")
        
        # Add complexity modifiers
        if complexity > 0.7:
            complexity_modifier = "Intellectual"
        elif complexity > 0.5:
            complexity_modifier = "Thoughtful"
        else:
            complexity_modifier = "Accessible"
            
        # Add diversity modifiers  
        if diversity > 0.8:
            diversity_modifier = "Explorer"
        elif diversity > 0.6:
            diversity_modifier = "Adventurer"
        elif diversity > 0.4:
            diversity_modifier = "Curious"
        else:
            diversity_modifier = "Focused"
            
        # Add cultural modifiers
        if cultural_div > 0.5:
            cultural_modifier = "Global"
        elif cultural_div > 0.3:
            cultural_modifier = "Cosmopolitan"
        else:
            cultural_modifier = "Traditional"
            
        # Combine for final personality type
        if dominant_score > 70:
            intensity = "Highly"
        elif dominant_score > 60:
            intensity = "Moderately" 
        else:
            intensity = "Gently"
            
        # Special combinations
        if dominant_trait == "extraversion" and secondary_trait == "openness":
            return f"{cultural_modifier} {diversity_modifier}"
        elif dominant_trait == "openness" and complexity > 0.7:
            return f"{complexity_modifier} {diversity_modifier}"
        elif dominant_trait == "agreeableness" and cultural_div > 0.4:
            return f"{cultural_modifier} Connector"
        else:
            return f"{intensity} {base_type} {diversity_modifier}"
    
    # Generate advanced descriptions
    def generate_dynamic_description(trait_name, score, context):
        """Generate contextual descriptions based on multiple factors"""
        base_descriptions = {
            "openness": {
                "high": "intellectually curious and creatively adventurous",
                "medium": "balanced between traditional and innovative approaches", 
                "low": "practical and preferring established methods"
            },
            "conscientiousness": {
                "high": "highly organized and goal-oriented",
                "medium": "flexibly structured with adaptive planning",
                "low": "spontaneous and preferring flexible approaches"
            },
            "extraversion": {
                "high": "energetically social and outwardly focused",
                "medium": "socially balanced with both outgoing and introspective tendencies",
                "low": "reflectively introspective and preferring intimate connections"
            },
            "agreeableness": {
                "high": "highly empathetic and cooperation-focused",
                "medium": "diplomatically balanced between empathy and assertion",
                "low": "analytically objective and logic-focused"
            },
            "emotional_stability": {
                "high": "emotionally resilient and stress-resistant",
                "medium": "emotionally responsive yet stable",
                "low": "emotionally sensitive and deeply feeling"
            }
        }
        
        # Trait-specific contextual additions based on musical analysis
        trait_specific_contexts = {
            "openness": {
                "high_diversity": "with a strong appetite for musical exploration and genre experimentation",
                "high_complexity": "drawn to sophisticated and avant-garde musical expressions",
                "high_cultural": "showing deep appreciation for global musical traditions"
            },
            "conscientiousness": {
                "high_diversity": "with methodical exploration of different musical styles",
                "high_complexity": "appreciating structured and technically complex compositions",
                "high_cultural": "systematically engaging with diverse cultural music forms"
            },
            "extraversion": {
                "high_diversity": "energized by a wide range of social and danceable music",
                "high_complexity": "enjoying both mainstream hits and sophisticated musical arrangements",
                "high_cultural": "connecting through music across different cultural communities"
            },
            "agreeableness": {
                "high_diversity": "finding harmony and connection through diverse musical experiences",
                "high_complexity": "appreciating both accessible melodies and nuanced emotional expressions",
                "high_cultural": "embracing music as a bridge between different cultures and perspectives"
            },
            "emotional_stability": {
                "high_diversity": "maintaining emotional balance through varied musical moods and styles",
                "high_complexity": "comfortable with both challenging and soothing musical experiences",
                "high_cultural": "finding emotional resonance in music from different cultural backgrounds"
            }
        }
        
        level = "high" if score >= 65 else "medium" if score >= 45 else "low"
        base_desc = base_descriptions[trait_name][level]
        
        # Add trait-specific contextual modifier (only one per trait to avoid repetition)
        trait_contexts = trait_specific_contexts.get(trait_name, {})
        contextual_addition = None
        
        # Priority: complexity > cultural > diversity (to avoid multiple modifiers)
        if context["complexity"] > 0.7 and "high_complexity" in trait_contexts:
            contextual_addition = trait_contexts["high_complexity"]
        elif context["cultural_diversity"] > 0.4 and "high_cultural" in trait_contexts:
            contextual_addition = trait_contexts["high_cultural"]
        elif context["diversity"] > 0.6 and "high_diversity" in trait_contexts:
            contextual_addition = trait_contexts["high_diversity"]
        
        if contextual_addition:
            return f"You are {base_desc}, {contextual_addition}."
        else:
            return f"You are {base_desc}."
    
    # Calculate confidence score
    avg_match_confidence = sum(confidence_factors) / len(confidence_factors) if confidence_factors else 0.5
    data_quality = min(len(top_genres) / 10, 1.0)  # Ideal: 10+ genres
    genre_weight_distribution = 1.0 - (max(weight for _, weight in top_genres) / sum(weight for _, weight in top_genres)) if top_genres else 0.5
    
    # Factor in audio features availability for confidence
    audio_features_bonus = 0
    if audio_features and len(audio_features) > 0:
        audio_features_bonus = min(len(audio_features) / 20, 1.0) * 0.2  # Up to 20% bonus
    
    overall_confidence = (avg_match_confidence * 0.3 + data_quality * 0.25 + genre_weight_distribution * 0.25 + audio_features_bonus * 0.2) * 100
    
    # Generate context for descriptions
    context = {
        "diversity": genre_diversity,
        "complexity": complexity_score,
        "cultural_diversity": cultural_diversity
    }
    
    # Generate final personality type
    personality_type = classify_advanced_personality(traits, genre_diversity, complexity_score, cultural_diversity)
    
    # Generate descriptions
    descriptions = {}
    for trait_name in traits:
        descriptions[trait_name] = generate_dynamic_description(trait_name, traits[trait_name], context)
    
    # Prepare audio features summary
    audio_features_summary = None
    if audio_features and len(audio_features) > 0:
        avg_features = {}
        feature_keys = ['valence', 'energy', 'danceability', 'acousticness', 'instrumentalness', 'tempo']
        for key in feature_keys:
            values = [f.get(key, 0) for f in audio_features if f and f.get(key) is not None]
            avg_features[key] = round(sum(values) / len(values), 3) if values else 0
        audio_features_summary = avg_features
    
    return {
        "scores": traits,
        "descriptions": descriptions,
        "personality_type": personality_type,
        "confidence": round(overall_confidence, 1),
        "analysis_metadata": {
            "genre_diversity": round(genre_diversity, 3),
            "cultural_diversity": round(cultural_diversity, 3), 
            "complexity_score": round(complexity_score, 3),
            "cultural_regions": list(cultural_regions),
            "matched_genres": matched_genres[:5],  # Top 5 for reference
            "total_genres_analyzed": len(top_genres),
            "audio_features_analyzed": len(audio_features) if audio_features else 0,
            "audio_features_weight": round(audio_weight, 3) if audio_weight > 0 else 0,
            "audio_features_summary": audio_features_summary
        }
    }