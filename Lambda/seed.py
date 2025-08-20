from sqlalchemy import create_engine, NullPool, text
from sqlalchemy.orm import sessionmaker
from models import Fortune, Base
from extensions import get_secure_parameter
import boto3, os, time

fortunes = [
    {"daily": True,  "author": "Confucius",       "text": "Our greatest glory is not in never falling, but in rising every time we fall."},
    {"daily": False, "author": "Yoda",            "text": "Do or do not. There is no try."},
    {"daily": False, "author": "Oscar Wilde",     "text": "Be yourself; everyone else is already taken."},
    {"daily": False, "author": "Albert Einstein", "text": "Life is like riding a bicycle. To keep your balance you must keep moving."},
    {"daily": False, "author": "Mark Twain",      "text": "The secret of getting ahead is getting started."},
    {"daily": False, "author": "Maya Angelou",    "text": "You will face many defeats in life, but never let yourself be defeated."},
    {"daily": False, "author": "Lao Tzu",         "text": "A journey of a thousand miles begins with a single step."},
    {"daily": False, "author": "Helen Keller",    "text": "Keep your face to the sunshine and you cannot see a shadow."},
    {"daily": False, "author": "Ralph Waldo Emerson", "text": "What lies behind us and what lies before us are tiny matters compared to what lies within us."},
    {"daily": False, "author": "Winston Churchill","text": "Success is not final, failure is not fatal: It is the courage to continue that counts."}
]

def createAppUser(engine, password, environment):
    with engine.begin() as conn:
        try:
            conn.execute(text("CREATE USER IF NOT EXISTS 'appUser'@'%' IDENTIFIED WITH mysql_native_password BY :password;"), {"password": password})
            conn.execute(text(f"GRANT SELECT, INSERT, UPDATE, DELETE ON cookie_{environment}_db.* TO 'appUser'@'%';"))
            conn.execute(text("FLUSH PRIVILEGES;"))
        except Exception:
            raise


def createFortune(sessionLocal, daily, author, text):
    session = sessionLocal()
    try:
        fortune = Fortune(
            daily = daily,
            author = author,
            text = text
        )
        session.add(fortune)
        session.commit()
    except Exception:
        session.rollback()
        raise
    finally:
        session.close()

def handler(event, context):

    dns = os.getenv("DB_DNS")
    environment = os.getenv("ENVIRONMENT")
    password = "devpassword"
    appPassword = "devpassword"
    if environment != "development":
        password = get_secure_parameter(f'/cookie-{environment}/adminPassword')
        appPassword = get_secure_parameter(f'/cookie-{environment}/userPassword')
    engine = create_engine(
        f"mysql+pymysql://root:{password}@{dns}:3306/cookie_{environment}_db",
        poolclass=NullPool
    )
    sessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

    createAppUser(engine, appPassword, environment)

    Base.metadata.create_all(bind=engine)

    for fortune in fortunes:
        createFortune(sessionLocal, fortune["daily"], fortune["author"], fortune["text"])

if __name__ == "__main__":
    time.sleep(10)
    handler(None, None)