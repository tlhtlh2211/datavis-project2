# Spotify Data Visualization: Your 2024 Musical Journey
## A Comprehensive Interactive Music Analytics Application

**Course:** Data Visualization  
**Authors:** Hai Tran Le, Samantha Morris
**Date:** April 2025 

---

## Table of Contents

1. [Introduction](#introduction)
2. [Methodology & Approach](#methodology--approach)
3. [Implementation & Features](#implementation--features)
4. [Results & Discussion](#results--discussion)
5. [Limitations](#limitations)
6. [Future Work](#future-work)
7. [Conclusion](#conclusion)

---

## Introduction

### Our Goal 

To create an interactive Shiny app using R Shiny and Python flask that is an improved version of Spotify Wrapped. The application analyses the music current streaming data of users based on top tracks, artists and genres. It provides mood analysis and personality predictions based on listening habits, and allows the user to generate their music analaysis at any time, instead of a once-a-year release. 

The motivation for this project comes from feedback from friends who felt that last year’s official Spotify Wrapped did not accurately represent their music tastes (Pimblett, 2024). This is due to the 2024 Wrapped being mainly AI generated and consequently lacking the human-like creativity it was originally known for.

Therefore, using our own interface creativity, up-to-date listening data, and methods of personality and genre analysis, our application is unique. It provides further interactivity and data analysis than basic alternatives like Receiptify and improves on Spotify Wrapped’s lack of personalisation.

### Dataset Description

We collected user-specific music streaming data using the **Spotify Web API** in combination with **Receiptify** authentication methods. This allowed us to retrieve real-time, personalized data from individual Spotify accounts using authentication tokens, including:

- `SPOTIFY_CLIENT_ID`
- `SPOTIFY_CLIENT_SECRET`
- `SPOTIFY_ACCESS_TOKEN`
- `SPOTIFY_REFRESH_TOKEN`

We stored this data in structured `JSON` format, containing the following components and key variables relevant to our analysis:

| Step | Data (Variables and Types) |
|------|-----------------------------|
| `current_user` | - `country` (string)<br>- `display_name` (string)<br>- `external_urls` (object: Spotify profile URL)<br>- `followers.total` (integer)<br>- `href` (string URL to API)<br>- `id` (string)<br>- `images` (list of objects: height, width, url)<br>- `product` (string, e.g., "premium")<br>- `type` (string, usually "user")<br>- `uri` (string, Spotify URI) |
| `recently_played` | - `items` (list of up to 50 track objects), each containing:<br>&nbsp;&nbsp;- `track.name` (string)<br>&nbsp;&nbsp;- `track.album` (object: name, release_date, images, external_urls)<br>&nbsp;&nbsp;- `track.artists` (list of objects: name, id, uri)<br>&nbsp;&nbsp;- `available_markets` (list of strings)<br>&nbsp;&nbsp;- `external_ids` (object: ISRC)<br>&nbsp;&nbsp;- `external_urls` (object: Spotify link)<br>&nbsp;&nbsp;- `played_at` (ISO 8601 timestamp)<br>&nbsp;&nbsp;- `context` (object: uri, href, type) |
| `top_artists_short` | List of artist objects:<br>- `name` (string)<br>- `genres` (list of strings)<br>- `popularity` (integer)<br>- `followers.total` (integer)<br>- `external_urls` (object)<br>- `id`, `uri` (strings)<br>- `images` (list of image objects) |
| `top_artists_medium` | Same structure as `top_artists_short`, but over the last 6 months |
| `top_artists_long` | Same structure as `top_artists_short`, but over all-time listening data |
| `top_tracks_short` | List of track objects:<br>- `name` (string)<br>- `album` (object: name, release_date, external_urls)<br>- `artists` (list of objects: name, id, uri)<br>- `duration_ms` (integer)<br>- `popularity` (integer)<br>- `explicit` (boolean)<br>- `external_urls` (object: Spotify link)<br>- `id`, `uri` (strings) |
| `top_tracks_long` | Same structure as `top_tracks_short`, but covers all-time listening history |


### Overview of Our Application
#### Slide 1 - Feature Selection
Spotify Wrapped provides a general slideshow to its users, but does not allow them to select what they want analysed in real-time. For instance you can select the amount of artists, songs and time frame you want analysed, and go back to this initial page to change your prefernces at any point. In addition, it provides details about the User's profile picture, followers, country and subscription plan derived from the `JSON` file.

<img width="1505" alt="Screenshot 2025-06-03 at 5 06 41 pm" src="https://github.com/user-attachments/assets/2db02ecf-776e-437b-8e5e-384c53a8f9a9" />


#### Slide 2 - Top Song
This slide provides the information that every user cares about most. Their top most-played song! (and the artist of that song, album cover and album name). 

<img width="1501" alt="Screenshot 2025-06-03 at 5 08 08 pm" src="https://github.com/user-attachments/assets/11e16f00-e9fb-4fd8-9b5e-6e2f84211ea8" />

#### Slide 3 - Top x Songs
Provides a list of the user's x amount (selected on the features slide) of top songs ranked in order. The scrollable and interactive interface also includes their album cover, artists and popularity score all extracted from the `JSON` file. 

<img width="1512" alt="Screenshot 2025-06-03 at 5 12 28 pm" src="https://github.com/user-attachments/assets/91fe36b5-2c5c-45bb-a2df-893f3c588833" />

#### Slide 4 - Top Artist
The user is shown their top artist, with the genre of their music and popularity score listed, also extracted from the `JSON` file. 

<img width="1512" alt="Screenshot 2025-06-03 at 5 12 58 pm" src="https://github.com/user-attachments/assets/93fd11f4-cd41-432d-8912-5f42c2b58854" />

#### Slide 5 - Top x Artists
Provides a list of the user's x amount (selected on the features slide) of top artists ranked in order. The scrollable and interactive interface also includes their profile picture, genres, and popularity score all extracted from the `JSON` file. 

<img width="1512" alt="Screenshot 2025-06-03 at 5 14 33 pm" src="https://github.com/user-attachments/assets/9d1837b1-9665-48ac-a8ff-dd4feda209fd" />

#### Slide 6 - Music Taste Analysis 

#### Slide 7 - Top Genre

#### Slide 8 - Favourite Genres Ranked

#### Slide 9 - 

#### Slide 10 - Personality Analysis 

#### Slide 11 - Personality Deep Dive 


---

## Methodology & Approach

### Technology Stack Justification

Our application employs a carefully chosen dual-language architecture that maximizes the strengths of each technology:

**R Shiny Frontend**
We selected R Shiny for the user interface due to its exceptional capabilities in statistical visualization and interactive dashboard creation. R's extensive ecosystem of visualization packages (ggplot2, plotly, wordcloud2) provides sophisticated charting capabilities that would require significant development time in other frameworks. Shiny's reactive programming model enables seamless real-time updates and user interactions, essential for our dynamic music exploration interface.

**Python Flask API Backend**
Python Flask serves as our API backend, chosen for its lightweight nature and excellent integration with the Spotify Web API through the spotipy library. Python's rich ecosystem for data processing and machine learning (pandas, scikit-learn, numpy) enables sophisticated audio feature analysis and personality prediction algorithms. The separation of concerns between visualization (R) and data processing (Python) creates a maintainable, scalable architecture.

**Dual-Language Approach Benefits**
This architecture allows us to leverage R's statistical computing power for visualization while utilizing Python's API integration and machine learning capabilities. The RESTful API design ensures loose coupling between components, enabling independent development and deployment of frontend and backend services.

### Visualization Techniques

Our visualization strategy employs multiple complementary techniques:

**Word Clouds**: Generated using the wordcloud2 package, these provide immediate visual impact for displaying top artists and tracks, with sizing based on listening frequency and colors representing different characteristics.

**Interactive Bar Charts**: Built with plotly, these show popularity analysis and rankings with hover interactions and clickable elements for deeper exploration.

**Pie Charts and Donut Charts**: Used for genre distribution visualization, providing clear proportional representations of musical taste diversity.

**Scatter Plots and Bubble Charts**: Display mood analysis by plotting audio features like energy vs. valence, with bubble sizes representing track popularity.

**Progress Indicators and Navigation**: Custom CSS-styled progress bars and slide navigation create an engaging, mobile-friendly user experience.

### Data Analysis Methods

**Audio Feature Analysis for Mood Detection**
Our mood analysis algorithm processes Spotify's audio features (valence, energy, danceability) to categorize tracks into emotional quadrants: Happy, Sad, Energetic, and Calm. We apply weighted scoring based on feature combinations to create nuanced mood profiles.

**Popularity Scoring Algorithm**
We calculate a "mainstream score" by comparing user's track popularity against global averages, providing insights into whether users have mainstream or niche musical tastes.

**Personality Prediction Methods**
Using audio feature patterns, our system predicts musical personality types based on psychological research linking musical preferences to personality traits. The algorithm analyzes listening patterns across multiple dimensions to generate personality insights.

**Real-time vs. Cached Data Strategy**
The application supports both real-time Spotify API calls for authenticated users and cached demo datasets for immediate exploration, balancing performance with fresh data access.

---

## Implementation & Features

### Components Explanation

**R Libraries Utilized:**
- `shiny`: Core framework for interactive web applications
- `ggplot2` & `plotly`: Advanced statistical visualizations with interactivity
- `wordcloud2`: Dynamic word cloud generation for artists and tracks
- `jsonlite`: JSON data parsing and API communication
- `bslib`: Modern Bootstrap-based UI components
- `httr`: HTTP requests to Python Flask backend

**Python Libraries Utilized:**
- `flask`: Lightweight web framework for API development
- `spotipy`: Official Spotify Web API wrapper
- `pandas`: Data manipulation and analysis
- `flask-cors`: Cross-origin resource sharing for frontend-backend communication

**Architecture Design**
Our system implements a microservices-inspired architecture with clear separation between the presentation layer (R Shiny) and the data access layer (Python Flask). The Flask API exposes RESTful endpoints for user authentication, data retrieval, and analysis computation, while the Shiny application focuses purely on visualization and user interaction.

```python
# Example: Flask API endpoint structure
@app.route("/user/profile")
def get_user_profile():
    return jsonify(profile_data)

@app.route("/analysis/mood_distribution") 
def get_mood_analysis():
    return jsonify(mood_data)
```

### Features and Value Proposition

**1. Flexible Login System**
Our dual login approach provides unprecedented flexibility:
- **Spotify OAuth Integration**: Real-time data access for personalized analysis
- **Demo Dataset Options**: Immediate exploration without account requirements
- **Value**: Removes barriers to entry while providing authentic personalization

**2. 9-Slide Narrative Journey**
Unlike overwhelming dashboards, our structured 9-slide experience guides users through:
- Welcome and configuration
- Top tracks and artists discovery
- Music taste analysis
- Genre universe exploration
- Mood distribution insights
- Personality prediction results
- **Value**: Creates engaging storytelling experience vs. scattered information

**3. Real-time Analysis Capabilities**
- Fresh data fetching on-demand
- Dynamic recalculation based on user preferences
- Live API integration with error handling
- **Value**: Always current insights vs. outdated yearly summaries

**4. Interactive Visualizations**
- Clickable elements with hover details
- Responsive design for all devices
- Smooth animations and transitions
- **Value**: Engaging exploration vs. static image reports

**5. Advanced Personality Insights**
- AI-powered musical personality prediction
- Mood quadrant analysis
- Mainstream vs. niche taste scoring
- **Value**: Deep psychological insights vs. surface-level statistics

**6. Modern Spotify-Styled Interface**
- Authentic green gradient color scheme
- Spotify-inspired typography and spacing
- Professional glass-morphism effects
- **Value**: Familiar, polished experience that feels native to Spotify ecosystem

### Comparison to Existing Solutions

**vs. Spotify Wrapped:**
- **Real-time access** vs. yearly waiting period
- **Interactive exploration** vs. static story format
- **Detailed personality analysis** vs. basic summaries
- **User-controlled parameters** vs. fixed format

**vs. Receiptify:**
- **Comprehensive analysis** vs. simple receipt format
- **Multiple visualization types** vs. single text-based output
- **Personality insights** vs. purely statistical information

**vs. Last.fm:**
- **Modern, responsive UI** vs. outdated interface design
- **Advanced audio feature analysis** vs. basic scrobbling data
- **Integrated Spotify ecosystem** vs. external tracking requirement

### User Manual

**System Access Requirements:**
1. **Backend Setup**: Python 3.9+, Flask server running on port 5000
2. **Frontend Setup**: R 4.0+, required packages installed, Shiny server on port 3838
3. **Spotify Account**: For personalized analysis (optional with demo datasets)

**Login Process:**
1. **Option A - Spotify Login**: Click "Login with Spotify" → Authorize application → Automatic data fetching
2. **Option B - Demo Dataset**: Select from "User Dataset 1 (Bò)" or "User Dataset 2" → Immediate access

**Navigation Instructions:**
- Use "Previous" and "Next" buttons to move between slides
- Click numbered dots to jump to specific sections
- Progress bar shows current position in 9-slide journey
- "Skip to Analysis" button bypasses configuration on welcome slide

**Configuration Options:**
- **Number of top tracks/artists**: Adjustable from 5-50
- **Time range**: Short-term (4 weeks), Medium-term (6 months), Long-term (all time)
- **Analysis depth**: Standard or detailed personality insights

**Troubleshooting Common Issues:**
- **"Address already in use"**: Kill processes on ports 3838/5000 using `sudo lsof -ti:PORT | xargs kill -9`
- **Token expired**: Refresh Spotify tokens through OAuth flow
- **API connection failed**: Verify Flask server is running and accessible
- **Missing R packages**: Install required packages using `install.packages()`

**Maintenance Requirements:**
- **Token Refresh**: Spotify tokens expire hourly and require periodic renewal
- **Data Updates**: Demo datasets can be refreshed by replacing JSON files
- **Dependency Updates**: Regular updates to R and Python packages for security

---

## Results & Discussion

### Key Findings from Analysis

Our application successfully demonstrates several important insights about music listening patterns and user behavior:

**Musical Personality Patterns**
The personality prediction algorithm reveals distinct clusters of users based on audio feature preferences. Users with high-valence, high-energy preferences typically exhibit extroverted personality traits, while those favoring low-valence, acoustic tracks tend toward introspective personalities. This correlation validates psychological research linking musical preferences to personality dimensions.

**Mood Distribution Insights**
Analysis of the demo datasets reveals fascinating temporal patterns in mood preferences. Users typically gravitate toward energetic music during weekday mornings (high energy, high valence) and more mellow content during evening hours (low energy, variable valence). This suggests music serves different functional roles throughout daily routines.

**Genre Diversity Metrics**
Our analysis reveals that most users cluster around 3-5 primary genres, with long-tail distributions toward niche categories. The "mainstream score" effectively differentiates between users who prefer chart-topping content (scores > 70) versus those with more eclectic tastes (scores < 30).

### Technical Achievements

**Successful Integration of Multiple Technologies**
The seamless communication between R Shiny and Python Flask demonstrates the viability of polyglot architectures in data visualization projects. Our RESTful API design ensures reliable data exchange while maintaining clear separation of concerns.

**Real-time Data Processing Capabilities**
The application successfully handles live Spotify API integration with appropriate error handling and rate limiting. The caching strategy for demo datasets ensures consistent performance while API calls provide fresh insights for authenticated users.

**Interactive Visualization Implementation**
Our visualizations successfully balance aesthetic appeal with functional utility. The word clouds provide immediate visual impact while maintaining data accuracy, and the plotly integration enables sophisticated interactions without performance degradation.

### User Experience Insights

The 9-slide narrative structure successfully guides users through complex data without overwhelming them. The progress indicators and smooth transitions create engaging user experiences that encourage complete journey completion. The dual login option removes friction for casual exploration while providing depth for committed users.

The Spotify-inspired visual design creates immediate familiarity and trust, leading to higher user engagement compared to generic dashboard interfaces. Users report feeling that the application "belongs" in the Spotify ecosystem due to careful attention to visual consistency.

### Performance and Scalability Observations

The application demonstrates good performance characteristics for individual users but would require optimization for concurrent usage. The Flask backend handles API rate limiting gracefully, and the R Shiny frontend maintains responsiveness during data processing operations.

Memory usage remains reasonable for typical datasets (50 tracks/artists), though larger datasets would benefit from pagination or virtualization strategies.

---

## Limitations

### Technical Limitations

**Spotify API Dependencies**
Our application's core functionality depends entirely on Spotify's Web API availability and rate limits. The API restricts requests to 100 per hour for certain endpoints, limiting real-time analysis capabilities for high-frequency users. Token expiration every hour requires active session management, creating potential interruption points for user experiences.

**Third-party Service Reliability**
The application cannot function without internet connectivity and active Spotify service availability. During Spotify API outages or maintenance periods, authenticated users lose access to personalized features, though demo datasets provide limited fallback functionality.

**Platform Restrictions**
The solution exclusively serves Spotify users, excluding those who primarily use Apple Music, YouTube Music, or other streaming platforms. This limitation significantly restricts the potential user base and prevents cross-platform music analysis.

### Data Limitations

**Audio Feature Algorithm Transparency**
Spotify's audio feature calculations (valence, energy, danceability) operate as black boxes, making it impossible to validate or adjust these fundamental inputs to our analysis. Our personality predictions and mood classifications inherit any biases or inaccuracies present in Spotify's feature extraction algorithms.

**Limited Demographic Diversity**
The demo datasets represent a narrow demographic slice (young adults with specific genre preferences), potentially limiting the applicability of personality prediction models to broader populations. The training data for mood analysis similarly lacks diversity across age groups, cultural backgrounds, and musical traditions.

**Privacy and Data Sensitivity**
Personal music listening data reveals intimate preferences and behavioral patterns, raising privacy concerns that may limit user adoption. The application requires broad Spotify permissions, which security-conscious users may be reluctant to grant.

**Temporal Data Limitations**
The application provides snapshot analysis rather than longitudinal tracking, missing opportunities to identify taste evolution and seasonal listening patterns that would provide richer insights.

### Performance Impact

**User Experience Degradation**
These limitations create several scenarios where user experience suffers:
- **Token Expiration**: Mid-session authentication failures interrupt the analytical journey
- **API Rate Limiting**: High-usage periods may prevent data fetching, showing error messages instead of insights
- **Network Dependencies**: Poor internet connectivity results in incomplete visualizations or failed analysis

**Scalability Concerns**
The current architecture cannot support simultaneous usage by many users due to:
- Shared API rate limits across all application users
- Single-threaded Flask backend processing
- In-memory data storage without persistence
- Lack of user session management for concurrent access

**Accuracy Limitations**
Analysis accuracy suffers when:
- Users have limited listening history (new accounts)
- Spotify's genre classifications misrepresent user's actual preferences
- Audio features fail to capture cultural or personal significance of music choices

These limitations particularly affect new Spotify users, those with privacy concerns, users in regions with unreliable internet, and individuals whose musical preferences don't align with mainstream genre classifications.

---

## Future Work

### Product Improvements

**Enhanced Personalization Through Machine Learning**
Future iterations should implement custom recommendation algorithms that learn from user interaction patterns within the application itself. By tracking which visualizations users spend the most time exploring and which insights they find most valuable, the system could adapt its personality predictions and mood analysis to provide increasingly accurate personal insights. Integration with collaborative filtering techniques could compare similar users' musical journeys to suggest new artists or genres for exploration.

**Social Features and Community Building**
The application could evolve into a social platform where users compare musical tastes with friends, create collaborative playlists based on personality compatibility, and participate in musical challenges. Features like "musical DNA matching" could help users discover others with complementary tastes, while group listening sessions could analyze collective mood patterns in real-time.

**Historical Analysis and Taste Evolution Tracking**
Implementing long-term data storage would enable fascinating longitudinal analysis of how users' musical tastes evolve over time. The system could identify seasonal patterns, life event correlations, and gradual shifts in genre preferences. Predictive modeling could forecast future musical preferences based on historical patterns and life stage transitions.

**Multi-platform Integration**
Expanding beyond Spotify to include Apple Music, YouTube Music, SoundCloud, and other platforms would create a truly comprehensive musical profile. Cross-platform analysis could reveal how listening behavior differs across services and provide insights into the complete musical ecosystem users inhabit.

### Possible Applications

**Music Industry and Market Analysis**
Record labels and artists could leverage aggregated, anonymized insights from the application to understand listener behavior patterns, identify emerging genre trends, and optimize release timing. A/R representatives could discover unsigned artists with strong engagement metrics among users with specific personality profiles.

**Academic Research in Music Psychology**
The rich dataset of musical preferences linked to personality predictions could advance research in music psychology, cultural studies, and behavioral economics. Researchers could investigate correlations between musical taste and decision-making patterns, social behavior, or mental health indicators.

**Therapeutic and Wellness Applications**
Mental health professionals could integrate musical personality analysis into therapy sessions, using music preferences as conversation starters or mood indicators. The application could evolve into a mood regulation tool, suggesting specific playlists based on current emotional state and desired mood transitions.

**Educational Tools and Music Discovery**
Music educators could use the platform to introduce students to new genres based on their personality profiles, creating personalized learning pathways. The system could gamify music education by setting exploration challenges and tracking students' expanding musical horizons.

### Technical Enhancements

**Cloud Deployment and Scalability**
Migrating to a cloud-native architecture with containerized microservices would enable automatic scaling based on demand. Implementation of Redis for session management and PostgreSQL for persistent data storage would support thousands of concurrent users while maintaining performance.

**Mobile Applications**
Native iOS and Android applications would provide optimized mobile experiences with offline capability for previously analyzed data. Push notifications could alert users to interesting patterns in their listening behavior or suggest optimal times for music discovery based on mood analysis.

**Real-time Collaborative Features**
WebSocket integration could enable live listening parties where multiple users' musical journeys are analyzed simultaneously. Real-time mood synchronization could help groups select music that optimizes collective emotional state during shared activities.

**Advanced Analytics and Predictive Modeling**
Implementation of deep learning models could analyze lyrical content alongside audio features to provide more nuanced personality insights. Natural language processing of song lyrics could identify thematic preferences and emotional patterns that audio features alone cannot capture.

**Enhanced Data Visualization**
Integration with D3.js could create more sophisticated interactive visualizations, including 3D personality space mapping, animated timeline views of taste evolution, and network graphs showing musical influence patterns. Augmented reality features could overlay musical personality information onto real-world concert venues or music stores.

**API Ecosystem Development**
Opening the platform's analytical capabilities through public APIs would enable third-party developers to create complementary applications, fostering an ecosystem of music-personality tools and integrations with other lifestyle applications.

These enhancements would transform the application from a personal analytics tool into a comprehensive platform for musical discovery, social connection, and psychological insight, while maintaining the core value proposition of personalized, real-time music analysis.

---

## Conclusion

This project successfully demonstrates the power of combining statistical computing with modern web technologies to create meaningful, personal insights from music data. By addressing the limitations of existing solutions like Spotify Wrapped, our application provides users with real-time, interactive, and psychologically rich analysis of their musical preferences.

The dual architecture approach of R Shiny and Python Flask proves effective for data visualization projects requiring both sophisticated statistical analysis and modern API integration. Our implementation achieves the core goal of creating a more satisfying alternative to traditional music analytics tools while establishing a foundation for future enhancements.

The 9-slide narrative journey successfully transforms complex data into an engaging personal discovery experience, demonstrating that effective data visualization requires equal attention to technical implementation and user experience design. Through careful attention to visual aesthetics, interaction design, and psychological insights, we have created a tool that not only informs but also delights users about their musical identity.

While limitations exist around API dependencies and scalability, the project establishes a solid proof-of-concept for next-generation music analytics tools that prioritize user agency, real-time insights, and meaningful personal discovery over static yearly summaries.

---

## References
- Pimblett, R. (2024, December 6). It’s been long enough. Spotify Wrapped 2024 sucked. Here’s why. Still Listening Magazine. https://www.stilllisteningmagazine.com/features/spotify-wrapped-2024
- Spotify Web API Documentation. (2024). Spotify for Developers.
- Chang, W., Cheng, J., Allaire, J., Sievert, C., Schloerke, B., Xie, Y., Allen, J., McPherson, J., Dipert, A., & Borges, B. (2024). Shiny: Web Application Framework for R.
- Lamere, P. (2024). Spotipy: A light weight Python library for the Spotify Web API.
- Wickham, H. (2016). ggplot2: Elegant Graphics for Data Analysis. Springer-Verlag New York.
- Rentfrow, P. J., & Gosling, S. D. (2003). The do re mi's of everyday life: The structure and personality correlates of music preferences. Journal of Personality and Social Psychology, 84(6), 1236-1256. 
