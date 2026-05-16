import sys
import os
from sqlalchemy import create_engine, inspect, text
from sqlalchemy.orm import sessionmaker

# Add the backend directory to sys.path
sys.path.append(os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

try:
    from app.core.config import settings
    from app.core.database import Base, engine
    from app.models.user import User
except ImportError as e:
    print(f"Error importing modules: {e}")
    print("Make sure you are running this script from the backend/scripts directory.")
    sys.exit(1)

def fix_database():
    print(f"Connecting to database: {settings.DATABASE_URL}")
    
    # Use a direct connection to run ALTER TABLE commands
    with engine.connect() as conn:
        inspector = inspect(engine)
        
        # Check users table
        if 'users' in inspector.get_table_names():
            columns = [c['name'] for c in inspector.get_columns('users')]
            print(f"Current columns in 'users' table: {columns}")
            
            # List of columns to add if they are missing
            # Format: (column_name, column_type, default_value_sql)
            columns_to_add = [
                ('full_name', 'VARCHAR', 'NULL'),
                ('gender', 'VARCHAR', 'NULL'),
                ('age', 'INTEGER', 'NULL'),
                ('height', 'INTEGER', 'NULL'),
                ('weight', 'INTEGER', 'NULL'),
                ('fitness_level', 'VARCHAR', "'beginner'"),
                ('ai_fitness_rating', 'INTEGER', '0'),
                ('profile_picture', 'VARCHAR', 'NULL'),
                ('profile_emoji', 'VARCHAR', 'NULL'),
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
                ('created_at', 'TIMESTAMP WITH TIME ZONE', 'NOW()'),
                ('updated_at', 'TIMESTAMP WITH TIME ZONE', 'NULL'),
            ]
            
            for col_name, col_type, default in columns_to_add:
                if col_name not in columns:
                    print(f"Adding missing column: {col_name} ({col_type})")
                    try:
                        # PostgreSQL syntax for adding column
                        if 'postgresql' in settings.DATABASE_URL:
                            conn.execute(text(f'ALTER TABLE users ADD COLUMN {col_name} {col_type}'))
                            if default != 'NULL':
                                conn.execute(text(f'ALTER TABLE users ALTER COLUMN {col_name} SET DEFAULT {default}'))
                                conn.execute(text(f'UPDATE users SET {col_name} = {default} WHERE {col_name} IS NULL'))
                        # SQLite syntax (simpler)
                        else:
                            conn.execute(text(f'ALTER TABLE users ADD COLUMN {col_name} {col_type} DEFAULT {default}'))
                        
                        conn.commit()
                        print(f"Successfully added {col_name}")
                    except Exception as e:
                        print(f"Error adding {col_name}: {e}")
                else:
                    print(f"Column {col_name} already exists.")
            
            print("\nDatabase fix completed.")
        else:
            print("Error: 'users' table not found. Running Base.metadata.create_all() instead.")
            Base.metadata.create_all(bind=engine)
            print("Database tables created.")

if __name__ == "__main__":
    fix_database()
