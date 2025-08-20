import boto3
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from flask import current_app

def get_secure_parameter(name):
    ssm = boto3.client('ssm', region_name='eu-central-1')
    response = ssm.get_parameter(
        Name=name,
        WithDecryption=True
    )
    return response['Parameter']['Value']

engine = None
sessionLocal = None

def init_db(app):
    global engine, sessionLocal
    dbUrl = app.config["DB_URL"]
    engine = create_engine(app.config["DB_URL"],
        pool_size=5,
        max_overflow=10,
        pool_timeout=30,
        pool_recycle=3600
    )
    sessionLocal = sessionmaker(autocommit=False, autoflush=True, bind=engine)

def db_session():
    return sessionLocal()