"""
API route definitions for Spotify data visualization project.
This package organizes routes into logical groups.
"""
# Use absolute imports instead of relative imports
from routes.user import user_bp
from routes.analysis import analysis_bp

def register_routes(app):
    """
    Register all route blueprints with the Flask app
    
    Args:
        app: Flask application instance
    """
    # Register user routes with /user prefix
    app.register_blueprint(user_bp, url_prefix='/user')
    
    # Register analysis routes with /analysis prefix
    app.register_blueprint(analysis_bp, url_prefix='/analysis')