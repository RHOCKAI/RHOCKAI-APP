FROM python:3.11-slim

WORKDIR /app

# Install dependencies
COPY requirements/base.txt . 
RUN pip install --no-cache-dir -r base.txt

# Copy the rest of the backend code
COPY . .

# Match the port to Render's default
EXPOSE 10000

# Run the application
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "10000"]
