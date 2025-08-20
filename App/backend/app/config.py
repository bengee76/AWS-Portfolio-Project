from .extensions import get_secure_parameter
import os


class Config:
    env = os.getenv("ENVIRONMENT", "development")
    DB_PASS = "devpassword"#tochange
    DB_URL = f"mysql+pymysql://appUser:{DB_PASS}@db:3306/cookie_development_db"

    if env == "staging" or env == "production":
        dns = os.getenv("DB_DNS", "development")
        DB_PASS = get_secure_parameter(f'/cookie-{env}/userPassword')
        DB_URL = f"mysql+pymysql://appUser:{DB_PASS}@{dns}:3306/cookie_{env}_db"

class DevelopmentConfig(Config):
    DEBUG = True
class StagingConfig(Config):
    DEBUG = False
class ProductionConfig(Config):
    DEBUG = False

config_map = {
    "development": DevelopmentConfig,
    "staging": StagingConfig,
    "production": ProductionConfig,
}