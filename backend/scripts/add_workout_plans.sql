-- SQL Migration to add AI Workout Planning features
-- Target Database: PostgreSQL

BEGIN;

-- 1. Create Workout Plans table
CREATE TABLE workout_plans (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    name VARCHAR NOT NULL,
    focus VARCHAR NOT NULL,
    start_date TIMESTAMP WITH TIME ZONE NOT NULL,
    end_date TIMESTAMP WITH TIME ZONE,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_workout_plans_users FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

CREATE INDEX ix_workout_plans_id ON workout_plans (id);
CREATE INDEX ix_workout_plans_user_id ON workout_plans (user_id);

-- 2. Create Scheduled Workouts table
CREATE TABLE scheduled_workouts (
    id SERIAL PRIMARY KEY,
    plan_id INTEGER NOT NULL,
    day_number INTEGER NOT NULL,
    target_date TIMESTAMP WITH TIME ZONE,
    name VARCHAR NOT NULL,
    focus_muscle_groups JSON NOT NULL,
    is_completed BOOLEAN NOT NULL DEFAULT FALSE,
    completed_session_id INTEGER,
    CONSTRAINT fk_scheduled_workouts_plans FOREIGN KEY (plan_id) REFERENCES workout_plans(id) ON DELETE CASCADE,
    CONSTRAINT fk_scheduled_workouts_sessions FOREIGN KEY (completed_session_id) REFERENCES workout_sessions(id) ON DELETE SET NULL
);

CREATE INDEX ix_scheduled_workouts_id ON scheduled_workouts (id);
CREATE INDEX ix_scheduled_workouts_plan_id ON scheduled_workouts (plan_id);

-- 3. Create Planned Exercises table
CREATE TABLE planned_exercises (
    id SERIAL PRIMARY KEY,
    scheduled_workout_id INTEGER NOT NULL,
    exercise_id INTEGER NOT NULL,
    "order" INTEGER NOT NULL,
    target_sets INTEGER NOT NULL,
    target_reps INTEGER NOT NULL,
    target_weight_kg INTEGER,
    target_rest_seconds INTEGER NOT NULL DEFAULT 60,
    is_substituted BOOLEAN NOT NULL DEFAULT FALSE,
    original_exercise_id INTEGER,
    CONSTRAINT fk_planned_exercises_workout FOREIGN KEY (scheduled_workout_id) REFERENCES scheduled_workouts(id) ON DELETE CASCADE,
    CONSTRAINT fk_planned_exercises_exercise FOREIGN KEY (exercise_id) REFERENCES exercises(id) ON DELETE CASCADE,
    CONSTRAINT fk_planned_exercises_original FOREIGN KEY (original_exercise_id) REFERENCES exercises(id) ON DELETE SET NULL
);

CREATE INDEX ix_planned_exercises_id ON planned_exercises (id);
CREATE INDEX ix_planned_exercises_workout_id ON planned_exercises (scheduled_workout_id);

COMMIT;
