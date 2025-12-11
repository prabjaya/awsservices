#!/bin/bash
set -e

echo "==================================="
echo "Python Microservice Setup Script"
echo "==================================="

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check prerequisites
echo -e "\n${YELLOW}Checking prerequisites...${NC}"

command -v aws >/dev/null 2>&1 || { echo -e "${RED}AWS CLI is required but not installed.${NC}" >&2; exit 1; }
command -v terraform >/dev/null 2>&1 || { echo -e "${RED}Terraform is required but not installed.${NC}" >&2; exit 1; }
command -v docker >/dev/null 2>&1 || { echo -e "${RED}Docker is required but not installed.${NC}" >&2; exit 1; }

echo -e "${GREEN}✓ All prerequisites met${NC}"

# Get AWS region
read -p "Enter AWS region (default: us-east-1): " AWS_REGION
AWS_REGION=${AWS_REGION:-us-east-1}

# Get database password
read -sp "Enter database password: " DB_PASSWORD
echo

if [ -z "$DB_PASSWORD" ]; then
    echo -e "${RED}Database password is required${NC}"
    exit 1
fi

# Step 1: Create Terraform backend
echo -e "\n${YELLOW}Step 1: Creating Terraform backend (S3 + DynamoDB)...${NC}"
cd infrastructure

# Temporarily comment out backend configuration
sed -i.bak '/backend "s3"/,/}/s/^/#/' main.tf

terraform init
terraform apply -target=aws_s3_bucket.terraform_state -target=aws_dynamodb_table.terraform_locks -auto-approve

# Restore backend configuration
mv main.tf.bak main.tf

# Migrate state to S3
terraform init -migrate-state -force-copy

echo -e "${GREEN}✓ Terraform backend created${NC}"

# Step 2: Deploy infrastructure
echo -e "\n${YELLOW}Step 2: Deploying infrastructure...${NC}"
terraform apply -var="db_password=$DB_PASSWORD" -var="aws_region=$AWS_REGION" -auto-approve

# Get outputs
ECR_URL=$(terraform output -raw ecr_repository_url)
ALB_DNS=$(terraform output -raw alb_dns_name)

echo -e "${GREEN}✓ Infrastructure deployed${NC}"
echo -e "ECR Repository: ${ECR_URL}"
echo -e "ALB DNS: ${ALB_DNS}"

# Step 3: Build and push Docker image
echo -e "\n${YELLOW}Step 3: Building and pushing Docker image...${NC}"
cd ../application

# Login to ECR
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $(echo $ECR_URL | cut -d'/' -f1)

# Build and push
docker build -t $ECR_URL:latest .
docker push $ECR_URL:latest

echo -e "${GREEN}✓ Docker image pushed to ECR${NC}"

# Step 4: Update ECS service
echo -e "\n${YELLOW}Step 4: Deploying to ECS...${NC}"
aws ecs update-service \
    --cluster python-microservice-cluster \
    --service python-microservice-service \
    --force-new-deployment \
    --region $AWS_REGION

echo -e "${GREEN}✓ ECS service updated${NC}"

# Wait for service to stabilize
echo -e "\n${YELLOW}Waiting for service to become stable...${NC}"
aws ecs wait services-stable \
    --cluster python-microservice-cluster \
    --services python-microservice-service \
    --region $AWS_REGION

echo -e "${GREEN}✓ Service is stable${NC}"

# Test deployment
echo -e "\n${YELLOW}Testing deployment...${NC}"
sleep 10
HEALTH_CHECK=$(curl -s http://$ALB_DNS/health)
echo "Health check response: $HEALTH_CHECK"

echo -e "\n${GREEN}==================================="
echo "Deployment Complete!"
echo "===================================${NC}"
echo -e "Application URL: ${GREEN}http://$ALB_DNS${NC}"
echo -e "\nTest commands:"
echo "  curl http://$ALB_DNS/health"
echo "  curl http://$ALB_DNS/"
echo "  curl -X POST http://$ALB_DNS/api/data -H 'Content-Type: application/json' -d '{\"test\":\"data\"}'"
echo ""
echo -e "${YELLOW}Note: Save your database password securely!${NC}"
