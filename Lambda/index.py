from sqlalchemy import create_engine, func, NullPool
from sqlalchemy.orm import sessionmaker
from models import Fortune
import boto3, os

def get_secure_parameter(name):
    ssm = boto3.client('ssm', region_name="eu-central-1")
    response = ssm.get_parameter(
        Name=name,
        WithDecryption=True
    )
    return response['Parameter']['Value']

def changeDailyFortune(sessionLocal):
    session = sessionLocal()
    try:
        oldDaily = session.query(Fortune).filter(Fortune.daily == True).first()
        newDaily = session.query(Fortune).filter(Fortune.daily == False).order_by(func.rand()).first()
        oldDaily.daily = False
        newDaily.daily = True
        session.commit()
    except Exception as e:
        session.rollback()
        raise e
    finally:
        session.close()

def handler(event, context):
    password = get_secure_parameter('/coockie/appPassword')
    dns = os.getenv("DB_DNS")

    engine = create_engine(
        f"mysql+pymysql://appUser:{password}@{dns}:3306/coockieDb",
        poolclass=NullPool
    )
    sessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

    changeDailyFortune(sessionLocal)

    return {
        "statusCode": 200,
        "body": "Daily fortune updated successfully."
    }