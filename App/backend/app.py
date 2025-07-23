from sqlalchemy import create_engine, func
from sqlalchemy.orm import sessionmaker
from flask import Flask, jsonify
from flask_cors import CORS
from Models.models import Fortune
import boto3, os


#GET SECRET
def get_secure_parameter(name):
    ssm = boto3.client('ssm', region_name='eu-central-1')
    response = ssm.get_parameter(
        Name=name,
        WithDecryption=True
    )
    return response['Parameter']['Value']
dns = os.getenv("DB_DNS")
environment = os.getenv("ENVIRONMENT")
password = get_secure_parameter(f'/cookie-{environment}/userPassword')
#DATABASE
engine = create_engine(
    f"mysql+pymysql://appUser:{password}@{dns}:3306/cookie_{environment}_db",
    pool_size=5,
    max_overflow=10,
    pool_timeout=30,
    pool_recycle=3600
)
sessionLocal = sessionmaker(autocommit=False, autoflush=True, bind=engine)

def dailyFortune():
    session = sessionLocal()
    try:
        dailyFortune = session.query(Fortune).filter(Fortune.daily == True).first()
        return dailyFortune
    finally:
        session.close()

def randomFortune():
    session = sessionLocal()
    try:
        randomFortune = session.query(Fortune).order_by(func.rand()).first()
        return randomFortune
    finally:
        session.close()

#WEBAPP
app = Flask(__name__)
CORS(app)

@app.route('/api/health', methods=['GET'])
def health_check():
    return jsonify({"status": "healthy"}), 200

@app.route('/api/dailyFortune', methods=['GET'])
def getDailyFortune():
    fortune = dailyFortune()
    if fortune:
        return jsonify(
            {
                "text": fortune.text,
                "author": fortune.author
            }
        )
    else:
        return jsonify({"message": "No fortune found"}), 404

@app.route('/api/randomFortune', methods=['GET'])
def getRandomFortune():
    fortune = randomFortune()
    if fortune:
        return jsonify(
            {
                "text": fortune.text,
                "author": fortune.author
            }
        )
    else:
        return jsonify({"message": "No fortune found"}), 404

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)