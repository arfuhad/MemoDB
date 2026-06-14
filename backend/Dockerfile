FROM python:3.11-slim

WORKDIR /app

# System deps kept minimal; asyncpg ships wheels.
COPY pyproject.toml ./
RUN pip install --no-cache-dir .

COPY app ./app
COPY migrations ./migrations

EXPOSE 8000
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
