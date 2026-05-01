"""
Alembic environment configuration for AI Workout Tracker
---------------------------------------------------------

Features:
- Supports offline and online migrations
- Works on Windows (path fix included)
- Loads FastAPI application models for autogenerate
- Reads database URL from alembic.ini or env vars
- Production-ready structure
"""

import sys
from pathlib import Path
from logging.config import fileConfig
from typing import Optional

from sqlalchemy import engine_from_config, pool
from alembic import context

# ------------------------------------------------------------------
# PATH FIX (IMPORTANT FOR WINDOWS + BACKEND STRUCTURE)
# ------------------------------------------------------------------

# Project structure:
# AI POSTURE/
# ├── backend/
# │   └── app/
# ├── alembic/
# └── alembic.ini

BASE_DIR = Path(__file__).resolve().parents[1]
BACKEND_DIR = BASE_DIR / "backend"

if str(BACKEND_DIR) not in sys.path:
    sys.path.append(str(BACKEND_DIR))

# ------------------------------------------------------------------
# ALEMBIC CONFIG
# ------------------------------------------------------------------

config = context.config

# Configure Python logging via alembic.ini
if config.config_file_name is not None:
    fileConfig(config.config_file_name)

# ------------------------------------------------------------------
# IMPORT SQLALCHEMY BASE + MODELS
# ------------------------------------------------------------------

# IMPORTANT:
# Every model must be imported here so Alembic can detect them

from app.core.database import Base
from app.models.user import User
from app.models.workout import WorkoutSession

# Metadata used for autogeneration
target_metadata = Base.metadata

# ------------------------------------------------------------------
# OPTIONAL: DATABASE URL OVERRIDE (ENV VAR SUPPORT)
# ------------------------------------------------------------------

def get_database_url() -> Optional[str]:
    """
    Allow overriding sqlalchemy.url via environment variable.
    Example:
        set DATABASE_URL=postgresql://user:pass@localhost/db
    """
    import os
    return os.getenv("DATABASE_URL")


db_url = get_database_url()
if db_url:
    config.set_main_option("sqlalchemy.url", db_url)

# ------------------------------------------------------------------
# OFFLINE MIGRATIONS
# ------------------------------------------------------------------

def run_migrations_offline() -> None:
    """
    Run migrations in OFFLINE mode.

    This emits SQL statements to the script output without
    requiring a database connection.
    """

    url = config.get_main_option("sqlalchemy.url")

    context.configure(
        url=url,
        target_metadata=target_metadata,
        literal_binds=True,
        compare_type=True,
        compare_server_default=True,
        dialect_opts={"paramstyle": "named"},
    )

    with context.begin_transaction():
        context.run_migrations()

# ------------------------------------------------------------------
# ONLINE MIGRATIONS
# ------------------------------------------------------------------

def run_migrations_online() -> None:
    """
    Run migrations in ONLINE mode.

    Creates an engine and associates a live connection.
    """

    connectable = engine_from_config(
        config.get_section(config.config_ini_section, {}),
        prefix="sqlalchemy.",
        poolclass=pool.NullPool,
    )

    with connectable.connect() as connection:
        context.configure(
            connection=connection,
            target_metadata=target_metadata,
            compare_type=True,
            compare_server_default=True,
        )

        with context.begin_transaction():
            context.run_migrations()

# ------------------------------------------------------------------
# ENTRY POINT
# ------------------------------------------------------------------

if context.is_offline_mode():
    run_migrations_offline()
else:
    run_migrations_online()
