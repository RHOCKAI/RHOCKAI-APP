# Rhockai - Advanced Personal Training Platform

Rhockai is a professional workout tracking application with smart pose detection, real-time form analysis, and comprehensive performance analytics.

## 🏗️ Project Structure

```
AI POSTURE/
├── backend/          # FastAPI backend
├── frontend/         # Flutter mobile app
└── docker-compose.yml
```

## 🚀 Quick Start with Docker

### Prerequisites
- Docker & Docker Compose installed
- Git installed

### 1. Clone the Repository
```bash
git clone <your-repo-url>
cd "AI POSTURE"
```

### 2. Setup Environment Variables
```bash
cp .env.example .env
# Edit .env with your configuration
```

### 3. Start Services
```bash
# Start all services
docker-compose up -d

# Start with pgAdmin for database management
docker-compose --profile tools up -d

# View logs
docker-compose logs -f backend
```

### 4. Run Database Migrations
```bash
docker-compose exec backend alembic upgrade head
```

### 5. Access Services
- **Backend API**: http://localhost:8000
- **API Docs**: http://localhost:8000/docs
- **pgAdmin**: http://localhost:5050 (if started with --profile tools)

## 🛠️ Development Setup

### Backend (FastAPI)
```bash
cd backend
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
pip install -r requirements/base.txt
uvicorn app.main:app --reload
```

### Frontend (Flutter)
```bash
cd frontend
flutter pub get
flutter run
```

## 📊 Features

- **Smart Pose Detection**: Real-time form analysis for perfect reps
- **Personal Dashboard**: Clear performance and health metrics
- **Multi-language Support**: Voice feedback in 7+ languages
- **Premium Features**: Secure payments via Stripe & Lemon Squeezy
- **Gamification**: Stay motivated with streaks, levels, and achievements

## 🔧 Tech Stack

### Backend
- FastAPI
- PostgreSQL
- SQLAlchemy
- Alembic
- Pydantic v2

### Frontend
- Flutter
- Riverpod (State Management)
- Google ML Kit (Pose Detection)
- Camera & TTS

## 📝 Environment Variables

See `.env.example` for all available configuration options.

## 🐳 Docker Commands

```bash
# Stop all services
docker-compose down

# Rebuild and restart
docker-compose up -d --build

# View logs
docker-compose logs -f

# Access backend shell
docker-compose exec backend bash

# Access database
docker-compose exec postgres psql -U workout_user -d workout_tracker
```

## 📚 API Documentation

Once the backend is running, visit:
- Swagger UI: http://localhost:8000/docs
- ReDoc: http://localhost:8000/redoc

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License

This project is proprietary and confidential.
