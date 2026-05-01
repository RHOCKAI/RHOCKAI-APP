FROM python:3.11-slim

WORKDIR /app

# Install dependencies from the backend folder
COPY backend/requirements/base.txt . 
RUN pip install --no-cache-dir -r base.txt

# Copy the entire backend source code to the container
COPY backend/ .

# Match the port to Render's default
EXPOSE 10000

# Run the application (app.main:app works because we copied the contents of backend/ into /app)
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "10000"]
