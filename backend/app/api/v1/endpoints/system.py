from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from sqlalchemy import inspect, text
from app.core.database import get_db, engine, Base
from app.core.config import settings
import logging

logger = logging.getLogger(__name__)

router = APIRouter()

@router.get("/version")
async def get_system_version():
    """
    Get the latest app version and download URL for OTA updates.
    """
    return {
        "latest_version": settings.LATEST_APP_VERSION,
        "download_url": settings.APK_DOWNLOAD_URL,
        "force_update": False
    }

@router.get("/fix-database")
async def fix_database(db: Session = Depends(get_db)):
    """
    Emergency endpoint to fix database schema issues by adding missing columns.
    """
    results = []
    try:
        inspector = inspect(engine)
        
        # 1. Check users table
        if 'users' in inspector.get_table_names():
            columns = [c['name'] for c in inspector.get_columns('users')]
            
            # List of columns to add if they are missing
            columns_to_add = [
                ('gender', 'VARCHAR', 'NULL'),
                ('age', 'INTEGER', 'NULL'),
                ('height', 'INTEGER', 'NULL'),
                ('weight', 'INTEGER', 'NULL'),
                ('fitness_level', 'VARCHAR', "'beginner'"),
                ('ai_fitness_rating', 'INTEGER', '0'),
                ('language', 'VARCHAR', "'en'"),
                ('theme', 'VARCHAR', "'light'"),
                ('voice_feedback', 'BOOLEAN', 'TRUE'),
                ('is_premium', 'BOOLEAN', 'FALSE'),
                ('subscription_end', 'TIMESTAMP WITH TIME ZONE', 'NULL'),
                ('trial_ends_at', 'TIMESTAMP WITH TIME ZONE', 'NULL'),
                ('lemon_squeezy_customer_id', 'VARCHAR', 'NULL'),
                ('social_provider', 'VARCHAR', 'NULL'),
                ('social_id', 'VARCHAR', 'NULL'),
                ('is_active', 'BOOLEAN', 'TRUE'),
                ('is_verified', 'BOOLEAN', 'FALSE'),
                ('is_admin', 'BOOLEAN', 'FALSE'),
                ('updated_at', 'TIMESTAMP WITH TIME ZONE', 'NULL'),
            ]
            
            for col_name, col_type, default in columns_to_add:
                if col_name not in columns:
                    try:
                        # PostgreSQL syntax
                        if 'postgresql' in str(engine.url):
                            db.execute(text(f'ALTER TABLE users ADD COLUMN {col_name} {col_type}'))
                            if default != 'NULL':
                                db.execute(text(f'ALTER TABLE users ALTER COLUMN {col_name} SET DEFAULT {default}'))
                                db.execute(text(f'UPDATE users SET {col_name} = {default} WHERE {col_name} IS NULL'))
                        else:
                            db.execute(text(f'ALTER TABLE users ADD COLUMN {col_name} {col_type} DEFAULT {default}'))
                        
                        db.commit()
                        results.append(f"Successfully added column 'users.{col_name}'")
                    except Exception as e:
                        db.rollback()
                        results.append(f"Error adding 'users.{col_name}': {str(e)}")
                else:
                    results.append(f"Column 'users.{col_name}' already exists")
        else:
            results.append("Table 'users' not found")

        # 2. Try to create all tables (in case some are completely missing)
        try:
            Base.metadata.create_all(bind=engine)
            results.append("Base.metadata.create_all() executed")
        except Exception as e:
            results.append(f"Error in create_all(): {str(e)}")

        return {
            "status": "completed",
            "results": results
        }
    except Exception as e:
        logger.error(f"Database fix failed: {e}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Database fix failed: {str(e)}"
        )
