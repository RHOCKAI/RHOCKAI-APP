# app/models/exercise.py

from sqlalchemy import Column, Integer, String, JSON
from app.core.database import Base

class Exercise(Base):
    __tablename__ = "exercises"
    
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, unique=True, nullable=False)
    slug = Column(String, unique=True, nullable=False)
    
    description = Column(String, nullable=False)
    difficulty = Column(String, nullable=False)  # beginner, intermediate, advanced
    
    # Target muscle groups (JSON array)
    muscle_groups = Column(JSON, nullable=False)
    
    # Exercise parameters
    default_reps = Column(Integer, default=10)
    default_sets = Column(Integer, default=3)
    
    # Instructions (JSON array of strings)
    instructions = Column(JSON, nullable=True)
    
    # Demo video URL
    demo_url = Column(String, nullable=True)