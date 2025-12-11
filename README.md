# Python Microservice with AWS Infrastructure

This project contains a Python microservice deployed on AWS ECS with complete infrastructure automation.

## Repository Structure

```
.
├── application/          # Python microservice code
├── infrastructure/       # Terraform IaC
└── .github/workflows/   # CI/CD pipelines
```

## Architecture

- **Application**: FastAPI microservice with audit logging
- **Container**: Docker image pushed to AWS ECR
- **Compute**: AWS ECS Fargate
- **Database**: RDS PostgreSQL for API request storage
- **Logging**: CloudWatch logs exported to S3
- **Audit**: Lambda function triggered on each API call
- **State**: Terraform state stored in S3 with DynamoDB locking

## Prerequisites

- AWS Account with appropriate permissions
- GitHub repository with secrets configured
- Terraform >= 1.0
- Python 3.11+
- Docker

## GitHub Secrets Required

- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- `AWS_REGION`
- `ECR_REPOSITORY`
- `DB_PASSWORD`

## Deployment

1. Infrastructure: `cd infrastructure && terraform init && terraform apply`
2. Application: Push to main branch triggers CI/CD
# awsservices
