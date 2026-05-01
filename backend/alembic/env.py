# alembic/env.py

from logging.config import fileConfig
from sqlalchemy import engine_from_config, pool
from alembic import context
from app.core.database import Base
from app.core.config import settings

# Import all models here
from app.models import user, workout_session, exercise, subscription, analytics

config = context.config
config.set_main_option("sqlalchemy.url", settings.DATABASE_URL)

fileConfig(config.config_file_name)
target_metadata = Base.metadata

# ... rest of alembic config