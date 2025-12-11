output "ecr_repository_url" {
  description = "ECR repository URL"
  value       = module.ecr.repository_url
}

output "ecs_cluster_name" {
  description = "ECS cluster name"
  value       = module.ecs.cluster_name
}

output "alb_dns_name" {
  description = "Application Load Balancer DNS name"
  value       = module.ecs.alb_dns_name
}

output "rds_endpoint" {
  description = "RDS endpoint"
  value       = module.rds.db_endpoint
}

output "logs_bucket_name" {
  description = "S3 bucket for logs"
  value       = module.s3.logs_bucket_name
}

output "audit_lambda_name" {
  description = "Audit Lambda function name"
  value       = module.lambda.function_name
}
