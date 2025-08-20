from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import NullPool
from models import Fortune
from extensions import get_secure_parameter
import boto3, os

def handler(event, context):
    dns = os.getenv("DB_DNS")
    environment = os.getenv("ENVIRONMENT")
    password = "devpassword"
    if environment != "development":
        password = get_secure_parameter(f'/cookie-{environment}/userPassword')
    engine = create_engine(
        f"mysql+pymysql://appUser:{password}@{dns}:3306/cookie_{environment}_db",
        poolclass=NullPool
    )
    sessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

    Fortune.changeDailyFortune(sessionLocal)

if __name__ == "__main__":
    handler(None, None)