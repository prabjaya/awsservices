from fastapi import FastAPI, Request, Depends
from fastapi.responses import JSONResponse
import boto3
import json
import os
from datetime import datetime
from sqlalchemy import create_engine, Column, Integer, String, DateTime, Text
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker, Session
import logging

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Database setup
DATABASE_URL = os.getenv(
    "DATABASE_URL",
    "postgresql://dbuser:dbpassword@localhost:5432/apidb"
)

engine = create_engine(DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()

# Lambda client for audit
lambda_client = boto3.client('lambda', region_name=os.getenv('AWS_REGION', 'us-east-1'))
AUDIT_LAMBDA_NAME = os.getenv('AUDIT_LAMBDA_NAME', 'api-audit-lambda')

# Models
class APIRequest(Base):
    __tablename__ = "api_requests"
    
    id = Column(Integer, primary_key=True, index=True)
    timestamp = Column(DateTime, default=datetime.utcnow)
    method = Column(String(10))
    path = Column(String(255))
    client_ip = Column(String(50))
    request_body = Column(Text, nullable=True)
    response_status = Column(Integer)

# Create tables
Base.metadata.create_all(bind=engine)

app = FastAPI(title="Python Microservice", version="1.0.0")

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

async def trigger_audit_lambda(request_data: dict):
    """Trigger audit Lambda function"""
    try:
        lambda_client.invoke(
            FunctionName=AUDIT_LAMBDA_NAME,
            InvocationType='Event',  # Async invocation
            Payload=json.dumps(request_data)
        )
        logger.info(f"Audit lambda triggered for {request_data['path']}")
    except Exception as e:
        logger.error(f"Failed to trigger audit lambda: {str(e)}")

@app.middleware("http")
async def log_requests(request: Request, call_next):
    """Middleware to log all API requests"""
    # Capture request details
    body = None
    if request.method in ["POST", "PUT", "PATCH"]:
        body = await request.body()
        body = body.decode() if body else None
    
    # Process request
    response = await call_next(request)
    
    # Store in database
    db = next(get_db())
    try:
        api_request = APIRequest(
            method=request.method,
            path=str(request.url.path),
            client_ip=request.client.host,
            request_body=body,
            response_status=response.status_code
        )
        db.add(api_request)
        db.commit()
        
        # Trigger audit lambda
        audit_data = {
            "timestamp": datetime.utcnow().isoformat(),
            "method": request.method,
            "path": str(request.url.path),
            "client_ip": request.client.host,
            "status": response.status_code
        }
        await trigger_audit_lambda(audit_data)
        
    except Exception as e:
        logger.error(f"Failed to log request: {str(e)}")
        db.rollback()
    finally:
        db.close()
    
    return response

@app.get("/")
async def root():
    return {"message": "Python Microservice API", "status": "healthy"}

@app.get("/health")
async def health_check():
    return {"status": "healthy", "timestamp": datetime.utcnow().isoformat()}

@app.post("/api/data")
async def create_data(request: Request, db: Session = Depends(get_db)):
    body = await request.json()
    return {
        "message": "Data received",
        "data": body,
        "timestamp": datetime.utcnow().isoformat()
    }

@app.get("/api/data")
async def get_data(db: Session = Depends(get_db)):
    return {
        "message": "Data retrieved",
        "timestamp": datetime.utcnow().isoformat()
    }

@app.get("/api/requests")
async def get_requests(limit: int = 10, db: Session = Depends(get_db)):
    """Get recent API requests from database"""
    requests = db.query(APIRequest).order_by(APIRequest.timestamp.desc()).limit(limit).all()
    return {
        "count": len(requests),
        "requests": [
            {
                "id": r.id,
                "timestamp": r.timestamp.isoformat(),
                "method": r.method,
                "path": r.path,
                "client_ip": r.client_ip,
                "status": r.response_status
            }
            for r in requests
        ]
    }

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
