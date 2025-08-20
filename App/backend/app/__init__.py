from flask import Flask
from .config import config_map
from .extensions import init_db
import os

def create_app():
    env = os.getenv("ENVIRONMENT", "development")
    app = Flask(__name__)
    app.config.from_object(config_map[env])

    init_db(app)

    from .routes import main
    app.register_blueprint(main)

    return app