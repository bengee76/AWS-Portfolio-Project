from sqlalchemy import Column, Integer, String, Boolean
from sqlalchemy.orm import declarative_base

Base = declarative_base()
class Fortune(Base):
    __tablename__ = 'fortunes'

    id = Column(Integer, primary_key=True, autoincrement=True)
    daily = Column(Boolean, default=False)
    author = Column(String(30), nullable=False)
    text = Column(String(255), nullable=False)