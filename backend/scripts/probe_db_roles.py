import os
os.chdir(r'c:\Users\beino\Desktop\AI_POSTURE\backend')

from sqlalchemy import create_engine, text

candidates = [
    'postgresql+psycopg2://workout_user:INNOTEC1234@localhost:5432/ai_workout_db',
    'postgresql+psycopg2://postgres:INNOTEC1234@localhost:5432/ai_workout_db',
    'postgresql+psycopg2://postgres:postgres@localhost:5432/ai_workout_db',
    'postgresql+psycopg2://workout_user:postgres@localhost:5432/ai_workout_db',
    'postgresql+psycopg2://postgres:admin@localhost:5432/ai_workout_db',
    'postgresql+psycopg2://workout_user:admin@localhost:5432/ai_workout_db',
]

for d in candidates:
    try:
        e = create_engine(d)
        with e.connect() as conn:
            print('URL', d)
            print('current_user=', conn.execute(text("SELECT current_user")).scalar())
            print('tableowner=', conn.execute(text("SELECT tableowner FROM pg_tables WHERE schemaname='public' AND tablename='users'")).fetchall())
            print('roles=', conn.execute(text("SELECT rolname FROM pg_roles WHERE rolname IN ('postgres','workout_user')")).fetchall())
            print('---')
    except Exception as ex:
        print('FAIL', d, type(ex).__name__, ex)
        print('---')
