FROM python:3.12-slim

WORKDIR /app

# Copy the requirements package tracking your project dependencies
COPY requirements.txt /app/
RUN pip install --no-cache-dir -r requirements.txt

# Extract the contents of your subfolder directly into the container working root
COPY devops /app/

EXPOSE 8000

# Triggers the app cleanly without needing complex virtual environment sourcing
CMD ["python3", "manage.py", "runserver", "0.0.0.0:8000"]