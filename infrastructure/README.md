# Infrastructure as Code

Terraform modules for deploying the Python microservice on AWS.

## Architecture

- **VPC**: Multi-AZ with public and private subnets
- **ECR**: Docker image registry
- **ECS Fargate**: Container orchestration
- **ALB**: Application Load Balancer
- **RDS PostgreSQL**: Database
- **Lambda**: Audit function
- **S3**: Log storage
- **CloudWatch**: Monitoring and logging

## Modules

- `vpc`: Network infrastructure
- `ecr`: Container registry
- `rds`: PostgreSQL database
- `s3`: Log storage bucket
- `lambda`: Audit function
- `ecs`: ECS cluster and service

## Usage

```bash
# Initialize
terraform init

# Plan
terraform plan -var="db_password=YOUR_PASSWORD"

# Apply
terraform apply -var="db_password=YOUR_PASSWORD"

# Outputs
terraform output
```

## State Management

Terraform state is stored in S3 with DynamoDB locking for team collaboration.

## Variables

See `variables.tf` for all configurable options. Copy `terraform.tfvars.example` to `terraform.tfvars` and customize.
