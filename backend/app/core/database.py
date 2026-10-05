# app/core/database.py

from sqlalchemy import create_engine, inspect, text
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool
from app.core.config import settings

if settings.DATABASE_URL.startswith('sqlite'):
    engine = create_engine(
        settings.DATABASE_URL,
        connect_args={"check_same_thread": False},
        poolclass=StaticPool,
    )
else:
    engine = create_engine(settings.DATABASE_URL)

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base = declarative_base()


def ensure_database_schema() -> None:
    """Add missing columns for older database instances without crashing startup."""
    try:
        inspector = inspect(engine)
        if 'users' not in inspector.get_table_names():
            return

        columns = {column['name'] for column in inspector.get_columns('users')}
        required_columns = {
            'full_name': 'VARCHAR',
            'gender': 'VARCHAR',
            'age': 'INTEGER',
            'height': 'INTEGER',
            'weight': 'INTEGER',
            'fitness_level': "VARCHAR DEFAULT 'beginner'",
            'ai_fitness_rating': 'INTEGER DEFAULT 0',
            'profile_picture': 'VARCHAR',
            'profile_emoji': 'VARCHAR',
            'language': "VARCHAR DEFAULT 'en'",
            'theme': "VARCHAR DEFAULT 'light'",
            'voice_feedback': 'BOOLEAN DEFAULT TRUE',
            'is_premium': 'BOOLEAN DEFAULT FALSE',
            'subscription_end': 'TIMESTAMP WITH TIME ZONE',
            'trial_ends_at': 'TIMESTAMP WITH TIME ZONE',
            'lemon_squeezy_customer_id': 'VARCHAR',
            'social_provider': 'VARCHAR',
            'social_id': 'VARCHAR',
            'is_active': 'BOOLEAN DEFAULT TRUE',
            'is_verified': 'BOOLEAN DEFAULT FALSE',
            'is_admin': 'BOOLEAN DEFAULT FALSE',
            'is_onboarded': 'BOOLEAN DEFAULT FALSE',
            'created_at': 'TIMESTAMP WITH TIME ZONE DEFAULT NOW()',
            'updated_at': 'TIMESTAMP WITH TIME ZONE',
        }

        with engine.begin() as conn:
            for column_name, column_def in required_columns.items():
                if column_name in columns:
                    continue
                if 'postgresql' in str(engine.url).lower():
                    conn.execute(
                        text(f'ALTER TABLE users ADD COLUMN {column_name} {column_def}')
                    )
                else:
                    conn.execute(
                        text(f'ALTER TABLE users ADD COLUMN {column_name} {column_def}')
                    )
    except Exception:
        # Schema repair is best-effort; startup should continue if the DB is not
        # yet initialized or the table is in a nonstandard state.
        pass


def get_db():
    """Dependency for database session"""
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()