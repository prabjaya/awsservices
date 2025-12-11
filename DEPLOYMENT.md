# Deployment Guide

## Prerequisites

1. AWS Account with appropriate IAM permissions
2. AWS CLI configured locally
3. Terraform installed (>= 1.0)
4. Docker installed
5. GitHub repository created

## Step 1: Setup Terraform Backend

First, create the S3 bucket and DynamoDB table for Terraform state:

```bash
cd infrastructure
terraform init
terraform apply -target=aws_s3_bucket.terraform_state -target=aws_dynamodb_table.terraform_locks
```

After this completes, uncomment the backend configuration in `main.tf` and run:

```bash
terraform init -migrate-state
```

## Step 2: Configure GitHub Secrets

Add the following secrets to your GitHub repository (Settings > Secrets and variables > Actions):

- `AWS_ACCESS_KEY_ID`: Your AWS access key
- `AWS_SECRET_ACCESS_KEY`: Your AWS secret key
- `AWS_REGION`: AWS region (e.g., us-east-1)
- `DB_PASSWORD`: Strong password for RDS database

## Step 3: Deploy Infrastructure

```bash
cd infrastructure
terraform init
terraform plan -var="db_password=YOUR_SECURE_PASSWORD"
terraform apply -var="db_password=YOUR_SECURE_PASSWORD"
```

Save the outputs:
- ECR repository URL
- ALB DNS name
- RDS endpoint

## Step 4: Build and Push Docker Image

```bash
# Login to ECR
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <ECR_REGISTRY>

# Build and push
cd application
docker build -t <ECR_REPOSITORY_URL>:latest .
docker push <ECR_REPOSITORY_URL>:latest
```

## Step 5: Deploy Application via GitHub Actions

Push your code to the main branch:

```bash
git add .
git commit -m "Initial deployment"
git push origin main
```

GitHub Actions will automatically:
1. Build the Docker image
2. Push to ECR
3. Deploy to ECS

## Step 6: Verify Deployment

Check the ALB DNS name from Terraform outputs:

```bash
curl http://<ALB_DNS_NAME>/health
curl http://<ALB_DNS_NAME>/
```

## Step 7: Test API and Audit Logging

```bash
# Create data
curl -X POST http://<ALB_DNS_NAME>/api/data \
  -H "Content-Type: application/json" \
  -d '{"test": "data"}'

# Get requests
curl http://<ALB_DNS_NAME>/api/requests
```

Check S3 bucket for audit logs:

```bash
aws s3 ls s3://<LOGS_BUCKET_NAME>/audit-logs/ --recursive
```

## Monitoring

- **ECS Service**: AWS Console > ECS > Clusters > python-microservice-cluster
- **CloudWatch Logs**: /ecs/python-microservice
- **Lambda Logs**: /aws/lambda/python-microservice-audit-lambda
- **S3 Audit Logs**: Check the logs bucket

## Cleanup

To destroy all resources:

```bash
cd infrastructure
terraform destroy -var="db_password=YOUR_PASSWORD"
```

## Troubleshooting

### ECS Tasks Not Starting
- Check CloudWatch logs for container errors
- Verify security group rules
- Ensure ECR image exists

### Database Connection Issues
- Verify RDS security group allows traffic from ECS tasks
- Check DATABASE_URL environment variable
- Ensure RDS is in the same VPC

### Lambda Not Triggering
- Check ECS task IAM role has lambda:InvokeFunction permission
- Verify Lambda function name in environment variables
- Check Lambda CloudWatch logs for errors
