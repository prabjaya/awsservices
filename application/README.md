# Python Microservice Application

FastAPI-based microservice with automatic audit logging and database persistence.

## Features

- RESTful API with FastAPI
- PostgreSQL database integration
- Automatic request logging to RDS
- Lambda-based audit trail to S3
- Health check endpoints
- Docker containerized

## API Endpoints

- `GET /` - Root endpoint
- `GET /health` - Health check
- `POST /api/data` - Create data
- `GET /api/data` - Retrieve data
- `GET /api/requests` - Get recent API requests

## Local Development

```bash
# Install dependencies
pip install -r requirements.txt

# Set environment variables
export DATABASE_URL="postgresql://dbuser:dbpassword@localhost:5432/apidb"
export AUDIT_LAMBDA_NAME="api-audit-lambda"
export AWS_REGION="us-east-1"

# Run application
python main.py
```

## Docker

```bash
# Build
docker build -t python-microservice .

# Run
docker run -p 8000:8000 \
  -e DATABASE_URL="postgresql://dbuser:dbpassword@host.docker.internal:5432/apidb" \
  python-microservice
```

## Testing

```bash
# Health check
curl http://localhost:8000/health

# Create data
curl -X POST http://localhost:8000/api/data \
  -H "Content-Type: application/json" \
  -d '{"key": "value"}'

# Get requests
curl http://localhost:8000/api/requests
```
