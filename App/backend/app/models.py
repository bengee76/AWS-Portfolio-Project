from sqlalchemy import Column, Integer, String, Boolean, func
from sqlalchemy.orm import declarative_base
import os
if os.getenv("LAMBDA") != "True":
    from .extensions import db_session

Base = declarative_base()

class Fortune(Base):
    __tablename__ = 'fortunes'

    id = Column(Integer, primary_key=True, autoincrement=True)
    daily = Column(Boolean, default=False)
    author = Column(String(30), nullable=False)
    text = Column(String(255), nullable=False)

    

    @classmethod
    def getDailyFortune(cls):
        session = db_session()
        try:
            fortune = session.query(cls).filter(Fortune.daily == True).first()
            return fortune
        finally:
            session.close()
    @classmethod
    def getRandomFortune(cls):
        session = db_session()
        try:
            randomFortune = session.query(cls).order_by(func.rand()).first()
            return randomFortune
        finally:
            session.close()
    @classmethod
    def changeDailyFortune(cls, session):  #Change to method actually used by flask. Lambda should only do an api call
        session = session()
        try:
            oldDaily = session.query(cls).filter(Fortune.daily == True).first()
            newDaily = session.query(cls).filter(Fortune.daily == False).order_by(func.rand()).first()
            oldDaily.daily = False
            newDaily.daily = True
            session.commit()
        except Exception:
            session.rollback()
            raise
        finally:
            session.close()