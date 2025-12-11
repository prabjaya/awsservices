terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  
  backend "s3" {
    bucket         = "terraform-state-bucket-microservice"
    key            = "microservice/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
  }
}

provider "aws" {
  region = var.aws_region
}

# VPC and Networking
module "vpc" {
  source = "./modules/vpc"
  
  project_name = var.project_name
  environment  = var.environment
  vpc_cidr     = var.vpc_cidr
}

# ECR Repository
module "ecr" {
  source = "./modules/ecr"
  
  project_name = var.project_name
  environment  = var.environment
}

# RDS PostgreSQL
module "rds" {
  source = "./modules/rds"
  
  project_name        = var.project_name
  environment         = var.environment
  vpc_id              = module.vpc.vpc_id
  private_subnet_ids  = module.vpc.private_subnet_ids
  db_password         = var.db_password
}

# S3 for Logs
module "s3" {
  source = "./modules/s3"
  
  project_name = var.project_name
  environment  = var.environment
}

# Audit Lambda
module "lambda" {
  source = "./modules/lambda"
  
  project_name       = var.project_name
  environment        = var.environment
  logs_bucket_name   = module.s3.logs_bucket_name
}

# ECS Cluster and Service
module "ecs" {
  source = "./modules/ecs"
  
  project_name          = var.project_name
  environment           = var.environment
  vpc_id                = module.vpc.vpc_id
  public_subnet_ids     = module.vpc.public_subnet_ids
  private_subnet_ids    = module.vpc.private_subnet_ids
  ecr_repository_url    = module.ecr.repository_url
  db_host               = module.rds.db_endpoint
  db_name               = module.rds.db_name
  db_password           = var.db_password
  audit_lambda_name     = module.lambda.function_name
  logs_bucket_name      = module.s3.logs_bucket_name
}
