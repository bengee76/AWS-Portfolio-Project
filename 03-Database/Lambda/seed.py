from sqlalchemy import create_engine, func, NullPool, text
from sqlalchemy.orm import sessionmaker
from models import Fortune, Base
import boto3, os

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

def get_secure_parameter(name):
    ssm = boto3.client('ssm')
    response = ssm.get_parameter(
        Name=name,
        WithDecryption=True
    )
    return response['Parameter']['Value']

def createAppUser(engine, password):
    with engine.connect() as conn:
        try:
            conn.execute(text("CREATE USER 'appUser'@'%' IDENTIFIED BY :password;"), {"password": password})
            conn.execute(text("GRANT ALL PRIVILEGES ON testdb.* TO 'appUser'@'%';"))
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
    except Exception as e:
        session.rollback()
        print(f"DB error{e}")
        raise
    finally:
        session.close()

def handler(event=None, context=None):
    password = get_secure_parameter('/coockie/password')
    appPassword = get_secure_parameter('/coockie/appPassword')
    dns = os.getenv("DB_DNS")

    engine = create_engine(
        f"mysql+pymysql://admin:{password}@{dns}:3306/coockieDb",
        poolclass=NullPool
    )
    sessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

    createAppUser(engine, appPassword)

    Base.metadata.create_all(bind=engine)

    for fortune in fortunes:
        try:
            createFortune(sessionLocal, fortune["daily"], fortune["author"], fortune["text"])
        except Exception:
            raise