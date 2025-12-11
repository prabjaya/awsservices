# Architecture Overview

## System Architecture

```
┌─────────────┐
│   GitHub    │
│   Actions   │
└──────┬──────┘
       │ CI/CD
       ▼
┌─────────────┐
│     ECR     │
│   (Docker)  │
└──────┬──────┘
       │
       ▼
┌─────────────────────────────────────────┐
│              AWS VPC                     │
│  ┌────────────────────────────────────┐ │
│  │  Public Subnets (Multi-AZ)         │ │
│  │  ┌──────────────┐                  │ │
│  │  │     ALB      │                  │ │
│  │  └──────┬───────┘                  │ │
│  └─────────┼────────────────────────────┘ │
│            │                            │
│  ┌─────────┼────────────────────────────┐ │
│  │  Private Subnets (Multi-AZ)        │ │
│  │         ▼                           │ │
│  │  ┌──────────────┐                  │ │
│  │  │ ECS Fargate  │                  │ │
│  │  │   (Tasks)    │                  │ │
│  │  └──┬───────┬───┘                  │ │
│  │     │       │                      │ │
│  │     │       └──────────┐           │ │
│  │     ▼                  ▼           │ │
│  │  ┌──────────┐    ┌──────────┐     │ │
│  │  │   RDS    │    │  Lambda  │     │ │
│  │  │PostgreSQL│    │  (Audit) │     │ │
│  │  └──────────┘    └─────┬────┘     │ │
│  └────────────────────────┼──────────┘ │
└───────────────────────────┼────────────┘
                            │
                            ▼
                     ┌──────────────┐
                     │      S3      │
                     │  (Audit Logs)│
                     └──────────────┘
```

## Components

### Application Layer
- **FastAPI**: Python web framework
- **SQLAlchemy**: ORM for database operations
- **Boto3**: AWS SDK for Lambda invocation

### Infrastructure Layer
- **VPC**: Isolated network with public/private subnets across 2 AZs
- **ALB**: Distributes traffic to ECS tasks
- **ECS Fargate**: Serverless container orchestration
- **ECR**: Docker image registry
- **RDS PostgreSQL**: Relational database for API requests
- **Lambda**: Audit function triggered on each API call
- **S3**: Storage for audit logs with lifecycle policies
- **CloudWatch**: Centralized logging and monitoring

## Data Flow

1. **API Request**: Client → ALB → ECS Task
2. **Request Logging**: ECS Task → RDS (stores request metadata)
3. **Audit Trigger**: ECS Task → Lambda (async invocation)
4. **Audit Storage**: Lambda → S3 (stores detailed audit logs)
5. **Container Logs**: ECS Task → CloudWatch → S3 (via export)

## Security

- Private subnets for ECS tasks and RDS
- Security groups restrict traffic between components
- IAM roles with least privilege
- Encrypted S3 buckets
- VPC endpoints for AWS services (optional enhancement)

## High Availability

- Multi-AZ deployment
- Auto-scaling ECS tasks (configurable)
- RDS with automated backups
- ALB health checks with automatic failover

## Monitoring

- CloudWatch Logs for application and Lambda
- ECS Container Insights
- RDS Performance Insights
- S3 access logs
- ALB access logs

## Cost Optimization

- Fargate Spot instances (optional)
- S3 lifecycle policies (90-day retention)
- ECR image lifecycle (keep last 10)
- RDS instance sizing (t3.micro for dev)
