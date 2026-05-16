"""comprehensive database sync

Revision ID: b2c3d4e5f6g7
Revises: a1b2c3d4e5f6
Create Date: 2026-05-07 18:38:00.000000

"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy.engine.reflection import Inspector

# revision identifiers, used by Alembic.
revision = 'b2c3d4e5f6g7'
down_revision = 'a1b2c3d4e5f6'
branch_labels = None
depends_on = None

def upgrade() -> None:
    conn = op.get_bind()
    inspector = Inspector.from_engine(conn)
    tables = inspector.get_table_names()

    # 1. Fix 'users' table columns
    if 'users' in tables:
        columns = [c['name'] for c in inspector.get_columns('users')]
        
        # Columns to add to 'users'
        user_cols = [
            ('full_name', sa.String(), True),
            ('gender', sa.String(), True),
            ('age', sa.Integer(), True),
            ('height', sa.Integer(), True),
            ('weight', sa.Integer(), True),
            ('fitness_level', sa.String(), False, sa.text("'beginner'")),
            ('ai_fitness_rating', sa.Integer(), False, sa.text('0')),
            ('profile_picture', sa.String(), True),
            ('profile_emoji', sa.String(), True),
            ('language', sa.String(), False, sa.text("'en'")),
            ('theme', sa.String(), False, sa.text("'light'")),
            ('voice_feedback', sa.Boolean(), False, sa.text('true')),
            ('is_premium', sa.Boolean(), False, sa.text('false')),
            ('subscription_end', sa.DateTime(timezone=True), True),
            ('lemon_squeezy_customer_id', sa.String(), True),
            ('social_provider', sa.String(), True),
            ('social_id', sa.String(), True),
            ('is_active', sa.Boolean(), False, sa.text('true')),
            ('is_verified', sa.Boolean(), False, sa.text('false')),
            ('is_admin', sa.Boolean(), False, sa.text('false')),
            ('updated_at', sa.DateTime(timezone=True), True),
        ]
        
        for col in user_cols:
            if col[0] not in columns:
                if len(col) == 4:
                    op.add_column('users', sa.Column(col[0], col[1], nullable=col[2], server_default=col[3]))
                else:
                    op.add_column('users', sa.Column(col[0], col[1], nullable=col[2]))

    # 2. Create missing tables if they don't exist
    if 'app_sessions' not in tables:
        op.create_table(
            'app_sessions',
            sa.Column('id', sa.String(), primary_key=True),
            sa.Column('user_id', sa.Integer(), sa.ForeignKey('users.id'), nullable=True),
            sa.Column('session_start', sa.DateTime(timezone=True), server_default=sa.func.now()),
            sa.Column('session_end', sa.DateTime(timezone=True), nullable=True),
            sa.Column('duration_seconds', sa.Integer(), nullable=True),
            sa.Column('device_type', sa.String(), nullable=True),
            sa.Column('device_model', sa.String(), nullable=True),
            sa.Column('os_name', sa.String(), nullable=True),
            sa.Column('os_version', sa.String(), nullable=True),
            sa.Column('app_version', sa.String(), nullable=True),
            sa.Column('country', sa.String(), nullable=True),
            sa.Column('city', sa.String(), nullable=True),
            sa.Column('timezone', sa.String(), nullable=True),
            sa.Column('connection_type', sa.String(), nullable=True)
        )

    if 'screen_views' not in tables:
        op.create_table(
            'screen_views',
            sa.Column('id', sa.Integer(), primary_key=True, autoincrement=True),
            sa.Column('user_id', sa.Integer(), sa.ForeignKey('users.id'), nullable=True),
            sa.Column('session_id', sa.String(), sa.ForeignKey('app_sessions.id'), nullable=True),
            sa.Column('screen_name', sa.String(), nullable=False),
            sa.Column('previous_screen', sa.String(), nullable=True),
            sa.Column('time_on_screen', sa.Integer(), nullable=True),
            sa.Column('viewed_at', sa.DateTime(timezone=True), server_default=sa.func.now()),
            sa.Column('extra_data', sa.JSON(), nullable=True)
        )

    if 'feature_usage' not in tables:
        op.create_table(
            'feature_usage',
            sa.Column('id', sa.Integer(), primary_key=True, autoincrement=True),
            sa.Column('user_id', sa.Integer(), sa.ForeignKey('users.id'), nullable=True),
            sa.Column('feature_name', sa.String(), nullable=False),
            sa.Column('action', sa.String(), nullable=False),
            sa.Column('used_at', sa.DateTime(timezone=True), server_default=sa.func.now()),
            sa.Column('extra_data', sa.JSON(), nullable=True)
        )

    if 'user_demographics' not in tables:
        op.create_table(
            'user_demographics',
            sa.Column('id', sa.Integer(), primary_key=True, autoincrement=True),
            sa.Column('user_id', sa.Integer(), sa.ForeignKey('users.id'), unique=True),
            sa.Column('age_range', sa.String(), nullable=True),
            sa.Column('gender', sa.String(), nullable=True),
            sa.Column('fitness_level', sa.String(), nullable=True),
            sa.Column('fitness_goal', sa.String(), nullable=True),
            sa.Column('country', sa.String(), nullable=True),
            sa.Column('city', sa.String(), nullable=True),
            sa.Column('timezone', sa.String(), nullable=True),
            sa.Column('primary_device', sa.String(), nullable=True),
            sa.Column('primary_os', sa.String(), nullable=True),
            sa.Column('app_language', sa.String(), server_default=sa.text("'en'")),
            sa.Column('how_found_app', sa.String(), nullable=True),
            sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.func.now()),
            sa.Column('updated_at', sa.DateTime(timezone=True), onupdate=sa.func.now())
        )

    if 'subscription_events' not in tables:
        op.create_table(
            'subscription_events',
            sa.Column('id', sa.Integer(), primary_key=True, autoincrement=True),
            sa.Column('user_id', sa.Integer(), sa.ForeignKey('users.id')),
            sa.Column('event_type', sa.String(), nullable=False),
            sa.Column('plan_from', sa.String(), nullable=True),
            sa.Column('plan_to', sa.String(), nullable=True),
            sa.Column('amount', sa.Float(), nullable=True),
            sa.Column('currency', sa.String(), server_default=sa.text("'USD'")),
            sa.Column('payment_method', sa.String(), nullable=True),
            sa.Column('external_subscription_id', sa.String(), nullable=True),
            sa.Column('external_transaction_id', sa.String(), nullable=True),
            sa.Column('trial_start', sa.DateTime(timezone=True), nullable=True),
            sa.Column('trial_end', sa.DateTime(timezone=True), nullable=True),
            sa.Column('converted_from_trial', sa.Boolean(), server_default=sa.text('false')),
            sa.Column('cancellation_reason', sa.String(), nullable=True),
            sa.Column('occurred_at', sa.DateTime(timezone=True), server_default=sa.func.now())
        )

    if 'error_logs' not in tables:
        op.create_table(
            'error_logs',
            sa.Column('id', sa.Integer(), primary_key=True, autoincrement=True),
            sa.Column('user_id', sa.Integer(), sa.ForeignKey('users.id'), nullable=True),
            sa.Column('error_type', sa.String(), nullable=False),
            sa.Column('error_message', sa.Text(), nullable=False),
            sa.Column('stack_trace', sa.Text(), nullable=True),
            sa.Column('screen', sa.String(), nullable=True),
            sa.Column('app_version', sa.String(), nullable=True),
            sa.Column('os_name', sa.String(), nullable=True),
            sa.Column('os_version', sa.String(), nullable=True),
            sa.Column('device_model', sa.String(), nullable=True),
            sa.Column('occurred_at', sa.DateTime(timezone=True), server_default=sa.func.now())
        )

def downgrade() -> None:
    pass
